# 领域服务层（`lib/domain/`）

对应《架构需求文档》§5.1 DOMAIN 层：书库服务（扫描 / 检索 / 元数据）、播放编排、
入库编排。

## 依赖规则

- 允许：`domain` → `domain` / `contracts`
- 禁止：`domain` → `ui` / `app` / `modules` / `platform`

## 约定

- 业务概念（书 / 卷 / 章）只在本层及以上出现；`contracts` 与 `modules` 不得感知。
- 时间、随机数、文件系统等外部依赖以注入方式提供，保证可测试。

## 目录

| 目录 | 内容 |
| :--- | :--- |
| `common/` | `IdGenerator` 端口、`UlidIdGenerator`（不可变 ID，字典序即时间序） |
| `library/database/` | Drift schema（9 张表）、迁移策略、代码生成产物 |
| `library/scan/` | 媒体格式白名单、自然排序、拓扑推导、NFC 路径归一化、扫描编排与两阶段回填 |
| `library/media/` | `MediaMetadataReader` 端口（Phase 2 回填时长 / 内嵌封面） |

### 为什么持久化在领域层而不是新增 `data/` 层

书 / 卷 / 章是**领域概念**，它们的持久化属于领域自身的关注点；而 §5.1 的
`modules` 层明确"不得感知业务概念"，把书库数据库放进去会直接违反 §5.2。
因此维持文档既有的六层不变，代价是领域层承担 Drift 依赖 —— 但数据库类
**只接收 `QueryExecutor`**，不依赖 Flutter，单测用 `NativeDatabase.memory()`
即可在纯 Dart 下运行，领域层仍保持可测试性。

### 数据层的三条硬约束

1. **ID 不可变**（ULID），文件重绑只改 `file_path`，不重写 ID（§8.2）。
2. **绑定键唯一**：`(library_root_id, file_path)` —— 重链时必须在同一事务内先解绑旧值，
   否则触发唯一索引冲突。
3. **禁止破坏性迁移**：`onUpgrade` 缺少步骤时直接抛错，绝不 `dropAll`（§8.3）。
