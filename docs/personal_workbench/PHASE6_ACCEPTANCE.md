# Personal Workbench Phase 6 Acceptance — Developer Context + Tools

> 状态：**P6.1–P6.6 已实现，P6.7 Windows 本地验收进行中**。Developer 页面与 Search Integration 已完成实际 UI 验证；P6.6 后最终 `flutter analyze` 已确认无 Phase 6 新增 error。AI Developer Context、schema v6 重启恢复与最终回归完成后即可封版。

## 1. 当前结论

Phase 6 已完成主要实现：

```text
[✓] P6.1 Developer Context Contract
[✓] P6.2 Schema v6 + Repository
[✓] P6.3 Application Services
[✓] P6.4 Workspace Developer Page
[✓] P6.5 Search Integration
[✓] P6.6 AI Context Integration — implementation
[ ] P6.7 Windows Acceptance — in progress
[ ] P6.8 Baseline
```

当前不提前声明 Phase 6 封版；以下 Windows 验收项完成后再创建 `PHASE6_BASELINE.md`。

---

## 2. Schema v6

当前数据库版本：

```text
schemaVersion = 6
```

新增表：

```text
developer_projects
developer_commands
developer_snippets
```

迁移链：

```text
5 -> 6
```

实现核验：

- [x] fresh database 创建 `_schemaV1` 到 `_schemaV6`
- [x] migration switch 注册 `case 5 -> _schemaV6`
- [x] v6 只新增 Developer 表与索引
- [x] 不修改 / drop Phase 1–5 原业务表
- [x] Developer 外键关联 Workspace / Project
- [x] 同一 Workspace 最多一个未归档 Primary Project
- [ ] 从已有 v5 `workbench.db` 启动升级后完整退出并再次打开
- [ ] 重启后 Phase 1–5 原数据仍可读取

---

## 3. Developer Project

实现：

- [x] Create
- [x] Update
- [x] List by Workspace
- [x] Primary Project
- [x] Archive
- [x] 归档 Primary 后自动选择剩余 Project
- [x] Copy local path
- [x] Copy repository URL
- [x] Activity 记录

Windows 验收：

- [x] Developer 页面可打开
- [x] 新建 Project 可用于 Search 验证
- [ ] 编辑 Project
- [ ] 设置 / 切换 Primary Project
- [ ] 归档 Project
- [ ] 完整重启后 Project 恢复

---

## 4. Developer Command

实现：

- [x] Create
- [x] Update
- [x] List by Workspace / Project
- [x] Category
- [x] Pin
- [x] Working Directory
- [x] Archive
- [x] Copy Command
- [x] Activity 记录

Windows 验收：

- [x] Command 可创建并用于 Search 验证
- [ ] 编辑 Command
- [ ] Pin / Category / Working Directory
- [ ] Copy Command
- [ ] 归档 Command
- [ ] 完整重启后 Command 恢复

---

## 5. Developer Snippet

实现：

- [x] Create
- [x] Update
- [x] List by Workspace / Project
- [x] Language
- [x] Pin
- [x] Archive
- [x] Copy Content
- [x] Activity 记录

Windows 验收：

- [x] Snippet 可创建并用于 Search 验证
- [ ] 编辑 Snippet
- [ ] Language / Pin
- [ ] Copy Content
- [ ] 归档 Snippet
- [ ] 完整重启后 Snippet 恢复

---

## 6. Developer Context Service

当前输出：

```text
DeveloperContext
├─ projects[]
├─ primaryProject?
├─ commands[]
├─ snippets[]
└─ devResources[]
```

实现核验：

- [x] UI 不直接跨表拼 Developer Context
- [x] Project / Command / Snippet 通过 Repository 聚合
- [x] Dev Resource 复用现有 `ResourceModel`
- [x] Developer Resource 类型过滤
- [x] AIContextBuilder 复用 DeveloperContextService

---

## 7. Workspace Developer Page

入口：

```text
工作台
-> Workspace
-> 开发
```

当前页面：

```text
项目
常用命令
代码片段
开发资源
```

已完成 Windows UI 验证：

- [x] Workspace 二级导航显示「开发」
- [x] Developer 页面正常打开
- [x] 空状态正常
- [x] Project / Command / Snippet 新建入口
- [x] 页面整体风格与 Phase 5 Workbench UI 一致
- [x] 内容区与右侧 scrollbar 保持安全距离
- [x] Windows 桌面布局无明显溢出

---

## 8. Search Integration

Developer Search Entity Type：

```text
developer_project
developer_command
developer_snippet
```

索引内容：

### Project

```text
name
local_path
repository_url
branch
tech_stack
notes
primary marker
```

### Command

```text
name
command
working_directory
category
notes
```

### Snippet

```text
title
language
content
notes
```

已完成 Windows 验收：

- [x] Project 可搜索
- [x] Command 可搜索
- [x] Snippet 可搜索
- [x] Search placeholder 包含项目 / 命令 / 代码片段
- [x] Search 不要求新增数据库 schema
- [x] 点击 Developer Search Result 进入对应 Workspace Developer Page

P6.5 已由实际本地测试确认通过。

---

## 9. AI Context Integration

实现结构：

```text
DeveloperContextService
        ↓
AIContextBuilder
        ↓
AIContextBudget
        ↓
Context Preview
        ↓
PromptBuilder
```

### Task Scope

默认允许加入：

```text
P1 Primary Project
P2 Pinned / selected Command
P3 Pinned / selected Snippet
P2 Dev Resource
```

不会默认全量塞入所有 Command / Snippet。

### Workspace Scope

允许加入：

```text
Primary Project
少量其他 Project
少量 Command
少量 Snippet
Dev Resource
```

### Knowledge / Global Scope

仍依赖 SearchService 小规模检索；Developer Search Result 现在可以被 `_loadEntityItem()` 解析为完整 Developer AI Context。

### Manual Context

支持：

```text
Developer Project
Developer Command
Developer Snippet
```

Windows 待验收：

- [ ] Task Scope Preview 出现 Project
- [ ] Task Scope Preview 出现 Command
- [ ] Task Scope Preview 出现 Snippet
- [ ] Workspace Scope 出现 Developer Context
- [ ] Global 搜索 Developer 数据后能进入 AI Context
- [ ] 手工「添加上下文」可添加 Developer 实体
- [ ] exclude / restore 对 Developer 实体正常
- [ ] Context Budget 仍生效
- [ ] AI Preview Provider / Real Provider Prompt 能收到 Developer Context

---

## 10. Phase 6 工具安全边界

Phase 6 V1 已保持以下边界：

```text
允许：
- 展示路径
- 复制路径
- 展示命令
- 复制命令
- 展示 Snippet
- 复制 Snippet
- 聚合开发资源

禁止：
- 自动执行 Shell / PowerShell / Bash
- 自动执行 Git
- 自动运行测试
- 自动启动 Docker
- 自动修改代码
- AI Tool Calling
- Terminal Emulator
```

验收标准：Developer 页面不存在隐式执行按钮或 AI 自动执行路径。

---

## 11. Restart Recovery

最终封版前执行：

```text
1. Project / Command / Snippet 均至少保留一条测试数据
2. 完整关闭 Windows App
3. 重新 flutter run -d windows
4. 打开同一 Workspace -> 开发
5. 确认 Developer 数据仍存在
6. 打开知识与搜索，确认 Developer Search 可恢复
7. 打开 AI Drawer，确认 Developer Context 可重新生成
```

状态：

- [ ] schema v6 restart recovery
- [ ] Developer data restart recovery
- [ ] Search rebuild after restart
- [ ] AI Context after restart

---

## 12. Phase 1–5 Smoke Regression

Phase 6 不允许破坏：

```text
Home
Continue / Current Task
Quick Capture
Focus
Workspace Overview
Task
Note
Issue
Resource
Decision
Knowledge
Global Search
AI Drawer
AI Thread / Message
Context Preview
历史会话
```

状态：

- [ ] Phase 1–5 smoke regression final pass

此前 P6.1–P6.5 开发过程中未观察到明显业务数据回归，但最终验收仍需在 Phase 6 完成后统一确认一次。

---

## 13. Flutter Analyze

P6.6 AI Context Integration 完成后已再次执行：

```powershell
flutter analyze
```

结果仍为：

```text
130 issues found
```

用户本地确认终端未出现 Phase 6 新增 `error`；当前可见项仍为项目既有 info / warning。

状态：

- [x] P6.6 后最终 analyze 无 Phase 6 新增 error

---

## 14. Phase 6 最终封版条件

```text
[ ] Schema v6 migration + restart 验证
[ ] Project CRUD Windows 验证
[ ] Command CRUD Windows 验证
[ ] Snippet CRUD Windows 验证
[✓] Developer Page UI
[✓] Search Integration
[ ] AI Developer Context Windows 验证
[ ] Phase 1–5 smoke regression
[✓] flutter analyze 无 Phase 6 新增 error
```

全部完成后：

```text
P6.7 Windows Acceptance ✓
P6.8 创建 PHASE6_BASELINE.md
Phase 6 封版
```
