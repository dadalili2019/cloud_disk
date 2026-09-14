# Personal Workbench Phase 4 Scope — Knowledge + Search

## 1. Phase 目标

Phase 4 将原规划中的 Knowledge 与 Search 合并为一个阶段，目标是形成一条完整闭环：

> 工作过程数据 → 沉淀为可复用 Knowledge → 建立统一全文索引 → 跨工作区检索 → 再进入当前工作上下文。

本阶段不把 Knowledge 做成第二套 Notes，也不引入向量数据库或在线 AI 服务。V1 先把本地数据模型、关系模型、全文检索和页面交互做稳定。

---

## 2. Knowledge 的定位

### Notes

记录“当时发生了什么”，允许临时、杂乱、重复，并保留项目现场上下文。

### Knowledge

记录“以后还值得复用什么”，应经过整理、抽象和去上下文噪音。

推荐沉淀链路：

```text
Raw Note / Decision / Issue / Resource / Task
                    ↓
                 Review
                    ↓
                 Distill
                    ↓
              Knowledge Entry
                    ↓
            Search / Reuse / AI Context
```

---

## 3. Knowledge V1 字段

| 字段 | 说明 |
|---|---|
| id | UUID |
| title | 知识标题 |
| category | 用户维护的分类 |
| summary | 知识摘要 |
| use_when | 什么情况下适合使用 |
| file_path | Markdown 正文路径 |
| is_pinned | 是否置顶 |
| created_at | 创建时间 |
| updated_at | 更新时间 |
| archived_at | 归档时间 |

正文继续使用 Markdown 文件保存；SQLite 只保存元数据和关系。

默认目录：

```text
PersonalWorkbench/
├── data/
│   └── workbench.db
├── workspaces/
└── knowledge/
    └── *.md
```

---

## 4. Knowledge 关系

统一使用现有 `entity_links`，不新增各业务专属关联表。

### 来源关系

```text
Knowledge --derived_from--> Note
Knowledge --derived_from--> Decision
Knowledge --derived_from--> Issue
Knowledge --derived_from--> Resource
Knowledge --derived_from--> Task
```

### 工作上下文关系

```text
Knowledge --applies_to--> Task
```

因此 Task Context 在 Phase 4 后正式包含：

```text
Task Context
├── Notes
├── Issues
├── Resources
├── Decisions
├── Knowledge
└── Recent Activity
```

---

## 5. Search V1 范围

统一搜索以下类型：

- Task
- Note
- Issue
- Resource
- Decision
- Knowledge

搜索结果统一为：

```text
SearchResult
├── entityType
├── entityId
├── workspaceId?
├── title
├── snippet
└── score
```

### 索引策略

V1 使用 SQLite FTS5：

```text
SQLite / Markdown truth
        ↓
 SearchService.rebuildIndex()
        ↓
    FTS5 search_index
        ↓
 FTS MATCH + BM25 ranking
        ↓
 LIKE fallback
        ↓
   SearchResult[]
```

原则：

- `search_index` 只是检索索引，不是业务数据真源。
- Markdown 正文和 SQLite 业务表仍是唯一真实数据来源。
- 页面初始化可重建索引，后续再优化为事件驱动的增量更新。
- FTS 对中文或特殊字符查询不理想时使用 LIKE fallback，优先保证“能搜到”。

---

## 6. 页面边界

Phase 4 新增一级入口：

```text
知识与搜索
```

页面两种状态：

### 无搜索词

展示 Knowledge Library：

- 分类筛选
- Knowledge 卡片
- 新建知识
- 编辑知识
- 置顶
- Summary
- Use When
- Markdown Reusable Pattern

### 有搜索词

展示 Global Search：

- 跨 Workspace 搜索
- 跨实体类型搜索
- 展示实体类型、标题、摘要片段
- 点击结果回到对应 Workspace 页面
- Knowledge 结果直接打开 Knowledge 编辑器

旧 `/ragknowledge` 功能暂不删除，在菜单中明确命名为 `RAG 知识库`，避免与 Personal Workbench Knowledge 混淆。

---

## 7. 本阶段明确不做

以下能力留给后续阶段：

- Embedding / Vector Search
- Rerank
- 自动 AI Distill
- AI 自动分类与标签
- 自动生成 Knowledge Summary
- 云端同步
- 多用户协作
- 独立搜索服务器

Phase 4 可以预留接口，但不能让这些能力成为 Knowledge / Search 基础闭环的前置依赖。

---

## 8. 验收标准

Phase 4 完成时至少满足：

1. Knowledge 可以创建、编辑、读取并持久化。
2. Knowledge Markdown 文件与 SQLite 元数据职责清晰。
3. Knowledge 能通过 `derived_from` 保存来源关系。
4. Knowledge 能通过 `applies_to` 进入 Task Context。
5. Search 可以检索 Task / Note / Issue / Resource / Decision / Knowledge。
6. 搜索结果能跳回相应业务页面。
7. 中文关键词在 FTS 不命中时仍有 LIKE fallback。
8. 重启应用后 Knowledge 与索引可以重新恢复。
9. 不破坏 Phase 1–3 已封版的数据与交互。

---

## 9. Phase 4 当前开发顺序

```text
P4.1  Schema + Knowledge Model
  ↓
P4.2  Knowledge Repository / Markdown Persistence
  ↓
P4.3  SearchIndexRepository + FTS5
  ↓
P4.4  KnowledgeService + SearchService
  ↓
P4.5  Task Context 接入 Knowledge
  ↓
P4.6  Knowledge + Search 页面
  ↓
P4.7  Distill / Source Link 交互
  ↓
P4.8  本地联调、搜索质量和回归验证
  ↓
PHASE4_BASELINE
```

当前分支：

```text
feature/personal-workbench-phase4
```

Phase 4 从 `feature/personal-workbench-phase3` 的封版提交直接创建，不从 main 重建。
