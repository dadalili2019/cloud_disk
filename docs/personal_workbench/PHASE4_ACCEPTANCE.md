# Personal Workbench Phase 4 Acceptance — Knowledge + Search

> 状态：**通过**。Phase 4 已完成 Windows 实际运行、重启恢复与 Phase 1–3 smoke regression，可作为后续阶段开发基线。

## 1. Knowledge 基础闭环

- [x] 手工新建 Knowledge 可以保存。
- [x] Knowledge 可以再次打开并编辑。
- [x] Category 可以形成筛选项。
- [x] Pin 状态可以持久化。
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

搜索范围已实现：

- [x] Task
- [x] Note
- [x] Issue
- [x] Resource
- [x] Decision
- [x] Knowledge

搜索行为：

- [x] 英文关键词可以搜索。
- [x] 中文关键词可以搜索。
- [x] 标题可以命中。
- [x] 正文 / Summary / Description 等内容可以命中。
- [x] FTS5 + LIKE partial fallback 可以合并去重返回结果。
- [x] 搜索结果展示实体类型、标题和摘要片段。
- [x] Knowledge 结果点击后打开 Knowledge 编辑器。
- [x] Workspace 实体结果点击后进入正确 Workspace 业务页面。

说明：实际样例数据已验证 Knowledge / Task / Resource / Decision 等跨实体搜索与部分匹配；Note / Issue 搜索能力由相同统一索引链路实现并纳入最终 smoke regression。

## 4. 索引恢复

- [x] 页面初始化 / 重建索引无异常。
- [x] 重建后已有 Knowledge 仍可搜索。
- [x] 重建后 Workspace 数据仍可搜索。
- [x] `search_index` 只作为派生索引，不影响业务真实数据。

## 5. 重启恢复

完全退出 Windows 应用后重新启动：

- [x] Knowledge 条目仍存在。
- [x] Knowledge Markdown 正文仍存在。
- [x] Category / Summary / Use When / Pin 状态仍存在。
- [x] 从 Workspace 沉淀的 Source Context 仍存在。
- [x] 打开 `知识与搜索` 后索引能够重新建立。
- [x] 重启后搜索仍可正常返回结果。

## 6. Phase 1–3 回归

Phase 4 与 Phase 3 diff 已核对。Phase 4 没有重写 Quick Capture、Focus Session、Issue、Resource、Decision、Note、Task CRUD 的既有核心实现；改动主要集中在导航/路由、DB schema v4、Runtime 注入、Task Context 增加 Knowledge，以及新增 Knowledge/Search 能力。

最终 smoke regression：

### Home

- [x] 首页可以正常加载。
- [x] Continue / 当前任务正常。
- [x] Quick Capture 区域正常。
- [x] Focus 卡片 / 今日时间线正常。

### Workspace

- [x] Workspace 列表与 Overview 正常。
- [x] Task 页面、当前任务、搜索跳转正常。
- [x] Note 页面正常。
- [x] Issue 页面正常。
- [x] Resource 页面正常。
- [x] Decision 页面正常。

## 7. Phase 4 封版结论

```text
[✓] Knowledge CRUD
[✓] Markdown Storage
[✓] Workspace → Knowledge Distill
[✓] Source Context / derived_from
[✓] Task Context includes Knowledge
[✓] SQLite FTS5 Search Index
[✓] LIKE Partial Match Supplement
[✓] Global Search Result Routing
[✓] Index Rebuild
[✓] Windows Restart Recovery
[✓] Phase 1–3 Smoke Regression
```

Phase 4 验收通过，可以创建 `PHASE4_BASELINE.md` 并进入后续阶段。
