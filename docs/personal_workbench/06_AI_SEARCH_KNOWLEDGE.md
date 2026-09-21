# Personal Workbench AI / Search / Knowledge

## 1. Knowledge

Knowledge 是“可复用经验”，不是第二套 Note。

字段：

- title
- category
- summary
- use_when
- markdown
- pinned
- sources

来源通过 derived_from 保存。

## 2. Search

### 数据来源

SearchService 构建索引时读取：

- Workspace Tasks
- Notes Markdown
- Issues
- Resources
- Decisions
- Knowledge
- Developer Projects
- Commands
- Snippets

### 查询策略

第一层：

~~~text
FTS5 MATCH
+ BM25
~~~

第二层：

~~~text
LIKE substring fallback
~~~

原因：

- FTS Token 对部分中文、标点和数字串较严格。
- LIKE 用于保证“123”能匹配“12323213”这类 substring。

## 3. AI Scope

AI 支持：

- Task
- Workspace
- Knowledge
- Global

## 4. AI Context Builder

### Task Scope

优先加入：

- 当前 Task
- Linked Notes
- Open Issues
- Decisions
- Resources
- Developer Context
- Knowledge
- Recent Activity

### Workspace Scope

优先：

- Current Task
- 少量 recent Task
- Notes
- Issues
- Resources
- Decisions
- Developer Context
- Knowledge

### Global Scope

根据 Query 使用 SearchService 获取少量相关实体，不进行全库正文无界拼接。

## 5. Context Budget

所有 Context 在进入 Prompt 前经过 AIContextBudget。

目的：

- 限制总长度
- 保留高优先级内容
- 降低冗余
- 避免大段 Snippet / Markdown 占满上下文

## 6. Prompt Builder

统一形成：

~~~text
System Prompt
Context Block
Conversation History
User Prompt
~~~

Provider 只负责模型调用。

## 7. Provider

ConfigurableAIProvider 支持：

- Environment
- Preview
- DeepSeek
- OpenAI Compatible

Environment 未配置时回退 Preview。

DeepSeek 默认：

~~~text
Base URL: https://api.deepseek.com
Chat Path: /chat/completions
~~~

OpenAI Compatible 默认：

~~~text
Chat Path: /v1/chat/completions
~~~

## 8. Secret Policy

API Key：

- Session 内存优先
- 可 fallback 到 environment config
- 不写入 Workbench DB
- 不写入普通 SharedPreferences
- 不进入 Backup / Export

## 9. Conversation

持久化：

- ai_threads
- ai_messages

支持：

- 创建
- Rename
- Archive
- 按 Anchor 查询
- 重启恢复

Assistant Message 会记录 Context Snapshot Reference。

Snapshot 记录：

- Scope
- Workspace / Task / Knowledge Anchor
- Included Entity Ref

不复制整份业务正文。

## 10. 当前仍需验证

- 真实 API Gateway / API Key 完整链路
- 长会话 Token Budget 行为
- 中文检索相关性
- Search Index 大数据量性能
- 编辑后索引即时一致性


## AI Context Builder 代码组织

AI Context 的业务入口仍然只有：

~~~text
AIContextBuilder.build(request)
~~~

内部实现已经按职责拆开：

~~~text
build(request)
  ↓
Scope Strategy
  ├─ Task
  ├─ Workspace
  ├─ Knowledge
  └─ Global
  ↓
Context Collection
  ├─ linked notes
  ├─ issues / resources / decisions
  ├─ developer context
  ├─ knowledge
  ├─ search hits
  └─ activity
  ↓
Entity Mapping / Formatting
  ↓
dedupe + manual include/exclude + priority sort
  ↓
AIContextModel
~~~

这次拆分不改变原有 Context 规则，只解决一个文件同时承担太多职责的问题。

后面如果新增新的 Context 类型，先判断它属于：

- Scope 选择逻辑；
- 数据收集；
- Entity 映射；
- 内容格式化；

不要继续把所有逻辑堆回 `ai_context_builder.dart`。


## Global AI Drawer 代码组织

Global AI Drawer 目前先做第一阶段拆分：

~~~text
global_ai_drawer.dart
├─ global_ai_drawer_widgets.dart
└─ global_ai_drawer_formatters.dart
~~~

职责：

- `global_ai_drawer.dart`：State、加载、Scope 切换、Context 操作、Conversation 生命周期、发送/重试。
- `global_ai_drawer_widgets.dart`：Header、Scope UI、Body、Message、Composer 等渲染辅助方法。
- `global_ai_drawer_formatters.dart`：Scope / Entity / Provider / 时间 / 错误文本格式化。

`_contextPreview` 暂时仍留在 State 主类，因为它直接控制 `_contextExpanded` 的 `setState`。后面如果继续拆，会先把状态边界理清楚，而不是为了减少行数强行移动。


## Knowledge 页面代码组织

Knowledge 页面现在按“页面状态 / 列表展示 / 编辑 / helper”拆开：

~~~text
workbench_knowledge_page.dart
├─ workbench_knowledge_cards.dart
├─ workbench_knowledge_editor.dart
└─ workbench_knowledge_support.dart
~~~

页面主文件仍然负责：

- Knowledge load
- Search debounce / SearchService
- Category filter
- Distill dialog
- Create / Edit
- Search Result route

卡片和编辑 Dialog 只负责展示和输入，不直接重新组织 KnowledgeService 业务规则。


## AI 异常与 Conversation 保护

AI 第一轮异常链路已经开始自动化保护。

Provider 层覆盖：

- 未配置 Provider 时不发网络请求。
- Endpoint / Header / Prompt Message 组装。
- Timeout 转为可读错误。
- 网络异常转为统一 Provider 错误。
- HTTP 4xx / 5xx。
- 错误 Body 限长，避免把超长响应直接带到 UI。
- 非法 JSON。
- 空 Response。
- OpenAI-compatible 多段 content。
- 长 Response 不在 Provider 层无故截断。

Conversation 层覆盖：

- Global / Task / Workspace / Knowledge anchor 校验。
- Task Thread 自动绑定所属 Workspace。
- Archived Anchor / Thread 不继续写入。
- 第一条 User Message 自动生成 Thread Title。
- Assistant Message 只保存 Context Reference Snapshot，不重复复制完整正文。
- Thread / Message SQLite 持久化。
- 数据库关闭重新打开后 Conversation History 仍然可恢复。

Retry 规则：

~~~text
第一次发送
→ User Message 已落库
→ Provider 失败
→ UI 保留 Failed Message

Retry
→ 不再重复追加同一条 User Message
→ Prompt History 排除最后那条已落库 User Message
→ Provider 成功后只补 Assistant Message
~~~

这条 History 规则已经从 Drawer 私有方法移到 Application 层纯函数，UI 行为不变，后续可以独立测试。

当前暂时不拆 Global AI Drawer 的完整 State。先把 Provider、Conversation、Retry 行为锁住，再决定是否值得继续抽状态层。
