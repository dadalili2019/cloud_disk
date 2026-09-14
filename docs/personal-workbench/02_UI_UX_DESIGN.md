# Personal Workbench V1 — UI / UX 设计规范

## 1. 整体方向

```text
Comfort Dark
紧凑
低噪音
桌面工作台
```

避免企业 Dashboard、Jira 风格、大面积说明文案、复杂卡片堆叠。

## 2. 基础视觉

```text
Page Background    #17191d
Sidebar            #181b1f
Panel              #1d2025
Secondary Panel    #22262c
Raised Panel       #272c33
Border             #30353d
Primary Accent     #d7ff6a
Muted Text         #9ca4ae
Blocker Red        #ff8f8f
Investigating      #ffc274
Blue               #8cc8ff
Purple             #c6a7ff
```

## 3. 全局布局

```text
Topbar  54px
Sidebar 224px
Compact Sidebar 76px
```

## 4. Sidebar

```text
Home
Workspace
Time
Knowledge
Developer
Tools
Settings
```

## 5. Topbar

保留：

```text
Personal Workbench
Current Workspace / Context
Global Search
AI
Settings
```

## 6. Workspace Tabs

```text
Overview
Tasks
Notes
Issues
Resources
More
```

## 7. Drawer

详情优先使用 Right Drawer：Task、Issue、Resource、Knowledge、AI、Resume Context。

普通详情建议 500~560px；工具 / Markdown / AI 可 560~720px。

## 8. Home

```text
Current Focus
├─ Current Task
├─ Next Step
├─ Blocker
└─ Continue

Today
Recent Activity
Quick Entry
```

## 9. Workspace Overview

Current Focus 是最大区域：Task Title / Status / Progress / Next Step / Last Context / Continue。

## 10. Tasks

Current Task 视觉优先级最高。默认不使用重型三列 Kanban。

## 11. Markdown Notes

Desktop：

```text
┌─────────────┬───────────────────────────────┐
│ Note List   │ Header                        │
│             ├───────────────────────────────┤
│             │ Toolbar                       │
│             ├───────────────┬───────────────┤
│             │ Markdown Edit │ Preview       │
└─────────────┴───────────────┴───────────────┘
```

支持 `Edit / Split / Preview`，工具栏支持 H1/H2/Bold/Code/List/Task List/Code Block/Link。

保存状态：`Saving... / Saved`。

## 12. Issues

```text
Blocker       Red
Investigating Orange
Open          Blue
Resolved      Muted / Green
```

Drawer：Impact / Hypothesis / Next Investigation Step / Linked Context / Timeline / Resolve。

## 13. Developer

```text
Projects
Environments
Services
Commands
Snippets
```

## 14. Tools

```text
Favorites
All Tools
Recently Used
```

点击工具打开大型 Drawer / Workbench。

## 15. Global AI

右侧 Drawer。Scope：Current Task / Workspace / Knowledge / Global。

Context 使用 Chips 展示，允许移除。

## 16. Loading

所有耗时操作必须提供明确状态，尤其 AI / Database / Markdown Save / Search / File Scan。

## 17. 文案

默认短、直接、操作导向：

```text
Next
Blocker
Continue
Save
Open
Copy
Archive
Resolve
```

## 18. 响应式

V1 Windows Desktop 优先。手机端后续将 Sidebar 转 Bottom Navigation / Drawer，Markdown 双栏转单栏 Edit/Preview 切换，Right Drawer 转 Full Screen Sheet。
