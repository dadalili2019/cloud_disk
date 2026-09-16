# Personal Workbench Phase 5 Acceptance — AI Context + Global AI

> 状态：**Windows 验收进行中**。Workbench 全局 UI、Workspace 子页面与 Global AI Drawer 已完成实际 Windows 截图 smoke；Preview Provider 单轮发送链路已通过；Context 手工排除 / 恢复 / 搜索 / 添加链路已通过；Task / Workspace / Knowledge / Global 四种 Scope Preview 已通过；真实 DeepSeek Provider 已实现，但用户计划稍后再配置参数，因此 Real Provider 网络调用可后补验证。

## 0. 当前验收进度

已通过 Windows 实际界面确认：

```text
[✓] Global App Shell
[✓] Topbar Current Context
[✓] Topbar 响应式 Search 入口
[✓] Home
[✓] Workspace Frame / Overview
[✓] Task 页面
[✓] Note 双栏编辑器
[✓] Issue 页面
[✓] Resource 页面
[✓] Decision 页面
[✓] Knowledge 页面
[✓] Global AI Drawer 打开 / 关闭
[✓] Workspace 页面打开 AI 自动继承 Current Task
[✓] Task / Workspace / Knowledge / Global 四种 Scope Preview
[✓] Context 摘要 / 管理视图可展示
[✓] Preview Provider 单轮发送与回复链路
[✓] 首轮 AI Thread / User Message / Assistant Message 写入链路
[✓] Context 手工排除 / 恢复
[✓] Context 搜索 / 手工添加
[✓] Context Preview 数量重新计算
```

仍需重点手工验证：

```text
调整后的 Context 实际发送
AI 多轮 Thread / Message persistence
历史会话重新打开
Context Snapshot
Windows 重启恢复
schema v4 → v5 数据回归
Phase 1–4 功能 smoke regression
```

---

## 1. AI Context Builder

四种 Scope：

- [x] Task Scope 可以构建上下文。
- [x] Workspace Scope 可以构建上下文。
- [x] Knowledge Scope 可以构建上下文。
- [x] Global Scope 可以通过 SearchService 获取少量相关上下文。

Task Scope 应包含：

- [x] Current Task。
- [ ] Next Step / Task 内容。
- [ ] Active Issue / Blocker。
- [x] Linked Note。
- [x] Resource。
- [x] Decision。
- [ ] Knowledge。
- [x] Recent Activity。

> Windows 实际截图已验证不同 Task 的 Context Preview 能展示 Task / Note / Resource / Decision / Activity；Blocker / Knowledge 需使用包含对应数据的样例继续验证。

实现约束：

- [x] Task Scope 复用 `TaskContextService`。
- [x] AIContextBuilder 不直接读取 UI State。
- [x] Global Scope 不默认扫描全部本地数据。

## 2. Context Budget

- [x] 使用确定性 P0-P4 优先级。
- [x] 使用字符预算。
- [x] 使用条数预算。
- [ ] P0 Current Task / Blocker 在实际预览中优先保留。
- [ ] 超预算时旧 Note / Knowledge / Activity 可被裁剪。

当前默认：

```text
maxItems = 24
maxCharacters = 18000
```

## 3. Context Preview

- [x] Global AI Drawer 可以显示 Context Preview。
- [x] 可以看到 Scope。
- [x] 可以看到 Anchor。
- [x] 可以看到 Included Context。
- [x] 可以看到 Context Priority。
- [x] 可以看到 Context 字符数量。

### 手工控制

- [x] Included Context 可以手工排除。
- [x] 排除项会显示在“已排除”。
- [x] 排除项可以恢复。
- [x] `添加上下文` 搜索弹窗可以正常返回工作上下文结果。
- [x] 搜索结果可以手工加入当前 Context。
- [x] 手工加入 / 排除以后 Preview 会重新计算。
- [ ] 实际发送消息时使用调整后的 Context。

实际 Windows 验收记录：

```text
初始 Context：11 条
排除一条 Activity：11 → 10
恢复该 Activity：10 → 11
搜索 testnote：返回「笔记 · testnote」
手工加入 testnote：11 → 12
新增项优先级：P2
```

已实际看到搜索返回 Task / Note / Resource / Decision；Issue / Knowledge 类型可在后续 Regression 测试中继续覆盖。

## 4. PromptBuilder

- [x] PromptBuilder 与 UI 分离。
- [x] 输入为 AIContext + User Message + Conversation History。
- [x] 输出包含 System Prompt / Context Block / History / User Prompt。
- [x] System Prompt 明确禁止虚构已执行操作。

## 5. Schema v5

数据库：

```text
schemaVersion = 5
```

新增：

```text
ai_threads
ai_messages
```

验证：

- [ ] 既有 schema v4 数据升级后仍存在。
- [ ] Workspace / Task / Note / Issue / Resource / Decision / Knowledge 无丢失。
- [x] `ai_threads` 可以正常写入。
- [x] `ai_messages` 可以正常写入。
- [ ] schema v5 重启后可以再次打开。

## 6. AI Thread / Message

### Thread

- [x] 新对话可以创建 Thread。
- [x] Task Scope 正确用于首轮会话。
- [x] Task Anchor 正确用于首轮会话。
- [ ] 首条用户消息可以自动形成 Thread title。
- [ ] 同一 Anchor 可以创建多个 Thread。
- [ ] 历史会话可以重新打开 Thread。

### Message

- [x] User Message 正确保存并重新读取展示。
- [x] Assistant Message 正确保存并重新读取展示。
- [ ] 多轮消息按时间顺序恢复。
- [ ] 完整退出 App 后再次启动，Thread / Message 仍存在。

> 首轮发送截图中，Preview Provider 回复是在持久化后通过 Conversation Service 重新读取并显示，因此可确认首轮 Thread / User Message / Assistant Message 写入链路正常；重启持久化仍需单独验证。

## 7. Context Snapshot

Assistant Message 保存：

```text
context_snapshot_json
```

验证：

- [ ] Assistant Message 的 snapshot 非空。
- [ ] snapshot 包含 scope。
- [ ] snapshot 包含 anchor / workspace（适用时）。
- [ ] snapshot 包含本次实际 included entity refs。
- [ ] snapshot 不复制完整 Note / Knowledge 正文。

## 8. Global AI Drawer

- [x] 顶部 AI 按钮可以打开右侧 Drawer。
- [x] Drawer 可以关闭。
- [x] 显示当前 Provider 状态。
- [x] Scope Selector 可用并完成四种 Scope 实际切换。
- [x] Workspace Selector 可用。
- [x] Task Selector 可用。
- [x] Knowledge Selector 实际切换验证。
- [x] Global Scope 实际 Preview 验证。
- [x] Context Preview 可用。
- [x] Message Input 可用并完成实际发送。
- [x] 首轮发送后历史会话入口出现。
- [ ] 历史会话实际重新打开验证。
- [x] 新建会话按钮可见。
- [x] Home 打开 AI 时自动继承 Current Task。
- [x] Workspace 打开 AI 时优先继承该 Workspace 的 Current Task。

## 9. Preview Provider

在没有设置任何 AI 环境变量时：

- [x] App 正常启动。
- [x] Provider 显示 `Preview` 状态。
- [x] 实际发送使用 Preview Provider，没有调用真实模型。
- [x] 收到 Preview Provider 回复。
- [x] Preview 回复写入 AI Message 并重新读取展示。
- [ ] Context Snapshot 正常保存。

实际验收问题：

```text
帮我总结一下当前任务做到哪里了，下一步应该做什么？
```

实际返回包含：

```text
Phase 5 Preview Provider
已接收用户问题
已接收 Workbench Context
已经过 PromptBuilder
尚未调用真实模型
```

说明 Preview Provider 的本地完整调用链已跑通。

## 10. Real AI Provider

实现状态：

- [x] `AIProvider` 抽象存在。
- [x] `OpenAICompatibleAIProvider` 已实现。
- [x] Provider 与 UI 解耦。
- [x] API Key 不写死在源码。
- [x] API Key 不写入 Workbench SQLite。
- [x] 支持 runtime environment variables。
- [x] 支持 `--dart-define`。
- [x] 支持自定义 Authorization Header / Prefix。
- [x] 支持 Extra Headers。
- [x] 支持请求 timeout。
- [x] 支持 HTTP / JSON / empty response 错误提示。

### DeepSeek

- [x] `https://api.deepseek.com` 自动识别。
- [x] DeepSeek 官方地址默认使用 `/chat/completions`。
- [x] 其他 OpenAI-compatible 服务默认使用 `/v1/chat/completions`。
- [x] 用户显式设置 `WORKBENCH_AI_CHAT_PATH` 时优先使用用户配置。

### 后补真实网络验收

用户准备好 DeepSeek 参数后验证：

- [ ] Base URL + Model + API Key 可以启动 Real Provider。
- [ ] Provider 名称不再显示 Preview。
- [ ] Current Task Scope 可以收到真实 DeepSeek 回复。
- [ ] 多轮真实模型对话可用。
- [ ] DeepSeek 不可用 / Key 错误时 Drawer 显示错误且 App 不崩溃。

> 此组网络测试可以在 Phase 5 其他本地功能通过后单独补测；在真实模型尚未验证前，Baseline 必须明确记录该限制，不能宣称 Real Provider 已完成端到端验收。

## 11. Windows 重启恢复

完整退出应用并重新：

```powershell
flutter run -d windows
```

验证：

- [ ] AI Thread 仍存在。
- [ ] AI Message 仍存在。
- [ ] Thread Scope / Anchor 正确恢复。
- [ ] 原有 Workbench 数据仍存在。
- [ ] AI Drawer 可以继续使用。

## 12. Workbench UI / Windows Smoke

已通过当前 Windows 截图确认：

- [x] Global App Shell 正常。
- [x] Sidebar 分组正常。
- [x] Topbar Current Context 正常。
- [x] Topbar Search 在当前窗口宽度显示紧凑入口。
- [x] AI Drawer Overlay 不导致主页面布局崩溃。
- [x] Workspace 二级导航正常。
- [x] Workspace Overview 桌面双列布局正常。
- [x] Task 页面正常显示。
- [x] Note 双栏页面正常显示。
- [x] Issue 空状态页面正常显示。
- [x] Resource 页面正常显示。
- [x] Decision 页面正常显示。
- [x] Knowledge 页面正常显示。

仍需最后验证：

- [ ] 改变 Windows 窗口宽度时无明显 overflow / 红屏。
- [ ] AI Drawer 打开后各核心页面仍可正常滚动。
- [ ] Dialog / Drawer 开关过程中无明显焦点异常。

## 13. Phase 1–4 Regression

当前已完成页面级 smoke：

- [x] Home 可以正常加载。
- [x] Continue / Current Task 可以正常显示。
- [x] Quick Capture 区域可以正常显示。
- [x] Focus 区域可以正常显示。
- [x] Workspace Overview 可以正常加载。
- [x] Task 页面可以正常加载。
- [x] Note 页面可以正常加载。
- [x] Issue 页面可以正常加载。
- [x] Resource 页面可以正常加载。
- [x] Decision 页面可以正常加载。
- [x] Knowledge 页面可以正常加载。
- [ ] Global Search 实际关键词检索回归。

> 以上为页面 / 数据显示 smoke。涉及新增、编辑、保存等写操作的完整 Phase 1–4 回归仍以最终验收结果为准。

## 14. 下一轮推荐验收路径

### Case A — Preview Provider 单轮链路（已通过）

```text
[✓] 保持不配置任何 AI 环境变量
[✓] 打开 AI Drawer
[✓] Provider = Preview
[✓] 自动继承 Current Task
[✓] 输入问题并发送
[✓] 收到 Preview Provider 回复
```

“正在思考…”属于瞬时 UI 状态，当前最终截图未单独捕获，不据此标记通过或失败。

### Case B — Context 手工管理（核心链路已通过）

```text
[✓] 点击“管理”
[✓] 排除一条非 P0 Context
[✓] 确认进入“已排除”
[✓] 点击恢复
[✓] 点击“添加上下文”
[✓] 搜索 testnote
[✓] 添加「笔记 · testnote」
[✓] Context 数量 11 → 12
```

待后续发送链路顺带确认：

```text
[ ] 实际发送消息时使用调整后的 Context
```

### Case C — 四种 Scope（已通过）

```text
[✓] 任务
[✓] 工作区
[✓] 知识
[✓] 全局
```

已确认各 Scope 的 Anchor / Selector / Context Preview 可正常工作。

### Case D — Thread Persistence

```text
1. 回到一个 Task Thread
2. 再发送第二轮消息
3. 点击右上角历史图标，确认 Thread title 已生成
4. 完全退出应用
5. flutter run -d windows
6. 打开 AI Drawer
7. 从历史会话重新打开该 Thread
8. 确认两轮用户消息和两轮 AI 回复均存在
9. 确认 Scope / Task Anchor 仍然正确
```

### Case E — Regression

```text
1. Knowledge 页面搜索一个已知关键词
2. Quick Capture 保存一条临时内容
3. Task / Note / Resource / Decision 各打开一次
4. 重启后确认原有数据仍存在
```

## 15. Phase 5 封版条件

在以下条件满足前，不创建 `PHASE5_BASELINE.md`：

```text
[ ] flutter analyze 无 Phase 5 新增编译错误
[✓] Preview Provider 单轮本地链路通过
[✓] 四种 AI Scope Preview 通过
[✓] 手工 include / exclude 核心链路通过
[ ] AI Thread / Message 多轮持久化通过
[ ] Windows 重启恢复通过
[ ] schema v4 → v5 迁移无数据回归
[ ] Phase 1–4 功能 smoke regression 通过
```

DeepSeek 真实调用如果暂时未测试，允许单独标记为：

```text
Implemented / Pending External Credential Validation
```

但 `PHASE5_BASELINE.md` 中必须明确记录该状态。
