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
