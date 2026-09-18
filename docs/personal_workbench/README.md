# Personal Workbench 文档中心

本目录是 Personal Workbench 当前版本的唯一长期维护文档入口。

## 文档地图

1. [01_PRODUCT_SCOPE.md](01_PRODUCT_SCOPE.md)  
   产品定位、目标用户、核心对象、功能边界。

2. [02_FUNCTIONAL_SPEC.md](02_FUNCTIONAL_SPEC.md)  
   当前所有功能的行为说明、页面能力和主要业务规则。

3. [03_UI_UX_DESIGN.md](03_UI_UX_DESIGN.md)  
   Global Shell、Workspace、Drawer、Dialog、响应式和视觉设计规范。

4. [04_TECHNICAL_ARCHITECTURE.md](04_TECHNICAL_ARCHITECTURE.md)  
   Flutter、Runtime、Application、Domain、Data、SQLite、Markdown 的技术架构。

5. [05_DATA_AND_STORAGE.md](05_DATA_AND_STORAGE.md)  
   Schema v6、核心表、FTS5、文件目录、设置、备份和恢复数据边界。

6. [06_AI_SEARCH_KNOWLEDGE.md](06_AI_SEARCH_KNOWLEDGE.md)  
   AI Context、Prompt、Provider、Conversation、Search、Knowledge 的实现说明。

7. [07_IMPLEMENTATION_OPERATIONS.md](07_IMPLEMENTATION_OPERATIONS.md)  
   开发环境、运行、构建、配置、备份、恢复、故障定位和发布操作。

8. [08_TESTING_ACCEPTANCE.md](08_TESTING_ACCEPTANCE.md)  
   功能回归、Windows 验收、Analyze、Build、Backup/Restore 验收清单。

9. [09_STATUS_ROADMAP.md](09_STATUS_ROADMAP.md)  
   当前完成状态、剩余 Hardening、AI 实机验证、CI、Mobile Roadmap。

10. [10_VERSION_HISTORY.md](10_VERSION_HISTORY.md)  
    Phase 1–7 与 v1.4 的历史摘要，不再作为当前实现规范。

## 当前文档基线

当前实现基线：

- 主分支：main
- Personal Workbench v1.4 已合并
- Windows Desktop first
- Flutter 3.47.4 stable 为当前验证 SDK
- Workbench Database Schema：v6
- Windows Release Build 已通过
- flutter analyze 当前仍存在历史 lint，但未观察到阻塞性 error

## 维护原则

- 代码行为与文档冲突时，以 main 代码为事实来源，并立即修正文档。
- 新功能不要再创建 PHASE8_SCOPE / PHASE8_BASELINE 这类碎片文档。
- 历史阶段信息统一记录在 10_VERSION_HISTORY.md。
- 当前设计、实施、架构只维护本目录中的主题文档。
