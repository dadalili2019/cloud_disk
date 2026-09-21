# Personal Workbench 版本历史

本文只记录历史，不作为当前实现规范。

## Phase 1–3

建立 Workspace、Task、Current Task、Markdown Note、Entity Link、Activity、Issue、Resource、Decision、Home、Continue、Quick Capture、Focus、Today。

## Phase 4

增加 Knowledge、Knowledge Distill、SQLite FTS5 Search、Search Result Routing。

## Phase 5

增加 AI Context Builder、Context Budget、Prompt Builder、Global AI、AI Thread / Message History、OpenAI-compatible Provider。

## Phase 6

增加 Developer Project、Developer Command、Developer Snippet、Developer Context、Search Integration、AI Developer Context。

## Phase 7

增加 Settings、Backup、Export、Restore、Data Safety、Provider Settings。

## v1.4 UI Consolidation

完成 Global Shell、Home、Workspace、Knowledge、Time、Developer、Tools、Settings、Dark Mode、Windows Window / Login Polish。

v1.4 通过 PR #1 合并到 main。

## 2026-09-20 Codebase Cleanup

在 `refactor/personal-workbench-cleanup` 分支进行：

- 清理 cloud disk 历史业务代码。
- 删除无效旧路由。
- 规范目录和 Dart 文件名。
- 清理历史依赖。
- 删除本机绝对路径测试脚本。
- 增加基础单元测试。
- Tray 从 NetDisk 改为 Personal Workbench。
- 当前代码不再继续使用 Phase 历史命名。
- 新增长期编码规范。

这次调整以“减少历史包袱，不改变当前业务行为”为原则。


## 2026-09-20 Analyzer / Workspace Cleanup

继续完成：

- Flutter 3.47.4 下 Analyzer issue 从 33 个清到 0。
- 当前 `flutter analyze` 为 `No issues found`。
- 当前 `flutter test` 为 4 tests passed。
- 删除未被引用的旧 `workbench_workspace_pages.dart`。
- Workspace 当前代码去掉 `V2` 历史命名。
- 当前 Workspace 页面命名恢复为正常业务语义，不再同时维护旧版 / 新版概念。


## 2026-09-20 Workspace / Settings File Split

继续做低风险结构整理：

- Settings 页面按 Sections / Navigation / Appearance / Components 拆文件。
- Workspace Overview 按 Navigation / Overview Content 拆文件。
- 保留原有 private Widget 和行为，不为了拆文件扩大 public API。
- 使用 Dart `part / part of` 维持同一个 library 内部的封装边界。


## 2026-09-20 AI Context Builder Split

继续做 AI 核心链路结构整理：

- `AIContextBuilder` 对外接口保持不变。
- Task / Workspace / Knowledge / Global Scope 逻辑独立组织。
- Context 收集、Entity 映射、文本格式化分别拆开。
- 没有新增无意义的 Service / Manager 层。
- Context 优先级、数量限制、搜索范围、include / exclude 和输出内容保持原逻辑。


## 2026-09-20 Global AI Drawer Split - Step 1

先做低风险拆分：

- UI helper 移到 `global_ai_drawer_widgets.dart`。
- 纯格式化函数移到 `global_ai_drawer_formatters.dart`。
- State、Conversation、Context 操作仍保留在主文件。
- `_contextPreview` 因为直接涉及 `setState`，暂不强拆。
- 不改变 AI Drawer 的交互和业务行为。


## 2026-09-20 Home Page Split

继续整理首页代码：

- `workbench_home_page.dart` 保留加载、状态和整体布局。
- Current Focus / Progress 拆到 `workbench_home_focus.dart`。
- Today / Recent Activity 拆到 `workbench_home_panels.dart`。
- Drawer Layer、Loading / Error、内部数据模型和格式化 helper 拆到 `workbench_home_support.dart`。
- 不改变首页 UI、路由、数据来源和交互。


## 2026-09-20 Knowledge Page Split

继续整理 Knowledge 页面：

- 主文件保留 load / search / category / distill / editor orchestration。
- Knowledge Card / Search Result 拆到 `workbench_knowledge_cards.dart`。
- Knowledge Editor Dialog 拆到 `workbench_knowledge_editor.dart`。
- Entity Label 等 helper 拆到 `workbench_knowledge_support.dart`。
- 不改变 SearchService、KnowledgeService、Distill 和页面交互行为。


## 2026-09-20 Developer Page Split

继续整理 Developer 页面：

- 主文件只保留 Context load / refresh 和页面骨架。
- Project / Command / Snippet CRUD 与 Dialog 拆到 `workbench_developer_actions.dart`。
- Projects / Commands / Snippets / Resources 展示拆到 `workbench_developer_sections.dart`。
- Command Category Label 等 helper 拆到 `workbench_developer_support.dart`。
- 不改变 DeveloperService 调用、CRUD 行为、复制、归档和页面交互。


## 2026-09-20 Developer State Boundary Fix

Developer 页面拆分后继续修正 State 边界：

- Action extension 不再直接调用 `State.setState`。
- 页面 State 增加统一的 `_reloadState()` 状态刷新入口。
- 修复 Flutter Analyzer 的 7 个 `invalid_use_of_protected_member`。
- 编码规范补充：part / extension 拆分时，protected State API 必须留在 State 子类内部。


## 2026-09-20 Core Test Hardening - Step 1

开始从结构重构转向自动化测试：

- 新增 AI Context Budget 单元测试。
- 新增 SearchService rebuild 行为测试。
- 覆盖 Search freshness window。
- 覆盖并发 rebuild 合并，避免重复重建。
- 覆盖 Search 参数透传。
- 测试不依赖真实 SQLite、外网、个人路径。


## 2026-09-20 Search / Restore Test Hardening

继续补核心链路保护：

- 新增 SqliteSearchIndexRepository 行为测试。
- 覆盖 FTS + LIKE 合并和去重。
- 覆盖 FTS 失败时 LIKE fallback。
- 覆盖 entity type / workspace filter、LIKE escape 和 limit clamp。
- Restore 校验逻辑从 RestoreService 抽成 BackupArchiveValidator。
- 覆盖路径穿越、绝对路径、缺失快照、format version、future schema 和损坏 ZIP。
- RestoreService 继续只负责 staging / apply，不改变 Restore 流程。


## 2026-09-20 Search Rebuild Performance / Backup Test

继续从“有测试”进入“测试保护下优化”：

- SearchService 完整 rebuild 改为先收集 SearchIndexEntry，再一次交给 Repository。
- Workspace Repository 查询并发发起。
- Note / Knowledge Markdown 并发读取。
- SQLite Search rebuild 在真实 WorkbenchDatabase 下使用 transaction。
- 完整 rebuild clear 一次，每 100 条批量 INSERT，不再逐实体 delete + insert。
- 增量 Search replace / remove 保持原逻辑。
- AppPaths 增加 createAt，用于临时目录测试，不依赖个人机器路径。
- BackupService 依赖收窄为 WorkbenchSqlExecutor。
- 新增真实 Backup ZIP 测试，覆盖 manifest、文件清单、portable settings 和敏感配置排除。


## 2026-09-21 Restore Stage / Apply Hardening

继续补灾难恢复链路：

- Restore staging 增加 settings preflight。
- staging 时把 portable settings 重新写成已过滤版本，不把 api_key / secret / token 留在 pending。
- next-start apply 在覆盖数据库和目录前先解析 settings。
- preflight 失败时当前数据库和业务目录保持不动，并清理无效 pending。
- 新增 staging / next-start apply 自动化测试。
- 覆盖 Safety Backup、pending marker、DB / WAL / SHM、Workspace / Knowledge / Attachment、portable settings 和失败清理。


## 2026-09-21 Optimization Plan / Business Rule Tests

开始把后续优化方式固定下来：

- 新增 `12_CODE_OPTIMIZATION_PLAN.md`，后续代码优化按固定顺序推进。
- 编码规范补充“业务规则先测试、Schema 变更必须 Migration Test、性能优化先锁行为”。
- Roadmap 不再以继续拆大文件为主线。
- 开始补 Task / Workspace 业务规则测试。


## 2026-09-21 Knowledge / Settings Rule Tests

继续按优化计划补业务规则保护：

- KnowledgeService 增加 create / update / Markdown / Search Index 测试。
- 覆盖 derived_from source links 和 applies_to Task。
- 覆盖 Knowledge 文件名冲突。
- 覆盖 create Repository 失败时 Markdown 清理。
- WorkbenchSettingsService 增加默认值和持久化测试。
- 覆盖 AI timeout / Backup retention 边界。
- 覆盖 Session API Key 不进入 SharedPreferences。
- 覆盖 Last Active Location 白名单和非法 enum fallback。
- 同时识别 Knowledge 跨 Markdown / SQLite / Link / Search 的失败补偿需要单独加固，本轮不顺手扩大改动。


## 2026-09-21 Task Repository Current Constraint

继续把 Task 规则下沉到真实数据库验证：

- 新增 SqliteTaskRepository 真实 SQLite 测试。
- 覆盖同 Workspace Current Task 唯一索引。
- 覆盖 setCurrent 事务切换和 todo → doing。
- 覆盖 setCurrent 失败后的事务回滚。
- 覆盖 Done Task 不能成为 Current。
- 覆盖历史 done + current 脏状态的 normalize。


## 2026-09-21 Knowledge Cross-store Compensation

继续加固 Knowledge 跨存储一致性：

- KnowledgeRepository 增加 delete，用于 create 失败补偿。
- EntityLinkRepository 增加精确 unlink。
- create 在 Link / Search Index 失败时按 Search → Link → Repository → Markdown 反向补偿。
- update 在失败时恢复旧 Markdown、旧 Repository 数据和旧 Search Index。
- 补偿使用 best-effort，原始业务异常仍然作为调用方看到的错误。
- 新增 Link 失败、Search Index 失败和 Update 回滚测试。


## 2026-09-21 SQLite Repository Test Isolation Fix

修正 Task Repository 测试环境边界：

- 正式运行的 WorkbenchDatabase.open 继续使用 NativeDatabase.createInBackground。
- 新增 WorkbenchDatabase.openInMemoryForTesting，只用于 Repository / Schema 自动化测试。
- Repository 测试不再额外依赖 Drift background isolate 和临时数据库文件。
- sqlite_task_repository_test 的 tearDown 改为数据库成功初始化后才 close，避免 setup 失败后再抛 LateInitializationError。
- 测试目标保持不变：仍然验证真实 SQLite Schema、Index、Transaction 和 Repository 行为。


## 2026-09-21 Test Schema Version Boundary

继续修正 Repository 测试边界：

- WorkbenchDatabase.openInMemoryForTesting 增加 targetSchemaVersion。
- 测试数据库默认仍可创建当前最新 Schema。
- Task Repository 测试只创建 Schema v1，因为 Current Task、Workspace 和对应唯一索引都属于 v1。
- in-memory 测试关闭 WAL，正式数据库仍保持 WAL。
- Schema 创建和 Migration 统一通过 _schemaForVersion 映射，给下一阶段 Migration Test 做准备。
- 避免 Task Repository 测试被 Knowledge FTS、AI、Developer 等无关后续 Schema 影响。


## 2026-09-21 Database Schema / Migration Test Baseline

开始建立长期数据库升级保护：

- WorkbenchDatabase 增加 openFileForTesting，只用于文件型 Migration Test。
- Fresh Database 自动验证当前 Schema v6。
- 自动覆盖 v1 / v2 / v3 / v4 / v5 → v6。
- 旧版本数据库先写入真实历史数据，再关闭并按最新版本重新打开。
- Migration 后验证 Workspace / Task，以及对应版本已有的 Issue / Focus / Knowledge / AI Thread 数据不丢。
- 验证 Current Task unique index。
- 验证 Developer Primary unique index。
- 验证 search_index FTS 可写可查。
- 验证 user_version 最终为当前 Schema Version。
- 正式 WorkbenchDatabase.open 仍然保持 background database + WAL，不改变运行逻辑。


## 2026-09-21 Windows Migration Test File Lock Boundary

继续收口 Windows 下 Migration Test 的清理边界：

- openFileForTesting 关闭 prepared statement cache，只影响测试入口。
- Migration 测试关闭数据库后仍会尝试删除临时目录并重试。
- 仅在 Windows 且确认是 errno 32 的文件占用时，清理失败不再把 Migration Test 判为失败。
- 其他 PathAccessException 仍然继续抛出。
- 正式数据库 open / WAL / background isolate 不变。


## 2026-09-21 Migration Test FTS5 Host Boundary

继续收口 Windows 下数据库测试边界：

- v4 Schema 的 search_index 使用 SQLite FTS5。
- Windows `flutter test` 跑在宿主 Dart VM，不会加载 Flutter 原生 sqlite3 插件运行时。
- 测试专用数据库入口在 Windows Host Test 下跳过 FTS5 虚拟表创建。
- Fresh / Migration 测试仍然真实验证其余表、索引、事务、数据保留和唯一约束。
- FTS5 仍保留在正式 Schema 中，正式 WorkbenchDatabase.open 不变。
- FTS 行为留给支持 FTS5 的 Runtime / 后续 Windows integration test 验证。


## 2026-09-21 GitHub Actions CI Baseline

开始把本地质量检查变成仓库自动 Gate：

- 新增 Windows-first GitHub Actions。
- Pull Request 自动执行 flutter pub get / flutter analyze / flutter test。
- main push 和 workflow_dispatch 在质量检查通过后执行 flutter build windows --release。
- Windows Release 作为 Artifact 保留 14 天。
- CI 使用 Flutter 3.47.4 stable，与当前本地验证基线一致。
- 增加 concurrency，同一分支的新 CI 会取消旧运行。
- 实施文档删除个人 Flutter SDK 绝对路径，改为通用 flutter 命令。


## 2026-09-21 AI Provider / Conversation Hardening

开始加固 AI 失败链路：

- OpenAICompatibleAIProvider 增加配置、请求组装、Timeout、Network、HTTP、Invalid JSON、Empty Response、Content Array、Long Response 测试。
- Retry Prompt History 从 Global AI Drawer 私有方法移到 application/ai_conversation_history.dart。
- Retry 时排除最后一条已经持久化的 User Message，避免重复带入 Prompt。
- AIConversationService 增加 Anchor 校验、Archived 边界、首条消息自动标题、Context Reference Snapshot 测试。
- SQLite AI Thread / Message 增加关闭数据库后重新打开的持久化恢复测试。
- 当前不做 Global AI Drawer 大规模 State 重构，先用测试锁行为。


## 2026-09-21 Image Tools Shared Foundation - Step 1

开始整理 Image Tools 重复基础逻辑：

- 新增 `image_tools_support.dart`。
- 统一图片文件选择与支持扩展名。
- 统一输出目录选择与默认目录创建。
- 统一 JPG / PNG 输出格式、扩展名和编码。
- 统一文件大小格式化。
- 统一图片工具 Card 容器。
- Image Convert / Watermark / Crop / Filter / Collage / Dedupe 接入共享基础能力。
- 新增公共基础能力单元测试。
- 本轮不改变各工具的图像处理算法、参数和交互流程。


## 2026-09-21 Image Tools Shared Foundation - Step 2

继续整理 Image Tools 重复逻辑：

- Preview 的文件读取、decode、等比缩放和 PNG 编码下沉到共享 helper。
- Image Convert / Watermark / Crop / Filter 保留各自 transform 顺序，只复用稳定 Preview 基础能力。
- 文字 Watermark 的位置、字体、前景色、阴影绘制下沉为纯算法。
- Image Convert 和 Watermark 共用同一套 Watermark 绘制逻辑。
- Batch Runner 统一逐项执行、success count、progress 和中途停止。
- Image Convert / Watermark Retry 继续保留各自 failed item 语义，但复用 Batch Runner。
- 页面 State / setState 继续留在页面内部，不引入万能 Image Tool Controller。
- 新增 Preview / Watermark / Batch 单元测试。


## 2026-09-21 Navigation Shell Split - Step 1

开始进入 Navigation / Notes Editor 阶段：

- `navigation_page.dart` 从约 780 行收敛为约 237 行。
- 主文件只保留 NavigationPage State、路由跳转、当前工作区加载与切换。
- Topbar、Shell Colors、Shell Button 抽到 `navigation_shell_topbar.dart`。
- Sidebar、Nav Item、Content Frame 抽到 `navigation_shell_sidebar.dart`。
- 使用 Dart `part / part of` 保持 private Widget 和 helper 的封装边界。
- 不改变现有路由、选中状态、AI Drawer、窗口按钮和工作区切换行为。


## 2026-09-21 Notes Editor Save Consistency

进入 Notes Editor 阶段时先处理数据一致性，再做 UI 拆分：

- 新增 `NotesEditorSaveCoordinator`，用 revision + 串行写入保护保存顺序。
- Auto Save 期间继续编辑时，旧写入完成后继续保存最新 revision，避免旧内容覆盖新内容。
- 手动保存期间继续编辑时，不会把新修改误标记为已保存。
- 关闭 Auto Save 后切换笔记，会提示保存 / 放弃 / 取消，避免未保存内容静默丢失。
- 新建笔记前同样保护当前未保存修改。
- 保存进行中切换 / 新建会先等待当前显式保存结束。
- 页面关闭时仍会把最后一版 Auto Save 内容排在正在执行的写入之后。
- 新增 Save Coordinator 单元测试。


## 2026-09-21 Notes Editor UI Split

Notes Editor 在保存一致性稳定后继续做展示职责拆分：

- `workbench_notes_editor_page.dart` 保留加载、选择、新建、保存时序、未保存确认和快捷键。
- 新增 `workbench_notes_editor_widgets.dart`。
- Notes List、Editor Panel、Header、Editor / Preview / Split、Save State 下沉为同 library private Widget。
- 展示 Widget 只接收状态与 callback，不访问 WorkbenchRuntime。
- 不改变 Auto Save / Manual Save 行为。


## 2026-09-21 Entity Async List UI

- `WorkbenchAsyncList<T>` 统一 loading / error / empty / list shell。
- Issue / Resource / Decision 接入公共外壳。
- 各自 CRUD、卡片内容、Task Link 与 Drawer 继续留在业务页面。
- 不引入通用 CRUD framework。
