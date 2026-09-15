# Personal Workbench Phase 5 Acceptance — AI Context + Global AI

> 状态：**待 Windows 实际验收**。真实 DeepSeek Provider 已实现，但用户计划稍后再配置参数，因此 Real Provider 网络调用可后补验证；其余 Phase 5 功能需先完成本地 smoke acceptance。

## 1. AI Context Builder

四种 Scope：

- [ ] Task Scope 可以构建上下文。
- [ ] Workspace Scope 可以构建上下文。
- [ ] Knowledge Scope 可以构建上下文。
- [ ] Global Scope 可以通过 SearchService 获取少量相关上下文。

Task Scope 应包含：

- [ ] Current Task。
- [ ] Next Step / Task 内容。
- [ ] Active Issue / Blocker。
- [ ] Linked Note。
- [ ] Resource。
- [ ] Decision。
- [ ] Knowledge。
- [ ] Recent Activity。

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

- [ ] Global AI Drawer 可以显示 Context Preview。
- [ ] 可以看到 Scope。
- [ ] 可以看到 Anchor。
- [ ] 可以看到 Included Context。
- [ ] 可以看到 Context Priority。
- [ ] 可以看到 Context 字符数量。

### 手工控制

- [ ] Included Context 可以手工排除。
- [ ] 排除项会显示在“已排除”。
- [ ] 排除项可以恢复。
- [ ] `添加上下文` 可以搜索 Task / Note / Issue / Resource / Decision / Knowledge。
- [ ] 搜索结果可以手工加入当前 Context。
- [ ] 手工加入 / 排除以后 Preview 会重新计算。
- [ ] 实际发送消息时使用调整后的 Context。

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
- [ ] `ai_threads` 可以正常写入。
- [ ] `ai_messages` 可以正常写入。
- [ ] schema v5 重启后可以再次打开。

## 6. AI Thread / Message

### Thread

- [ ] 新对话可以创建 Thread。
- [ ] Scope 正确保存。
- [ ] Workspace / Task / Knowledge Anchor 正确保存。
- [ ] 首条用户消息可以自动形成 Thread title。
- [ ] 同一 Anchor 可以创建多个 Thread。
- [ ] 历史会话下拉可以重新打开 Thread。

### Message

- [ ] User Message 正确保存。
- [ ] Assistant Message 正确保存。
- [ ] 多轮消息按时间顺序恢复。
- [ ] 完整退出 App 后再次启动，Thread / Message 仍存在。

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

- [ ] 顶部 AI 按钮可以打开右侧 Drawer。
- [ ] Drawer 可以关闭。
- [ ] 显示当前 Provider 名称。
- [ ] Scope Selector 可用。
- [ ] Workspace Selector 可用。
- [ ] Task Selector 可用。
- [ ] Knowledge Selector 可用。
- [ ] Context Preview 可用。
- [ ] Message Input 可用。
- [ ] 历史会话可用。
- [ ] 新建会话按钮可用。

## 9. Preview Provider

在没有设置任何 AI 环境变量时：

- [ ] App 正常启动。
- [ ] Provider 显示 `Preview Provider`。
- [ ] 发送消息不会访问真实模型。
- [ ] 收到 Preview Provider 回复。
- [ ] Preview 回复仍写入 AI Message。
- [ ] Context Snapshot 正常保存。

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
- [ ] Provider 名称不再显示 Preview Provider。
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

## 12. Phase 1–4 Regression

只做快速 smoke regression：

- [ ] Home 正常。
- [ ] Continue 正常。
- [ ] Quick Capture 正常。
- [ ] Focus 正常。
- [ ] Workspace Overview 正常。
- [ ] Task 正常。
- [ ] Note 正常。
- [ ] Issue 正常。
- [ ] Resource 正常。
- [ ] Decision 正常。
- [ ] Knowledge 正常。
- [ ] Global Search 正常。

## 13. 本轮推荐验收路径

### Case A — Preview Provider

```text
1. 不配置任何 AI 环境变量
2. flutter run -d windows
3. 打开 AI Drawer
4. 确认 Provider = Preview Provider
5. Scope = Current Task
6. 选择 Workspace + Task
7. 查看上下文
8. 排除一条 Context
9. 恢复该 Context
10. 搜索并添加一条额外 Context
11. 输入问题并发送
12. 收到 Preview 回复
```

### Case B — Thread Persistence

```text
1. 连续发送两轮消息
2. 记录 Thread title
3. 完全退出应用
4. flutter run -d windows
5. 打开 AI Drawer
6. 从历史会话重新打开 Thread
7. 确认两轮消息均存在
```

### Case C — Scope

分别验证：

```text
Task
Workspace
Knowledge
Global
```

至少确认 Context Preview 无异常，Anchor 与 Scope 正确。

### Case D — Regression

快速点击 Phase 1–4 核心页面，确认无红屏和明显数据丢失。

## 14. Phase 5 封版条件

在以下条件满足前，不创建 `PHASE5_BASELINE.md`：

```text
[ ] flutter analyze 无 Phase 5 新增编译错误
[ ] Preview Provider 完整链路通过
[ ] 四种 AI Scope Preview 通过
[ ] 手工 include / exclude 通过
[ ] AI Thread / Message 持久化通过
[ ] Windows 重启恢复通过
[ ] schema v4 → v5 迁移无数据回归
[ ] Phase 1–4 smoke regression 通过
```

DeepSeek 真实调用如果暂时未测试，允许单独标记为：

```text
Implemented / Pending External Credential Validation
```

但 `PHASE5_BASELINE.md` 中必须明确记录该状态。
