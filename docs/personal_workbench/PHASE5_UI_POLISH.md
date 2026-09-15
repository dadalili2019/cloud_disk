# Personal Workbench Phase 5 — AI UI Polish

> 状态：进行中。此清单用于 Phase 5 功能完成后的 UI / UX 收口，不替代 `PHASE5_ACCEPTANCE.md`。

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

对应代码：

```text
lib/workbench/presentation/global_ai_drawer.dart
```

---

## 3. 第二轮 — Message Readability

待实现：

- [ ] Assistant Message 支持轻量 Markdown 渲染。
- [ ] 至少支持标题、列表、段落、代码块、inline code。
- [ ] User Message 继续使用普通文本气泡。
- [ ] Code Block 支持 Copy。
- [ ] 超长 AI 回复保持可滚动且不破坏 Drawer 宽度。

目的：

> DeepSeek / OpenAI-compatible 模型真正接入以后，回答不能以一整块纯文本展示。

---

## 4. 第三轮 — Failure / Retry UX

待实现：

- [ ] Provider 失败时在消息流中显示失败状态。
- [ ] 已保存 User Message 不应因为 Provider 失败在 UI 中消失。
- [ ] Assistant failure 提供 `Retry`。
- [ ] Retry 使用原 Thread + 当前 Context 重新请求。
- [ ] 401 / 403 / timeout / 5xx 保持简短可读错误信息。
- [ ] 顶部 InfoBar 只作为补充，不作为唯一错误反馈。

---

## 5. 第四轮 — Desktop Interaction

待实现：

- [ ] `Ctrl + Enter` 发送。
- [ ] `Enter` 保留换行。
- [ ] `Esc` 关闭 AI Drawer。
- [ ] Context Scope 切换支持清晰 Hover / Focus 状态。
- [ ] History 对话框支持键盘选择。
- [ ] Drawer 最小宽度下不出现横向 overflow。

---

## 6. 第五轮 — Thread Management

待实现 / 后续评估：

- [ ] Thread Rename。
- [ ] Thread Archive。
- [ ] History 可以区分 Task / Workspace / Knowledge / Global。
- [ ] History 显示更新时间。
- [ ] 当前 Thread 有明显选中状态。

不在 Phase 5 强制做：

```text
Thread Folder
Tag
Cloud Sync
Share Thread
```

---

## 7. 技术收口（非纯 UI）

Phase 5 Baseline 前还需要评估：

### Conversation History Budget

当前 Work Context 已有限制：

```text
maxItems = 24
maxCharacters = 18000
```

但 Conversation History 仍需要单独预算。

第一版建议：

```text
保留最近 8 ~ 12 轮 user / assistant 消息
或增加字符上限
```

### Search Index Freshness

Global / Workspace AI Scope 会使用 `SearchService`。

需要确保：

```text
用户直接打开 AI
```

时不会依赖“之前必须打开过知识与搜索页面”才能获得最新 Search Index。

建议在 Application 层增加 freshness / rebuild 策略，而不是让 AI UI 自己维护索引。

---

## 8. 当前状态

```text
Phase 5 Core Features        Complete
Phase 5 AI Drawer Functional Complete
Phase 5 UI Polish Round 1    Complete
Message Readability          Pending
Failure / Retry UX           Pending
Desktop Interaction          Pending
History Budget               Pending
Search Freshness             Pending
DeepSeek Credential Test     Pending
Windows Acceptance           Pending
```

完成 UI / 技术收口后再进入最终 P5.8 Windows Acceptance。
