# Personal Workbench 测试与验收

## 1. 验收原则

不是“页面能打开”就算完成。

至少确认：

- 功能行为正确。
- 数据能保存。
- 重启以后数据还在。
- 异常有兜底。
- Analyze 没有新 warning。
- Test 能跑。
- Windows Release Build 能过。

## 2. Desktop Smoke Regression

### Shell

- Login
- Workspace Switcher
- Search
- AI Drawer
- Settings
- Sidebar Route Highlight
- Resize
- Tray 打开 / 退出

### Home / Workspace

- Current Task
- Next Step
- Blocker
- Progress
- Continue
- Quick Capture
- Workspace Create / Rename / Archive / Restore / Switch

### Task / Notes

- Task CRUD / Current / Status / Progress
- Note Create / Edit / Auto Save / Ctrl+S
- Link to Current Task
- Restart Recovery

### Issue / Resource / Decision

分别验证 CRUD、关联和重启恢复。

### Knowledge / Search

- Knowledge Create / Edit / Distill / Category / Pin
- Search Task / Note / Issue / Resource / Decision / Knowledge / Developer
- Chinese text
- Numeric substring
- Rebuild Index

### Time / Developer / AI

- Focus Start / Finish / Today Total
- Developer Project / Command / Snippet / Resource
- AI Provider / Context Preview / Scope / Send / Retry / History / Restart Recovery

### Backup / Export / Restore

- Manual / Auto / Retention / Safety Backup
- Export ZIP / Markdown / JSON
- Export 不包含 API Key
- Restore Validate / Stage / Restart Apply / Search rebuild

## 3. 当前验证基线

当前已确认的静态检查基线：

~~~text
flutter analyze
→ No issues found
~~~

测试套件已经持续扩展，不再在文档里写死测试数量。每次核心改动合并后，以本地 `flutter test` 实际结果为准。

`flutter build windows` 继续作为合并和发布前必须执行的 Gate，不在没有真实执行结果时写成“已通过”。

## 4. 自动检查 Gate

本地提交前：

~~~powershell
flutter pub get
flutter analyze
flutter test
flutter build windows
~~~

GitHub Actions：

~~~text
Pull Request
→ flutter pub get
→ flutter analyze
→ flutter test

main push / 手工触发
→ Analyze + Test
→ flutter build windows --release
→ Windows Release Artifact
~~~

当前已经开始把 Analyze 当成真正约束：

- `avoid_print: true`
- 文件名统一 snake_case
- 历史临时测试脚本已删除
- 已加入 Workbench utility 单元测试

后面不要再默认用“历史 lint 很多，所以先不管”作为处理方式。新 warning 优先解决。

## 5. 自动化测试优先级

已经开始补：

- AI Context Budget：预算、P0 保留、最大条数、excluded。
- SearchService：rebuild、freshness window、并发 rebuild 合并、查询参数透传。

本轮继续补：

- Search Repository：空查询、FTS + LIKE 合并、FTS 失败 fallback、过滤、LIKE 转义、limit clamp、replace 顺序。
- Restore Validator：有效 manifest、路径穿越、绝对路径、缺失数据库、format version、future schema、损坏 ZIP。

本轮继续补：

- Search 完整 rebuild：Service 组装 Entry、Repository 批量写入、100 条分批。
- Backup ZIP：manifest、数据库快照、Markdown / Attachment、portable settings、敏感配置排除。

本轮继续补：

- Restore staging：Safety Backup、允许路径、pending marker、settings sanitize。
- Restore next-start apply：DB / WAL / SHM、Workspace / Knowledge / Attachment、portable settings、pending cleanup。
- Restore preflight：损坏 settings / missing DB 不覆盖当前数据。

当前开始进入业务规则测试：

- Task create / update / done / current / activity。
- Workspace create / slug unique / directory / activity。
- Workspace rename / archive / restore / activity。

本轮继续补：

- Knowledge create / update / Markdown / Search Index。
- Knowledge derived_from source links / applies_to Task。
- Knowledge 文件名冲突和 create 失败后的 Markdown 清理。
- Settings defaults / persistence / enum fallback。
- AI timeout、Backup retention 边界。
- Session API Key 只保存在内存，不进入 SharedPreferences。
- Last Active Location 白名单。

本轮继续补：

- Task Repository 使用真实 SQLite Schema 验证 Current Task 唯一索引。
- Repository 测试通过 in-memory SQLite 运行，不依赖正式环境的 background isolate。
- 文件型 Migration Test 关闭 prepared statement cache，减少 Windows 临时数据库文件句柄延迟释放。
- Task Repository 测试只初始化它真实依赖的 Schema v1，不被 Knowledge / AI / Developer 等后续 Schema 干扰。
- 验证 setCurrent 事务切换和失败回滚。
- 验证 Done Task 不能成为 Current。

本轮继续补：

- Knowledge create 在 Entity Link / Search Index 失败时反向补偿。
- Knowledge update 在 Search Index 失败时恢复旧 Markdown / Repository / Index。
- 补偿失败不覆盖原始业务异常。

本轮继续补：

- Fresh Database 直接创建当前 Schema v6。
- v1 / v2 / v3 / v4 / v5 → v6 Migration。
- Migration 后旧数据保留。
- Migration 后 Current Task / Developer Primary 唯一约束仍然生效。
- FTS search_index 在支持 FTS5 的 SQLite Runtime 下可用。
- Windows `flutter test` 使用宿主 Dart VM SQLite，原生 Flutter SQLite 插件不会参与；因此该环境跳过 FTS5 建表和 FTS 断言，其他 Schema / Migration / Index / Transaction 仍真实执行。
- targetSchemaVersion 非法输入边界。

GitHub Actions CI 已建立第一轮 Windows Gate。

本轮继续补：

- OpenAI-compatible Provider endpoint / header / prompt。
- Timeout / network / HTTP 4xx/5xx。
- 非法 JSON / Empty Response / Long Response。
- Multimodal-style content array。
- Retry History 不重复带入最后一条已持久化 User Message。
- AI Conversation anchor / archived / title / context snapshot。
- SQLite Thread / Message 持久化和关闭重开恢复。

Image Tools 第一轮公共基础测试已补：

- JPG / PNG 输出格式与编码。
- 文件大小格式化。
- 默认输出目录创建。
- 自定义输出目录创建。

Image Tools 第二轮公共逻辑测试已补：

- Preview 大图等比缩放 / 小图保持尺寸。
- Preview PNG 编码。
- 空文字水印不改图。
- 文字水印实际绘制。
- Batch success / failure / progress。
- Batch 中途停止。

Notes Editor 保存一致性测试已补：

- Save Coordinator reset / dirty state。
- 手动保存期间继续编辑，旧保存完成后仍保持 dirty。
- Auto Save 串行写入，保存期间继续编辑会继续写入最新 revision。
- 第二次显式保存会排在正在执行的写入之后。
- 保存失败继续保持 dirty，不误标记为已保存。

Notes Editor 展示职责拆分与第一批 Widget Smoke Test 已完成。

当前自动化基线已覆盖：

- WorkbenchCard / WorkbenchTag / WorkbenchEmptyState / WorkbenchSectionPage mount 与基础交互。
- Notes Editor Save Coordinator 保存时序。
- 核心 Service / Repository / Migration / AI / Search / Backup / Restore / Image Tools 规则。

下一阶段测试重点：

1. 真实 AI Gateway / API Key / Provider Integration。
2. Windows Release Artifact 启动与升级 Smoke。
3. 合成数据量 Search / Backup / Restore 手工验证入口已建立；执行真实规模基准并记录结果。

测试必须可重复，不依赖个人电脑绝对路径、手工准备文件、固定账号或某个外网服务永远可用。

## 6. 本轮代码清理回归重点

- Login 能进入 Workbench。
- Settings 能打开。
- Tools 卡片都能进入对应工具。
- Workspace Overview 正常。
- Global Shell 路由高亮正常。
- System Tray 文案已经是 Personal Workbench。
- 已删除的旧 cloud disk route 不再被引用。
