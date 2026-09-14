# Personal Workbench Phase 3 — Home + Time

## 1. Phase 3 目标

Phase 1 建立了 Workspace / Task / Note 的最小闭环。

Phase 2 把 Current Task 上下文补完整：

```text
Current Task
├─ Note
├─ Issue
├─ Resource
└─ Decision
```

Phase 3 不继续扩展 Workspace 内部对象，而是开始解决一个新的问题：

> 每次打开 Personal Workbench，我今天应该从哪里继续？

因此 Phase 3 的核心是：

```text
Home
├─ Continue
├─ Quick Capture
├─ Today Timeline
└─ Focus / Time
```

不是传统 Dashboard，也不以图表和统计为中心。

---

## 2. Home 的产品定位

首页只回答四个问题：

```text
1. 我现在最应该继续什么？
2. 我今天有哪些正在推进的工作？
3. 我刚想到的东西放哪里？
4. 我今天实际投入了多少时间？
```

首页不展示大量历史信息，不做复杂 BI，不复制 Workspace Overview。

Workspace Overview 回答“这个工作区现在是什么状态”；
Home 回答“我现在应该做什么”。

---

## 3. Continue

### 3.1 定位

Continue 是 Phase 3 的第一优先级能力。

它不是简单跳转按钮，而是把最近有效工作上下文组合成一个“继续工作入口”。

最低信息：

```text
Workspace
Current Task
Next Step
Current Blocker
最近 Note / Resource / Decision 摘要
最近活动时间
```

### 3.2 数据来源

优先复用 Phase 2 的：

```text
TaskContextService
```

禁止 Home 再分别查询 Note / Issue / Resource / Decision。

### 3.3 Continue 卡片

首页首屏优先展示一个主要 Continue 卡片：

```text
继续工作

Workspace Name
Current Task
下一步：xxx

阻塞：xxx（如有）

[继续]
```

点击“继续”进入对应 Workspace Overview 或当前 Task 上下文页面。

Phase 3 初期不做复杂智能推荐。

候选排序先采用确定性规则：

```text
1. 最近有活动且存在 Current Task 的 Workspace
2. 最近更新时间倒序
```

---

## 4. Today / 今日工作

Home 除主 Continue 外，可展示今天涉及的其他活动工作区。

信息保持轻量：

```text
Workspace
Current Task
Next Step
今日累计时间（若有）
```

不在 Phase 3 做复杂跨 Workspace 优先级算法。

---

## 5. Quick Capture

### 5.1 定位

Quick Capture 用于快速记下“暂时不想分类，但不能丢”的内容。

入口应在 Home 上直接可用，操作路径尽量短。

### 5.2 Phase 3 最小边界

支持快速输入一段文本，并选择：

```text
保存为 Note
或
保存为 Task
```

默认 Workspace：

```text
当前 Continue 所属 Workspace
```

如果没有 Continue Workspace，则要求用户选择 Workspace。

Phase 3 不做：

```text
AI 自动分类
自动提取任务
语义解析
复杂 Inbox 工作流
```

---

## 6. Time / 时间记录

### 6.1 定位

时间能力服务于“我今天把时间花在哪里”，而不是做完整工时系统。

### 6.2 Focus Session

支持在 Current Task 上开始一个 Focus Session：

```text
开始
暂停 / 结束
```

核心字段建议：

```text
id
workspaceId
taskId
startedAt
endedAt
durationSeconds
note
createdAt
```

### 6.3 Today Timeline

Today Timeline 展示今天实际发生的工作片段：

```text
09:30 - 10:15  Workspace A / Task A
10:30 - 11:10  Workspace B / Task B
```

初期只展示 Focus Session，不混入所有 Activity Event。

### 6.4 Today Summary

首页可展示：

```text
今日专注：2h 35m
涉及工作区：3
完成 Focus Session：4
```

仅做轻量摘要，不做周/月报表。

---

## 7. 数据库 Schema v3

Phase 3 预计新增：

```text
focus_sessions
quick_captures（可选，如果最终 Quick Capture 直接落 Note / Task，则不建表）
```

优先原则：

> 能直接落现有 Task / Note 就不额外建中间表。

数据库版本：

```text
2 → 3
```

禁止删除现有数据库重新初始化。

---

## 8. Application 层建议

新增：

```text
HomeService
ContinueService
FocusSessionService
TodayService
QuickCaptureService
```

其中：

```text
ContinueService
  ↓
TaskContextService
```

`TaskContextService` 继续作为上下文唯一聚合入口。

---

## 9. 首页 UI 原则

首页保持中文、紧凑、少说明文字。

推荐结构：

```text
今天

┌─────────────────────────────┐
│ 继续工作                     │
│ Workspace / Current Task    │
│ 下一步：xxx                  │
│ [继续]                       │
└─────────────────────────────┘

┌──────────────┐ ┌──────────────┐
│ 快速记录      │ │ 今日专注      │
└──────────────┘ └──────────────┘

今日工作
- Workspace A / Task A
- Workspace B / Task B

今日时间线
...
```

不使用大量统计卡片，不做仪表盘式首页。

---

## 10. Phase 3 实现顺序

建议严格按顺序：

```text
1. Schema v3 Migration
2. HomeService / ContinueService
3. Home 页面替换旧首页入口
4. Continue 卡片 + 跳转
5. Quick Capture
6. Focus Session Model / Repository / Service
7. Current Task 开始 / 结束 Focus
8. Today Timeline
9. Today Summary
10. Phase 3 回归
```

第一条开发链必须先跑通：

```text
打开应用
  ↓
进入 Home
  ↓
看到最近有效 Current Task
  ↓
看到 Next Step / Blocker
  ↓
点击“继续”
  ↓
回到对应 Workspace 上下文
```

在这条链跑通之前，不先做时间统计和 Quick Capture。

---

## 11. Phase 3 不做

明确不做：

```text
Knowledge
Global Search
AI Assistant
AI 自动分类
AI 自动总结
Cloud Sync
多人协作
复杂 Calendar
复杂周/月工时报表
任务智能排序
自动日程规划
```

这些属于后续阶段。

---

## 12. Phase 3 完成标准

Phase 3 完成后，用户打开 Personal Workbench 应该能在首页直接回答：

```text
我现在最应该继续什么？
下一步是什么？
当前有没有阻塞？
我今天还在推进哪些工作？
我今天投入了多少时间？
我临时想到的东西怎么快速记下来？
```
