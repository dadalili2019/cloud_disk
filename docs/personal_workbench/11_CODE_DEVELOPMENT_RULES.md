# Personal Workbench 代码开发原则

这份文档是后面写代码的长期规则。

不管是我自己改、让 Codex 改，还是让其他 AI 写，默认都要按这里来。不是要求代码写得很“高级”，而是希望项目后面越来越容易看、容易改、容易排错，不要越写越乱。

## 1. 先说最重要的

1. 先把问题搞清楚，再写代码。
2. 能用简单方式解决，就不要做复杂设计。
3. 该抽象的抽象，不该抽象的不要硬抽象。
4. 重复逻辑要收口，但不要为了少两行代码做一层没意义的封装。
5. 重构现有功能时，优先保持业务行为不变。
6. 新增功能要考虑异常、性能、数据和后续维护。
7. 代码改了，相关文档一起改。
8. 没有用的代码直接删，不留“以后可能会用”的垃圾。
9. 不要用 TODO 代替本次应该完成的事情。
10. AI 不能只追求“能跑”，要把代码当长期维护代码写。

## 2. 目录怎么放

~~~text
lib/
├─ app/            # Shell、导航、托盘等应用级能力
├─ pages/          # Login、Settings、独立工具
├─ router/         # 路由
├─ theme/          # 主题
├─ widgets/        # 真正跨模块复用的组件
└─ workbench/
   ├─ application/ # 业务用例和服务
   ├─ core/        # Model、DB、Path、Settings
   ├─ data/        # Repository 实现
   ├─ domain/      # Repository / Provider 接口
   ├─ presentation/# 页面、Drawer、Dialog、UI State
   └─ workbench_runtime.dart
~~~

不要：

- 为一个文件随便再建一层目录。
- 把不知道放哪的东西全部丢进 `utils`。
- 再建 `bak`、`temp`、`old`、`v2`、`phase2` 这种当前代码目录。
- 在仓库里保留旧实现副本。真要找旧代码，用 Git History。

## 3. 命名

Dart 文件：

~~~text
snake_case.dart
~~~

类：

~~~text
PascalCase
~~~

变量、方法：

~~~text
camelCase
~~~

名字要表达业务含义，例如：

~~~text
currentWorkspace
activeTask
searchResults
backupDirectory
contextBudget
~~~

不要默认用：

~~~text
tmp
data1
list2
obj
xx
NewHomeV2
Phase2Service
TempSettings
~~~

循环里的 `i`、坐标 `x/y` 这种上下文非常明确的情况除外。

`v2` 只有真的是 API、Schema、文件格式版本时才用。

## 4. 注释怎么写

我需要注释，但不是每一行都写中文解释。

主要写：

### 为什么这么做

~~~dart
// Restore 不能直接覆盖正在使用的 SQLite 文件，
// 所以这里只 staging，下一次启动前再替换。
~~~

### 容易踩坑的边界

~~~dart
// Auto backup 失败不能阻塞应用启动。
~~~

### 不明显的业务规则

~~~dart
// 同一个 Workspace 同一时间只能有一个 current task。
~~~

### 核心接口说明

复杂 Service、Repository、核心 Model 可以写简短 doc comment。

不要写这种没有信息量的注释：

~~~dart
// 设置 loading 为 true
_loading = true;

// 调用 load 方法
await load();
~~~

也不要长期保留“优化版”“新版”“临时”“后续再改”这类很快过期的注释。

## 5. 一个函数做多少事

一个方法尽量只处理一个明确动作。

如果一个方法同时做数据库、Prompt、文件、Dialog、UI、日志，基本就应该拆。

出现这些情况就检查：

- 方法需要一直往下翻。
- if / switch 嵌套很多。
- 参数越来越多。
- 同一段逻辑出现两次以上。
- 方法名字已经说不清它到底负责什么。

但不要机械规定“超过 20 行必须拆”。有些顺序明确的业务编排 30～50 行反而比拆成很多一行方法更容易看。

## 6. 文件大小

不是硬规定，但要有警觉：

- 200～400 行：通常正常。
- 400～700 行：检查职责是不是开始混。
- 700 行以上：默认检查是否应该拆。
- 1000 行以上：没有明确理由就不要继续往里加。

当前优先关注：

- `global_ai_drawer.dart`
- `workbench_home_page.dart`
- `workbench_knowledge_page.dart`
- `workbench_developer_page.dart`
- Workspace Overview 页面
- `ai_context_builder.dart`

拆的时候按职责拆，不按“每 300 行切一个文件”。

## 7. UI 代码

Presentation 层负责展示、输入、页面状态和调用 Application Service。

不要在 Widget 里直接写：

- 复杂 SQL
- 大段文件处理
- 大段业务规则
- 网络协议拼装

注意 rebuild：

- 一个小状态不要让整个超大页面反复 rebuild。
- 能用局部 StatefulWidget / 小组件隔离就隔离。
- 不在 `build()` 里做 IO、数据库查询和网络请求。
- Future 不要每次 build 都重新创建，除非就是要刷新。

长列表优先考虑 `ListView.builder`、分页、limit、lazy rendering，不要默认一次 build 几千个 Widget。

## 8. 异步和性能

不要在 UI isolate 做明显重活：

- 大图片处理
- 大文件解析
- 大量 JSON / ZIP
- 大规模索引重建

数据量上来以后要考虑 isolate / background 处理。

同一次操作已经查到的数据，能复用就复用。避免重复 IO 和 N+1 查询。

数据库注意：

- 查询限制范围。
- 高频查询看索引。
- 批量写入优先 transaction。
- Schema 变更必须有 migration。
- 不要在循环里无脑一条一条查数据库。

Search Index 是可重建数据，不是事实数据唯一来源。

## 9. 错误处理

不要大范围这样写：

~~~dart
try {
  ...
} catch (_) {}
~~~

只有“失败明确可以忽略”的地方才能吞异常，而且要写为什么。

例如：

~~~dart
// Tray 初始化失败不影响主应用启动。
~~~

业务失败要让上层知道。

UI 至少区分：

- loading
- empty
- error
- normal

普通用户界面不要直接展示一大串底层异常；开发日志可以保留详细上下文。

## 10. 日志

正式代码不要直接 `print()`。

当前已开启：

~~~yaml
avoid_print: true
~~~

后面真需要日志时，统一做日志入口，不要不同页面自己随便打印。

不要记录：

- API Key
- 完整敏感 Header
- 大段用户正文
- 不必要的个人文件内容

## 11. 数据和安全

API Key：

- 不写 SQLite。
- 不进入 Backup。
- 不进入 Export。
- 不写普通日志。

路径：

- 不写死个人电脑绝对路径。
- 统一通过 `AppPaths` 或用户选择路径。

删除、覆盖、Restore 这种不可逆操作要明确确认。

写文件优先 atomic write。

数据库和 Markdown 同时变化时，要考虑中途失败以后怎么补偿。

## 12. 抽象原则

应该抽象：

- 同一个业务规则出现多处。
- 同一种数据访问需要统一边界。
- UI 组件真的重复使用。
- 外部 Provider 需要可替换。
- 一段逻辑有明确独立职责。

不要为了“架构漂亮”变成：

~~~text
AService
→ AManager
→ AHandler
→ AExecutor
→ AHelper
~~~

最后每层只转发一行。

也不要提前设计根本还不存在的扩展点。

## 13. 依赖

新增 package 前先问：

1. Dart / Flutter 自己能不能简单解决？
2. 当前项目是不是已经有同类依赖？
3. 这个包还在维护吗？
4. 为一个小功能引一个大包值不值？
5. Windows 是否支持？

不用的依赖及时删。

不要因为 AI 熟悉某个库，就直接往项目里加。

## 14. 测试

新业务逻辑优先补 unit test，特别是：

- 数据转换
- 文件名 / 路径
- Repository
- Service
- Search
- Backup / Restore
- AI Context
- Settings

测试必须可重复。

不要出现：

~~~text
C:\Users\xxx\Desktop\...
~~~

不要依赖个人电脑提前存在某个文件。

Bug 修复如果适合自动化复现，优先先补失败测试，再修。

## 15. 性能不是最后才看

写代码时就问：

- 这个列表最多多少条？
- 这个操作会不会每次 build 都执行？
- 会不会重复读文件？
- 会不会产生 N+1 SQL？
- 图片是不是一次把原图全读进内存？
- 搜索是不是每敲一个字符就做重活？
- AI Context 是不是把不需要的正文也全部加载？

但是也不要没有瓶颈证据就做复杂微优化。

先把结构写对，再优化真正热点。

## 16. AI / Codex 改代码必须遵守

### 改之前

- 先读相关代码和文档。
- 先确认当前真实实现，不根据文件名猜。
- 找到调用链再改。
- 判断有没有历史代码可以直接删。
- 不要重复实现已有能力。

### 改的时候

- 保持现有产品边界。
- 不随便引入新框架。
- 不随便改数据库 Schema。
- 不为了重构顺手改变 UI 行为。
- 不制造新的超大文件。
- 不保留死代码。
- 不加无意义注释。
- 文件名和目录按当前规范。
- 处理 loading / empty / error。
- 考虑性能和数据量。
- 涉及数据安全时优先保守。

### 改完以后

AI 要明确告诉我：

- 改了哪些文件。
- 删除了哪些文件。
- 为什么改。
- 有没有行为变化。
- 有没有数据库 / 配置变化。
- 有没有需要我手工操作的地方。
- 应该执行哪些验证命令。

至少验证：

~~~powershell
flutter analyze
flutter test
flutter build windows
~~~

如果当前环境不能执行，要明确写“未执行”，不能默认说已经通过。

## 17. 文档怎么跟代码走

~~~text
功能行为       → 02_FUNCTIONAL_SPEC.md
UI / 交互      → 03_UI_UX_DESIGN.md
架构 / 目录    → 04_TECHNICAL_ARCHITECTURE.md
数据 / Schema  → 05_DATA_AND_STORAGE.md
AI / Search    → 06_AI_SEARCH_KNOWLEDGE.md
运行 / 发布    → 07_IMPLEMENTATION_OPERATIONS.md
测试 / 验收    → 08_TESTING_ACCEPTANCE.md
进度 / Roadmap → 09_STATUS_ROADMAP.md
编码原则       → 11_CODE_DEVELOPMENT_RULES.md
~~~

不是每次都新增文档。优先更新现有主题文档。

## 18. 提交前自己检查

- 有没有明显重复？
- 有没有不用的 import / class / package？
- 命名能不能直接看懂？
- 复杂地方有没有解释“为什么”？
- 有没有吞异常？
- 有没有个人绝对路径？
- 有没有敏感信息？
- 有没有主线程重活？
- 有没有 N+1 查询？
- 文件是不是已经太大？
- 该补的测试补了吗？
- 文档要不要同步？

## 19. 最终希望代码是什么样

不是代码行数最少，也不是架构层数最多。

我希望它是：

- 目录一看就知道东西放在哪里。
- 打开一个类能比较快看懂它负责什么。
- 出问题以后能定位。
- 加功能不用到处改。
- 删除功能能删干净。
- 数据安全。
- 性能没有明显低级问题。
- AI 后面继续写代码，也不会把项目越写越乱。

这就是这份规范的目的。
