# Personal Workbench Phase 7 Acceptance — Settings + Backup

> 状态：P7.1–P7.6 已实现；P7.7 Windows Acceptance 收口中。当前仅剩 Restore 重启恢复、Phase 1–6 smoke regression、最终 `flutter analyze` 三项本机确认。

## 1. 阶段状态

```text
[✓] P7.1 Settings Contract + Scope
[✓] P7.2 Settings Shell + Appearance Integration
[✓] P7.3 General + Notes + Shortcuts
[✓] P7.4 AI Provider Settings
[✓] P7.5 Backup + Export
[✓] P7.6 Restore + Data Safety
[ ] P7.7 Windows Acceptance
[ ] P7.8 Baseline
```

## 2. Settings

最终结构：

```text
设置
├─ 常规
├─ 外观
├─ 笔记
├─ AI
├─ 数据与备份
└─ 快捷键
```

Windows 已确认：

```text
[✓] Settings Shell 正常
[✓] Appearance 正常
[✓] Notes Settings 正常
[✓] Shortcuts 正常
[✓] AI Settings 正常
[✓] Data & Backup 正常
```

## 3. General / Notes / Shortcuts

General：

```text
Default Workspace
Startup Page
Quick Capture → Current Task
Restore Last Active Context
```

Notes：

```text
Markdown (.md)
Default View = Edit / Preview / Split
Auto Save
Ctrl + S Save
Notes Folder read-only
```

Shortcuts：

```text
Ctrl + S      Save Note
Ctrl + Enter  Send AI Message
Esc           Close AI Drawer
```

未实现的全局快捷键明确显示为 `未绑定`。

## 4. AI Provider Settings

支持：

```text
Environment
Preview
DeepSeek
OpenAI Compatible
```

支持配置：

```text
Base URL
Model
Chat Path
Timeout
API Key (session only)
Test Connection
```

安全边界：

```text
API Key 不写入 workbench.db
API Key 不写入普通 SharedPreferences
API Key 不进入 Backup / Export
Session Key 仅在当前 App 进程内存存在
```

## 5. Backup

Backup 覆盖：

```text
workbench.db consistent snapshot
Workspace Markdown
Knowledge Markdown
Attachments
non-secret Workbench / Theme Preferences
manifest.json
```

SQLite 使用 `VACUUM INTO` 生成一致性快照。

支持：

```text
Manual Backup
Auto Backup
Safety Backup
```

Windows 已确认：

```text
[✓] Manual Backup 可创建
```

## 6. Portable Export

Export 与 Backup 分离：

```text
Backup → Restore-oriented
Export → Portable user-owned data
```

Windows UX：

```text
点击“导出”
→ Windows Save-As Dialog
→ 用户选择目录 / 文件名
→ ZIP 写入用户选择的位置
```

已确认：

```text
[✓] Windows Save-As Dialog 正常
[✓] 默认文件名 PersonalWorkbench_Export_*.zip
[✓] Portable Export 可生成 ZIP
```

Portable Export 不能用于 Restore。

## 7. Restore + Data Safety

恢复链路：

```text
Select Backup
→ Validate
→ Confirmation Dialog
→ Safety Backup
→ .pending_restore staging
→ 完全退出 App
→ 下次启动在 DB open 前应用恢复
→ Search Index rebuild
```

安全措施：

```text
[✓] 不在运行时直接覆盖 active SQLite
[✓] Restore 前自动 Safety Backup
[✓] Zip Slip / path traversal 防护
[✓] 只恢复批准的数据目录和 preferences
[✓] Secret preference keys 不恢复
```

Windows 最终待确认：

```text
[ ] Restore confirmation dialog 正常
[ ] Safety Backup 创建成功
[ ] Pending Restore staging 成功
[ ] 完整重启后恢复到 Backup 状态
[ ] Search 在恢复后正常
[ ] AI Context 在恢复后正常
```

## 8. Phase 1–6 Smoke Regression

最终快速确认：

```text
Home
Workspace
Task
Note
Issue
Resource
Decision
Knowledge + Search
Developer
AI Drawer / History
Settings
```

状态：

```text
[ ] final smoke pass
```

## 9. Flutter Analyze

最终封版前执行：

```powershell
flutter analyze
```

验收标准：

```text
[ ] 无 Phase 7 新增 compile error
```

`issues found` 是 analyzer 的 info / warning 汇总，不等同于 compile error。

## 10. Final Gate

```text
[✓] Settings implementation
[✓] AI Provider implementation
[✓] Backup implementation
[✓] Export Save-As implementation
[✓] Restore safety implementation
[ ] Restore restart verification
[ ] Phase 1–6 smoke regression
[ ] final flutter analyze
```

全部完成后：

```text
P7.7 Windows Acceptance ✓
P7.8 PHASE7_BASELINE.md
Windows Desktop V1 Complete
```
