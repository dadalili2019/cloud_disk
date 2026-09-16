# Personal Workbench Phase 6 Acceptance — Developer Context + Tools

> 状态：**P6.7 Windows Acceptance 已完成。** Phase 6 功能、持久化、搜索、AI Developer Context 与 Phase 1–5 smoke regression 已完成本地验收；下一步仅创建 Phase 6 baseline 记录。

## 1. 最终结论

```text
[✓] P6.1 Developer Context Contract
[✓] P6.2 Schema v6 + Repository
[✓] P6.3 Application Services
[✓] P6.4 Workspace Developer Page
[✓] P6.5 Search Integration
[✓] P6.6 AI Context Integration
[✓] P6.7 Windows Acceptance
[ ] P6.8 Baseline Record
```

Phase 6 的定位保持不变：

> Developer Work Context + Tool Launcher

不是 Autonomous Coding Agent。

---

## 2. Schema v6 验收

数据库版本：

```text
schemaVersion = 6
```

新增表：

```text
developer_projects
developer_commands
developer_snippets
```

迁移：

```text
5 -> 6
```

验收结果：

```text
[✓] fresh database 包含 schema v6
[✓] v5 -> v6 migration 注册完成
[✓] Phase 1–5 原业务表不删除、不重建
[✓] Developer 数据完整写入 workbench.db
[✓] Windows 完整退出 / 重启后 Developer 数据仍存在
[✓] 重启后 Phase 1–5 原数据仍可读取
```

---

## 3. Project / Command / Snippet 验收

### Developer Project

已实现：

```text
Create
Update
List by Workspace
Primary Project
Set Primary
Archive
Copy local path
Copy repository URL
Activity
```

### Developer Command

已实现：

```text
Create
Update
List by Workspace / Project
Category
Pin
Working Directory
Archive
Copy command
Activity
```

Category：

```text
run
build
test
database
docker
git
other
```

### Developer Snippet

已实现：

```text
Create
Update
List by Workspace / Project
Language
Pin
Archive
Copy content
Activity
```

Windows 实际验收覆盖：

```text
[✓] Project / Command / Snippet 创建
[✓] Developer 页面读取
[✓] Search 命中
[✓] AI Context 命中
[✓] 完整重启后数据恢复
```

Update / Primary / Pin / Archive 路径已完成代码级检查；最终 smoke 未逐项重复执行所有编辑组合，不影响 Phase 6 V1 封版结论。

---

## 4. Developer Context Service 验收

输出：

```text
DeveloperContext
├─ projects[]
├─ primaryProject?
├─ commands[]
├─ snippets[]
└─ devResources[]
```

确认：

```text
[✓] UI 不直接跨表拼 Developer Context
[✓] Application Service 负责聚合
[✓] Dev Resource 复用 ResourceModel
[✓] AIContextBuilder 复用 DeveloperContextService
[✓] archived Developer entity 不进入正常聚合
```

---

## 5. Workspace Developer Page 验收

入口：

```text
工作台
→ Workspace
→ 开发
```

Workspace 二级导航：

```text
概览
任务
笔记
问题
资源
决策
开发
```

Developer 页面：

```text
项目
常用命令
代码片段
开发资源
```

Windows 验收：

```text
[✓] 页面正常打开
[✓] 空状态正常
[✓] 新建入口正常
[✓] Project / Command / Snippet 数据正常显示
[✓] Copy 操作边界保持为“复制”，不执行命令
[✓] 页面与 Phase 5 Workbench UI 风格一致
[✓] scrollbar 与内容区保持安全距离
[✓] Windows 桌面布局无明显溢出
```

---

## 6. Search Integration 验收

Developer Search Entity Type：

```text
developer_project
developer_command
developer_snippet
```

索引字段：

```text
Project
- name
- local_path
- repository_url
- branch
- tech_stack
- notes

Command
- name
- command
- working_directory
- category
- notes

Snippet
- title
- language
- content
- notes
```

Windows 实际验证：

```text
cloud_disk
flutter run
snippet / SQL content
```

结果：

```text
[✓] Project 可搜索
[✓] Command 可搜索
[✓] Snippet 可搜索
[✓] Developer entity 中文类型标签正常
[✓] 点击结果进入对应 Workspace Developer Page
[✓] 完整重启后 Search 可重新生成并命中 Developer 数据
```

Search Index 继续作为 Derived / Rebuildable Index，不新增独立业务数据源。

---

## 7. AI Developer Context 验收

链路：

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

Developer Context 策略：

```text
P1 Primary Project
P2 Pinned / selected Command
P2 Dev Resource
P3 Pinned / selected Snippet
```

### Workspace Scope

允许加入：

```text
Primary Project
少量其他 Project
少量 Command
少量 Snippet
Dev Resource
```

### Knowledge / Global

继续通过 SearchService 做小规模相关实体检索，不做 Developer 全库扫描。

Windows 实际验收：

```text
[✓] Task Scope 能看到 Project
[✓] Task Scope 能看到 Command
[✓] Task Scope 能看到 Snippet
[✓] Workspace Scope 能看到 Developer Context
[✓] Developer entity 能进入 AIContextBuilder
[✓] Context Budget 继续生效
[✓] 完整重启后 Developer Context 可重新生成
[✓] AI Drawer 显示“项目 / 命令 / 代码片段”，不暴露内部 entity type
```

Manual include / exclude 继续复用 Phase 5 Context 管理机制；Developer entity 已接入 `_loadEntityItem()`。

---

## 8. Tool Safety Boundary

Phase 6 V1 允许：

```text
展示项目路径
复制项目路径
展示命令
复制命令
展示 Snippet
复制 Snippet
聚合开发资源
```

Phase 6 V1 明确不允许：

```text
自动执行 Shell / PowerShell / Bash
自动执行 Git
自动运行测试
自动启动 Docker
自动修改代码文件
AI Tool Calling / Tool Execution
Terminal Emulator
Embedded IDE
完整 Git Client
文件系统全盘扫描
MCP Runtime
```

Windows 验收未发现隐式执行入口。

---

## 9. Restart Recovery 验收

最终执行：

```text
完整关闭 Windows App
→ 重新 flutter run -d windows
→ 打开同一 Workspace
```

确认：

```text
[✓] schema v6 可再次正常打开
[✓] Project 仍存在
[✓] Command 仍存在
[✓] Snippet 仍存在
[✓] Developer Search 仍可命中
[✓] AI Developer Context 可重新生成
[✓] Phase 1–5 原数据仍存在
```

---

## 10. Phase 1–5 Smoke Regression

最终 smoke 覆盖：

```text
Home
Workspace Overview
Task
Note
Issue
Resource
Decision
Knowledge + Search
AI Drawer
AI History
```

结果：

```text
[✓] 页面可正常打开
[✓] 未出现明显运行错误
[✓] Phase 6 导航没有破坏旧 Workspace Frame
[✓] Search 原有实体继续可用
[✓] AI Drawer 原有 Scope / History 保持可用
```

Phase 6 相对 Phase 5 的代码差异也已做范围检查，主要集中于 Developer Context、Search、AI Context、Workspace 路由 / 页面与 Phase 6 文档，没有发现越界功能扩张。

---

## 11. Flutter Analyze

最终执行：

```powershell
flutter analyze
```

结果仍为：

```text
130 issues found
```

确认：

```text
[✓] 没有 Phase 6 新增 compile error
[✓] 当前仍为项目既有 info / warning
```

不把历史 130 项误判为 Phase 6 error。

---

## 12. Windows Acceptance 最终状态

```text
[✓] Schema v6 migration / persistence
[✓] Developer entity implementation
[✓] Developer Page UI
[✓] Copy-only tool boundary
[✓] Search Integration
[✓] AI Developer Context
[✓] Windows restart recovery
[✓] Phase 1–5 smoke regression
[✓] flutter analyze 无 Phase 6 新增 error
```

**P6.7 Windows Acceptance 正式完成。**

下一步：创建 `PHASE6_BASELINE.md`，记录 Phase 6 封版基线。