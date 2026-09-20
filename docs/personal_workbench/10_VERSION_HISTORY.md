# Personal Workbench 版本历史

本文只记录历史，不作为当前实现规范。

## Phase 1–3

建立 Workspace、Task、Current Task、Markdown Note、Entity Link、Activity、Issue、Resource、Decision、Home、Continue、Quick Capture、Focus、Today。

## Phase 4

增加 Knowledge、Knowledge Distill、SQLite FTS5 Search、Search Result Routing。

## Phase 5

增加 AI Context Builder、Context Budget、Prompt Builder、Global AI、AI Thread / Message History、OpenAI-compatible Provider。

## Phase 6

增加 Developer Project、Developer Command、Developer Snippet、Developer Context、Search Integration、AI Developer Context。

## Phase 7

增加 Settings、Backup、Export、Restore、Data Safety、Provider Settings。

## v1.4 UI Consolidation

完成 Global Shell、Home、Workspace、Knowledge、Time、Developer、Tools、Settings、Dark Mode、Windows Window / Login Polish。

v1.4 通过 PR #1 合并到 main。

## 2026-09-20 Codebase Cleanup

在 `refactor/personal-workbench-cleanup` 分支进行：

- 清理 cloud disk 历史业务代码。
- 删除无效旧路由。
- 规范目录和 Dart 文件名。
- 清理历史依赖。
- 删除本机绝对路径测试脚本。
- 增加基础单元测试。
- Tray 从 NetDisk 改为 Personal Workbench。
- 当前代码不再继续使用 Phase 历史命名。
- 新增长期编码规范。

这次调整以“减少历史包袱，不改变当前业务行为”为原则。
