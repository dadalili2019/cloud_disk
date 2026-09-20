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

2026-09-20 当前本地验证结果：

~~~text
flutter analyze
→ No issues found

flutter test
→ 4 tests passed
~~~

`flutter build windows` 继续作为合并和发布前必须执行的 Gate，不在没有真实执行结果时写成“已通过”。

## 4. 自动检查 Gate

~~~powershell
flutter pub get
flutter analyze
flutter test
flutter build windows
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

下一批：

1. Search Repository：FTS + LIKE fallback、过滤、limit。
2. Backup manifest / portable settings。
3. Restore validation / 路径安全。
4. Repository / Service unit tests。
5. Task current constraint。
6. Knowledge source links。
7. Settings persistence。
8. Widget smoke tests。

测试必须可重复，不依赖个人电脑绝对路径、手工准备文件、固定账号或某个外网服务永远可用。

## 6. 本轮代码清理回归重点

- Login 能进入 Workbench。
- Settings 能打开。
- Tools 卡片都能进入对应工具。
- Workspace Overview 正常。
- Global Shell 路由高亮正常。
- System Tray 文案已经是 Personal Workbench。
- 已删除的旧 cloud disk route 不再被引用。
