# Personal Workbench 功能说明

## 1. Home

Home 用于恢复当前工作状态。

主要能力：

- 展示最主要的 Current Task
- 展示 Next Step
- 展示 Blocker
- 展示 Progress
- 展示 Last Context
- Today
- Recent Activity
- Quick Capture
- Continue

Quick Capture 支持保存为：

- Note
- Task
- Issue

创建 Task 不会自动替换 Current Task。

## 2. Workspace

### 2.1 Workspace 管理

支持：

- 创建
- 列表
- 选择
- 重命名
- 归档
- 恢复归档工作区

Workspace slug 创建后保持稳定，不因重命名自动变化。

### 2.2 Task

主要字段：

- title
- description
- status
- progress
- next_step
- priority
- is_current
- due_at

规则：

- 状态：todo / doing / done
- progress 范围 0–100
- done 时 progress 归一为 100
- done 任务自动退出 Current Task
- 同一 Workspace 最多一个 Current Task

### 2.3 Note

- Markdown 正文
- 元数据保存在 SQLite
- 正文保存在 Markdown 文件
- 支持自动保存
- 支持 Edit / Preview / Split 默认视图配置
- 可关联 Current Task
- Entity Link 保留历史关系

### 2.4 Issue

用于记录问题、风险与排查上下文。

支持：

- 新建
- 编辑
- 状态
- severity
- impact
- hypothesis
- next investigation step
- resolution
- 关联 Current Task

### 2.5 Resource

保存与 Workspace / Task 相关的资源：

- 名称
- 类型
- URI
- 描述

### 2.6 Decision

保存关键决策：

- title
- decision text
- rationale
- revisit condition
- status

### 2.7 Overview

聚合当前 Workspace 的：

- Current Task
- Blocker
- Related Notes
- Resources
- Decisions
- Recent Activity

## 3. Time / Focus

支持：

- 开始专注
- 结束专注
- 今日累计专注时间
- 今日 Session 时间线
- 今日参与 Workspace 数
- 已完成 Session 数

同一时间只允许一个 Active Focus Session。

## 4. Knowledge

### 4.1 Knowledge Library

字段：

- title
- category
- summary
- use_when
- Markdown content
- pinned
- sources

### 4.2 Knowledge Distill

来源可选：

- Task
- Note
- Issue
- Resource
- Decision

流程：

~~~text
选择 Workspace
→ 选择来源实体
→ 生成可编辑草稿
→ 用户确认标题/分类/摘要/适用场景/正文
→ 保存 Knowledge
~~~

来源关系通过 entity_links 保存 derived_from。

## 5. Search

搜索实体：

- Task
- Note
- Issue
- Resource
- Decision
- Knowledge
- Developer Project
- Developer Command
- Developer Snippet

搜索策略：

- SQLite FTS5
- BM25 排序
- LIKE substring fallback
- 支持 Workspace / Entity Type 过滤

## 6. Developer

### Project

- name
- local_path
- repository_url
- branch
- tech_stack
- notes
- primary

### Command

- name
- command
- working_directory
- category
- notes
- pinned

### Snippet

- title
- language
- content
- notes
- pinned

### Developer Resource

从 Resource 中聚合开发相关资源。

V1 只展示、保存、复制，不自动执行命令。

## 7. Global AI

支持 Scope：

- Task
- Workspace
- Knowledge
- Global

支持：

- Context Preview
- Manual Include
- Manual Exclude
- Conversation History
- Retry
- Thread Rename
- Thread Archive
- Markdown Response

Provider：

- Environment
- Preview
- DeepSeek
- OpenAI Compatible

## 8. Settings

### General

- Default Workspace
- Startup Page
- Quick Capture 关联 Current Task
- Restore Last Active Context

### Appearance

- Theme Preset
- Theme Mode
- Accent
- Font
- Reset

### Notes

- Default View
- Auto Save
- Storage Format / Folder 信息

### AI

- Provider
- Base URL
- Model
- Chat Path
- Timeout
- Session API Key
- Test Connection

### Data & Backup

- Local Data Path
- Auto Backup Frequency
- Retention
- Manual Backup
- Export
- Restore

### Shortcuts

展示已支持的快捷键入口，不提供完整全局热键管理。

## 9. Backup / Export / Restore

### Backup

面向恢复，包含：

- SQLite Snapshot
- Workspace Markdown
- Knowledge Markdown
- Attachments
- 非敏感设置
- Manifest

### Export

面向数据携带，不保证可恢复。

### Restore

只接受 Workbench Backup。

流程：

~~~text
Select Backup
→ Validate
→ Safety Backup
→ Stage Pending Restore
→ Exit App
→ Next Start Apply Restore
→ Rebuild / Resume Runtime
~~~

## 10. Tools

当前工具：

- JSON Formatter
- Text Compare
- Speed Test
- RAG Knowledge
- Image Convert
- Watermark
- Crop
- Filter
- Collage
- Dedupe
- Game
