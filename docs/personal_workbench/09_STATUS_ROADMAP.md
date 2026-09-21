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

第一轮 Desktop Hardening 已完成。

### 结构

已完成：

- Workspace / Settings / Home / Knowledge / Developer 第一轮职责拆分。
- Global AI Drawer 第一阶段 UI helper / formatter 拆分。
- Navigation Shell 按 State / Topbar / Sidebar / Content Frame 拆分。
- Notes Editor 保存一致性加固。
- Notes Editor Notes List / Editor / Preview / Save State 展示职责拆分。
- Workbench Runtime Composition 下沉，不引入 DI Framework。
- Issue / Resource / Decision 共用 `WorkbenchAsyncList<T>` 的 loading / error / empty / list shell。
- Image Tools 两轮公共逻辑整理。

暂不继续：

- Global AI Drawer 第二阶段没有明确维护痛点，先不强拆。
- Image Tools Failed Task / Preview Widget 暂不继续抽象。
- Issue / Resource / Decision 不做万能 CRUD Framework。

### 测试与质量 Gate

已完成：

- Task / Workspace / Knowledge / Settings 业务规则测试。
- Search / Backup / Restore 关键异常和恢复测试。
- Database Fresh Schema 与 v1~v5 → v6 Migration 测试。
- AI Provider / Conversation 异常测试。
- Image Tools 纯逻辑测试。
- Notes Editor Save Coordinator 测试。
- Workbench 基础 Widget Smoke Test。
- GitHub Actions PR Analyze / Test Gate。

### 工程收口

已完成：

- Windows 产品名统一为 Personal Workbench。
- Windows executable 统一为 `personal_workbench.exe`。
- Repository / Dart package 继续保留 `cloud_disk`，避免无业务价值的大范围 import 重命名。
- 依赖 / Asset 第一轮审计不做无证据删除；后续只有确认未引用时再清理。

后续主线不再是持续重构，而是进入真实环境验证与 Release 验收。

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

合成数据量手工验证入口已建立，可在临时目录验证 Repository / Markdown / Search collection / Backup / Restore，不污染真实数据。

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
