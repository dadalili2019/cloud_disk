# Personal Workbench Phase 1 基线

## 1. 阶段结论

Phase 1 已完成并通过实际 Windows 运行回归。

本阶段建立 Personal Workbench 的最小可用闭环：

```text
工作区
  ↓
任务
  ↓
当前任务
  ↓
Markdown 笔记
  ↓
任务与笔记关联
  ↓
概览聚合
  ↓
关闭程序 / 重新启动
  ↓
数据完整恢复
```

## 2. 已实现功能

### 2.1 工作区

- 创建工作区
- 工作区列表
- 切换工作区
- 工作区独立目录
- 工作区创建动态记录

### 2.2 任务

- 新建任务
- 编辑任务
- 任务名称
- 状态：待办 / 进行中 / 已完成
- 进度：0–100%
- 下一步
- 当前任务
- 一个工作区最多一个当前任务
- 第一条任务可自动成为当前任务
- 设为当前任务时，待办任务自动进入进行中
- 已完成任务进度固定为 100%
- 已完成任务自动退出当前任务
- 已完成任务不可重新设为当前任务

### 2.3 笔记

- 新建 Markdown 笔记
- 笔记列表
- Markdown 正文编辑
- 650ms debounce 自动保存
- 切换笔记前强制保存
- 退出页面时保存未落盘内容
- 自定义 .md 文件名
- 保存状态展示

### 2.4 任务与笔记关系

- 创建笔记时默认关联当前任务
- 使用 entity_links 持久化关系
- 当前任务完成后，历史关联仍保留
- 笔记页面可看到“关联任务”
- 概览页可查看当前任务关联笔记

### 2.5 工作区概览

- 当前任务
- 当前进度
- 下一步
- 当前任务关联笔记
- 最近动态
- 当前任务完成后显示“暂无当前任务”

### 2.6 最近动态

当前已记录：

- 创建工作区
- 新建任务
- 设为当前任务
- 更新任务
- 完成任务
- 新建笔记

## 3. UI 约束

Personal Workbench 新增界面统一使用中文。

页面保持信息精简，不增加大段功能解释文字。

当前工作区内导航：

```text
概览 | 任务 | 笔记
```

## 4. 数据与存储

### 4.1 SQLite

Workbench 使用独立数据库：

```text
PersonalWorkbench/data/workbench.db
```

旧功能继续使用原有 DBHelper / my_database.db，不进行替换。

### 4.2 Markdown 文件

笔记正文真实保存为 Markdown 文件：

```text
PersonalWorkbench/
└─ workspaces/
   └─ <workspace-slug>/
      └─ notes/
         └─ *.md
```

SQLite 仅保存笔记元数据与相对路径。

### 4.3 核心表

Phase 1 使用：

- workspaces
- tasks
- notes
- entity_links
- activity_events

## 5. 技术结构

```text
presentation/
  页面与交互
      ↓
application/
  WorkspaceService
  TaskService
  NoteService
  EntityLinkService
  WorkspaceOverviewService
      ↓
domain/
  Repository interfaces
      ↓
data/
  SQLite repositories
  Markdown store
      ↓
core/
  Workbench database
  App paths
  Models
  Utils
```

Workbench Runtime 使用懒初始化，仅进入工作台后初始化 Workbench 存储，不影响旧功能首屏启动。

## 6. 已验证场景

实际 Windows 运行已验证：

1. 应用可正常启动
2. Workbench 数据库可初始化
3. 创建工作区成功
4. 创建任务成功
5. 设置当前任务成功
6. 概览正确读取当前任务
7. 创建 Markdown 笔记成功
8. 笔记自动关联当前任务
9. 概览正确读取关联笔记
10. 编辑任务状态 / 进度 / 下一步成功
11. 完成任务自动退出当前任务
12. 笔记与已完成任务关系仍保留
13. 完全关闭应用并重新运行后数据恢复正常

## 7. Phase 1 不包含

以下能力不属于 Phase 1：

- AI 自动整理
- 全局搜索
- Today / 今日聚合
- Quick Capture / 快速收集
- Blocker
- Issue / Resource / Decision 等扩展实体
- Knowledge 系统
- Developer Tools 深度整合
- Cloud Sync
- 多设备同步
- 复杂任务看板
- 复杂标签系统

这些内容在后续 Phase 单独设计和实现。
