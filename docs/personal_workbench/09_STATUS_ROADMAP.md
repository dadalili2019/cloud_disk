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

当前代码质量基线：

~~~text
flutter analyze
→ No issues found

flutter test
→ 4 tests passed
~~~

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
- 下一步继续判断 Conversation State 是否值得抽离，先不强拆。
- `workbench_knowledge_page.dart`
- `workbench_developer_page.dart`

原则是按职责拆，不机械拆。

### 测试

- Service / Repository tests
- Search tests
- Backup / Restore tests
- AI Context budget tests
- Settings persistence
- Widget smoke

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

Backup / Restore 重点：完整灾难恢复、Manifest compatibility、Corrupted ZIP、Missing DB、Search rebuild。

## 6. CI

GitHub Actions 最低：

~~~text
flutter pub get
flutter analyze
flutter test
~~~

Windows Build 可以放 merge / release：

~~~text
flutter build windows
~~~

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
