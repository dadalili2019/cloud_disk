# Personal Workbench 文档中心

> 文档状态：V1 Baseline  
> 最后整理：2026-09-14  
> 对应代码仓库：`dadalili2019/cloud_disk`  
> 目标：作为 Personal Workbench 后续产品设计、开发、实施、维护的长期说明文档。

---

## 1. 文档用途

这一套文档不是一次性的需求说明，而是项目的长期设计基线。

后续每次新增功能、调整交互、修改存储方案或改变技术实现时，都应该优先更新对应文档，再进入开发。

文档解决四类问题：

1. **产品为什么这样设计**
2. **功能做到哪里为止**
3. **页面和交互应该是什么样**
4. **代码和数据应该如何实现**

---

## 2. 文档目录

| 文档 | 主要内容 |
|---|---|
| `01_PRODUCT_DESIGN_AND_SCOPE.md` | 产品定位、核心对象、功能边界、模块职责、V1 非目标 |
| `02_UI_UX_DESIGN.md` | UI 信息架构、页面结构、视觉规范、交互规则、Markdown Notes、Global AI |
| `03_FLUTTER_TECHNICAL_ARCHITECTURE.md` | 当前代码基线、Flutter 技术架构、分层、迁移策略、性能原则 |
| `04_DATA_MODEL_AND_STORAGE.md` | SQLite、Markdown、Entity Link、数据模型、目录结构、AI Context |
| `05_IMPLEMENTATION_ROADMAP.md` | 开发阶段、里程碑、验收标准、代码迁移顺序 |
| `06_DECISIONS.md` | 已确认的关键产品/技术决策及原因 |
| `personal_workbench_v1_schema.sql` | V1 SQLite 逻辑 Schema |

---

## 3. 当前产品一句话定义

**Personal Workbench 是一个帮助个人恢复工作上下文、持续推进任务的本地优先工作台。**

它不是单纯回答：

> 我还有什么事情没做？

而是回答：

> 我现在做到哪里了？  
> 下一步是什么？  
> 我卡在哪里？  
> 当时为什么这样做？  
> 相关笔记、资源和知识在哪里？

---

## 4. 当前核心模型

```text
Workspace
└─ Current Task
   ├─ Note
   ├─ Issue
   ├─ Resource
   ├─ Decision
   └─ Knowledge
```

AI、Home、Overview、Continue 都围绕这个 Work Context 工作。

---

## 5. 当前已确认技术方向

```text
Flutter + Dart
Windows Desktop First

fluent_ui
go_router

沿用当前应用已有的 Theme / Shell / Desktop 能力

新 Workbench 数据：
SQLite（建议 Drift 管理）
Markdown (.md)
Local File System

Local-first
```

---

## 6. 文档维护规则

每次功能调整建议遵循：

```text
产品边界变化
→ 更新 01

UI/交互变化
→ 更新 02

工程结构/技术实现变化
→ 更新 03

数据库/文件/关系变化
→ 更新 04

开发顺序/阶段变化
→ 更新 05

关键决策变化
→ 更新 06
```

---

## 7. 状态标记

文档中使用：

- `Confirmed`：已经确认，开发按此执行。
- `Planned`：方向确定，但尚未实现。
- `Legacy`：当前代码已有，但未来准备替换或迁移。
- `Deferred`：V1 暂不实现。
- `Open`：尚未确认。

---

## 8. 当前开发基线

当前 GitHub 仓库已经存在可运行的 Flutter 桌面应用，包含：

- `fluent_ui`
- `go_router`
- Windows Window 管理
- System Tray
- ThemeController
- SharedPreferences
- SQLite / sqflite_common_ffi
- Todo 页面
- JSON 格式化
- 文本比对
- 图片工具
- RAG Knowledge 页面等

Personal Workbench **不是重新创建一个 Flutter 项目**。

后续开发原则：

> 在现有项目上逐步演进，复用可复用能力，避免一次性重写。

---

## 9. V1 核心验收目标

第一条必须真正跑通的链路：

```text
创建 Workspace
→ 创建 Task
→ 设置 Current Task
→ 设置 Next Step
→ 创建 Markdown Note
→ Note linked_to Task
→ 关闭应用
→ 重新打开
→ Overview 能恢复 Current Task / Next Step / Linked Note
```

这一条通过，才代表 Personal Workbench 的核心能力成立。
