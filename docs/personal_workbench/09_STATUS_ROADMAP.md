# Personal Workbench 当前状态与 Roadmap

## 1. 当前状态

截至 Personal Workbench v1.4 合并到 main：

### 已完成

- Global Shell
- Home
- Workspace Core
- Task
- Note
- Issue
- Resource
- Decision
- Time / Focus
- Knowledge
- Search
- Developer Context
- Global AI
- AI History
- Settings
- Backup
- Export
- Restore
- Tool Shell
- Windows UI Polish
- Windows Release Build

## 2. 当前不是“继续加页面”的阶段

下一阶段应进入 Hardening。

## 3. Phase A — Desktop Hardening

优先级最高。

内容：

- 回归测试
- 新代码 warning 清理
- 历史 lint 分批偿还
- Notes Auto Save Off 边界保护复核
- Search consistency
- Restore full verification
- Error state
- Long text / resize regression

## 4. Phase B — AI Real Environment Verification

目标：

~~~text
Provider Config
→ Test Connection
→ Global AI
→ Context Builder
→ Provider
→ Markdown Result
→ Conversation Persistence
→ Restart Recovery
~~~

补充：

- 真实 Gateway
- 真实 API Key
- Timeout
- HTTP error
- Empty response
- Long response

## 5. Phase C — Search / Backup / Restore Hardening

Search：

- 修改后即时同步
- 重建索引性能
- 中文 relevance
- 大数据量性能

Backup / Restore：

- 完整灾难恢复演练
- Manifest compatibility
- Corrupted ZIP
- Missing DB
- Search rebuild

## 6. Phase D — Automated Test + CI

当前 GitHub 无正式 CI。

建议 GitHub Actions：

~~~text
flutter pub get
flutter analyze
flutter test
~~~

可选：

~~~text
flutter build windows
~~~

Windows Build 较慢，可只在 release / merge 时执行。

## 7. Desktop Stable Baseline

完成 A–D 后标记：

~~~text
Personal Workbench Desktop Stable V1
~~~

## 8. Phase E — Mobile Adaptation

当前未开始。

需要重新设计：

- Navigation
- Small-screen Layout
- Touch Target
- Drawer / Dialog
- File Picker
- Local Storage Path
- Backup / Export
- AI Drawer
- Workspace Tabs

Mobile 不应直接复制 Desktop UI。

## 9. 非当前 Roadmap

以下除非需求明确变化，否则不进入最近计划：

- Cloud Sync
- Team Collaboration
- Account System
- CRDT
- Real-time Multi-device
- Autonomous Coding Agent
- Shell Execution
- Embedded IDE
- Full Git Client
- Plugin Marketplace
