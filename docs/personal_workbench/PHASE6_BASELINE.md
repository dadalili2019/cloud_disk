# Personal Workbench Phase 6 基线

## 1. 阶段结论

Phase 6 已完成 Windows 本地 V1 验收，并形成新的 Personal Workbench 基线。

本阶段把 Phase 5 的 Context-aware Assistant 往开发工作场景推进了一步，但仍明确保持在：

```text
Developer Work Context + Tool Launcher
```

而不是：

```text
Autonomous Coding Agent
```

最终形成：

```text
Workspace
  ↓
Developer Context
  ├─ Project
  ├─ Command
  ├─ Snippet
  └─ Dev Resource
       ↓
Search
       ↓
AI Context
```

Phase 6 的核心价值是：

> 重新进入一个开发类 Workspace 时，可以快速恢复项目位置、仓库、分支、技术栈、常用命令、代码片段和开发资源，并让这些内容进入统一 Search 与 AI Context。

---

## 2. Phase 6 功能对象基线

V1 固定 4 类 Developer Context：

```text
Project
Command
Snippet
Dev Resource
```

### Project

结构化记录：

```text
项目名称
本地目录
Repository URL
常用分支
技术栈
说明
Primary Project
```

一个 Workspace 可以有多个 Project，但正常活动数据中最多一个 Primary Project。

### Command

保存高频开发命令：

```text
名称
命令正文
Working Directory
Category
Notes
Pinned
```

Category 固定：

```text
run
build
test
database
docker
git
other
```

V1 只展示 / 管理 / 复制，不执行。

### Snippet

保存可复用代码或配置片段：

```text
标题
Language
Content
Notes
Pinned
```

支持查看、编辑、复制，不升级为 IDE 级编辑器。

### Dev Resource

不新增独立业务 Resource 表。

继续复用：

```text
ResourceModel
```

Developer 页面只提供开发视角聚合。

---

## 3. Schema v6 基线

数据库版本：

```text
schemaVersion = 6
```

迁移：

```text
5 → 6
```

新增表：

```text
developer_projects
developer_commands
developer_snippets
```

### developer_projects

关键字段：

```text
id
workspace_id
name
local_path
repository_url
branch
tech_stack
notes
is_primary
created_at
updated_at
archived_at
```

关键约束：

```text
Workspace FK
is_primary 0/1
同一 Workspace 最多一个未归档 Primary Project
```

### developer_commands

关键字段：

```text
id
workspace_id
project_id nullable
name
command
working_directory nullable
category
notes
is_pinned
created_at
updated_at
archived_at
```

### developer_snippets

关键字段：

```text
id
workspace_id
project_id nullable
title
language
content
notes
is_pinned
created_at
updated_at
archived_at
```

Phase 1–5 原有表不删除、不重建。

Windows 完整退出 / 重启后已确认 Developer 数据与原有 Workbench 数据仍可读取。

---

## 4. Repository / Application Service 基线

Developer Repository：

```text
DeveloperProjectRepository
DeveloperCommandRepository
DeveloperSnippetRepository
```

SQLite 实现：

```text
SqliteDeveloperProjectRepository
SqliteDeveloperCommandRepository
SqliteDeveloperSnippetRepository
```

Application Service：

```text
DeveloperProjectService
DeveloperCommandService
DeveloperSnippetService
DeveloperContextService
```

职责原则：

```text
Presentation
   ↓
Application Service
   ↓
Repository
   ↓
SQLite
```

UI 不直接跨表查询 Developer 数据。

---

## 5. Developer CRUD 基线

### Project

支持：

```text
Create
Update
List
Set Primary
Archive
Copy Path
Copy Repository URL
```

首个 Project 自动成为 Primary Project。

归档 Primary Project 后，如果仍有其他活动 Project，会自动选择新的 Primary Project。

### Command

支持：

```text
Create
Update
List
Pin
Category
Working Directory
Archive
Copy Command
```

Command 可关联 Workspace 内某个 Project，也允许不关联 Project。

### Snippet

支持：

```text
Create
Update
List
Language
Pin
Archive
Copy Content
```

Snippet 同样支持可选 Project 关联。

删除语义统一采用：

```text
Soft Archive
```

不物理删除业务数据。

---

## 6. Activity 基线

Developer 关键操作进入 Workbench Activity：

```text
project_created
project_updated
project_archived
command_created
command_updated
command_archived
snippet_created
snippet_updated
snippet_archived
```

Copy 不记录 Activity，避免产生低价值事件噪声。

---

## 7. Developer Context Service 基线

核心输出：

```text
DeveloperContext
├─ projects[]
├─ primaryProject?
├─ commands[]
├─ snippets[]
└─ devResources[]
```

实现：

```text
lib/workbench/application/developer_context_service.dart
```

作用：

```text
统一 Developer 页面聚合
统一 AI Developer Context 数据来源
隔离 UI 与 Repository 细节
```

归档 Developer Entity 不进入正常 Workspace 聚合。

---

## 8. Workspace Developer Page 基线

Workspace 二级导航最终为：

```text
概览
任务
笔记
问题
资源
决策
开发
```

Developer 页面入口：

```text
/workspace/:workspaceId/developer
```

页面固定区域：

```text
项目
常用命令
代码片段
开发资源
```

支持：

```text
Project 新增 / 编辑 / Primary / 归档 / 复制
Command 新增 / 编辑 / Pin / 归档 / 复制
Snippet 新增 / 编辑 / Pin / 归档 / 复制
Dev Resource 聚合与复制
```

UI 继续复用：

```text
ThemePalette
WorkbenchSectionPage
WorkbenchSectionHeader
WorkbenchCard
WorkbenchTag
Workspace Frame
```

Windows 验收时已修复 Developer 内容区与右侧 scrollbar 重叠问题。

---

## 9. Search Integration 基线

Developer Search Entity Type：

```text
developer_project
developer_command
developer_snippet
```

继续复用 Phase 4 Search Index：

```text
FTS5
BM25
Derived / Rebuildable Index
```

不新增新的搜索业务数据库。

### Project 搜索字段

```text
name
local_path
repository_url
branch
tech_stack
notes
primary marker
```

### Command 搜索字段

```text
name
command
working_directory
category
notes
```

### Snippet 搜索字段

```text
title
language
content
notes
```

Windows 已确认：

```text
Project 可搜索
Command 可搜索
Snippet 可搜索
点击结果进入对应 Developer 页面
完整重启后可重新构建并搜索
```

---

## 10. AI Developer Context 基线

Developer Context 已正式进入：

```text
AIContextBuilder
```

链路仍保持 Phase 5 架构：

```text
Context Builder
   ↓
Context Budget
   ↓
PromptBuilder
   ↓
AI Provider
```

不绕过 Phase 5 的 Context Budget / PromptBuilder。

### Task Scope

Developer Context 策略：

```text
P1 Primary Project
P2 Pinned / selected Command
P2 Dev Resource
P3 Pinned / selected Snippet
```

不会默认把 Workspace 所有 Developer 数据全部塞入 Task Context。

### Workspace Scope

允许：

```text
Primary Project
少量其他 Project
少量 Command
少量 Snippet
Dev Resource
```

### Global / Knowledge Scope

继续遵守：

```text
User Query
→ SearchService
→ 少量 Developer Entity
→ AIContextBuilder
```

Global 不全库扫描所有 Project / Command / Snippet。

---

## 11. AI Manual Context 基线

`_loadEntityItem()` 已支持：

```text
developer_project
developer_command
developer_snippet
```

因此 Developer Entity 可以参与：

```text
Search
Manual Include
Exclude
Restore
Context Preview
Prompt Context
```

AI Drawer 显示名称统一为：

```text
项目
命令
代码片段
```

不向用户暴露内部 entity type。

---

## 12. AI Context Snapshot 原则保持不变

Phase 6 没有改变 Phase 5 Snapshot 原则。

Assistant Message 的 `context_snapshot_json` 仍保存：

```text
scope
workspace / anchor reference
included entity refs
```

不保存 Developer Entity 正文副本。

例如 Snippet Content 可以进入本次 Prompt，但 Snapshot 只记录它的 Entity Ref。

原则继续是：

> Snapshot 记录“参考了什么”，而不是复制业务正文。

---

## 13. Tool Safety Boundary 基线

Phase 6 最重要的边界之一：

### V1 允许

```text
展示本地项目路径
复制项目路径
展示 Repository URL
展示命令
复制命令
展示 Snippet
复制 Snippet
聚合开发资源
```

### V1 不允许

```text
Shell / PowerShell / Bash 自动执行
Git 自动执行
Test 自动执行
Docker 自动启动
代码文件自动修改
AI Tool Calling / Tool Execution
Terminal Emulator
Embedded IDE
完整 Git Client
全盘文件系统扫描
MCP Runtime
Cloud Sync / Collaboration
```

因此 Phase 6 仍然是：

```text
Context-aware Developer Assistant
```

不是：

```text
Autonomous Coding Agent
```

---

## 14. Windows Restart Recovery 基线

最终 Windows 验收执行：

```text
完整关闭 App
→ 重新 flutter run -d windows
→ 打开同一 Workspace
```

确认：

```text
Project 恢复
Command 恢复
Snippet 恢复
Search 恢复
AI Developer Context 可重新生成
Phase 1–5 原数据仍存在
```

Schema v6 本地持久化链路通过。

---

## 15. Phase 1–5 回归结果

Phase 6 最终 smoke 已确认：

```text
Home
Workspace Overview
Task
Note
Issue
Resource
Decision
Knowledge + Search
AI Drawer
AI History
```

页面可正常打开，没有观察到明显运行错误。

Phase 6 Workspace Developer Page 与导航扩展没有破坏旧 Workspace Frame。

---

## 16. Flutter Analyze 基线

最终执行：

```powershell
flutter analyze
```

结果：

```text
130 issues found
```

终端没有 Phase 6 新增 compile error。

当前仍主要属于仓库既有：

```text
info
warning
file_names
unused_import
avoid_print
deprecated_member_use
use_build_context_synchronously
```

Phase 6 封版标准是：

```text
无 Phase 6 新增编译 error
```

已满足。

---

## 17. Phase 6 与 Phase 5 差异边界

Phase 6 相对 Phase 5 的主要新增集中在：

```text
Developer Models
Developer Repository
Developer Application Services
Schema v6
Developer Workspace Page
Developer Search Integration
Developer AI Context Integration
Workspace Developer Route / Navigation
Phase 6 Scope / Acceptance / Baseline Docs
```

没有在 Phase 6 引入：

```text
命令执行器
Agent Runtime
代码修改工具
自动 Git
自动测试
自动 Docker
```

Phase 5 已封版能力没有重新设计。

---

## 18. 已知后续 Hardening

以下内容可以进入后续独立阶段，不重新打开 Phase 6 主范围：

```text
Developer CRUD 更完整的自动化测试
Primary Project 不允许被直接取消的业务约束进一步收紧
Dev Resource 类型语义进一步细化
Project / Command / Snippet 搜索精确定位到具体卡片
Search Index 编辑后即时同步优化
Developer Context relevance ranking
Snippet 大内容的 AI Context 裁剪策略
Open project folder / URL 的系统级安全打开能力
历史 analyzer info / warning 清理
```

如果未来增加真正的本地工具执行，必须单独进入新的阶段并重新设计：

```text
Permission
Confirmation
Sandbox
Audit
Failure Recovery
Tool Result Contract
```

不能直接在 Phase 6 上追加自动执行能力。

---

## 19. Phase 6 封版状态

```text
[✓] Developer Context Contract
[✓] Schema v6 Migration
[✓] Project Repository / Service
[✓] Command Repository / Service
[✓] Snippet Repository / Service
[✓] Developer Context Aggregation
[✓] Workspace Developer Page
[✓] Copy-only Tool Boundary
[✓] Developer Search Integration
[✓] AI Developer Context Integration
[✓] Task Scope Developer Context
[✓] Workspace Scope Developer Context
[✓] Manual Developer Context Capability
[✓] Windows Restart Recovery
[✓] Phase 1–5 Smoke Regression
[✓] No Phase 6 Compile Error
```

**Phase 6 正式封版。**

后续功能不得继续无边界追加到 Phase 6；新的能力应进入新的阶段规划。