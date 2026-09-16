# Personal Workbench Phase 5 Acceptance — AI Context + Global AI

> 状态：**Phase 5 Windows 本地验收完成**。Global AI、四种 Scope、Context 手工管理、Preview Provider、多轮会话、历史会话、重启持久化、Workbench UI 与 Phase 1–4 回归均已完成。DeepSeek Real Provider 已实现，但真实凭据与网络调用按计划后补验证。

## 1. 最终结论

Phase 5 V1 已完成并达到本地封版条件。

```text
[✓] Global App Shell / Home / Workspace / Knowledge UI
[✓] Workspace Overview / Task / Note / Issue / Resource / Decision
[✓] Topbar Current Context / 响应式 Search
[✓] Global AI Drawer
[✓] Task / Workspace / Knowledge / Global 四种 Scope
[✓] Task Scope 自动继承 Current Task
[✓] Context Preview / Priority / 字符数
[✓] Context 排除 / 恢复 / 搜索 / 手工添加
[✓] Preview Provider 单轮与多轮发送
[✓] AI Thread / Message 持久化
[✓] 历史会话重新打开
[✓] 完整关闭应用后重启恢复
[✓] Thread Scope / Task Anchor 重启恢复
[✓] schema v5 重启可再次打开
[✓] Phase 1–4 回归未发现数据丢失
[✓] flutter analyze 未发现 Phase 5 编译 error
```

`flutter analyze` 最终返回 130 个既有静态检查项，终端未出现 `error`；当前可见问题为 info / warning，例如旧代码命名、unused import、deprecated API 等，不作为 Phase 5 编译阻塞项。

---

## 2. AI Context Builder

四种 Scope 已验证：

- [x] Task
- [x] Workspace
- [x] Knowledge
- [x] Global

Task Scope 已实际看到：

- [x] Current Task
- [x] Linked Note
- [x] Resource
- [x] Decision
- [x] Recent Activity

Blocker / Knowledge 是否出现取决于当前 Task 是否存在对应真实关联数据，不作为无数据样例的阻塞条件。

实现约束：

- [x] Task Scope 复用 `TaskContextService`
- [x] AIContextBuilder 不依赖 UI State
- [x] Global Scope 不默认扫描全部本地数据
- [x] Global Scope 使用 SearchService 获取小规模相关上下文

---

## 3. Context Budget

当前确定性预算：

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

验收：

- [x] P0-P4 优先级可展示
- [x] 字符预算生效
- [x] 条数预算生效
- [x] Current Task 作为核心 P0 Context

极端超预算大数据样例属于后续 hardening，不阻塞 Phase 5 V1。

---

## 4. Context Preview / 手工管理

基础预览已验证：

- [x] Scope
- [x] Anchor
- [x] Included Context
- [x] Priority
- [x] 字符数量

实际 Windows 验收记录：

```text
初始 Context：11 条
排除 Activity：11 → 10
恢复 Activity：10 → 11
搜索 testnote：返回「笔记 · testnote」
添加 testnote：11 → 12
新增项：P2
```

因此以下链路均通过：

- [x] 手工排除
- [x] 已排除列表
- [x] 恢复
- [x] 搜索上下文
- [x] 手工添加
- [x] 去重
- [x] Preview 自动重新计算

---

## 5. PromptBuilder

- [x] 与 UI 分离
- [x] 输入为 AIContext + User Message + Conversation History
- [x] 输出 System Prompt / Context Block / History / User Prompt
- [x] System Prompt 明确禁止虚构已执行操作
- [x] Preview Provider 实际经过 PromptBuilder 链路

---

## 6. Schema v5

```text
schemaVersion = 5
```

新增：

```text
ai_threads
ai_messages
```

验证：

- [x] `4 -> 5` migration 已注册
- [x] v5 migration 仅新增 AI 表及索引
- [x] 不 drop / rebuild Phase 1–4 业务表
- [x] `ai_threads` 正常写入
- [x] `ai_messages` 正常写入
- [x] 完整退出后 schema v5 可重新打开
- [x] 原 Workspace / Task / Note / Resource / Decision / Knowledge 数据仍可正常读取

当前实际数据库回归未发现数据丢失。

---

## 7. AI Thread / Message

Thread：

- [x] 新建会话
- [x] Scope 保存
- [x] Workspace / Task / Knowledge Anchor 保存
- [x] 首条 User Message 自动形成 Thread title
- [x] 历史入口可用
- [x] 历史 Thread 可重新打开

Message：

- [x] User Message 保存
- [x] Assistant Message 保存
- [x] 多轮消息追加
- [x] 多轮顺序恢复
- [x] 完整关闭 App 后仍存在

实际验收中，同一个 Task Thread 完成两轮 Preview Provider 对话；重启后通过历史会话重新打开，用户确认两轮用户消息、两轮 AI 回复及 Task Anchor 均正常。

---

## 8. Context Snapshot

Assistant Message 保存：

```text
context_snapshot_json
```

实现路径：

```text
AIConversationService.addAssistantMessage
→ jsonEncode(context.referenceSnapshot())
→ AIMessageModel.contextSnapshotJson
→ SqliteAIMessageRepository.insert
→ ai_messages.context_snapshot_json
```

Snapshot 仅保存引用信息：

```text
scope
workspace_id（适用时）
anchor reference
included entity refs
```

验收 / 实现核验：

- [x] Assistant Message 写入 snapshot
- [x] 包含 Scope
- [x] 包含 Workspace / Anchor（适用时）
- [x] 包含 Included Entity Refs
- [x] 不复制 Note / Knowledge Markdown 正文
- [x] Repository 读取时恢复 `context_snapshot_json`

---

## 9. Global AI Drawer

已验证：

- [x] 打开 / 关闭
- [x] Preview Provider 状态
- [x] 四种 Scope Selector
- [x] Workspace Selector
- [x] Task Selector
- [x] Knowledge Selector
- [x] Global Scope Preview
- [x] Context Preview
- [x] Context 管理
- [x] Message Input
- [x] 新建会话
- [x] 历史会话
- [x] Home 自动继承 Current Task
- [x] Workspace 优先继承对应 Current Task

UI 已统一到当前 Workbench Palette / Card / Tag / Typography 体系。

---

## 10. Preview Provider

未配置真实 AI 参数时：

- [x] App 正常启动
- [x] 显示 `Preview`
- [x] 不调用真实模型
- [x] 用户问题进入 Provider
- [x] Workbench Context 进入 PromptBuilder
- [x] Assistant 回复展示
- [x] 回复持久化
- [x] 多轮对话可用

实际发送包括：

```text
帮我总结一下当前任务做到哪里了，下一步应该做什么？
我应该做什么呢
```

均收到 Preview Provider 回复。

---

## 11. Real AI Provider / DeepSeek

实现状态：

- [x] `AIProvider` 抽象
- [x] `OpenAICompatibleAIProvider`
- [x] Provider 与 UI 解耦
- [x] API Key 不写死源码
- [x] API Key 不写 Workbench SQLite
- [x] Runtime environment variables
- [x] `--dart-define`
- [x] 自定义 Authorization Header / Prefix
- [x] Extra Headers
- [x] Timeout
- [x] HTTP / JSON / empty response 错误处理

DeepSeek：

- [x] `https://api.deepseek.com` 自动识别
- [x] 官方地址默认 `/chat/completions`
- [x] 其他 OpenAI-compatible 服务默认 `/v1/chat/completions`
- [x] `WORKBENCH_AI_CHAT_PATH` 可覆盖

当前状态：

```text
Implemented / Pending External Credential Validation
```

后续补充 DeepSeek 参数后单独验证：

```text
Base URL + Model + API Key
Real Provider 状态
真实 DeepSeek 回复
多轮真实模型对话
错误 Key / 网络失败体验
```

此项不阻塞 Phase 5 本地 V1 封版，但不得表述为真实模型端到端验收已完成。

---

## 12. Workbench UI / Windows Smoke

已完成：

- [x] Global App Shell
- [x] Sidebar 分组
- [x] Topbar Current Context
- [x] Topbar 响应式 Search
- [x] Home
- [x] Workspace List
- [x] Workspace Frame / 二级导航
- [x] Workspace Overview 桌面双列
- [x] Task
- [x] Note 双栏
- [x] Issue
- [x] Resource
- [x] Decision
- [x] Knowledge
- [x] AI Drawer Overlay
- [x] 窗口布局 smoke
- [x] Drawer / 页面滚动 smoke

---

## 13. Phase 1–4 Regression

Phase 5 完成后确认原有核心功能与数据可继续使用：

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

重启后原有 Workbench 数据仍存在，未发现 Phase 5 schema / UI 改造导致的业务数据回归。

---

## 14. Flutter Analyze

最终执行：

```powershell
flutter analyze
```

结果：

```text
130 issues found
```

终端未显示 `error`。当前可见项为项目既有的 info / warning，包括命名规范、unused import、deprecated API、BuildContext async gap 等。

Phase 5 验收标准为：

```text
无 Phase 5 新增编译 error
```

该标准已满足。

---

## 15. Phase 5 封版结果

```text
[✓] AI Context Contract
[✓] AIContextBuilder
[✓] Context Budget
[✓] Context Preview
[✓] PromptBuilder
[✓] Schema v5
[✓] AI Thread / Message
[✓] Context Snapshot
[✓] Preview Provider
[✓] OpenAI-compatible Provider
[✓] DeepSeek 接入能力实现
[✓] Global AI Drawer
[✓] Workbench 全局 UI 收口
[✓] 四种 AI Scope
[✓] Context include / exclude
[✓] 多轮持久化
[✓] 历史会话
[✓] Windows Restart Recovery
[✓] Phase 1–4 Regression
[✓] flutter analyze 无 Phase 5 编译 error
```

Phase 5 Windows 本地 V1 验收完成。

唯一明确待补的外部验证：

```text
DeepSeek Real Provider
Implemented / Pending External Credential Validation
```
