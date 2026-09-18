# Personal Workbench

Personal Workbench 是一个 Windows Desktop 优先、本地优先（Local-first）的个人工作上下文系统。

它的目标不是做一个普通 Todo App，而是让用户在重新进入工作时，能够快速恢复：

- 当前在做什么；
- 下一步是什么；
- 当前阻塞是什么；
- 相关笔记、问题、资源和决策在哪里；
- 最近发生了什么；
- 哪些经验已经沉淀成可复用知识。

仓库名称仍保留为 cloud_disk，但当前主产品名称统一为 **Personal Workbench**。

## 当前状态

当前主干版本已经完成 Personal Workbench v1.4 的 Desktop UI 与核心功能整合。

已具备：

- Global Shell / Home / Continue / Quick Capture
- Workspace / Current Task
- Markdown Notes
- Issue / Resource / Decision
- Developer Context
- Time / Focus
- Knowledge Library / Knowledge Distill
- FTS5 + LIKE fallback 全局搜索
- Global AI / Context Builder / Conversation History
- Settings
- Manual / Auto / Safety Backup
- Portable Export
- Restore staging + next-start apply
- JSON / Text Compare / Speed Test / Image Tools / RAG / Game

Windows Release Build 已验证可生成：

~~~text
build/windows/x64/runner/Release/cloud_disk.exe
~~~

## 技术栈

- Flutter 3.47.4 stable（当前 Windows 验证基线）
- fluent_ui
- go_router
- Drift + SQLite
- SQLite FTS5
- Markdown 文件存储
- SharedPreferences
- OpenAI-compatible HTTP Provider
- Windows Desktop

## 快速运行

~~~powershell
flutter pub get
flutter run -d windows
~~~

静态检查：

~~~powershell
flutter analyze
~~~

Windows Release 构建：

~~~powershell
flutter build windows
~~~

## 文档

项目当前文档入口：

[docs/personal_workbench/README.md](docs/personal_workbench/README.md)

建议先阅读：

1. [产品与边界](docs/personal_workbench/01_PRODUCT_SCOPE.md)
2. [功能说明](docs/personal_workbench/02_FUNCTIONAL_SPEC.md)
3. [UI / UX 设计](docs/personal_workbench/03_UI_UX_DESIGN.md)
4. [技术架构](docs/personal_workbench/04_TECHNICAL_ARCHITECTURE.md)
5. [数据与存储](docs/personal_workbench/05_DATA_AND_STORAGE.md)
6. [AI / Search / Knowledge](docs/personal_workbench/06_AI_SEARCH_KNOWLEDGE.md)
7. [实施与运行](docs/personal_workbench/07_IMPLEMENTATION_OPERATIONS.md)
8. [测试与验收](docs/personal_workbench/08_TESTING_ACCEPTANCE.md)
9. [状态与 Roadmap](docs/personal_workbench/09_STATUS_ROADMAP.md)

## 核心数据原则

Personal Workbench 采用本地优先架构：

~~~text
SQLite
  ├─ 业务元数据
  ├─ 关系
  ├─ Activity
  ├─ AI Conversation
  └─ Search Index

Markdown
  ├─ Workspace Notes
  └─ Knowledge

SharedPreferences
  └─ 非敏感设置
~~~

API Key 不写入 Workbench SQLite，也不进入 Backup / Export。

## 产品边界

当前版本不是：

- 云同步产品；
- 多人协作平台；
- Autonomous Coding Agent；
- Shell / PowerShell 自动执行器；
- Git / Docker / Test 自动执行器；
- 完整 IDE；
- CRDT / 实时协同系统。

Developer 模块当前是 Context-aware Developer Assistant，主要负责保存和提供项目、命令、代码片段、开发资源上下文，不自动执行本地命令。

## 文档维护规则

以后功能变更时：

- 功能行为变化：更新 02_FUNCTIONAL_SPEC.md；
- UI / 交互变化：更新 03_UI_UX_DESIGN.md；
- 架构或依赖变化：更新 04_TECHNICAL_ARCHITECTURE.md；
- Schema / 文件目录变化：更新 05_DATA_AND_STORAGE.md；
- AI / Search / Knowledge 变化：更新 06_AI_SEARCH_KNOWLEDGE.md；
- 部署、运行、备份恢复流程变化：更新 07_IMPLEMENTATION_OPERATIONS.md；
- 验收状态变化：更新 08_TESTING_ACCEPTANCE.md 和 09_STATUS_ROADMAP.md。

历史 Phase 文档不再作为当前实现依据；历史信息通过 Git History 与 10_VERSION_HISTORY.md 追溯。
