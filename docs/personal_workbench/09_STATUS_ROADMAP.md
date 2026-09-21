# Personal Workbench 当前状态与 Roadmap

## 1. 现在做到哪里

核心能力已经基本齐了：

- Global Shell / Home
- Workspace / Task / Notes
- Issue / Resource / Decision
- Time / Focus
- Knowledge / Search
- Developer Context
- Global AI / AI History
- Settings
- Backup / Export / Restore
- Tool Shell
- Windows UI Polish

现在不应该继续无节制加页面。

下一阶段重点是：**把代码、测试、异常和性能做扎实。**

后续执行顺序统一以 [12_CODE_OPTIMIZATION_PLAN.md](12_CODE_OPTIMIZATION_PLAN.md) 为主，不再临时想到哪里改到哪里。

## 2. 当前代码清理

本轮已经开始处理：

- 删除早期 cloud disk 的 DTO / DBHelper / Utils。
- 删除文件、收藏、回收站、订阅、设备容量、共享目录等旧路由和旧页面。
- 当前目录收口为 `app / pages / workbench` 等明确职责。
- Dart 文件名统一 snake_case。
- 删除依赖个人电脑绝对路径的旧测试脚本。
- Tray 从 NetDisk 改为 Personal Workbench。
- 清理未使用依赖。
- 开启 `avoid_print`。
- 当前代码退出 Phase 历史命名。
- 新增长期编码规范。

这一批基础清理已经合并到 `main`。

上一次已确认的代码质量基线：

~~~text
flutter analyze
→ No issues found
~~~

当前测试套件已经从最初 4 个 utility tests 扩展到 Search、AI Context、Backup / Restore 等核心链路。测试数量不在文档里写死，每次合并核心改动后以本地 `flutter test` 实际结果为准。

Workspace 旧聚合页面和当前 `V2` 历史命名也已经继续清理。

## 3. Desktop Hardening

### 结构

已完成：

- Workspace 历史聚合页面删除。
- Workspace 当前 V2 命名清理。
- Workspace Overview 拆成 Frame / Navigation / Overview Content。
- Settings 拆成 Page / Sections / Navigation / Appearance / Components。

下一批优先处理：

- Global AI Drawer 已完成第一阶段：UI helper / formatter 拆分。
- Home 页面已按 Focus / Panels / Support 拆分，保留原 UI 和加载逻辑。
- Knowledge 页面已按 Cards / Editor / Support 拆分，保留原搜索和沉淀逻辑。
- Developer 页面已按 Actions / Sections / Support 拆分，保留原 CRUD 和展示逻辑。
- 下一步继续判断 Global AI Conversation State 是否值得抽离，先不强拆。
- 同时开始把重点转向 Service / Repository / Search / Backup / AI Context 自动化测试。

原则是按职责拆，不机械拆。

### 测试

已开始：

- AI Context Budget 单元测试。
- SearchService rebuild / freshness / concurrency / query forwarding 测试。

继续完成：

- Search Repository FTS / LIKE fallback / filter / limit 测试。
- Restore archive manifest / schema / path safety / corrupted ZIP 测试。

继续完成：

- Backup portable settings / manifest ZIP 测试。
- Search rebuild batch / transaction 路径测试。

继续完成：

- Restore staging / next-start apply 自动化测试。
- Restore settings preflight / sanitize。
- Pending Restore 失败边界保护。

当前开始：

- TaskService 业务规则测试。
- WorkspaceService create / slug unique / directory / activity 测试。
- WorkspaceAdminService rename / archive / restore 测试。

当前继续：

- KnowledgeService Markdown / source links / Search Index 规则测试。
- WorkbenchSettingsService 默认值 / persistence / secret boundary 测试。

已识别但不和本轮混改：

- Knowledge create / update 跨 Markdown、SQLite、Entity Link、Search Index 时的失败补偿还需要独立加固。

本轮继续：

- Task Repository 用真实 SQLite 锁 Current Task 唯一约束、事务切换和失败回滚。

本轮继续：

- Knowledge create / update 跨 Markdown、Repository、Entity Link、Search Index 增加反向补偿。
- Task Repository 真实 SQLite Current 约束已补。

本轮继续：

- Fresh Schema v6 自动化测试。
- v1~v5 到 v6 Migration 自动化测试。
- Migration 数据保留、Index、FTS 和约束验证。

AI Provider / Conversation 第一轮异常测试已完成并合并。

Image Tools 第一轮公共基础层已完成并合并。

当前继续：

- Preview 文件读取 / decode / resize / PNG encode 公共化。
- Watermark position / font / foreground / shadow 纯算法公共化。
- Image Convert / Watermark / Crop / Filter Batch Loop 公共化。
- 页面 setState / UI State 继续留在各页面，不做万能框架。
- 补 Preview / Watermark / Batch 单元测试。

下一批：

- Widget smoke
- Image Tools 剩余 Failed Task / Preview Widget 评估

### 异常

- 页面加载失败
- SQLite 异常
- 文件写入异常
- Search rebuild 异常
- AI timeout / HTTP error / empty response

### 性能

- 避免重复 IO 和重复查询。
- 大列表避免无意义全量 rebuild。
- Search rebuild 看真实数据量表现。
- AI Context 不重复读取不需要的 Markdown。
- 图片工具避免长期阻塞 UI isolate。

## 4. AI Real Environment Verification

~~~text
Provider Config
→ Test Connection
→ Global AI
→ Context Builder
→ Provider
→ Markdown Result
→ Conversation Persistence
→ Restart Recovery
~~~

验证真实 Gateway、API Key、Timeout、HTTP error、Empty response、Long response。

## 5. Search / Backup / Restore Hardening

Search 重点：即时同步、重建性能、中文 relevance、大数据量。

完整 Search Rebuild 已完成第一轮性能优化：

- Workspace 之间并发收集。
- 同一 Workspace 的 Repository 查询并发发起。
- Note / Knowledge Markdown 并发读取。
- Service 一次提交 SearchIndexEntry 集合。
- SQLite 真实运行时使用 transaction。
- clear 只执行一次。
- 每 100 条批量 INSERT。
- 增量 replace / remove 逻辑保持不变。

下一步再用真实数据量观察 rebuild 时间和中文 relevance，不继续凭感觉优化。

Backup / Restore 重点：完整灾难恢复、Manifest compatibility、Corrupted ZIP、Missing DB、Search rebuild。

## 6. CI

GitHub Actions 第一轮已经建立。

Pull Request：

~~~text
flutter pub get
→ flutter analyze
→ flutter test
~~~

main push / workflow_dispatch：

~~~text
Analyze + Test
→ flutter build windows --release
→ 上传 Windows Release Artifact
~~~

当前先保持 Windows-first，不做多平台矩阵，也不把发布流程和质量 Gate 混在一起。

## 7. Desktop Stable V1

上面完成以后，再标记：

~~~text
Personal Workbench Desktop Stable V1
~~~

## 8. 后面再考虑 Mobile

Mobile 需要重新设计 Navigation、Small-screen Layout、Touch Target、Drawer / Dialog、File Picker、Storage、Backup / Export、AI Drawer、Workspace Tabs。

不要直接复制 Desktop UI。

## 9. 近期不做

- Cloud Sync
- Team Collaboration
- Account System
- CRDT
- Real-time Multi-device
- Autonomous Coding Agent
- Shell Execution
- Embedded IDE
- Full Git Client
- Plugin Marketplace
