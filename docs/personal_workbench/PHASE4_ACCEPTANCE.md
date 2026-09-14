# Personal Workbench Phase 4 Acceptance — Knowledge + Search

> 状态：验收中。全部通过后再创建 `PHASE4_BASELINE.md`。

## 1. Knowledge 基础闭环

- [x] 手工新建 Knowledge 可以保存。
- [x] Knowledge 可以再次打开并编辑。
- [x] Category 可以形成筛选项。
- [ ] Pin 状态可以持久化。
- [x] Markdown 正文可以持久化。

## 2. Workspace → Knowledge 沉淀

- [x] `从工作区沉淀` 可以选择 Workspace。
- [x] 可以读取 Task / Note / Issue / Resource / Decision。
- [x] 选择来源后会生成可编辑草稿。
- [x] 沉淀后 Knowledge 出现在 Library。
- [x] Knowledge 保存 `derived_from` 关系。
- [x] 再次打开 Knowledge 时可以显示 Source Context。
- [x] 手工创建、没有来源的 Knowledge 不显示 Source Context。

## 3. Global Search

搜索范围：

- [x] Task
- [ ] Note
- [ ] Issue
- [x] Resource
- [x] Decision
- [x] Knowledge

搜索行为：

- [ ] 英文关键词可以搜索。
- [ ] 中文关键词可以搜索。
- [x] 标题可以命中。
- [ ] 正文 / Summary / Description 等内容可以命中。
- [x] FTS5 未命中时 LIKE fallback 仍能返回结果。
- [x] 搜索结果展示实体类型、标题和摘要片段。
- [ ] Knowledge 结果点击后打开 Knowledge 编辑器。
- [x] Workspace 实体结果点击后进入正确 Workspace 业务页面。

## 4. 索引恢复

- [ ] 点击 `重建索引` 后无异常。
- [ ] 重建后已有 Knowledge 仍可搜索。
- [ ] 重建后 Workspace 数据仍可搜索。
- [x] `search_index` 只作为派生索引，不影响业务真实数据。

## 5. 重启恢复

完全退出 Windows 应用后重新启动：

- [ ] Knowledge 条目仍存在。
- [ ] Knowledge Markdown 正文仍存在。
- [ ] Category / Summary / Use When / Pin 状态仍存在。
- [ ] 从 Workspace 沉淀的 Source Context 仍存在。
- [ ] 打开 `知识与搜索` 后索引能够重新建立。
- [ ] 重启后搜索仍可正常返回结果。

## 6. Phase 1–3 回归

### Home

- [ ] 首页可以正常加载。
- [ ] Continue / 当前任务正常。
- [ ] Quick Capture 保存为 Note 正常。
- [ ] Quick Capture 保存为 Task 正常。
- [ ] Focus 卡片正常。

### Workspace

- [ ] Workspace 列表正常。
- [ ] Overview 正常。
- [x] Task 新建 / 编辑 / 当前任务正常。
- [ ] Note 新建 / 自动保存正常。
- [ ] Issue 新建 / 编辑 / 关联任务正常。
- [ ] Resource 新建 / 编辑 / 关联任务正常。
- [ ] Decision 新建 / 编辑 / 关联任务正常。

### Focus

- [ ] 可以开始专注。
- [ ] 可以结束专注。
- [ ] 今日专注统计正常。
- [ ] 今日时间线正常。

## 7. Phase 4 封版条件

只有以下条件全部满足后才创建 `PHASE4_BASELINE.md`：

1. Knowledge 创建、编辑、沉淀、Source Context 全部通过。
2. 六类实体 Global Search 全部通过。
3. 中文搜索与 fallback 通过。
4. Windows 应用完整退出并重启后数据与关系恢复正常。
5. Phase 1–3 核心功能没有明显回归。
6. 没有阻塞级编译或运行错误。
