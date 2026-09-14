# Personal Workbench Phase 3 基线

## 1. 阶段结论

Phase 3 已完成，并经过实际 Windows 运行验证。

Phase 3 的目标不是继续扩展 Workspace 内部对象，而是解决：

> 打开 Personal Workbench 后，我今天应该从哪里继续？

最终首页形成：

```text
Home / 今天
├─ Continue
├─ Quick Capture
└─ Focus / Time
   ├─ Today Timeline
   └─ Today Summary
```

---

## 2. Continue

首页首屏会选择一个主要 Continue 工作项。

最低上下文：

```text
Workspace
Current Task
Next Step
Current Blocker
Note 数量
Issue 数量
Resource 数量
Decision 数量
```

Continue 直接复用 Phase 2 的 `TaskContextService`，不在 Home 内重复查询 Note / Issue / Resource / Decision。

当前选择规则保持确定性：

```text
1. 活动工作区
2. 存在 Current Task
3. 最近活动 / 更新时间优先
```

点击“继续”进入对应 Workspace Overview。

已实际验证：

```text
Workspace: test
Current Task: 12323213
Next Step: 3123123
Note: 0
Issue: 0
Resource: 1
Decision: 1
```

---

## 3. Quick Capture

首页提供轻量“快速记录”。

Phase 3 正式支持：

```text
保存为笔记
保存为任务
```

默认目标工作区为当前 Continue 所属 Workspace。

如果没有 Continue Workspace，则在保存时选择 Workspace。

### 保存为笔记

- 直接创建 Markdown Note
- 如果目标 Workspace 存在 Current Task，则自动关联当前任务
- 不新增 quick_captures 中间表

### 保存为任务

- 直接创建 Task
- 如果目标 Workspace 没有 Current Task，则新任务可以成为 Current Task
- 如果已有 Current Task，则不抢占当前任务

Phase 3 不做：

```text
AI 自动分类
自动语义解析
复杂 Inbox 工作流
```

---

## 4. Focus Session

Phase 3 新增 `focus_sessions` 持久化。

核心字段：

```text
id
workspace_id
task_id
started_at
ended_at
duration_seconds
note
created_at
```

支持：

```text
开始专注
结束专注
结束时填写本次记录
```

约束：

```text
全局同一时间只允许一个进行中的 Focus Session
```

Session 写入 SQLite，因此应用关闭 / 重启后，未结束 Session 仍可恢复识别。

Phase 3 暂不实现复杂暂停 / 恢复状态机。

---

## 5. Today Timeline

首页专注区域展示当天 Focus Session 时间线。

格式示例：

```text
15:57 - 15:57  test / 12323213  6秒
```

初期只展示 Focus Session，不混入所有 Activity Event。

已实际验证：

```text
开始专注
→ 计时
→ 结束
→ duration 写入 SQLite
→ 今日时间线生成
```

---

## 6. Today Summary

首页专注区域提供三个轻量摘要：

```text
今日专注时长
涉及工作区数量
完成 Focus Session 数量
```

已实际验证：

```text
今日专注：6秒
工作区：1
完成专注：1
```

Phase 3 不做：

```text
周报
月报
趋势图
工时报表
复杂 BI
```

---

## 7. Application 层基线

Phase 3 新增主要服务：

```text
ContinueService
QuickCaptureService
FocusSessionService
TodayService
```

依赖关系：

```text
ContinueService
  ↓
TaskContextService
```

时间链路：

```text
FocusSessionService
  ↓
TodayService
  ↓
Home
```

---

## 8. 数据库基线

Phase 3 schemaVersion：

```text
3
```

迁移：

```text
2 → 3
```

新增主要表：

```text
focus_sessions
```

Quick Capture 直接落现有 Task / Note，因此没有新增 `quick_captures` 表。

迁移不删除 Phase 1 / Phase 2 已有数据库数据。

---

## 9. 首页结构基线

首页现在不是传统 Dashboard，而是动作入口：

```text
今天

继续工作
  Workspace
  Current Task
  Next Step
  Context Count
  [继续]

快速记录
  [输入]
  [保存为笔记] [保存为任务]

专注
  今日专注
  工作区数量
  完成专注数量
  [开始专注 / 结束专注]

  今日时间线
```

设计原则：

- 全中文
- 首页优先回答“现在做什么”
- 不重复 Workspace Overview
- 不堆大量统计卡片
- 时间能力服务于个人工作恢复，不做工时系统

---

## 10. 已实际验证的关键链路

### Continue

```text
启动应用
→ 首页识别最近有效 Workspace / Current Task
→ 展示 Next Step 与上下文数量
→ 点击继续进入 Workspace Overview
```

### Quick Capture

```text
首页输入一句话
→ 保存为 Note 或 Task
→ 直接落现有领域对象
```

### Focus / Time

```text
Current Task
→ 开始专注
→ 持续计时
→ 结束专注
→ SQLite 保存 duration
→ Today Timeline
→ Today Summary
```

### 实际验收数据

```text
Workspace: test
Task: 12323213
Focus Duration: 6秒
Workspace Count: 1
Completed Sessions: 1
```

---

## 11. Phase 3 明确不做

本阶段不扩展：

```text
复杂 Focus 暂停状态机
周 / 月时间报表
复杂优先级推荐
Knowledge
Global Search
AI 自动整理
AI 自动分类
Cloud Sync
多人协作
```

---

## 12. Phase 3 封版状态

```text
[✓] Schema v3 Migration
[✓] Continue
[✓] Home
[✓] Quick Capture
[✓] Focus Session
[✓] Today Timeline
[✓] Today Summary
[✓] Windows 实际回归
```

Phase 3 作为后续开发基线，不再向本阶段继续追加新功能。
