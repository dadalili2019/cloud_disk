# Personal Workbench

Personal Workbench 是一个 Windows Desktop 优先、本地优先（Local-first）的个人工作上下文系统。

它不是普通 Todo App。核心目标是：重新打开应用以后，我可以很快知道自己现在在做什么、下一步是什么、哪里被卡住了，以及相关的笔记、问题、资源、决策和知识放在哪里。

仓库与 Dart package 名称仍保留为 `cloud_disk`，当前产品与 Windows Release 统一叫 **Personal Workbench**。

## 当前能力

现在已经具备：

- Global Shell / Home / Continue / Quick Capture
- Workspace / Current Task
- Markdown Notes
- Issue / Resource / Decision
- Time / Focus
- Knowledge Library / Knowledge Distill
- FTS5 + LIKE fallback 全局搜索
- Developer Context
- Global AI / Context Builder / Conversation History
- Settings
- Manual / Auto / Safety Backup
- Portable Export
- Restore staging + next-start apply
- JSON / Text Compare / Speed Test / Image Tools / RAG / Game

## 当前代码结构

~~~text
lib/
├─ app/                    # 应用外壳、导航、系统托盘
├─ pages/                  # Login、Settings、独立工具页
├─ router/                 # 路由
├─ theme/                  # 主题
├─ widgets/                # 跨模块复用组件
└─ workbench/
   ├─ application/         # 业务用例和服务编排
   ├─ core/                # Model、Database、Path、Settings
   ├─ data/                # SQLite / Markdown 实现
   ├─ domain/              # Repository / Provider 接口
   ├─ presentation/        # 页面、Dialog、Drawer、UI State
   └─ workbench_runtime.dart
~~~

早期 cloud disk 的 DTO、DBHelper、旧网络工具、文件/收藏/回收站/共享目录等历史代码已经退出当前产品代码。

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

## 本地运行

~~~powershell
flutter pub get
flutter run -d windows
~~~

提交前至少执行：

~~~powershell
flutter analyze
flutter test
flutter build windows
~~~

GitHub 现在也会自动执行 CI：

~~~text
Pull Request → flutter pub get → flutter analyze → flutter test
main push / 手工触发 → 上面质量检查通过后再 build Windows Release
~~~

Windows Release 输出仍然是：

~~~text
build/windows/x64/runner/Release/personal_workbench.exe
~~~

Windows 可执行文件已经收口为 `personal_workbench.exe`；Dart package 名称暂时保留 `cloud_disk`，避免无业务价值的大范围 import 重命名。

## Stable V1 Candidate

当前项目已经进入 Desktop Stable V1 Candidate 阶段。

本地统一验收入口：

~~~powershell
./tool/verify_stable_v1.ps1
~~~

需要追加大规模 Search / Backup / Restore 验证：

~~~powershell
./tool/verify_stable_v1.ps1 -IncludeScale
~~~

配置真实 AI 环境后：

~~~powershell
./tool/verify_stable_v1.ps1 -IncludeAi
~~~

正式标记 Stable V1 前仍需要完成真实 AI、已有数据 Upgrade、正式 Windows Runtime Search / FTS5 和人工业务 Smoke。

## 文档

统一从这里进入：

[docs/personal_workbench/README.md](docs/personal_workbench/README.md)

以后人工写代码或者让 AI / Codex 写代码，都先看：

[11_CODE_DEVELOPMENT_RULES.md](docs/personal_workbench/11_CODE_DEVELOPMENT_RULES.md)

后续优化顺序统一看：

[12_CODE_OPTIMIZATION_PLAN.md](docs/personal_workbench/12_CODE_OPTIMIZATION_PLAN.md)

## 数据原则

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

API Key 不写 Workbench SQLite，也不进入 Backup / Export。

## 产品边界

当前不做：

- 云同步
- 多人协作
- Autonomous Coding Agent
- 自动执行 Shell / PowerShell / Git / Docker / Test
- 完整 IDE
- CRDT / 实时协同

Developer 模块现在还是 Context-aware Developer Assistant，负责保存和提供项目、命令、代码片段和开发上下文，不自动执行本地命令。

## 文档怎么维护

代码和功能调整时，对应文档一起改：

- 功能行为：`02_FUNCTIONAL_SPEC.md`
- UI / 交互：`03_UI_UX_DESIGN.md`
- 架构 / 依赖 / 目录：`04_TECHNICAL_ARCHITECTURE.md`
- Schema / 文件目录：`05_DATA_AND_STORAGE.md`
- AI / Search / Knowledge：`06_AI_SEARCH_KNOWLEDGE.md`
- 运行 / 构建 / 备份恢复：`07_IMPLEMENTATION_OPERATIONS.md`
- 验收：`08_TESTING_ACCEPTANCE.md`
- 当前进度：`09_STATUS_ROADMAP.md`
- 历史：`10_VERSION_HISTORY.md`
- 编码原则：`11_CODE_DEVELOPMENT_RULES.md`
- 优化计划：`12_CODE_OPTIMIZATION_PLAN.md`

历史 Phase 只放版本历史，不再拿来命名当前代码。
