# Personal Workbench Phase 5 — AI UI Polish

> 状态：核心 UI / 技术收口已完成，待 Windows 实际验收。此清单不替代 `PHASE5_ACCEPTANCE.md`。

## 1. 设计基线

Global AI 继续遵守 Personal Workbench V1 原则：

```text
Comfort / Compact / Low Noise / Desktop First
```

AI 是 App Shell 的 Right Drawer，不是独立主页面。

目标宽度：

```text
560 ~ 720px
```

---

## 2. 第一轮 — Layout Polish

已实现：

- [x] Drawer 从 430px 调整为约 620px，并根据窗口宽度自适应。
- [x] Header 显示 `Workbench AI`。
- [x] Header 显示当前 Context，而不是把 Provider 当主信息。
- [x] Provider 改为紧凑 Badge。
- [x] Scope 从单个 ComboBox 改为紧凑四段选择。
- [x] Task / Workspace / Knowledge 只显示当前 Scope 必需的 Anchor Selector。
- [x] History 从常驻下拉移出主布局，改为 Header 入口。
- [x] New Thread 保持 Header 快捷入口。
- [x] Context Preview 默认收起。
- [x] Context 收起状态使用 compact chips。
- [x] Context 展开后显示完整 included / excluded 列表。
- [x] 手工 include / exclude 功能保留。
- [x] Message 最大宽度随新版 Drawer 增大。
- [x] 发送时展示 Pending User Message。
- [x] 发送时展示 `Thinking…` 状态。
- [x] 打开历史会话 / 收到回复后自动滚动到底部。
- [x] Composer 上方固定显示当前 Scope / Anchor。
- [x] Composer 在已有 Preview 时显示 Context 数量。
- [x] Empty State 压缩为一个主要提示。

---

## 3. 第二轮 — Message Readability

已实现：

- [x] Assistant Message 使用轻量 Markdown 渲染。
- [x] 支持标题、段落、无序列表、有序列表。
- [x] 支持 fenced code block。
- [x] 支持 inline code。
- [x] 支持 `**bold**`。
- [x] User Message 保持普通文本气泡。
- [x] Code Block 支持 Copy。
- [x] Code Block 超宽内容使用横向滚动，不撑破 Drawer。
- [x] AI Message 使用 SelectableText，便于复制。

实现文件：

```text
lib/workbench/presentation/assistant_markdown.dart
```

Phase 5 使用轻量 Markdown 子集，不引入完整 Markdown / HTML 渲染依赖。

---

## 4. 第三轮 — Failure / Retry UX

已实现：

- [x] Provider 失败后在消息流中显示 `AI 回复失败`。
- [x] 已保存 User Message 在 Provider 失败后仍保留在 Thread / UI。
- [x] Failure Card 提供 `Retry`。
- [x] Retry 复用原 Thread。
- [x] Retry 不重复插入 User Message。
- [x] Retry 重新构建当前 Context / Prompt。
- [x] Retry 成功后只新增 Assistant Message。
- [x] 失败信息做长度控制，避免大段 Gateway 错误占满 Drawer。
- [x] 顶部 InfoBar 仅处理 Context / 创建 Thread 等前置错误；Provider 失败主要在消息流反馈。

---

## 5. 第四轮 — Desktop Interaction

已实现：

- [x] `Ctrl + Enter` 发送。
- [x] `Enter` 保留换行。
- [x] `Esc` 关闭 AI Drawer。
- [x] Composer 显示桌面快捷键提示。

待实际 Windows 验证：

- [ ] TextBox 聚焦时 `Ctrl + Enter` 不产生额外换行。
- [ ] `Esc` 在输入框聚焦时仍能关闭 Drawer。
- [ ] Drawer 最小宽度无横向 overflow。

后续可选优化：

- [ ] Context Scope 增强 Hover / Focus 样式。
- [ ] History 对话框增强完整键盘导航。

---

## 6. Thread Management

当前已有：

- [x] History 显示 Task / Workspace / Knowledge / Global Scope。
- [x] History 显示更新时间。
- [x] 新建 Thread。
- [x] 打开历史 Thread。

后续可选：

- [ ] Thread Rename UI。
- [ ] Thread Archive UI。
- [ ] 当前 Thread 更明显的选中状态。

以下不属于 Phase 5：

```text
Thread Folder
Tag
Cloud Sync
Share Thread
```

---

## 7. Conversation History Budget

已实现于：

```text
AIPromptBuilder
```

当前默认：

```text
maxHistoryMessages = 20
maxHistoryCharacters = 12000
```

约等于最多最近 10 轮 user / assistant 消息，同时再受字符上限保护。

策略：

```text
从最新消息向前保留
→ 达到消息条数上限停止
→ 达到字符上限停止
→ 单条过长时保留其最近部分
```

因此 Thread 可以完整持久化，但模型 Prompt 不会随着历史会话无限增长。

---

## 8. Search Index Freshness

已实现 Application 层 freshness gate。

```text
SearchService.searchFresh()
→ ensureFreshIndex()
→ rebuildIndex() when stale
```

当前默认：

```text
freshnessWindow = 2 minutes
```

行为：

```text
应用启动后 AI 第一次需要 Search
→ 自动 rebuild index

2 分钟内继续 AI Search
→ 复用现有 index

超过 freshness window
→ 下一次 AI Search 自动刷新
```

并发 rebuild 会复用同一个 `_rebuildInFlight`，避免同时重复全量扫描。

AI 以下 Scope 已切换为 fresh search：

```text
Workspace
Knowledge
Global
```

AI Drawer 的“添加上下文”搜索同样使用 fresh search。

因此 AI 不再依赖用户先打开“知识与搜索”页面。

---

## 9. 当前状态

```text
Phase 5 Core Features        Complete
Phase 5 AI Drawer Functional Complete
Phase 5 UI Polish Round 1    Complete
Message Readability          Complete
Failure / Retry UX           Complete
Desktop Interaction          Implemented / Pending Windows Verification
History Budget               Complete
Search Freshness             Complete
Thread Management            Optional Follow-up
DeepSeek Credential Test     Pending
Windows Acceptance           Pending
```

下一步：

```text
Windows compile / interaction acceptance
→ Preview Provider smoke test
→ schema / persistence regression
→ DeepSeek credential validation（用户准备参数后）
→ PHASE5_BASELINE.md
```
