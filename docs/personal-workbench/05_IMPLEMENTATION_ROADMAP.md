# Personal Workbench V1 — 开发实施计划

## 1. 原则

不重写整个 cloud_disk；不一次实现所有页面；不先做 AI；不先做 Cloud Sync。先跑通核心 Work Context。

## 2. Phase 0 — 代码基线整理

检查 pubspec / main / router / NavigationPage / ThemeController / DBHelper / TodoPage / Windows Build，形成风险与改造清单。

## 3. Phase 1 — Work Context Core

实现：

```text
Workspace
Task
Current Task
Markdown Note
Entity Link
Activity
Workspace Overview
```

新增：`workbench.db / Migration / Repositories / Services / AppPaths / AtomicFileWriter / Result / AppError`。

路由至少：

```text
/workspace/:id/overview
/workspace/:id/tasks
/workspace/:id/notes
```

## 4. Phase 1 验收

创建 Workspace `cloud_disk`，创建 Task `Flutter Windows 性能优化`，设置 Current Task 和 Next Step，创建 `Flutter Windows 性能排查记录.md`，建立 Note linked_to Task。Overview 返回 Current Task / Next Step / Linked Note / Recent Activity。关闭重开后仍然恢复。

## 5. Phase 2 — Workspace Complete

增加 Issue / Resource / Decision / Archive / Workspace Settings。

## 6. Phase 3 — Home + Time

实现 Home Snapshot / Continue / Quick Capture / Focus Session / Today Timeline / Summary。

## 7. Phase 4 — Knowledge

实现 Distill / Source Link / Use When / Categories。

## 8. Phase 5 — Search

实现 Global Search / FTS5 / Markdown Index。

## 9. Phase 6 — AI

实现 Global AI Drawer、AIContextBuilder、PromptBuilder、AIThread、AIMessage。必须先稳定 Context Builder，再接模型。

## 10. Phase 7 — Developer + Tools

实现 Developer Assets 和高频本地 Tools。

## 11. Phase 8 — Settings + Backup

实现 General / Appearance / Notes / AI / Data / Shortcuts / Backup / Export / Restore。

## 12. Phase 9 — Mobile

Desktop V1 稳定后再适配 Android / iOS，优先复用 Domain / Application / Repository。

## 13. 现有代码迁移

- NavigationPage：保留并逐步替换菜单。
- Router：继续 go_router，新增 Workbench Route。
- ThemeController：继续使用，增加 Comfort Dark preset。
- TodoPage：标记 Legacy，新 Task 稳定后再选择导入/下线。
- DBHelper：保留给 Legacy；Workbench 新模块不使用。

## 14. 每阶段规则

```text
更新文档
→ 明确范围
→ 写代码
→ flutter analyze
→ flutter test
→ Windows Release 验证
→ 更新 Decisions
→ Commit
```

## 15. Done Definition

功能可用、数据可恢复、异常有处理、Loading 可见、无明显 UI 卡顿、核心逻辑有测试、文档同步更新。
