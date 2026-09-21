# Personal Workbench 文档中心

这个目录只维护 Personal Workbench 当前真正需要长期看的文档。

我的原则是：文档要能帮助后面继续开发和维护，不为了“文档齐全”堆一堆没人看的内容。代码变了，对应文档也要跟着变。

## 文档地图

1. [01_PRODUCT_SCOPE.md](01_PRODUCT_SCOPE.md) — 产品是什么、解决什么问题、哪些事情现在不做。
2. [02_FUNCTIONAL_SPEC.md](02_FUNCTIONAL_SPEC.md) — 当前功能怎么用、怎么处理、用户操作以后发生什么。
3. [03_UI_UX_DESIGN.md](03_UI_UX_DESIGN.md) — Shell、Workspace、Drawer、Dialog、响应式和页面交互。
4. [04_TECHNICAL_ARCHITECTURE.md](04_TECHNICAL_ARCHITECTURE.md) — 当前代码分层、Runtime、SQLite、Markdown、路由和模块关系。
5. [05_DATA_AND_STORAGE.md](05_DATA_AND_STORAGE.md) — Schema、表、Markdown、Search Index、Settings、Backup / Restore。
6. [06_AI_SEARCH_KNOWLEDGE.md](06_AI_SEARCH_KNOWLEDGE.md) — AI Context、Prompt、Provider、Conversation、Search、Knowledge。
7. [07_IMPLEMENTATION_OPERATIONS.md](07_IMPLEMENTATION_OPERATIONS.md) — 怎么运行、检查、构建、排错、备份恢复和发布。
8. [08_TESTING_ACCEPTANCE.md](08_TESTING_ACCEPTANCE.md) — 功能回归、Analyze、Test、Build、Backup / Restore 验收。
9. [09_STATUS_ROADMAP.md](09_STATUS_ROADMAP.md) — 现在做到哪里，接下来优先处理什么。
10. [10_VERSION_HISTORY.md](10_VERSION_HISTORY.md) — 以前 Phase 1–7、v1.4 和后续结构整理记录。
11. [11_CODE_DEVELOPMENT_RULES.md](11_CODE_DEVELOPMENT_RULES.md) — 后面人工写代码或者让 AI 写代码，都按这里的方式来。
12. [12_CODE_OPTIMIZATION_PLAN.md](12_CODE_OPTIMIZATION_PLAN.md) — 后续代码优化、测试补强、性能和工程收口按这份计划推进。

## 当前基线

- Windows Desktop first
- Flutter 3.47.4 stable 为当前验证 SDK
- Workbench Database Schema：v6
- 主产品代码已经从早期 cloud disk 代码中独立出来
- 当前目录以 `app / pages / router / theme / widgets / workbench` 为主
- 历史 DTO、DBHelper、旧网盘页面不再属于 Personal Workbench
- 当前进入 Desktop Hardening 和代码整理阶段

## 维护原则

- 代码行为和文档冲突时，先以代码为事实，再立即把文档补上。
- 不再创建 `PHASE8_SCOPE`、`PHASE8_BASELINE` 这种阶段碎片文档。
- 当前代码不要继续出现 `phase2`、`v2` 这种历史阶段命名，除非它真的是协议或数据版本。
- 一次改动影响多个方面时，对应文档一起改，不留到“以后再补”。
