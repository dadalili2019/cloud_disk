# Personal Workbench 测试与验收

## 1. 当前已知验收结果

- v1.4 UI 已逐页 Windows 人工检查
- Windows Release Build 已成功
- flutter analyze 无观察到阻塞性 error
- 当前剩余历史 lint 不作为 Desktop V1 阻塞项

## 2. Desktop Smoke Regression

### Shell

- 登录
- Workspace Switcher
- Search
- AI Drawer
- Settings
- Sidebar Route Highlight
- Resize

### Home

- Current Task
- Next Step
- Blocker
- Progress
- Last Context
- Today
- Recent Activity
- Quick Capture
- Continue

### Workspace

- Create
- Rename
- Archive
- Restore
- Switch

### Task

- Create
- Edit
- Current Task
- Status
- Progress
- Complete

### Notes

- Create
- Edit
- Auto Save On
- Auto Save Off
- Ctrl+S
- Link to Current Task
- Restart Recovery

### Issue / Resource / Decision

分别验证 CRUD、关联、重启恢复。

### Knowledge

- Manual Create
- Edit
- Distill
- Category
- Pin
- Source Relation
- Restart Recovery

### Search

- Task
- Note
- Issue
- Resource
- Decision
- Knowledge
- Project
- Command
- Snippet
- Numeric substring
- Chinese text
- Rebuild Index

### Time

- Start Focus
- Prevent duplicate active session
- Finish
- Today Total
- Timeline

### Developer

- Project CRUD
- Primary
- Command CRUD / Pin
- Snippet CRUD / Pin
- Dev Resource
- Copy
- Search

### AI

- Provider Settings
- Test Connection
- Task Scope
- Workspace Scope
- Knowledge Scope
- Global Scope
- Context Preview
- Include / Exclude
- Send
- Retry
- Thread Rename
- Archive
- Restart Recovery

### Backup

- Manual Backup
- Auto Backup
- Retention
- Safety Backup

### Export

- ZIP
- Markdown
- JSON
- Attachments option
- No API Key

### Restore

完整验收流程：

~~~text
创建明显测试数据
→ Manual Backup
→ 修改数据
→ Restore Backup
→ Safety Backup
→ Exit
→ Restart
→ Verify old state restored
→ Search works
→ AI Context works
~~~

## 3. Build Gate

~~~powershell
flutter pub get
flutter analyze
flutter build windows
~~~

## 4. 当前 Analyze 基线

当前历史 lint 数量会随清理变化，不把“必须为 0”作为 V1 Gate。

Gate 为：

- 无 compile error
- 新增功能不引入明确 warning
- Release Build 成功

## 5. 后续应补自动化测试

优先：

1. Repository / Service unit tests
2. Task current constraint
3. Knowledge source links
4. Search query / fallback
5. Backup manifest
6. Restore validation
7. AI Context budget
8. Settings persistence
9. Widget smoke tests
