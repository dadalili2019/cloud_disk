# Personal Workbench Phase 2 基线

## 1. 阶段结论

Phase 2 已完成，并经过实际 Windows 运行验证。

Phase 1 的最小闭环：

```text
Workspace → Task → Current Task → Note → Overview
```

在 Phase 2 扩展为完整的当前任务上下文：

```text
Workspace
└─ Current Task
   ├─ Note
   ├─ Issue
   ├─ Resource
   └─ Decision
```

本阶段完成后，一个 Workspace 已经能够回答：

```text
我现在在做什么？
下一步是什么？
我卡在哪里？
我参考了什么？
我为什么这样决定？
```

---

## 2. 已实现功能

### 2.1 Issue / 问题

- 新建问题
- 编辑问题
- 状态：待处理 / 调查中 / 已解决 / 已归档
- 严重程度：低 / 中 / 高 / 严重
- 影响
- 当前假设
- 下一步调查
- 解决说明
- 创建时可自动关联当前任务
- 历史问题可手动关联当前任务
- 关系：`Issue --blocks--> Task`
- 未解决且关联 Current Task 的 Issue 显示在概览“当前阻塞”
- Issue 解决后自动退出“当前阻塞”
- 解决后历史关联关系仍然保留

### 2.2 Resource / 资源

- 新建资源
- 编辑资源
- 类型：代码仓库 / 本地路径 / 文档 / 服务地址 / 链接 / 设计资料 / 命令 / 其他
- 地址 / 路径 / 命令
- 说明
- 置顶
- 创建时可自动关联当前任务
- 历史资源可手动关联当前任务
- 关系：`Resource --supports--> Task`
- Current Task 相关 Resource 在概览“相关资源”展示

### 2.3 Decision / 决策

- 新建决策
- 编辑决策
- 决策名称
- 决定做什么
- 为什么这样决定
- 重新评估条件
- 状态：生效中 / 已替代 / 已归档
- 创建时可自动关联当前任务
- 历史决策可手动关联当前任务
- 关系：`Decision --applies_to--> Task`
- Current Task 相关 Decision 在概览“最近决策”展示

### 2.4 TaskContextService

Phase 2 增加统一任务上下文聚合层：

```text
TaskContext
├─ task
├─ notes[]
├─ issues[]
├─ resources[]
├─ decisions[]
└─ recentActivity[]
```

Overview 不再分别拼装 Note / Issue / Resource / Decision 的 Entity Link 查询。

后续 Home / Continue / AI 等能力应优先复用 `TaskContextService`，避免形成多套上下文查询逻辑。

### 2.5 Overview Phase 2

概览已包含：

```text
当前任务
下一步
当前阻塞
关联笔记
相关资源
最近决策
最近动态
```

“当前阻塞”只展示 Current Task 的未解决 Issue。

“关联笔记 / 相关资源 / 最近决策”均基于 Current Task Context 聚合。

### 2.6 Workspace Settings

工作区概览右上角提供“工作区设置”。

当前支持：

- 修改工作区名称
- 查看目录标识 slug
- slug 保持只读
- 归档工作区
- 查看已归档工作区
- 恢复已归档工作区

当前阶段不允许直接修改 slug，原因是 slug 与 Markdown 工作区目录绑定，修改会涉及文件目录迁移。

### 2.7 Archive / Restore

工作区归档采用软归档：

```text
status = archived
archived_at = timestamp
```

归档不会删除：

```text
Task
Note
Issue
Resource
Decision
Entity Link
Activity
Markdown 文件
```

归档后：

- 从活动工作区列表隐藏
- 即使没有任何活动工作区，工作区列表仍保留“已归档工作区”全局入口
- 可以恢复归档工作区
- 恢复后原任务上下文与数据继续存在

---

## 3. 数据库基线

Phase 2 schemaVersion：

```text
2
```

Phase 1 → Phase 2 使用 migration 升级，不删除已有 `workbench.db`。

新增主要表：

```text
issues
resources
decisions
```

继续复用：

```text
workspaces
tasks
notes
entity_links
activity_events
```

---

## 4. Entity Link 基线

当前正式使用的关系：

```text
Note     linked_to   Task
Issue    blocks      Task
Resource supports    Task
Decision applies_to  Task
```

关系持久化在 `entity_links`。

页面层不直接维护关系表，关系通过 Application / Service 层创建和读取。

---

## 5. 页面结构基线

Workspace 内部顶部导航：

```text
概览 | 任务 | 笔记 | 问题 | 资源 | 决策
```

工作区设置不占用顶部业务 Tab，入口位于概览右上角。

界面原则：

- 面向用户的 Workbench UI 统一中文
- 保持桌面端紧凑布局
- 不加入大段说明文字
- 不做传统重型项目管理 Dashboard

---

## 6. 已实际验证的关键链路

### Issue 生命周期

```text
创建 Current Task
  ↓
创建 / 关联 Issue
  ↓
Overview 当前阻塞出现
  ↓
Issue 改为已解决
  ↓
Overview 当前阻塞消失
  ↓
历史关系保留
```

### Resource 生命周期

```text
创建 Resource
  ↓
关联 Current Task
  ↓
资源页显示关联任务
  ↓
Overview 相关资源出现
```

### Decision 生命周期

```text
创建 Decision
  ↓
关联 Current Task
  ↓
决策页显示关联任务
  ↓
Overview 最近决策出现
```

### Workspace Archive 生命周期

```text
活动工作区
  ↓
归档
  ↓
活动列表隐藏
  ↓
已归档工作区全局入口
  ↓
恢复
  ↓
重新回到活动列表
  ↓
任务 / 资源 / 决策等原上下文仍然存在
```

### TaskContext 回归

`TaskContextService` 接管聚合后，Overview 的 Current Task、Issue、Resource、Decision、Activity 均保持正常。

---

## 7. Phase 2 明确不做

本阶段没有扩展：

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
Cloud Sync
多人协作
复杂 Kanban
复杂 Calendar
```

这些继续按后续阶段推进。

---

## 8. Phase 2 封版状态

```text
[✓] Schema v2 Migration
[✓] Issue
[✓] Resource
[✓] Decision
[✓] TaskContextService
[✓] Overview Phase 2
[✓] Workspace Settings
[✓] Archive / Restore
[✓] 实际 Windows 回归
```

Phase 2 作为后续开发基线，不再继续向该阶段追加新功能。
