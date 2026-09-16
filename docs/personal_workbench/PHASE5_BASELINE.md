# Personal Workbench Phase 5 基线

## 1. 阶段结论

Phase 5 已完成 Windows 本地 V1 验收，并形成新的 Personal Workbench 基线。

本阶段的核心目标是把 Personal Workbench 从：

```text
工作对象管理
+
Knowledge / Search
```

推进到：

> AI 能围绕真实 Workbench Context 工作，并且所有 AI 对话、上下文引用和会话历史保持本地可恢复。

最终形成：

```text
Workbench Context
      ↓
AIContextBuilder
      ↓
Context Budget
      ↓
PromptBuilder
      ↓
AI Provider
      ↓
AI Thread / Message
      ↓
Context Snapshot
```

同时完成整个 Workbench Windows UI 的统一收口。

---

## 2. AI Context Scope 基线

Phase 5 V1 固定四种 Scope：

```text
Task
Workspace
Knowledge
Global
```

职责：

### Task

围绕当前任务组织上下文。

包含：

```text
Current Task
Next Step
Active Issue / Blocker
Linked Note
Resource
Decision
Knowledge
Recent Activity
```

Task Scope 复用 `TaskContextService`，不重新发明 Task Context 关系层。

### Workspace

围绕一个 Workspace 组织少量工作上下文：

```text
Workspace
Current Task
Recent Tasks
Recent Notes
Recent Issues
Recent Resources
Recent Decisions
Recent Knowledge
Recent Activity
```

不默认加载整个 Workspace 历史。

### Knowledge

围绕一条 Knowledge 组织：

```text
Knowledge Metadata
Knowledge Markdown
Source Context
Relevant Work Context
```

### Global

不默认扫描全部本地数据。

策略：

```text
User Query
→ SearchService
→ 少量相关实体
→ AI Context
```

---

## 3. AI Context Contract

核心模型位于：

```text
lib/workbench/core/ai_context_models.dart
```

主要对象：

```text
AIContextScope
AIContextRef
AIContextRequest
AIContextItem
AIContextModel
AIContextPreviewItem
AIContextPreviewModel
```

`AIContextRequest` 支持：

```text
scope
query
workspaceId
taskId
knowledgeId
manuallyIncludedEntities
manuallyExcludedEntities
```

原则：

```text
UI 只描述“我要什么上下文”
AIContextBuilder 决定“实际给 AI 什么”
```

---

## 4. AIContextBuilder 基线

实现：

```text
lib/workbench/application/ai_context_builder.dart
```

依赖：

```text
WorkspaceRepository
TaskRepository
NoteRepository
IssueRepository
ResourceRepository
DecisionRepository
KnowledgeRepository
ActivityRepository
MarkdownStore
TaskContextService
KnowledgeService
SearchService
```

关键约束：

```text
AIContextBuilder 不访问 UI State
AIContextBuilder 不从页面 Widget 读取数据
Global Scope 不做全库扫描
Note / Knowledge Markdown 只有需要时才读取
manual exclude 优先于 include
Context entity 去重
```

---

## 5. Context Budget 基线

实现：

```text
lib/workbench/application/ai_context_budget.dart
```

默认预算：

```text
maxItems = 24
maxCharacters = 18000
```

优先级：

```text
P0 Current Task / Active Blocker
P1 Note / Decision
P2 Resource / Manual Context
P3 Knowledge
P4 Activity
```

裁剪原则：

```text
优先保留高优先级实体
超预算时优先移除低优先级内容
Current Task 不应因为普通低优先级内容被挤掉
```

当前 Windows 验收已确认 Task Context 中 P0-P4 可正确展示。

---

## 6. Context Preview 基线

实现：

```text
lib/workbench/application/ai_context_preview_service.dart
```

Global AI Drawer 中可以看到：

```text
Scope
Anchor
Included Context
Priority
Context Count
Character Count
Excluded Context
```

Windows 实际验收：

```text
初始 Context：11 条
排除 Activity：11 → 10
恢复 Activity：10 → 11
搜索 testnote
→ 返回「笔记 · testnote」
手工添加
→ 11 → 12
新增项 Priority：P2
```

支持：

```text
手工排除
恢复
搜索上下文
手工添加
去重
Preview 自动重算
```

---

## 7. PromptBuilder 基线

实现：

```text
lib/workbench/application/ai_prompt_builder.dart
```

输入：

```text
AIContext
User Message
Conversation History
```

输出：

```text
System Prompt
Context Block
Conversation History
User Prompt
```

System Prompt 基线约束：

```text
把 Workbench Context 当作证据
不要虚构项目事实
上下文不足时明确说明
不要声称已执行未实际执行的操作
回答保持简洁、可执行
```

PromptBuilder 与 UI、Provider 解耦。

---

## 8. AI Provider 基线

接口：

```text
lib/workbench/domain/ai_provider.dart
```

Phase 5 提供两类 Provider：

```text
PreviewAIProvider
OpenAICompatibleAIProvider
```

### Preview Provider

用途：

```text
不依赖真实 API
验证 Context / Prompt / Conversation / Persistence 链路
```

Windows 已实际完成单轮和多轮发送。

### OpenAI-compatible Provider

支持：

```text
Base URL
Model
API Key
Authorization Header / Prefix
Extra Headers
Timeout
自定义 Chat Path
```

凭据不写死源码，不写入 Workbench SQLite。

---

## 9. DeepSeek 接入状态

已实现 DeepSeek 兼容逻辑：

```text
https://api.deepseek.com
→ 默认 /chat/completions
```

其他 OpenAI-compatible Provider 默认：

```text
/v1/chat/completions
```

用户可通过：

```text
WORKBENCH_AI_CHAT_PATH
```

显式覆盖。

当前状态：

```text
Implemented / Pending External Credential Validation
```

也就是说：

```text
代码能力已完成
Preview 本地链路已完成
真实 DeepSeek 凭据 / 网络调用尚未最终验收
```

后续补参数时单独验证，不重新打开 Phase 5 结构设计。

---

## 10. Schema v5 基线

数据库版本：

```text
schemaVersion = 5
```

迁移：

```text
4 → 5
```

新增：

```text
ai_threads
ai_messages
```

### ai_threads

保存：

```text
id
scope
title
workspace_id
task_id
knowledge_id
created_at
updated_at
archived_at
```

### ai_messages

保存：

```text
id
thread_id
role
content
context_snapshot_json
created_at
```

Phase 1–4 原有表不删除、不重建。

Windows 实际升级 / 重启未发现原有业务数据丢失。

---

## 11. AI Thread / Message 基线

核心模型：

```text
AIThreadModel
AIMessageModel
```

Application Service：

```text
AIConversationService
```

支持：

```text
创建 Thread
首条消息生成 Title
User Message
Assistant Message
System Message
历史会话
按 Anchor 查询
重命名
归档
```

实际验证：

```text
Task 12323213
→ 第一轮 User / Assistant
→ 第二轮 User / Assistant
→ 完全退出应用
→ 重新启动
→ 历史会话重新打开
→ 两轮消息仍存在
→ Scope / Task Anchor 正常
```

---

## 12. Context Snapshot 基线

Assistant Message 保存：

```text
context_snapshot_json
```

Snapshot 不是正文副本。

保存：

```text
scope
workspace_id（适用时）
anchor reference
included entity refs
```

不保存：

```text
完整 Note Markdown
完整 Knowledge Markdown
完整 Workspace 历史
```

目的：

> 记录“这次回答参考了哪些工作对象”，而不是复制一份业务数据。

---

## 13. Global AI Drawer 基线

AI 入口位于 Global App Shell Topbar。

行为：

```text
点击 AI
→ 右侧 Overlay Drawer
```

Drawer 不触发主页面重新布局。

已支持：

```text
四种 Scope
Workspace Selector
Task Selector
Knowledge Selector
Context Preview
Context 管理
Message Composer
History
New Thread
Preview / Real Provider 状态
Markdown AI Response
Retry / Error State
```

上下文继承：

```text
Home 打开 AI
→ 优先继承 Current Task

Workspace 打开 AI
→ 优先继承该 Workspace 的 Current Task

Workspace 无 Current Task
→ Workspace Scope
```

---

## 14. Workbench UI 基线

Phase 5 同时完成 Windows Desktop First UI 收口。

Global Shell：

```text
Sidebar
Topbar
Current Context
Responsive Search
AI Entry
Settings
Window Controls
```

一级页面：

```text
Home
Workspace List
Knowledge + Search
```

Workspace 二级 Frame：

```text
Workspace Identity
Current Task / Next Step
Workspace Settings
Switch Workspace
Overview / Task / Note / Issue / Resource / Decision
```

Overview：

```text
Current Task
Blocker | Notes
Resources | Decisions
Recent Activity
```

共享 UI：

```text
WorkbenchCard
WorkbenchTag
WorkbenchSectionHeader
WorkbenchSectionPage
ThemePalette
```

Note 保留双栏结构：

```text
Note List | Markdown Editor
```

AI Drawer 复用同一 Palette / Border / Radius / Typography token，但保持紧凑对话布局。

---

## 15. Topbar 响应式基线

Current Context 优先保留。

Search：

```text
宽窗口
→ 搜索工作上下文…

常见 Windows 宽度
→ 搜索

很窄
→ 隐藏
```

不再因为常见窗口宽度不足而直接隐藏搜索入口。

---

## 16. Phase 1–4 回归结果

Phase 5 完成后继续确认：

```text
Home
Continue / Current Task
Quick Capture
Focus
Workspace Overview
Task
Note
Issue
Resource
Decision
Knowledge
Global Search
```

原数据重启后仍存在。

Phase 5 schema / UI 改造未发现破坏 Phase 1–4 核心功能。

---

## 17. Flutter Analyze 基线

最终执行：

```powershell
flutter analyze
```

结果：

```text
130 issues found
```

终端没有 `error`。

当前主要为既有：

```text
info
warning
file_names
unused_import
avoid_print
deprecated_member_use
use_build_context_synchronously
```

Phase 5 封版标准：

```text
无 Phase 5 新增编译 error
```

已满足。

---

## 18. Phase 5 明确不做

Phase 5 V1 不引入：

```text
Agent Tool Calling
自动执行本地命令
自动修改 Task / Note / Decision
Embedding RAG
Vector Database
Semantic Rerank
Multi-Agent
Workflow Engine
Web Search Agent
Voice / Image Understanding
Cloud Sync
Shared AI Thread
```

AI 当前定位：

> Context-aware Assistant，而不是 autonomous Agent。

---

## 19. 已知后续 Hardening

后续可以独立处理，不回开 Phase 5 主范围：

```text
DeepSeek 真实凭据验收
Provider 配置 UI
API Key 安全存储方案
AIService orchestration 进一步收口
AI Provider DTO 分层优化
AI Message + Thread 更新事务化
Context Budget 极限数据测试
Knowledge category 搜索索引补强
Search Index 编辑后即时一致性
Search 精确实体定位
仓库既有 130 个 analyzer info / warning 清理
```

---

## 20. Phase 5 封版状态

```text
[✓] AI Context Contract
[✓] AIContextBuilder
[✓] Context Budget
[✓] Context Preview
[✓] Manual Context Management
[✓] PromptBuilder
[✓] Schema v5 Migration
[✓] AI Thread / Message
[✓] Context Snapshot
[✓] Preview Provider
[✓] OpenAI-compatible Provider
[✓] DeepSeek Integration Capability
[✓] Global AI Drawer
[✓] Current Task Auto Inheritance
[✓] Four AI Scopes
[✓] Multi-turn Persistence
[✓] History Recovery
[✓] Windows Restart Recovery
[✓] Workbench UI Unification
[✓] Responsive Topbar Search
[✓] Phase 1–4 Regression
[✓] No Phase 5 Compile Error
```

Phase 5 正式封版。

后续功能不得继续无边界追加到 Phase 5；新能力应进入新的阶段规划。
