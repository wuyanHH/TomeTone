package com.tometone.app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File

/**
 * SAF（Storage Access Framework）桥。
 *
 * 为什么自己写：`StorageProvider` 契约需要**目录列举与元数据**（名称 / 是否目录 /
 * 大小 / 修改时间），而现成插件只提供 URI 级字节读取（且 `shared_storage` 已废弃）。
 *
 * 与 Flutter 的约定：
 * - `openDirectory()` → `{uri, name}` 或 `null`（用户取消）；拿到的 tree URI 会
 *   `takePersistableUriPermission`，重启后仍可访问。
 * - `list(documentUri)` → 子项数组；`documentUri` 可以是 tree URI（首次）或文档 URI。
 * - `stat(documentUri)` → 单个条目或 `null`。
 * - `documentUri(treeUri, relativePath)` → 库内相对路径对应的 document URI，
 *   找不到为 `null`。播放与封面靠它把「根 + 相对路径」变成可直接交给引擎的 URI。
 * - `readBytes(documentUri)` → 文件字节（有上限，超过返回 `too_large`）。
 * - `copyToCache(documentUri, name)` → 复制到 `cacheDir/tometone-media` 后的绝对路径。
 * - `releasePermission(treeUri)` → 放弃该 tree URI 的持久化读授权，返回是否放弃成功
 *   （本来就没授权 / URI 非法返回 `false`，不是错误）。
 *
 * 只做只读访问：M1 的入库通道只需要"读"，不碰写回（§7.1 v1 范围）。
 * `copyToCache` 只写应用私有缓存，不修改用户书库。
 */
class MainActivity : FlutterActivity() {
    private var pendingPick: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "tometone/device")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSupportedAbis" -> result.success(android.os.Build.SUPPORTED_ABIS.toList())
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openDirectory" -> openDirectory(result)
                    "list" -> list(call.argument<String>("documentUri"), result)
                    "stat" -> stat(call.argument<String>("documentUri"), result)
                    "documentUri" -> documentUri(
                        call.argument<String>("treeUri"),
                        call.argument<String>("relativePath"),
                        result
                    )
                    "readBytes" -> readBytes(
                        call.argument<String>("documentUri"),
                        result
                    )
                    "copyToCache" -> copyToCache(
                        call.argument<String>("documentUri"),
                        call.argument<String>("name"),
                        result
                    )
                    "releasePermission" -> releasePermission(
                        call.argument<String>("treeUri"),
                        result
                    )
                    else -> result.notImplemented()
                }
            }
    }

    private fun openDirectory(result: MethodChannel.Result) {
        if (pendingPick != null) {
            result.error("busy", "已有目录选择在进行", null)
            return
        }
        pendingPick = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PREFIX_URI_PERMISSION
            )
        }
        startActivityForResult(intent, REQUEST_PICK)
    }

    @Deprecated("SAF 选择器需要 Activity 结果；此处沿用 startActivityForResult")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_PICK) return
        val pending = pendingPick ?: return
        pendingPick = null

        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            pending.success(null)
            return
        }
        try {
            contentResolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION
            )
        } catch (error: SecurityException) {
            // 授权失败也要继续读完本次会话；只是重启后需要重新授权。
        }
        pending.success(mapOf("uri" to uri.toString(), "name" to displayNameOf(uri)))
    }

    /**
     * 放弃 tree URI 的持久化读授权（best-effort）。
     *
     * 与 [openDirectory] 里的 `takePersistableUriPermission` 相反：书库根被移除时，
     * 界面上告诉用户「会一并放弃系统授权」，这里就得真的把授权放掉。
     *
     * 只释放 [Intent.FLAG_GRANT_READ_URI_PERMISSION] 这一个 flag，绝不触碰其它权限位。
     * 授权本来就不在（[SecurityException]）或 URI 非法 → `success(false)`，
     * **不是错误**：调用方正忙着删登记，授权放弃失败不能让删除跟着失败。
     */
    private fun releasePermission(treeUri: String?, result: MethodChannel.Result) {
        if (treeUri.isNullOrEmpty()) {
            result.success(false)
            return
        }
        try {
            contentResolver.releasePersistableUriPermission(
                Uri.parse(treeUri),
                Intent.FLAG_GRANT_READ_URI_PERMISSION
            )
            result.success(true)
        } catch (error: SecurityException) {
            // 本来就没有持久化授权：对调用方而言与「已放弃」等价。
            result.success(false)
        } catch (error: IllegalArgumentException) {
            // URI 不合法（例如不是 tree URI）：同样按「没放弃任何东西」处理。
            result.success(false)
        }
    }

    private fun list(documentUri: String?, result: MethodChannel.Result) {
        if (documentUri == null) {
            result.error("invalid_argument", "documentUri 不能为空", null)
            return
        }
        try {
            val uri = Uri.parse(documentUri)
            val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(
                uri,
                documentIdOf(uri)
            )
            val entries = ArrayList<Map<String, Any?>>()
            contentResolver.query(childrenUri, PROJECTION, null, null, null)?.use { cursor ->
                while (cursor.moveToNext()) {
                    entries.add(entryOf(uri, cursor))
                }
            }
            result.success(entries)
        } catch (error: Exception) {
            result.error("saf_list_failed", error.message, null)
        }
    }

    private fun stat(documentUri: String?, result: MethodChannel.Result) {
        if (documentUri == null) {
            result.error("invalid_argument", "documentUri 不能为空", null)
            return
        }
        try {
            val uri = Uri.parse(documentUri)
            contentResolver.query(uri, PROJECTION, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    result.success(entryOf(uri, cursor))
                    return
                }
            }
            result.success(null)
        } catch (error: Exception) {
            result.error("saf_stat_failed", error.message, null)
        }
    }

    /**
     * 逐段把库内相对路径解析成 document URI。
     *
     * 只按 [DocumentsContract.Document.COLUMN_DISPLAY_NAME] **精确匹配**，
     * 不拼 `docId`、不做 URL 编解码：中文、空格、`%`、`#` 都是文件名的一部分，
     * 任何编解码都会让名称与磁盘上的显示名不再相等。
     *
     * 每层都用 [DocumentsContract.buildChildDocumentsUriUsingTree] 配合
     * [documentIdOf] 列出子项；**不要**用 `isTreeUri` 判断 URI 种类
     * （见 [documentIdOf] 的注释）。
     */
    private fun documentUri(
        treeUri: String?,
        relativePath: String?,
        result: MethodChannel.Result
    ) {
        if (treeUri.isNullOrEmpty()) {
            result.error("invalid_argument", "treeUri 不能为空", null)
            return
        }
        try {
            val root = Uri.parse(treeUri)
            val segments = (relativePath ?: "")
                .replace('\\', '/')
                .split('/')
                .filter { it.isNotEmpty() && it != "." }
            if (segments.isEmpty()) {
                result.success(treeUri)
                return
            }

            var documentId = documentIdOf(root)
            for (segment in segments) {
                if (segment == "..") {
                    result.error("invalid_path", "相对路径不允许包含 ..", null)
                    return
                }
                val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(
                    root,
                    documentId
                )
                var matchedId: String? = null
                contentResolver.query(childrenUri, PROJECTION, null, null, null)?.use { cursor ->
                    val nameIndex =
                        cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
                    val idIndex = cursor.getColumnIndexOrThrow(
                        DocumentsContract.Document.COLUMN_DOCUMENT_ID
                    )
                    while (cursor.moveToNext() && matchedId == null) {
                        if (cursor.getString(nameIndex) == segment) {
                            matchedId = cursor.getString(idIndex)
                        }
                    }
                }
                val nextId = matchedId
                if (nextId == null) {
                    // 文件不存在 / 授权范围内看不到：交给上层回落到「暂不可用」。
                    result.success(null)
                    return
                }
                documentId = nextId
            }

            result.success(
                DocumentsContract.buildDocumentUriUsingTree(root, documentId).toString()
            )
        } catch (error: Exception) {
            result.error("saf_document_uri_failed", error.message, null)
        }
    }

    /** 读取 document URI 的字节；打开失败为 `null`，超过上限为 `too_large`。 */
    private fun readBytes(documentUri: String?, result: MethodChannel.Result) {
        if (documentUri.isNullOrEmpty()) {
            result.error("invalid_argument", "documentUri 不能为空", null)
            return
        }
        try {
            val input = contentResolver.openInputStream(Uri.parse(documentUri))
            if (input == null) {
                result.success(null)
                return
            }
            input.use { stream ->
                val output = ByteArrayOutputStream()
                val buffer = ByteArray(READ_CHUNK_BYTES)
                var total = 0
                while (true) {
                    val read = stream.read(buffer)
                    if (read < 0) break
                    total += read
                    if (total > MAX_READ_BYTES) {
                        // 封面等小文件才走这里；大文件应走播放引擎 / 复制路径。
                        result.error(
                            "too_large",
                            "文件超过 ${MAX_READ_BYTES} 字节上限",
                            null
                        )
                        return
                    }
                    output.write(buffer, 0, read)
                }
                result.success(output.toByteArray())
            }
        } catch (error: Exception) {
            result.error("saf_read_failed", error.message, null)
        }
    }

    /**
     * 把 document URI 复制到应用私有缓存，返回本地绝对路径；失败为 `null`。
     *
     * 目标已存在且大小与源一致时直接复用 —— 缓存命中要足够便宜，
     * 否则每次打开书籍详情都会复制一遍音频。
     */
    private fun copyToCache(
        documentUri: String?,
        name: String?,
        result: MethodChannel.Result
    ) {
        if (documentUri.isNullOrEmpty()) {
            result.error("invalid_argument", "documentUri 不能为空", null)
            return
        }
        try {
            val uri = Uri.parse(documentUri)
            val directory = File(cacheDir, CACHE_DIR_NAME)
            if (!directory.exists() && !directory.mkdirs()) {
                result.success(null)
                return
            }

            val safeName = safeFileName(name ?: uri.lastPathSegment ?: "media")
            val target = File(directory, safeName)
            val sourceSize = sizeOf(uri)
            if (target.isFile && sourceSize != null && target.length() == sourceSize) {
                result.success(target.absolutePath)
                return
            }

            val input = contentResolver.openInputStream(uri)
            if (input == null) {
                result.success(null)
                return
            }
            val temporary = File(directory, "$safeName.part")
            try {
                input.use { source ->
                    temporary.outputStream().use { sink -> source.copyTo(sink) }
                }
                if (target.exists() && !target.delete()) {
                    temporary.delete()
                    result.success(null)
                    return
                }
                if (!temporary.renameTo(target)) {
                    temporary.copyTo(target, overwrite = true)
                    temporary.delete()
                }
            } catch (error: Exception) {
                temporary.delete()
                result.success(null)
                return
            }
            result.success(target.absolutePath)
        } catch (error: Exception) {
            result.error("saf_copy_failed", error.message, null)
        }
    }

    /** 源文件大小；provider 不提供时为 `null`（此时不复用缓存）。 */
    private fun sizeOf(uri: Uri): Long? {
        return try {
            contentResolver.query(
                uri,
                arrayOf(DocumentsContract.Document.COLUMN_SIZE),
                null,
                null,
                null
            )?.use { cursor ->
                if (!cursor.moveToFirst()) {
                    null
                } else {
                    val index = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_SIZE)
                    if (index >= 0 && !cursor.isNull(index)) cursor.getLong(index) else null
                }
            }
        } catch (error: Exception) {
            null
        }
    }

    /**
     * 把任意调用方名称变成安全的单段文件名。
     *
     * 逐段路径可能带 `/`、`\`、`:` 等字符；缓存目录只接受单段名称，
     * 因此替换为 `_` 并去掉开头的点（避免 `.` / `..`）。
     */
    private fun safeFileName(name: String): String {
        val cleaned = name
            .replace(Regex("[\\\\/:*?\"<>|\\u0000-\\u001F]"), "_")
            .trim()
            .trimStart('.')
        if (cleaned.isEmpty()) return "media"
        return if (cleaned.length > 120) cleaned.takeLast(120) else cleaned
    }

    private fun entryOf(treeUri: Uri, cursor: android.database.Cursor): Map<String, Any?> {
        val documentId = cursor.getString(
            cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DOCUMENT_ID)
        )
        val mimeType = cursor.getString(
            cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_MIME_TYPE)
        )
        val sizeIndex = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_SIZE)
        val modifiedIndex =
            cursor.getColumnIndex(DocumentsContract.Document.COLUMN_LAST_MODIFIED)

        return mapOf(
            "name" to cursor.getString(
                cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
            ),
            "documentUri" to DocumentsContract.buildDocumentUriUsingTree(
                treeUri,
                documentId
            ).toString(),
            "isDirectory" to (mimeType == DocumentsContract.Document.MIME_TYPE_DIR),
            "size" to if (sizeIndex >= 0 && !cursor.isNull(sizeIndex)) {
                cursor.getLong(sizeIndex)
            } else {
                null
            },
            "lastModified" to if (modifiedIndex >= 0 && !cursor.isNull(modifiedIndex)) {
                cursor.getLong(modifiedIndex)
            } else {
                null
            }
        )
    }

    /**
     * 取 URI 指向的 document id。
     *
     * **不要**用 [DocumentsContract.isTreeUri] 来区分：它只看路径首段是不是 `tree`，
     * 而 [DocumentsContract.buildDocumentUriUsingTree] 生成的文档 URI 形如
     * `…/tree/<treeId>/document/<docId>` —— 首段同样是 `tree`，会被误判成 tree URI，
     * 于是 [DocumentsContract.getTreeDocumentId] 返回的是**树根** id 而不是文档自己的 id。
     *
     * 后果（实测）：列出子目录时其实一直在列根目录的直接子项，导致
     * `书库根/<书>` 这一层能进去、再往下就永远重复同一层，扫描器递归到深度上限后
     * 拿不到任何章节 —— 表现为「扫描完成 · 0 册 0 章」。
     *
     * 正确判据是路径里有没有 `/document/<id>` 段（`PATH_DOCUMENT` 未公开，用字面量）：
     * - 纯 tree URI（`…/tree/<treeId>`）→ `getTreeDocumentId`
     * - 文档 URI（`…/document/<id>` 或 `…/tree/<treeId>/document/<id>`）→ `getDocumentId`
     */
    private fun documentIdOf(uri: Uri): String {
        val paths = uri.pathSegments
        val isDocumentUri = paths.size >= 2 && paths[paths.size - 2] == "document"
        return if (isDocumentUri) {
            DocumentsContract.getDocumentId(uri)
        } else {
            DocumentsContract.getTreeDocumentId(uri)
        }
    }

    private fun displayNameOf(uri: Uri): String {
        try {
            contentResolver.query(uri, PROJECTION, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    return cursor.getString(
                        cursor.getColumnIndexOrThrow(
                            DocumentsContract.Document.COLUMN_DISPLAY_NAME
                        )
                    )
                }
            }
        } catch (error: Exception) {
            // 名称只用于展示，读不到就退回 URI 末段。
        }
        return uri.lastPathSegment ?: uri.toString()
    }

    companion object {
        private const val CHANNEL = "tometone/saf"
        private const val REQUEST_PICK = 4001

        /** 封面等小文件的上限；超过即拒绝读入内存。 */
        private const val MAX_READ_BYTES = 12 * 1024 * 1024
        private const val READ_CHUNK_BYTES = 64 * 1024
        private const val CACHE_DIR_NAME = "tometone-media"

        private val PROJECTION = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_MIME_TYPE,
            DocumentsContract.Document.COLUMN_SIZE,
            DocumentsContract.Document.COLUMN_LAST_MODIFIED
        )
    }
}
