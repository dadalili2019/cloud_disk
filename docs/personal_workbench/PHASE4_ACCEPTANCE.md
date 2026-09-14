# Personal Workbench Phase 4 Acceptance — Knowledge + Search

> 状态：验收中。Knowledge/Search 主链路与重启恢复已通过；完成 Phase 1–3 smoke regression 后创建 `PHASE4_BASELINE.md`。

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
- [x] 正文 / Summary / Description 等内容可以命中。
- [x] FTS5 + LIKE partial fallback 可以合并去重返回结果。
- [x] 搜索结果展示实体类型、标题和摘要片段。
- [ ] Knowledge 结果点击后打开 Knowledge 编辑器。
- [x] Workspace 实体结果点击后进入正确 Workspace 业务页面。

## 4. 索引恢复

- [x] 页面初始化 / 重建索引无异常。
- [x] 重建后已有 Knowledge 仍可搜索。
- [x] 重建后 Workspace 数据仍可搜索。
- [x] `search_index` 只作为派生索引，不影响业务真实数据。

## 5. 重启恢复

完全退出 Windows 应用后重新启动：

- [x] Knowledge 条目仍存在。
- [x] Knowledge Markdown 正文仍存在。
- [x] Category / Summary / Use When 状态仍存在。
- [x] 从 Workspace 沉淀的 Source Context 仍存在。
- [x] 打开 `知识与搜索` 后索引能够重新建立。
- [x] 重启后搜索仍可正常返回结果。
- [ ] Pin 状态跨重启验证。

## 6. Phase 1–3 回归

Phase 4 与 Phase 3 diff 已核对。Phase 4 没有修改 Quick Capture、Focus Session、Issue、Resource、Decision、Note、Task CRUD 的既有 service/repository 实现；现有模块改动主要集中在导航/路由、DB schema v4、Runtime 注入、Task Context 增加 Knowledge，以及新增 Knowledge/Search 文件。因此最终采用快速 smoke regression，而不重复执行整套 Phase 1–3 功能测试。

### Home

- [ ] 首页可以正常加载。
- [ ] Continue / 当前任务正常。
- [ ] Quick Capture 区域正常。
- [ ] Focus 卡片 / 今日时间线正常。

### Workspace

- [ ] Workspace 列表与 Overview 正常。
- [x] Task 页面、当前任务、搜索跳转正常。
- [ ] Note 页面正常。
- [ ] Issue 页面正常。
- [ ] Resource 页面正常。
- [ ] Decision 页面正常。

## 7. 最后 smoke test

封版前只需再确认：

1. 首页正常显示 Continue、Quick Capture、Focus。
2. Workspace 的 Overview / Note / Issue / Resource / Decision 页面均能打开，无红屏。
3. Knowledge 搜索结果点击后能打开 Knowledge 编辑器。
4. 任意中文关键词与英文关键词各搜索一次，页面无异常且能返回预期数据（有对应数据时）。
5. 可选：置顶一条 Knowledge，重启后仍保持置顶。

## 8. Phase 4 封版条件

以下条件满足后创建 `PHASE4_BASELINE.md`：

1. Knowledge 创建、编辑、沉淀、Source Context 主链路通过。
2. Global Search 跨实体、partial fallback、结果跳转通过。
3. Windows 应用完整退出并重启后数据、关系和搜索恢复正常。
4. Phase 1–3 smoke regression 无明显回归。
5. 没有阻塞级编译或运行错误。
