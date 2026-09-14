# Personal Workbench — 关键决策记录

## D-001 不定位为 Todo App
**Status:** Confirmed  
定位为 Work Context Continuity System，核心解决上下文恢复。

## D-002 Workspace 是核心容器
**Status:** Confirmed  
核心链为 Workspace → Current Task → Related Context。

## D-003 每个 Workspace 最多一个 Current Task
**Status:** Confirmed

## D-004 Task 必须包含 Next Step
**Status:** Confirmed

## D-005 Notes 使用 Markdown
**Status:** Confirmed  
正文使用 `.md`，保证可读、可迁移、可版本管理、可被外部编辑器打开。

## D-006 Knowledge 也使用 Markdown 正文
**Status:** Confirmed

## D-007 SQLite 与 Markdown 分工
**Status:** Confirmed  
SQLite 管 Structured Metadata / Relation，Markdown 管 Note / Knowledge Body。

## D-008 Entity Link 使用统一关系表
**Status:** Confirmed

## D-009 AI 不是独立 Chatbot
**Status:** Confirmed  
AI 默认基于 Current Task / Workspace Context，并展示当前 Context。

## D-010 UI 减少说明性文字
**Status:** Confirmed

## D-011 沿用现有 Flutter 工程
**Status:** Confirmed  
继续 Flutter + Dart，Windows Desktop First。

## D-012 继续使用 fluent_ui
**Status:** Confirmed

## D-013 继续使用 go_router
**Status:** Confirmed

## D-014 不强制引入新状态管理框架
**Status:** Confirmed  
当前继续 ChangeNotifier / StatefulWidget 的轻量模式，复杂度显著增加后再评估。

## D-015 新 Workbench 数据库与 Legacy DB 解耦
**Status:** Confirmed  
Legacy 使用 `my_database.db`，Workbench 使用 `workbench.db`。

## D-016 新 Workbench 数据层使用 Repository
**Status:** Confirmed  
禁止新页面继续 Widget → DBHelper → SQL。

## D-017 V1 Desktop First
**Status:** Confirmed

## D-018 第一阶段不实现 AI
**Status:** Confirmed  
先跑通 Workspace / Task / Markdown Note / Entity Link / Overview。
