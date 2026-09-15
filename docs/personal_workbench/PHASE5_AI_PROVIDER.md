# Personal Workbench Phase 5 — Real AI Provider

## 1. 当前 Provider 策略

Workbench AI 当前采用自动选择：

```text
WORKBENCH_AI_BASE_URL + WORKBENCH_AI_MODEL 已配置
    ↓
OpenAICompatibleAIProvider

否则
    ↓
PreviewAIProvider
```

因此没有模型配置时，应用仍然可以正常启动和验证 Context / Prompt / Thread 链路。

---

## 2. 支持的接口

当前真实模型使用 OpenAI-compatible Chat Completions：

```text
POST {BASE_URL}{CHAT_PATH}
```

默认普通 OpenAI-compatible 服务使用：

```text
CHAT_PATH=/v1/chat/completions
```

如果：

```text
WORKBENCH_AI_BASE_URL=https://api.deepseek.com
```

Workbench 会自动识别 DeepSeek 官方 API，并默认使用：

```text
CHAT_PATH=/chat/completions
```

因此 DeepSeek 官方 API 通常只需要配置：

```text
WORKBENCH_AI_BASE_URL
WORKBENCH_AI_MODEL
WORKBENCH_AI_API_KEY
```

如果显式设置 `WORKBENCH_AI_CHAT_PATH`，则始终以显式配置为准。

请求核心格式：

```json
{
  "model": "your-model",
  "messages": [
    {"role": "system", "content": "..."},
    {"role": "user", "content": "..."}
  ],
  "stream": false
}
```

响应需要兼容：

```text
choices[0].message.content
```

同时兼容部分 Gateway 返回的 content array。

---

## 3. 环境变量

### 必填

```text
WORKBENCH_AI_BASE_URL
WORKBENCH_AI_MODEL
```

### 常用

```text
WORKBENCH_AI_API_KEY
```

### 可选

```text
WORKBENCH_AI_CHAT_PATH
WORKBENCH_AI_API_KEY_HEADER
WORKBENCH_AI_API_KEY_PREFIX
WORKBENCH_AI_EXTRA_HEADERS_JSON
WORKBENCH_AI_TIMEOUT_SECONDS
```

默认值：

```text
普通 OpenAI-compatible:
CHAT_PATH=/v1/chat/completions

DeepSeek 官方 API:
CHAT_PATH=/chat/completions

API_KEY_HEADER=Authorization
API_KEY_PREFIX=Bearer
TIMEOUT_SECONDS=90
```

---

## 4. Windows PowerShell 示例

### DeepSeek 官方 API

```powershell
$env:WORKBENCH_AI_BASE_URL="https://api.deepseek.com"
$env:WORKBENCH_AI_MODEL="your-deepseek-model"
$env:WORKBENCH_AI_API_KEY="your-key"
flutter run -d windows
```

无需额外设置 `WORKBENCH_AI_CHAT_PATH`。

### 普通 Bearer Token 网关

```powershell
$env:WORKBENCH_AI_BASE_URL="https://your-ai-gateway.example.com"
$env:WORKBENCH_AI_MODEL="your-model"
$env:WORKBENCH_AI_API_KEY="your-key"
flutter run -d windows
```

如果 Gateway 使用：

```text
api-key: xxx
```

则：

```powershell
$env:WORKBENCH_AI_BASE_URL="https://your-ai-gateway.example.com"
$env:WORKBENCH_AI_MODEL="your-model"
$env:WORKBENCH_AI_API_KEY="your-key"
$env:WORKBENCH_AI_API_KEY_HEADER="api-key"
$env:WORKBENCH_AI_API_KEY_PREFIX=""
flutter run -d windows
```

如果需要额外 Header：

```powershell
$env:WORKBENCH_AI_EXTRA_HEADERS_JSON='{"X-Tenant":"tenant-id","X-App":"personal-workbench"}'
```

---

## 5. dart-define 示例

也可以使用：

```powershell
flutter run -d windows `
  --dart-define=WORKBENCH_AI_BASE_URL=https://api.deepseek.com `
  --dart-define=WORKBENCH_AI_MODEL=your-deepseek-model `
  --dart-define=WORKBENCH_AI_API_KEY=your-key
```

注意：

> API Key 更推荐通过运行环境传递，而不是提交到源码、Git 或普通配置文件。

---

## 6. Context 到模型的请求链路

```text
User Message
    ↓
AIContextBuilder
    ↓
AIContextBudget
    ↓
PromptBuilder
    ↓
OpenAICompatibleAIProvider
    ↓
LLM Gateway
    ↓
Assistant Response
    ↓
AIMessage + context_snapshot_json
```

模型收到的是已经经过 Context Builder 和 Budget 筛选后的数据，不会默认收到整个本地数据库。

---

## 7. Prompt 结构

模型输入结构为：

```text
System
├─ Personal Workbench assistant rules
└─ Workbench Context

History
├─ user
├─ assistant
└─ ...

User
└─ current message
```

`PromptBuilder` 与 UI 分离。

---

## 8. 错误处理

真实 Provider 会明确返回以下错误：

```text
网络请求失败
请求超时
HTTP 非 2xx
返回非 JSON
返回内容为空
```

错误会由 Global AI Drawer 的 InfoBar 展示，不应导致整个 Workbench 崩溃。

HTTP 错误响应正文最多保留前 500 个字符用于排查，避免将超大错误页直接塞进 UI。

---

## 9. 安全边界

Phase 5 明确：

```text
API Key 不写死在 Dart 源码
API Key 不写入 workbench.db
API Key 不写入 AI Thread / Message
Context Snapshot 只保存实体引用
```

用户可以在 Context Preview 中确认本次请求会使用哪些 Workbench 数据。

---

## 10. P5.7 验收

### Preview 模式

未设置 AI 环境变量：

```text
发送消息
→ Preview Provider 回复
```

### Real 模式

配置真实模型：

```text
启动 Windows App
→ 打开 Workbench AI
→ Scope = Current Task
→ 选择 Workspace
→ 选择 Current Task
→ 查看上下文
→ 输入问题
→ 收到真实 LLM 回复
```

建议测试问题：

```text
根据当前任务上下文，总结我现在做到哪里了，并告诉我下一步应该做什么。
```

验证重点：

```text
[ ] 回复不再出现 Preview Provider 文案
[ ] 回复能引用 Current Task / Next Step
[ ] Context Preview 与模型实际使用上下文一致
[ ] 多轮消息可以继续对话
[ ] AI Thread / Message 写入 SQLite
[ ] 完全退出 App 再启动后会话仍存在
[ ] 模型不可用时显示错误，但 App 不崩溃
```
