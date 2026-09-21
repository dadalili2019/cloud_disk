# Personal Workbench 代码优化与整理计划

这份文档以后作为 Personal Workbench 持续优化的主计划。

我的想法不是为了“重构”而一直改代码，也不是看见文件长就拆。现在功能已经比较完整，后面的重点应该是：把业务规则锁住、把数据安全做好、把异常和性能问题处理掉，再去整理真正影响维护的结构。

后面不管是我自己改，还是让 AI / Codex 改，都按这里的顺序推进。

## 1. 当前状态

已经完成的一轮基础整理：

- 早期 cloud disk 历史代码基本清掉。
- 当前业务目录和文件名已经收口。
- Analyzer 已经清到可作为 Gate 使用。
- Settings / Workspace / Home / Knowledge / Developer 等大页面做过第一轮职责拆分。
- AI Context Builder 已经拆分。
- Global AI Drawer 已完成第一阶段 UI helper / formatter 拆分。
- Search 完整 rebuild 已做第一轮 batch / transaction 优化。
- Backup / Restore 已经补了 manifest、路径安全、staging、next-start apply 等测试。

所以后面不再把“继续拆大文件”当主线。

## 2. 后面优化的顺序

### 第一批：业务规则测试

先把最重要的业务规则变成自动化测试。

优先：

1. Task
   - Title 校验
   - Status / Progress 校验
   - Done 后 Progress = 100
   - Done 后不能继续作为 Current
   - Set Current 行为和 Activity
   - 同一个 Workspace 只能有一个 Current Task

2. Workspace
   - Create / Rename
   - Archive / Restore
   - Slug 唯一
   - Activity

3. Knowledge
   - Source Link
   - derived_from
   - Create / Update / Archive
   - Markdown 和数据库关系

4. Settings
   - 持久化
   - 默认值
   - 敏感字段不进入普通持久化
   - Backup / Restore portable settings

这一批的目标不是追求测试数量，而是把最容易因为重构被破坏的规则锁住。

### 第二批：Database Schema / Migration

数据库 Schema 已经进入长期维护阶段，这一批优先级很高。

要覆盖：

~~~text
Fresh Database
→ 当前 Schema 创建成功

Old Schema
→ Migration
→ 当前 Schema

Migration 后：
→ 表还在
→ 字段还在
→ Index 还在
→ FTS 还在
→ 原数据不丢
→ Current Task 约束仍然成立
~~~

以后每次 Schema Version 增加，都必须同时补 Migration Test。

### 第三批：GitHub CI

仓库需要增加自动检查。

Pull Request 最低执行：

~~~text
flutter pub get
flutter analyze
flutter test
~~~

Windows Build 放在 main / release 阶段：

~~~text
flutter build windows
~~~

目标是以后 AI 或人工提交代码，只要 Analyzer 或 Test 被破坏，GitHub 就能直接发现。

### 第四批：AI 异常链路

AI 功能后面不要只验证“正常返回”。

要补：

- Timeout
- HTTP 4xx / 5xx
- 非法 JSON
- Empty Response
- Long Response
- Retry
- Conversation Failure State
- Restart Recovery
- Context 超预算

先补测试，再判断 Global AI Drawer 的 State 要不要继续拆。

### 第五批：Image Tools 重复代码

目前 Image Convert / Watermark / Crop 有比较明显的重复逻辑。

后面重点看：

- Pick Images
- Output Directory
- Preview
- Run / Retry
- Failed Task
- Progress
- Card
- File Size / File Name

可以整理成共享的 Model / File Service / Widget，但不要做一个什么都能配置的“万能 Image Tool Framework”。

### 第六批：Navigation / Notes Editor

这两块仍然比较大，但功能边界目前还算清楚。

后面只有在确认职责混合、重复代码或者测试困难时再拆：

- Navigation Shell
- Topbar
- Sidebar
- Content Frame
- Notes List
- Editor
- Preview
- Save State

不是因为文件超过 500 行就必须拆。

### 第七批：剩余工程收口

最后再处理：

- 依赖审计
- Asset 审计
- Release Package / executable 命名
- Global AI Drawer 第二阶段
- Runtime Composition
- Issue / Resource / Decision 公共 UI
- Widget Smoke Tests

## 3. 每一轮怎么做

以后每一轮优化固定按这个节奏：

~~~text
先确认真实问题
→ 看调用链和现有测试
→ 判断是否需要先补测试
→ 独立分支修改
→ 不顺手改无关功能
→ flutter analyze
→ flutter test
→ 必要时 flutter build windows
→ 人工 Smoke Test
→ 同步文档
→ 合并 main
~~~

如果当前环境不能执行 Flutter 命令，就明确写“未执行”，不能默认说通过。

## 4. 什么情况下该重构

满足下面一种或多种情况再动：

- 同一个业务规则出现多份。
- 一个文件开始同时负责多个不相关职责。
- 修改一个小功能需要跨很多无关代码。
- 测试很难写，因为依赖绑得太死。
- 存在重复 IO / N+1 / 明显性能问题。
- 异常边界不清楚。
- 数据安全风险。
- 历史代码已经没有引用。
- 命名已经不能表达当前业务。

单纯因为“行数多”不作为充分理由。

## 5. 性能优化怎么做

性能不要靠感觉。

顺序：

~~~text
先确认热点
→ 用测试锁住行为
→ 找真正的 IO / SQL / rebuild 问题
→ 做最小优化
→ 再验证
~~~

优先关注：

- Database round-trip
- N+1
- 重复文件读取
- 重复 Markdown 加载
- Search rebuild
- AI Context
- 大图片处理
- 大列表 Build

没有证据时，不引入复杂缓存、线程池或者额外状态层。

## 6. 数据和不可逆操作

涉及这些内容时，优先级高于代码“好不好看”：

- Database Migration
- Backup
- Restore
- Delete
- Archive
- 文件覆盖
- API Key
- Export

必须考虑：

- 中途失败
- 数据能否回滚
- 是否有 Safety Backup
- 是否有路径安全
- 敏感数据是否泄漏
- 是否可以自动化测试

## 7. 每批完成标准

一批优化只有满足下面这些才算结束：

- 修改目标明确。
- 没有顺手改变无关业务。
- 没有新增 Analyzer issue。
- 能自动化的规则已经补测试。
- 涉及数据时异常边界已考虑。
- 文档和代码一致。
- 删除掉确认无用的旧代码。
- 没有为了“以后可能有用”保留第二套实现。

## 8. 当前近期执行顺序

当前进度：

- Task / Workspace 业务规则测试：第一轮完成，Repository 真实数据库约束也已补。
- Knowledge / Settings 业务规则测试：第一轮完成。
- Knowledge 跨 Markdown / SQLite / Link / Search 的失败补偿：第一轮加固完成。
- Database Schema / Migration 第一轮测试已完成：Fresh v6 + v1~v5 → v6。
- AI Provider / Conversation 异常测试第一轮已完成并合并。
- Image Tools 第一轮公共基础层抽取已完成并合并。
- Image Tools 第二轮 Preview / Watermark / Batch 公共纯逻辑整理进行中。

现在按这个顺序继续：

~~~text
1. Task / Workspace 业务规则测试（第一轮已完成）
2. Knowledge / Settings 业务规则测试（第一轮已完成）
3. Database Schema / Migration 测试（第一轮已完成）
4. GitHub Actions CI（第一轮已完成）
5. AI Provider / Conversation 异常测试（第一轮已完成）
6. Image Tools 重复逻辑整理（第一轮已完成，第二轮进行中）
7. Navigation / Notes Editor
8. 剩余依赖 / Asset / Release 收口
~~~

如果中途发现明确 Bug、数据安全问题或严重性能问题，可以插队，但要在 Roadmap 里写清楚为什么。

## 9. 和其他文档的关系

这份文档负责“后面按照什么顺序优化”。

具体编码方式看：

[11_CODE_DEVELOPMENT_RULES.md](11_CODE_DEVELOPMENT_RULES.md)

当前进度看：

[09_STATUS_ROADMAP.md](09_STATUS_ROADMAP.md)

每轮历史记录看：

[10_VERSION_HISTORY.md](10_VERSION_HISTORY.md)

以后不要再单独创建一堆临时优化计划。新的优化项优先补到这里。
