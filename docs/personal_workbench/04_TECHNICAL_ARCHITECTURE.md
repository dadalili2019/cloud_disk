# Personal Workbench 技术架构

## 1. 整体结构

~~~mermaid
flowchart TB
  UI[Presentation / Fluent UI]
  APP[Application Services]
  DOMAIN[Domain Repository Interfaces]
  DATA[Data Repositories]
  DB[(SQLite / Drift)]
  MD[Markdown Store]
  PREF[SharedPreferences]
  AI[AI Provider]

  UI --> APP
  APP --> DOMAIN
  DOMAIN --> DATA
  DATA --> DB
  APP --> MD
  APP --> PREF
  APP --> AI
~~~

原则很简单：UI 管展示和交互，Application 管业务编排，Domain 定义边界，Data 管数据落地，Core 放真正通用的模型和基础能力。

## 2. 当前目录

~~~text
lib/
├─ app/
│  ├─ navigation_page.dart
│  └─ system_tray_service.dart
├─ pages/
│  ├─ login_page.dart
│  ├─ settings/
│  ├─ comparison/
│  ├─ game/
│  ├─ image_tools/
│  ├─ json_format/
│  ├─ rag_knowledge/
│  └─ speed_test/
├─ router/
├─ theme/
├─ widgets/
└─ workbench/
   ├─ application/
   ├─ core/
   ├─ data/
   ├─ domain/
   ├─ presentation/
   └─ workbench_runtime.dart
~~~

当前 Dart 文件统一使用 `snake_case`，不再混用 camelCase、PascalCase 和带空格的文件名。

Workspace 当前入口也已经去掉历史 `V2` 命名：

~~~text
workbench_workspace_list_page.dart
workbench_workspace_overview_page.dart
WorkbenchWorkspaceListPage
WorkbenchWorkspaceFrame
WorkbenchOverviewPage
~~~

旧的聚合文件 `workbench_workspace_pages.dart` 已确认无引用并删除，不再保留两套 Workspace 页面实现。

## 3. 各层职责

### presentation

负责 Page、Drawer、Dialog、UI State 和用户交互。

不要直接写 SQLite SQL，也不要把文件处理、大段业务规则塞进 Widget。

### application

负责业务规则、用例编排、Context 聚合、Search、AI、Backup / Restore、Export。

主要服务包括：

- WorkspaceService
- TaskService
- NoteService
- IssueService
- ResourceService
- DecisionService
- KnowledgeService
- SearchService
- WorkspaceOverviewService
- AIContextBuilder
- AIConversationService
- FocusSessionService
- BackupService
- RestoreService

### domain

定义 Repository interfaces 和 AI Provider contract。

这里描述“业务需要什么”，不关心 SQLite 怎么实现。

### data

实现 SQLite Repository、Markdown Store、FTS Search Repository。

### core

放 Models、Database、AppPaths、Settings、Provider config 和小范围通用能力。

不要把业务 Service 往 Core 里塞。

## 4. Runtime

`WorkbenchRuntime` 是依赖组装入口。

~~~mermaid
sequenceDiagram
  participant UI
  participant RT as WorkbenchRuntime
  participant PATH as AppPaths
  participant RESTORE as RestoreService
  participant DB as WorkbenchDatabase
  participant SVC as Services

  UI->>RT: WorkbenchRuntime.instance
  RT->>PATH: create()
  RT->>RESTORE: applyPendingRestoreIfPresent()
  RT->>DB: open(workbench.db)
  RT->>SVC: construct repositories/services
  RT-->>UI: runtime ready
~~~

Runtime 继续使用 Future singleton。当前不为了“架构更高级”额外引入 DI 框架。

## 5. 路由

Workbench 主路由：

~~~text
/login
/home
/workspace
/workspace/:workspaceId/overview
/workspace/:workspaceId/tasks
/workspace/:workspaceId/notes
/workspace/:workspaceId/issues
/workspace/:workspaceId/resources
/workspace/:workspaceId/decisions
/workspace/:workspaceId/developer
/time
/knowledge
/developer
/tools
/setting
~~~

Tools 只保留当前真正能使用的路由：

~~~text
/jsonformat
/comparison
/speedtestpage
/ragknowledge
/imagetools/*
/game
~~~

早期 cloud disk 的 file、favorites、recycle、subscribe、shareFolder、deviceInformation 等路由已经删除。

## 6. 本地优先

~~~text
SQLite
  ├─ Metadata
  ├─ Relations
  ├─ Activity
  ├─ AI Conversation
  └─ Search Index

Markdown
  ├─ Notes
  └─ Knowledge

SharedPreferences
  └─ Preferences
~~~

Search Index 可以重建，不是事实数据的唯一来源。

## 7. AI

~~~mermaid
flowchart LR
  UI[Global AI Drawer]
  CTX[AIContextBuilder]
  BUDGET[AIContextBudget]
  PROMPT[AIPromptBuilder]
  PROVIDER[ConfigurableAIProvider]
  API[OpenAI Compatible API]
  HIST[(AI Threads / Messages)]

  UI --> CTX
  CTX --> BUDGET
  BUDGET --> PROMPT
  PROMPT --> PROVIDER
  PROVIDER --> API
  UI --> HIST
~~~

AI 调用不要绕过 Context Builder / Budget / Prompt Builder。

## 8. Backup / Restore

~~~text
Validate ZIP
→ Safety Backup
→ Stage .pending_restore
→ Exit
→ Next Startup
→ Apply Pending Restore
→ Open DB
~~~

Restore 不在运行时直接覆盖正在使用的数据库文件。

## 9. 页面文件怎么拆

当前开始按“入口文件 + 职责 part 文件”的方式拆复杂页面。

Settings：

~~~text
settings_page.dart
├─ settings_sections.dart
├─ settings_navigation.dart
├─ settings_appearance.dart
└─ settings_components.dart
~~~

Workspace Overview：

~~~text
workbench_workspace_overview_page.dart
├─ workbench_workspace_navigation.dart
└─ workbench_workspace_overview_content.dart
~~~

这里使用 Dart `part / part of`，目的不是增加新的架构层，而是把同一个页面 library 内部的私有组件拆开。这样可以继续保留 private Widget，不需要为了拆文件把大量内部类型改成 public。

拆分原则：

- 入口文件保留页面状态和主要生命周期。
- Navigation、Section、Components 按职责放到独立 part。
- 不借拆文件修改 UI 行为。
- 不为了拆文件制造跨层依赖。

## 10. 接下来主要优化什么

业务分层已经比较清楚，下一步主要是 AI Context、复杂 Drawer 和测试覆盖。

当前优先关注：

- `ai_context_builder.dart`
- `global_ai_drawer.dart`
- `workbench_home_page.dart`
- `workbench_knowledge_page.dart`
- `workbench_developer_page.dart`

后续继续按职责拆，不按行数机械切文件，也不借重构顺手改变业务行为。

具体规则统一看 [11_CODE_DEVELOPMENT_RULES.md](11_CODE_DEVELOPMENT_RULES.md)。
