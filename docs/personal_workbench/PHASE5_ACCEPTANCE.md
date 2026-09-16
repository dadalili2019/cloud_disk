# Personal Workbench Phase 5 Acceptance — AI Context + Global AI

> 状态：**Windows 最终验收中**。Global AI、四种 Scope、Context 手工管理、Preview Provider、多轮会话、历史会话和重启持久化均已通过。DeepSeek Real Provider 已实现，但凭据与真实网络调用按用户计划后补验证。

## 0. 当前结论

已通过 Windows 实际验证：

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
```

最后仍需完成：

```text
[ ] flutter analyze：确认无 Phase 5 新增 error
[ ] Knowledge 搜索实际关键词回归
[ ] Quick Capture 写入回归
[ ] Windows 窗口缩放 / AI Drawer 滚动 smoke
[ ] 最终 Phase 1–4 数据回归确认
```

---

## 1. AI Context Builder

四种 Scope：

- [x] Task Scope。
- [x] Workspace Scope。
- [x] Knowledge Scope。
- [x] Global Scope，通过 SearchService 获取少量相关上下文。

Task Scope 已实际看到：

- [x] Current Task。
- [x] Linked Note。
- [x] Resource。
- [x] Decision。
- [x] Recent Activity。

实现约束：

- [x] Task Scope 复用 `TaskContextService`。
- [x] AIContextBuilder 不依赖 UI State。
- [x] Global Scope 不默认扫描全部本地数据。

Blocker / Knowledge 是否出现由当前 Task 实际关联数据决定，不作为无数据样例的阻塞条件。

## 2. Context Budget

- [x] P0-P4 确定性优先级。
- [x] 字符预算。
- [x] 条数预算。
- [x] P0 Task 作为当前 Task Context 的最高优先级保留。

默认：

```text
maxItems = 24
maxCharacters = 18000
```

极限超预算裁剪属于后续大数据样例 hardening，不阻塞 Phase 5 V1。

## 3. Context Preview / 手工管理

基础预览：

- [x] Scope。
- [x] Anchor。
- [x] Included Context。
- [x] Priority。
- [x] 字符数量。

手工控制实际验收：

```text
初始 Context：11 条
排除 Activity：11 → 10
恢复 Activity：10 → 11
搜索 testnote：返回「笔记 · testnote」
添加 testnote：11 → 12
新增项：P2
```

因此：

- [x] 手工排除。
- [x] 已排除列表。
- [x] 恢复。
- [x] 搜索上下文。
- [x] 手工添加。
- [x] 去重。
- [x] Preview 自动重新计算。

## 4. PromptBuilder

- [x] 与 UI 分离。
- [x] 输入 AIContext + User Message + Conversation History。
- [x] 输出 System Prompt / Context Block / History / User Prompt。
- [x] 明确禁止虚构已执行操作。

## 5. Schema v5

```text
schemaVersion = 5
```

新增：

```text
ai_threads
ai_messages
```

实现核验：

- [x] `4 -> 5` migration 已注册。
- [x] v5 migration 仅创建 AI 新表和索引。
- [x] 不 drop / rebuild Phase 1–4 业务表。
- [x] ai_threads 正常写入。
- [x] ai_messages 正常写入。
- [x] schema v5 完整退出后可重新打开。

Windows 现有数据库升级后仍持续展示原 Workspace / Task / Note / Resource / Decision / Knowledge 数据，重启后仍正常，因此当前实际数据库回归未发现数据丢失。

## 6. AI Thread / Message

### Thread

- [x] 新对话创建 Thread。
- [x] Scope 保存。
- [x] Workspace / Task Anchor 保存。
- [x] 首条 User Message 自动生成 Thread title（实现逻辑 + 历史会话可识别）。
- [x] 历史入口可用。
- [x] 历史 Thread 可重新打开。

### Message

- [x] User Message 保存。
- [x] Assistant Message 保存。
- [x] 第二轮 User / Assistant Message 正常追加。
- [x] 多轮消息按时间顺序恢复。
- [x] 完整关闭应用后重新启动仍存在。

实际验收：同一 Task Thread 完成两轮 Preview Provider 对话；完全关闭 App、重新 `flutter run -d windows` 后，通过历史会话重新打开，用户确认两轮消息、两轮回复及 Task Anchor 均正常。

## 7. Context Snapshot

Assistant Message 保存：

```text
context_snapshot_json
```

代码路径核验：

```text
AIConversationService.addAssistantMessage
→ jsonEncode(context.referenceSnapshot())
→ AIMessageModel.contextSnapshotJson
→ SqliteAIMessageRepository.insert
→ ai_messages.context_snapshot_json
```

`referenceSnapshot()` 仅保存：

```text
scope
workspace_id（适用时）
anchor reference
included entity refs
```

因此：

- [x] Assistant Message 写入 snapshot。
- [x] 包含 Scope。
- [x] 包含 Workspace / Anchor（适用时）。
- [x] 包含 Included Entity Refs。
- [x] 不复制 Note / Knowledge Markdown 正文。
- [x] Repository 读取时恢复 `context_snapshot_json`。

## 8. Global AI Drawer

- [x] 打开 / 关闭。
- [x] Preview Provider 状态展示。
- [x] 四种 Scope Selector。
- [x] Workspace Selector。
- [x] Task Selector。
- [x] Knowledge Selector。
- [x] Global Scope Preview。
- [x] Context Preview。
- [x] Context 管理。
- [x] Message Input。
- [x] 新建会话。
- [x] 历史会话。
- [x] Home 自动继承 Current Task。
- [x] Workspace 优先继承该 Workspace Current Task。

## 9. Preview Provider

未配置真实 AI 参数时：

- [x] App 正常启动。
- [x] 显示 `Preview`。
- [x] 不调用真实模型。
- [x] 用户问题进入 Provider。
- [x] Workbench Context 进入 PromptBuilder。
- [x] Assistant 回复展示。
- [x] 回复持久化。
- [x] 多轮对话可用。

已实际发送：

```text
帮我总结一下当前任务做到哪里了，下一步应该做什么？
我应该做什么呢
```

均收到 Preview Provider 回复。

## 10. Real AI Provider / DeepSeek

实现状态：

- [x] `AIProvider` 抽象。
- [x] `OpenAICompatibleAIProvider`。
- [x] Provider 与 UI 解耦。
- [x] API Key 不写死源码。
- [x] API Key 不写 Workbench SQLite。
- [x] Runtime environment variables。
- [x] `--dart-define`。
- [x] 自定义 Authorization Header / Prefix。
- [x] Extra Headers。
- [x] Timeout。
- [x] HTTP / JSON / empty response 错误处理。

DeepSeek：

- [x] `https://api.deepseek.com` 识别。
- [x] 官方地址默认 `/chat/completions`。
- [x] 其他 OpenAI-compatible 默认 `/v1/chat/completions`。
- [x] `WORKBENCH_AI_CHAT_PATH` 可覆盖。

外部凭据验收状态：

```text
Implemented / Pending External Credential Validation
```

待用户后续补充 DeepSeek 参数后验证：

- [ ] Base URL + Model + API Key。
- [ ] Real Provider 状态。
- [ ] DeepSeek 实际回复。
- [ ] 多轮真实模型对话。
- [ ] 错误 Key / 网络失败体验。

此项不阻塞本地 Phase 5 V1 封版，但 Baseline 必须保留该限制。

## 11. Windows 重启恢复

- [x] AI Thread 存在。
- [x] AI Message 存在。
- [x] 多轮消息存在。
- [x] Thread Scope / Task Anchor 正确。
- [x] 原有 Workbench 数据仍存在。
- [x] AI Drawer 可继续使用。

## 12. Workbench UI / Windows Smoke

已通过：

- [x] Global App Shell。
- [x] Sidebar 分组。
- [x] Topbar Current Context。
- [x] Topbar 响应式 Search。
- [x] AI Drawer Overlay。
- [x] Workspace Frame / 二级导航。
- [x] Workspace Overview 桌面双列。
- [x] Task。
- [x] Note 双栏。
- [x] Issue。
- [x] Resource。
- [x] Decision。
- [x] Knowledge。

最后 smoke：

- [ ] 手工缩放 Windows 窗口，无明显 overflow / 红屏。
- [ ] AI Drawer 打开后核心页面可正常滚动。
- [ ] Dialog / Drawer 开关无明显焦点异常。

## 13. Phase 1–4 Regression

已确认页面 / 数据 smoke：

- [x] Home。
- [x] Continue / Current Task。
- [x] Quick Capture 区域加载。
- [x] Focus 区域加载。
- [x] Workspace Overview。
- [x] Task。
- [x] Note。
- [x] Issue。
- [x] Resource。
- [x] Decision。
- [x] Knowledge。

最后需要：

- [ ] Knowledge 搜索一个已知关键词。
- [ ] Quick Capture 实际保存一条临时内容。
- [ ] 重启后确认该写入仍存在。

## 14. 最后一轮验收步骤

### Case E — Regression

```text
1. 点击 Topbar「搜索」进入知识与搜索
2. 搜索 testnote 或 123，确认能返回已知结果
3. 回到首页，在 Quick Capture 输入一条临时内容并保存为笔记或任务
4. 确认新内容出现
5. 调整 Windows 窗口宽度（宽 → 窄 → 恢复）
6. 打开 AI Drawer，确认页面和 Drawer 都可滚动、无红屏
7. 完全关闭应用并重新启动
8. 确认刚才 Quick Capture 写入仍存在
```

### Final Analyze

执行：

```powershell
flutter analyze
```

验收标准：

```text
无 Phase 5 新增 error
```

仓库既有 info / warning 不作为 Phase 5 阻塞项，但需要确认没有本轮新增的编译级问题。

## 15. Phase 5 封版条件

当前：

```text
[✓] Preview Provider 本地链路
[✓] 四种 AI Scope
[✓] Context include / exclude
[✓] AI Thread / Message 多轮持久化
[✓] 历史会话
[✓] Windows 重启恢复
[✓] schema v5 迁移路径与现有数据回归
[✓] Context Snapshot 实现核验
[ ] Final Regression
[ ] flutter analyze 最终确认
```

Final Regression 与 Analyze 通过后：

```text
→ 创建 PHASE5_BASELINE.md
→ 标记 DeepSeek：Implemented / Pending External Credential Validation
→ Phase 5 封版
```
