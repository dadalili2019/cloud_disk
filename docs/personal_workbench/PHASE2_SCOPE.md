# Personal Workbench Phase 2 — Workspace Complete

## 1. Phase 2 目标

Phase 1 已经跑通：

```text
Workspace → Task → Current Task → Note → Entity Link → Overview
```

Phase 2 不扩展到 Home、Time、Knowledge 或 AI。

这一阶段只把一个 Workspace 内部的工作上下文补完整：

```text
Workspace
└─ Current Task
   ├─ Note
   ├─ Issue
   ├─ Resource
   └─ Decision
```

核心目标：

> 不只是知道“我正在做什么”，还要知道“卡在哪里、参考什么、为什么这样决定”。

---

## 2. 本阶段新增对象

### 2.1 Issue

Issue 不是简单 Bug List，而是当前工作中需要调查、跟踪或解决的问题。

核心字段：

```text
id
workspaceId
title
status
severity
impact
hypothesis
nextInvestigationStep
resolution
createdAt
updatedAt
archivedAt
```

状态：

```text
open
investigating
resolved
archived
```

Phase 2 UI 中文展示：

```text
待处理
调查中
已解决
已归档
```

Issue 可以通过 Entity Link 关联 Task：

```text
Issue blocks Task
Issue related_to Task
```

当前任务的未解决 Issue 可以作为 Overview 的“当前阻塞”。

---

### 2.2 Resource

Resource 是 Workspace 中的参考资源。

类型：

```text
repository
local_path
document
service
link
design
command
other
```

核心字段：

```text
id
workspaceId
name
resourceType
uri
description
isPinned
createdAt
updatedAt
archivedAt
```

可保存：

```text
GitHub URL
本地代码目录
文档路径
服务地址
命令
设计资料链接
```

Resource 可以关联 Task：

```text
Resource supports Task
```

---

### 2.3 Decision

Decision 独立保存，不只写在 Note 里。

核心字段：

```text
id
workspaceId
title
decisionText
rationale
revisitCondition
status
createdAt
updatedAt
archivedAt
```

状态：

```text
active
superseded
archived
```

中文展示：

```text
生效中
已替代
已归档
```

Decision 可以关联 Task：

```text
Decision applies_to Task
```

---

## 3. Workspace 页面结构

Phase 2 工作区内导航调整为：

```text
概览 | 任务 | 笔记 | 问题 | 资源 | 决策
```

不新增大段说明文字。

保持当前中文界面与紧凑桌面布局。

---

## 4. Overview 增强

Phase 2 的概览在 Phase 1 基础上增加：

```text
当前任务
下一步
当前阻塞
最近上下文
最近决策
最近动态
```

### 当前阻塞

优先显示：

```text
与 Current Task 关联
且状态不是 resolved / archived
的 Issue
```

### 最近上下文

聚合当前任务最近关联的：

```text
Note
Issue
Resource
Decision
```

不在 UI 层直接查询多张表，统一由 Context / Overview Service 聚合。

---

## 5. Entity Link 扩展

Phase 1 已有：

```text
Note linked_to Task
```

Phase 2 增加：

```text
Issue blocks Task
Issue related_to Task
Resource supports Task
Decision applies_to Task
```

页面禁止直接维护 entity_links。

所有关系通过 EntityLinkService 处理。

---

## 6. Application 层新增

建议新增：

```text
IssueService
ResourceService
DecisionService
TaskContextService
```

TaskContextService 返回：

```text
TaskContext
├─ task
├─ notes[]
├─ issues[]
├─ resources[]
├─ decisions[]
└─ recentActivity[]
```

Workspace Overview 逐步基于 TaskContext 构建，避免未来 Home / Continue / AI 各自重复拼装上下文。

---

## 7. SQLite Migration

Phase 2 必须通过 schema migration 增加：

```text
issues
resources
decisions
```

禁止通过删除 `workbench.db` 解决 schema 变化。

现有 Phase 1 数据必须保留。

数据库 schemaVersion：

```text
1 → 2
```

---

## 8. Phase 2 不做

本阶段明确不做：

```text
Home Snapshot
Continue
Quick Capture
Focus Session
Today Timeline
Time Summary
Knowledge
Global Search
AI
Developer
Backup / Restore
Cloud Sync
多人协作
复杂 Kanban
复杂标签系统
```

这些继续按后续 Phase 实现。

---

## 9. 实现顺序

建议严格按以下顺序开发：

```text
1. Schema v2 Migration
2. Issue Model / Repository / Service
3. Issue UI + Task Link
4. Resource Model / Repository / Service
5. Resource UI + Task Link
6. Decision Model / Repository / Service
7. Decision UI + Task Link
8. TaskContextService
9. Overview 增强
10. Archive / Workspace Settings
11. Phase 2 回归
```

---

## 10. Phase 2 验收链路

使用一个 Workspace 验证：

```text
创建 Current Task
  ↓
创建 Issue，并关联 Current Task
  ↓
Issue 显示为当前阻塞
  ↓
创建 Resource，并关联 Current Task
  ↓
创建 Decision，并关联 Current Task
  ↓
Overview 能恢复完整上下文
  ↓
关闭应用
  ↓
重新打开
  ↓
Issue / Resource / Decision / Links 全部恢复
```

Phase 2 完成后，一个 Workspace 应该能够回答：

```text
我现在在做什么？
下一步是什么？
我卡在哪里？
我参考了什么？
我为什么这样决定？
```
