# Personal Workbench Phase 6 Scope — Developer Context + Tools

> Phase 5 已完成 Context-aware Assistant、AI Thread / Message、四种 Scope 与全局 UI 收口。Phase 6 不直接升级成 Autonomous Agent，而是先把开发工作中高频出现的“项目、命令、代码片段、开发资源”正式纳入 Personal Workbench。

## 1. 阶段目标

Phase 6 解决一个核心问题：

> 当用户重新进入一个开发类 Workspace 时，不仅知道“现在在做什么”，还能够快速恢复“这个项目在哪里、怎么启动、常用命令是什么、关键代码片段和开发资源在哪里”。

核心结构：

```text
Workspace
  ↓
Developer Context
  ├─ Project
  ├─ Command
  ├─ Snippet
  └─ Dev Resource
```

Phase 6 的定位是：

```text
Developer Work Context + Tool Launcher
```

不是：

```text
Autonomous Coding Agent
```

---

## 2. 为什么现在做 Developer + Tools

Phase 1–5 已经形成：

```text
Workspace
  ↓
Current Task
  ├─ Note
  ├─ Issue
  ├─ Resource
  ├─ Decision
  └─ Knowledge
      ↓
Context-aware AI
```

但开发工作还缺少一组非常高频、并且难以用普通 Resource 完整表达的结构化信息：

```text
项目根目录
代码仓库
默认分支
技术栈
启动命令
构建命令
测试命令
常用脚本
代码片段
开发文档 / API / Dashboard
```

这些信息非常适合成为 Workspace 的长期上下文。

---

## 3. Phase 6 V1 功能范围

V1 固定包含 4 类对象：

```text
Project
Command
Snippet
Dev Resource
```

### 3.1 Project

一个 Workspace 可以配置一个或多个开发项目。

建议字段：

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

用途：

```text
项目在哪里
Git 仓库是什么
当前常用分支是什么
这个项目主要技术栈是什么
```

### 3.2 Command

保存常用开发命令，但 V1 只允许：

```text
展示
复制
按类别管理
```

建议字段：

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

category V1：

```text
run
build
test
database
docker
git
other
```

示例：

```text
flutter run -d windows
flutter analyze
docker ps
.venv/bin/python -m prefect deployment ls
```

### 3.3 Snippet

保存可复用开发片段。

建议字段：

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

V1 支持：

```text
查看
编辑
复制
语言标签
```

不做 IDE 级代码编辑器。

### 3.4 Dev Resource

普通 Resource 已经存在，但开发类 Workspace 需要更明确的开发入口。

V1 不重新造一套业务 Resource 表，而是提供 Developer View，对现有 Resource 中开发相关内容进行快速访问。

常见类型：

```text
Repository
API Docs
Swagger
Database Console
CI/CD
Dashboard
Design Docs
Issue Tracker
```

原则：

```text
业务数据仍使用 ResourceModel
Developer 页面只是开发视角的聚合入口
```

---

## 4. Workspace 内的 Developer 页面

Workspace Frame 增加一个新的二级入口：

```text
概览
任务
笔记
问题
资源
决策
开发
```

Developer 页面布局建议：

```text
开发
当前工作区的项目、命令和代码片段

┌────────────────────────────────────┐
│ Primary Project                    │
│ cloud_disk                         │
│ D:\...\cloud_disk                  │
│ GitHub · branch                    │
└────────────────────────────────────┘

常用命令
[运行] flutter run -d windows      [复制]
[检查] flutter analyze            [复制]

代码片段
Snippet A
Snippet B

开发资源
Repository / Docs / Dashboard ...
```

桌面端优先，不做手机端专属布局。

---

## 5. Developer Context Service

新增：

```text
DeveloperContextService
```

输入：

```text
workspaceId
```

输出：

```text
DeveloperContext
├─ projects[]
├─ primaryProject?
├─ commands[]
├─ snippets[]
└─ devResources[]
```

职责：

```text
聚合开发上下文
提供 Workspace Developer 页面
后续提供给 AI Context Builder
```

UI 不直接查询多张表拼 Developer Context。

---

## 6. AI Context 接入

Phase 6 会把 Developer Context 接到 Phase 5 的 AI Context Builder，但仍遵守 Context Budget。

Task / Workspace Scope 在适用时可以补充：

```text
Primary Project metadata
Pinned Commands
Relevant Snippets metadata/content
Dev Resources
```

建议优先级：

```text
P1 Primary Project metadata
P2 Pinned Command
P2 Relevant Snippet
P2 Dev Resource
```

禁止默认把所有 Snippet / Command 全量塞入模型。

Global Scope 仍不扫描全部开发数据。

---

## 7. 工具行为边界

Phase 6 V1 允许：

```text
复制本地路径
复制命令
复制代码片段
打开 URL 类 Resource
展示项目目录
```

Phase 6 V1 明确不允许：

```text
自动执行 shell / PowerShell / bash
自动运行 git command
自动修改代码文件
自动运行测试
自动启动 Docker
AI Tool Calling
AI 自动执行 Command
```

原因：

> 先把 Developer Context 做稳定，再讨论执行层权限、确认机制和审计。

---

## 8. Schema v6

Phase 6 预计升级：

```text
schemaVersion = 6
```

新增表：

```text
developer_projects
developer_commands
developer_snippets
```

现有 Resource 表继续复用，不新增 `developer_resources`。

迁移原则：

```text
5 → 6 只新增表和索引
不修改 Phase 1–5 原业务表
不删除现有数据
```

---

## 9. Search 接入

Phase 6 V1 将以下对象接入 SearchService：

```text
Project
Command
Snippet
```

Search Result entity type 新增：

```text
project
command
snippet
```

搜索示例：

```text
flutter analyze
PostgreSQL
Docker
DeepSeek
```

可以直接找到相应 Command / Snippet / Project。

---

## 10. Activity

关键修改记录到 Activity：

```text
project_created
project_updated
command_created
command_updated
snippet_created
snippet_updated
```

不记录纯“复制”行为，避免 Activity 噪音。

---

## 11. UI 原则

继续沿用 Phase 5 已封版的 Workbench UI：

```text
ThemePalette
WorkbenchSectionPage
WorkbenchCard
WorkbenchTag
Workspace Frame
```

不建立 Developer 专属视觉体系。

Project / Command / Snippet 的编辑优先使用：

```text
右侧 Drawer
或轻量 Dialog
```

不新增复杂多级导航。

---

## 12. Phase 6 开发顺序

### P6.1 Contract

```text
DeveloperProjectModel
DeveloperCommandModel
DeveloperSnippetModel
DeveloperContextModel
```

### P6.2 Schema v6 + Repository

```text
developer_projects
developer_commands
developer_snippets
```

### P6.3 Application Services

```text
DeveloperProjectService
DeveloperCommandService
DeveloperSnippetService
DeveloperContextService
```

### P6.4 Workspace Developer Page

```text
Project
Commands
Snippets
Dev Resources
```

### P6.5 Search Integration

```text
Project / Command / Snippet
→ SearchService
```

### P6.6 AI Context Integration

```text
Developer Context
→ AIContextBuilder
→ Context Budget
→ Context Preview
```

### P6.7 Windows Acceptance

验证：

```text
CRUD
复制
搜索
AI Context
schema v6 migration
restart recovery
Phase 1–5 regression
```

### P6.8 Baseline

```text
PHASE6_ACCEPTANCE.md
PHASE6_BASELINE.md
```

---

## 13. Phase 6 明确不做

```text
Agent Tool Calling
Shell Execution
PowerShell Execution
Terminal Emulator
Embedded IDE
Git Client 完整实现
Git Commit / Push / Pull 自动执行
文件系统全文扫描
自动代码修改
自动测试执行
MCP / Tool Plugin Runtime
Embedding / Vector Search
Cloud Sync
多人协作
```

这些能力后续如果做，应单独设计安全边界和确认机制。

---

## 14. Definition of Done

Phase 6 完成必须满足：

```text
[ ] Schema v6 migration 安全
[ ] Project CRUD
[ ] Command CRUD
[ ] Snippet CRUD
[ ] Developer Context 聚合可用
[ ] Workspace Developer Page 可用
[ ] Command / Path / Snippet 可复制
[ ] Dev Resource 可聚合显示
[ ] Project / Command / Snippet 可搜索
[ ] AI 可以按预算获得 Developer Context
[ ] Windows 重启后数据恢复
[ ] Phase 1–5 smoke regression 通过
[ ] flutter analyze 无 Phase 6 新增 error
```

完成后创建：

```text
PHASE6_ACCEPTANCE.md
PHASE6_BASELINE.md
```
