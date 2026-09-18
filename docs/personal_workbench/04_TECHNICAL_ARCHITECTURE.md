# Personal Workbench 技术架构

## 1. 总体架构

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

## 2. Flutter 层次

### presentation

职责：

- 页面
- Drawer
- Dialog
- UI State
- 用户交互

不直接编写 SQLite SQL。

### application

职责：

- 业务规则
- 用例编排
- Context 聚合
- Backup / Restore
- Search
- AI

代表服务：

- WorkspaceService
- TaskService
- NoteService
- IssueService
- ResourceService
- DecisionService
- KnowledgeService
- SearchService
- AIContextBuilder
- AIConversationService
- FocusSessionService
- BackupService
- RestoreService

### domain

定义 Repository interfaces 和 AI Provider contract。

### data

实现：

- SQLite repositories
- Markdown Store
- FTS Search Repository

### core

负责：

- Models
- Database
- AppPaths
- Settings model
- Provider config
- Utilities

## 3. Runtime

WorkbenchRuntime 是 Workbench 的依赖组装入口。

启动链路：

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

Runtime 使用 Future singleton，避免重复初始化。

## 4. 路由

使用 go_router。

主要 Workbench Route：

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

旧工具和 legacy route 仍保留，但由统一 Shell 承载。

## 5. 本地优先架构

数据分层：

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

优势：

- 业务关系适合 SQLite
- 长文本适合 Markdown
- 用户可直接拿走正文文件
- Search Index 可重建
- 设置不污染业务数据库

## 6. Search 架构

~~~mermaid
flowchart LR
  Entity[Task / Note / Issue / Resource / Decision / Knowledge / Dev] --> S[SearchService]
  S --> IDX[(FTS5 search_index)]
  IDX --> FTS[FTS MATCH + BM25]
  IDX --> LIKE[LIKE fallback]
  FTS --> R[SearchResult]
  LIKE --> R
~~~

## 7. AI 架构

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

AI 不能绕过 Context Builder / Budget / Prompt Builder。

## 8. Backup / Restore 架构

Restore 不在运行时直接覆盖已打开数据库。

~~~text
Validate ZIP
→ Safety Backup
→ Stage .pending_restore
→ Exit
→ Next Startup
→ Apply Pending Restore
→ Open DB
~~~

这避免在 SQLite 正在使用时直接替换数据库文件。

## 9. 技术边界

当前 Developer Context 不执行：

- Shell
- Git
- Docker
- Test
- File edit

未来如果增加 Tool Execution，必须单独设计：

- Permission
- Confirmation
- Sandbox
- Audit
- Failure Recovery
