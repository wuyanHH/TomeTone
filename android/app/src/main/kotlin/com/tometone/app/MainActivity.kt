package com.tometone.app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

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
 *
 * 只做只读访问：M1 的入库通道只需要"读"，不碰写回（§7.1 v1 范围）。
 */
class MainActivity : FlutterActivity() {
    private var pendingPick: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openDirectory" -> openDirectory(result)
                    "list" -> list(call.argument<String>("documentUri"), result)
                    "stat" -> stat(call.argument<String>("documentUri"), result)
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
     * tree URI 用 tree document id；文档 URI 用 document id。
     * 两者混用会直接抛 IllegalArgumentException，所以必须显式区分。
     */
    private fun documentIdOf(uri: Uri): String =
        if (DocumentsContract.isTreeUri(uri)) {
            DocumentsContract.getTreeDocumentId(uri)
        } else {
            DocumentsContract.getDocumentId(uri)
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

        private val PROJECTION = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_MIME_TYPE,
            DocumentsContract.Document.COLUMN_SIZE,
            DocumentsContract.Document.COLUMN_LAST_MODIFIED
        )
    }
}
