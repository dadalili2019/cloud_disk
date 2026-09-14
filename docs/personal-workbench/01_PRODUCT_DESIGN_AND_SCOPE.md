# Personal Workbench V1 — 产品设计与功能边界

## 1. 产品定位

Personal Workbench 更关注：

```text
我正在推进什么？
上次停在哪里？
下一步是什么？
现在被什么卡住？
当时已经知道了什么？
为什么做了这个决定？
需要哪些资源？
哪些经验以后还能复用？
```

核心价值：**降低重新进入工作状态时的上下文恢复成本。**

## 2. 核心产品概念

- **Workspace**：长期工作上下文容器。
- **Task**：我要推进什么，核心字段是 `Next Step`。
- **Note**：推进过程中知道了什么；正文使用 Markdown。
- **Issue**：当前被什么问题卡住；保存 Impact / Hypothesis / Next Investigation Step / Resolution。
- **Resource**：当前 Workspace 反复需要的 Repository、路径、文档、服务、命令等。
- **Decision**：保存 Decision / Why / Revisit Condition。
- **Knowledge**：从 Notes / Issues / Decisions 中提炼出来、可跨 Workspace 复用的知识。

## 3. 一级模块

```text
Home
Workspace
Time
Knowledge
Developer
Tools
Settings
```

全局能力：

```text
Global Search
Global AI
```

## 4. Home

Home 是“今天从哪里继续”的入口，不是传统 Dashboard。

只保留：

```text
Current Workspace
Current Task
Next Step
Blocker
Today
Recent Activity
Quick Entry
```

V1 不做复杂 KPI、团队统计和企业 Dashboard。

## 5. Workspace

Workspace 内部：

```text
Overview
Tasks
Notes
Issues
Resources
More
```

### Overview

只回答：

```text
我现在在做什么？
下一步是什么？
卡在哪里？
最近发生了什么？
```

### Tasks

不是重型 Kanban。围绕：

```text
Current Task
Todo
Completed
Next Step
Progress
```

状态：`todo / doing / done / archived`。

每个 Workspace 最多一个 Current Task。

### Notes

Confirmed：

- Markdown 原生格式。
- 笔记列表 + Markdown Editor。
- Edit / Split / Preview。
- 自动保存。
- 默认可关联 Current Task。
- Markdown 是正文 Source of Truth。

### Issues

主要字段：

```text
Title
Status
Severity
Impact
Hypothesis
Next Investigation Step
Resolution
```

### Resources

只保存 Workspace 专属资源。跨项目长期开发资源进入 Developer。

### More

```text
Activity
Decisions
Archive
Workspace Settings
```

## 6. Time

V1 不做完整 Calendar，只聚焦：

```text
Focus Session
Today Timeline
Today Summary
```

## 7. Knowledge

生命周期：

```text
Workspace Context
→ Review
→ Distill
→ Knowledge
→ Reuse
```

Knowledge 正文继续使用 Markdown。

## 8. Developer

Workspace Resources = 某个项目需要的资源。  
Developer = 长期跨项目复用的开发资产。

V1 类型：

```text
Project
Repository
Environment
Service
Command
Snippet
```

## 9. Tools

即时工具，不是资产管理页。

V1 方向：

```text
JSON Formatter
Timestamp Converter
UUID Generator
Text Diff
Base64
Regex Tester
Hash
SQL Formatter
Markdown Preview
API Request Builder
```

## 10. Settings

```text
General
Appearance
Markdown Notes
AI
Data & Backup
Shortcuts
```

## 11. Global AI

AI 不是独立 Chatbot。Scope：

```text
Current Task
Workspace
Knowledge
Global
```

必须显示当前 AI 使用了哪些 Context，用户可以移除。

## 12. 文案原则

页面是工作工具，不是产品说明书。只保留：

```text
页面标题
状态
关键数据
任务内容
操作按钮
```

## 13. V1 不做

```text
多人协作
组织 / 团队
复杂权限
企业项目管理
复杂 Kanban Builder
完整 Calendar
实时协作编辑
CRDT
插件市场
Cloud Sync
复杂账号体系
工作流引擎
```

## 14. 产品核心成功标准

第二天打开应用时，系统应直接恢复：

```text
昨天在做什么
做到哪里
下一步是什么
当前 Blocker
相关 Note / Resource / Decision
```
