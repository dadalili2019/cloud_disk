# Personal Workbench Phase 5 Scope — AI Context + Global AI

> Phase 4 已将原路线中的 Knowledge + Search 合并完成，因此从本阶段开始，原 Roadmap 的“Phase 6 — AI”前移为当前 **Phase 5**。

## 1. 阶段目标

Phase 5 不把 Personal Workbench 做成通用聊天工具，也不先追求 Agent / Tool Calling。

本阶段只解决一个核心问题：

> **让 AI 在用户提问时，准确拿到 Personal Workbench 已经保存的 Work Context，并且让用户知道 AI 当时看到了什么。**

核心链路：

```text
User Message
    ↓
Scope
    ↓
AIContextBuilder
    ↓
Context Budget
    ↓
PromptBuilder
    ↓
LLM Provider
    ↓
AI Response
    ↓
AIThread / AIMessage
```

必须遵守：

```text
先稳定 Context Builder
再接真实模型
```

---

## 2. 为什么现在进入 AI

Phase 1–4 已经具备 AI 所需的基础上下文：

```text
Workspace
  ↓
Current Task
  ├─ Note
  ├─ Issue
  ├─ Resource
  ├─ Decision
  └─ Knowledge
```

同时已经具备：

```text
TaskContextService
Entity Link
Knowledge
Global Search
Markdown Store
Activity
```

因此 Phase 5 不应该让 AI 自己到处查询数据库，而是建立统一的 AI Context 层。

---

## 3. AI Scope

V1 固定支持 4 种 Scope：

```text
task
workspace
knowledge
global
```

### task

默认围绕一个 Current Task：

```text
Task
Next Step
Active Issue / Blocker
Linked Notes
Resources
Decisions
Knowledge
Recent Activity
```

优先复用现有 `TaskContextService`。

### workspace

围绕一个 Workspace：

```text
Workspace
Current Task
Recent Tasks
Recent Notes
Active Issues
Resources
Recent Decisions
Relevant Knowledge
Recent Activity
```

不能默认把整个 Workspace 的全部历史内容塞进模型。

### knowledge

围绕一条 Knowledge：

```text
Knowledge metadata
Knowledge Markdown
Source Context
Relevant Work Context
```

### global

不绑定单一 Workspace。

V1 只允许使用：

```text
用户明确包含的实体
SearchService 检索到的少量相关实体
必要的全局 Knowledge
```

禁止默认扫描并发送所有本地数据。

---

## 4. AIContextBuilder

新增：

```text
AIContextBuilder
```

输入：

```text
scope
workspaceId?
taskId?
knowledgeId?
manuallyIncludedEntities[]
manuallyExcludedEntities[]
```

输出：

```text
AIContext
```

建议模型：

```text
AIContext
├─ scope
├─ anchor
├─ task
├─ nextStep
├─ blockers[]
├─ notes[]
├─ resources[]
├─ decisions[]
├─ knowledge[]
├─ recentActivity[]
└─ contextRefs[]
```

`AIContextBuilder` 只能通过 Application / Repository / Search Service 获取数据，不能读取 UI State。

---

## 5. Context Budget

即使是本地个人工具，也必须限制 Context。

V1 使用确定性优先级：

```text
P0 Current Task
P0 Next Step
P0 Active Blocker

P1 Recent / Linked Note
P1 Decision

P2 Resource metadata

P3 Knowledge
P4 Historical Activity
```

超出预算时优先丢弃：

```text
旧 Note
低相关 Knowledge
历史 Activity
```

Phase 5 第一版不做复杂 token optimization / embedding rerank。

先使用：

```text
字符预算 + 条数预算 + 固定优先级
```

让行为可预测、可测试。

---

## 6. Context Preview

在接真实 LLM 之前，必须提供 Context Preview。

用户至少可以看到：

```text
Scope
Anchor Workspace / Task / Knowledge
Included Context
Excluded Context
```

示例：

```text
Current Task · 12323213
Note · testnote
Resource · PostgreSQL
Decision · 123
Knowledge · Workflow / 12323213
```

目的：

1. 验证 Context Builder 是否正确。
2. 用户可以知道哪些本地数据将被发送给模型。
3. 为后续手工 include / exclude 提供基础。

---

## 7. PromptBuilder

新增：

```text
PromptBuilder
```

UI 禁止自己拼 Prompt。

输入：

```text
AIContext
userMessage
conversationHistory
```

输出：

```text
System Prompt
Context Block
Conversation History
User Prompt
```

职责边界：

```text
AIContextBuilder = 决定给 AI 什么资料
PromptBuilder    = 决定这些资料如何表达给模型
AIService        = 负责一次 AI 请求流程
```

---

## 8. AI Thread / Message

Phase 5 增加持久化会话。

### ai_threads

建议字段：

```text
id
scope
workspace_id nullable
task_id nullable
knowledge_id nullable
title
created_at
updated_at
archived_at nullable
```

约束：

```text
scope = task      → task_id 必须存在
scope = workspace → workspace_id 必须存在
scope = knowledge → knowledge_id 必须存在
scope = global    → anchor id 可以为空
```

同一 Workspace / Task 可以存在多个 AI Thread。

### ai_messages

建议字段：

```text
id
thread_id
role
content
context_snapshot_json
created_at
```

role：

```text
user
assistant
system（仅需要时）
```

---

## 9. Context Snapshot

AI Message 不永久复制整套 Note / Knowledge 正文。

保存：

```text
context_snapshot_json
```

内容是“引用快照”，例如：

```json
{
  "scope": "task",
  "workspace_id": "workspace-id",
  "task_id": "task-id",
  "entities": [
    {"type": "task", "id": "task-id"},
    {"type": "note", "id": "note-id"},
    {"type": "issue", "id": "issue-id"},
    {"type": "knowledge", "id": "knowledge-id"}
  ]
}
```

目的：

> 回看一条历史 AI 回复时，知道当时 AI 使用了哪些实体。

不把完整 Context 复制一份进数据库。

---

## 10. Global AI Drawer

Phase 5 使用一个全局 AI 抽屉，不为 Task / Workspace / Knowledge 分别做三套聊天页面。

入口建议：

```text
App Shell
└─ Global AI
```

抽屉结构：

```text
AI
├─ Scope Selector
├─ Anchor
├─ Context Preview
├─ Thread Messages
└─ Message Input
```

Scope 可以从当前页面自动给默认值，但 UI 最终只向 Application 层传：

```text
scope
message
anchor ids
includedContextIds
excludedContextIds
```

---

## 11. 模型调用层

新增抽象：

```text
AIProvider
```

例如：

```text
AIService
  ↓
AIProvider
```

Phase 5 不让页面直接调用 HTTP / SDK。

`AIProvider` 后面可以接：

```text
OpenAI-compatible API
公司内部 Gateway
其他兼容模型
```

具体 endpoint / api key / model 不写死在业务代码中。

真实 Provider 只在 Context Preview 与 PromptBuilder 验证稳定以后接入。

---

## 12. Phase 5 开发顺序

### P5.1 Context Contract

```text
AIContext
AIContextRef
AIContextRequest
```

### P5.2 AIContextBuilder

先实现：

```text
task scope
```

验证通过后再实现：

```text
workspace
knowledge
global
```

### P5.3 Context Budget + Preview

```text
priority
limit
included refs
excluded refs
```

### P5.4 PromptBuilder

建立统一 Prompt 结构。

### P5.5 Persistence

Schema v5：

```text
ai_threads
ai_messages
```

### P5.6 Global AI Drawer

先使用 Fake / Preview Provider 验证完整 UI 流程。

### P5.7 Real AI Provider

Context Builder 稳定后再接真实模型。

### P5.8 Windows Acceptance

验证：

```text
Context 正确
Scope 正确
历史会话恢复
Context Snapshot 正确
模型异常有提示
Phase 1–4 无回归
```

---

## 13. Phase 5 明确不做

本阶段不做：

```text
Agent Tool Calling
自动执行本地命令
自动修改 Task / Note / Decision
Vector DB / Embedding RAG
复杂语义 rerank
多 Agent
Workflow Engine
联网搜索 Agent
Voice
图片理解
Cloud Sync
多人共享 AI Thread
```

AI 第一阶段只做：

> **Context-aware Assistant，而不是 Autonomous Agent。**

---

## 14. Definition of Done

Phase 5 完成必须满足：

```text
[ ] AIContextBuilder 四种 scope 可用
[ ] task scope 复用 TaskContextService
[ ] Context Budget 可预测
[ ] Context Preview 可查看
[ ] Context 可以手工 include / exclude
[ ] PromptBuilder 独立于 UI
[ ] Schema v5 migration 安全
[ ] AI Thread / Message 可持久化
[ ] context_snapshot_json 可追溯
[ ] Global AI Drawer 可使用
[ ] AIProvider 与业务解耦
[ ] 模型调用失败有明确状态
[ ] Windows 重启后 Thread / Message 可恢复
[ ] Phase 1–4 smoke regression 通过
```

完成后创建：

```text
PHASE5_ACCEPTANCE.md
PHASE5_BASELINE.md
```
