# Personal Workbench 产品定位与边界

## 1. 产品定位

Personal Workbench 是一个本地优先的个人工作上下文系统。

核心问题不是“记录多少任务”，而是：

> 用户离开一段时间后重新进入工作时，能否在几秒内知道当前任务、下一步、阻塞、相关资料和最近上下文。

核心关系：

~~~text
Workspace
  ↓
Current Task
  ├─ Note
  ├─ Issue
  ├─ Resource
  ├─ Decision
  ├─ Knowledge
  └─ Developer Context
~~~

## 2. 产品目标

### 2.1 恢复工作上下文

Home / Continue 提供：

- 当前任务
- 下一步
- 阻塞
- 进度
- 最近上下文
- 最近动态

### 2.2 沉淀工作过程

Workspace 中的 Task / Note / Issue / Resource / Decision 可以形成可复用 Knowledge。

### 2.3 提供统一检索

跨以下实体统一搜索：

- Task
- Note
- Issue
- Resource
- Decision
- Knowledge
- Developer Project
- Developer Command
- Developer Snippet

### 2.4 AI 只作为上下文增强

AI 的目标是：

- 读取当前任务/工作区/知识上下文
- 控制上下文预算
- 构建 Prompt
- 请求 OpenAI-compatible Provider
- 保存会话历史

AI 不是自动执行本地命令的 Agent。

## 3. 一级导航

~~~text
首页
工作区
时间
知识

工作台
开发者
工具

设置
~~~

## 4. Workspace 二级导航

~~~text
概览
任务
笔记
问题
资源
决策
开发
~~~

## 5. 当前产品边界

### V1 包含

- Windows Desktop
- Local-first
- SQLite + Markdown
- Workspace Context
- Knowledge + Search
- AI Context
- Developer Context
- Backup / Export / Restore
- Local productivity tools

### V1 不包含

- Cloud Sync
- 多设备实时同步
- 多人协作
- 账号体系
- CRDT
- 自动 Git 操作
- 自动 Shell / PowerShell / Bash
- 自动 Docker / Test
- 自动修改代码
- MCP Tool Runtime
- 完整 IDE
- 完整 Calendar / Reminder 平台

## 6. 设计原则

- 少说明文字，页面以内容和操作为主。
- 不重复显示用户已经知道的上下文。
- 优先恢复上下文，而不是展示统计。
- 本地数据默认可迁移、可备份、可恢复。
- AI 不绕过 Context Builder / Budget / Prompt Builder。
- Developer 功能默认 Copy-only，不自动执行。
