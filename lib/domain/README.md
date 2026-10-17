# 领域服务层（`lib/domain/`）

对应《架构需求文档》§5.1 DOMAIN 层：书库服务（扫描 / 检索 / 元数据）、播放编排、
入库编排。

## 依赖规则

- 允许：`domain` → `domain` / `contracts`
- 禁止：`domain` → `ui` / `app` / `modules` / `platform`

## 约定

- 业务概念（书 / 卷 / 章）只在本层及以上出现；`contracts` 与 `modules` 不得感知。
- 时间、随机数、文件系统等外部依赖以注入方式提供，保证可测试。
