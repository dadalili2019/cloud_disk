# Personal Workbench Phase 7 Scope — Settings + Backup

> Phase 6 已完成 Developer Context + Tools，并形成正式 Windows Desktop 基线。Phase 7 不重新设计 Personal Workbench 的整体 UI，而是复用早期 `personal_workbench_full_v1_3_settings.html` 的 Settings 原型，将尚未落地的设置、备份、导出与恢复能力正式实现到当前 Flutter Workbench。

## 1. Phase 7 目标

Phase 7 的核心目标：

> 让 Personal Workbench 从“功能已经可用”进入“可以长期稳定使用、可配置、可迁移、可恢复”的 Desktop V1 状态。

最终结构：

```text
Settings
├─ General
├─ Appearance
├─ Notes
├─ AI
├─ Data & Backup
└─ Shortcuts
```

其中：

```text
Data & Backup
├─ Local Data
├─ Backup
├─ Export
├─ Restore
└─ Danger Zone
```

Phase 7 完成后，Windows Desktop V1 主功能线即完成。

---

## 2. UI 基线：不重新设计

Phase 7 UI 继续复用既有整体 HTML 原型：

```text
personal_workbench_full_v1.html
personal_workbench_full_v1_3_settings.html
```

原型已经确定：

```text
Settings Page
├─ 左侧 Settings Navigation
│  ├─ General
│  ├─ Appearance
│  ├─ Notes
│  ├─ AI
│  ├─ Data
│  └─ Shortcuts
└─ 右侧 Settings Content
```

Desktop 布局继续采用：

```text
约 190px Settings Navigation
+
自适应 Settings Content
```

不再新做一套 Settings HTML。

Flutter 实现视觉基线以当前 Phase 6 `ThemePalette + Workbench Shell` 为准，而不是机械恢复旧 HTML 的深色配色。

原则：

```text
保留旧原型的信息架构与交互
复用当前 Flutter 的视觉 token / card / border / typography
```

---

## 3. 当前代码与原型差距

### 3.1 General

旧原型已有：

```text
Default Workspace
Startup Page
Quick Capture → Current Task
Restore last active context
```

当前状态：

```text
未形成 Workbench General Settings
```

Phase 7 V1 实现。

### 3.2 Appearance

旧原型已有：

```text
Theme
Density
Reduce helper text
```

当前 Flutter 已实现：

```text
Theme Preset
Theme Mode
Accent Color
Font Family
Preview
Reset Default
```

并通过：

```text
ThemeController
SharedPreferences
```

持久化。

Phase 7 不重写 ThemeController。

Phase 7 工作：

```text
把现有 Appearance 页面纳入统一 Settings Shell
保持现有 ThemePreset / Mode / Accent / Font
Density / Reduce helper text 暂不强制实现，除非现有页面确有实际消费场景
```

### 3.3 Notes

旧原型已有：

```text
Storage Format = .md
Default View = Split / Edit / Preview
Auto Save
Notes Folder
```

当前 Note 已经使用 Markdown 文件存储，但这些行为还没有统一 Settings UI。

Phase 7 V1：

```text
Storage Format
→ 只读显示 Markdown (.md)

Default View
→ Split / Edit / Preview

Auto Save
→ bool

Notes Folder
→ 显示实际 AppPaths Workspace Notes 位置
→ V1 不允许任意迁移根目录
```

避免允许用户随意修改 Notes Folder 导致数据库中的相对路径与文件实际位置失配。

### 3.4 AI

旧原型已有：

```text
Include linked context
Include Knowledge
Context Scope
AI Entry
```

Phase 5–6 后实际 AI 架构已经升级为：

```text
Task / Workspace / Knowledge / Global Scope
AIContextBuilder
Context Budget
PromptBuilder
Provider
```

当前 Provider 参数仍主要来自：

```text
WORKBENCH_AI_BASE_URL
WORKBENCH_AI_MODEL
WORKBENCH_AI_API_KEY
WORKBENCH_AI_CHAT_PATH
WORKBENCH_AI_API_KEY_HEADER
WORKBENCH_AI_API_KEY_PREFIX
WORKBENCH_AI_EXTRA_HEADERS_JSON
WORKBENCH_AI_TIMEOUT_SECONDS
```

Phase 7 AI Settings 以“Provider 配置”为重点，不重新提供已经在 Drawer 中存在的 Scope 选择。

V1 Settings：

```text
Provider Type
Base URL
Model
Chat Path
Timeout
API Key
Connection Status
Test Connection
```

约束：

```text
API Key 不写入 Workbench SQLite
API Key 不写入普通 SharedPreferences
API Key 不进入 Backup / Export
```

非敏感 Provider 设置可本地持久化。

API Key 应使用操作系统安全凭据存储；若 Windows secure storage 接入在本阶段产生兼容性阻塞，则保留 Environment / dart-define 作为 fallback，但不降低为明文 SharedPreferences。

Phase 5 的环境变量配置继续保留兼容，不破坏现有部署方式。

### 3.5 Data & Backup

旧原型已有：

```text
Local Data Folder
Auto Backup
Backup Frequency
Export All Data
Reset Local Data
```

当前 `AppPaths` 已预留：

```text
PersonalWorkbench/
├─ data/
│  └─ workbench.db
├─ workspaces/
├─ knowledge/
├─ attachments/
├─ backups/
└─ exports/
```

Phase 7 正式实现 Backup / Export / Restore。

### 3.6 Shortcuts

旧原型已有：

```text
Global Search
Quick Capture
AI
Continue Work
Save Note
```

Phase 7 V1：

```text
先做“快捷键总览 + 已支持快捷键显示”
```

是否允许用户自定义键位，不作为 Desktop V1 必须项。

避免在 Phase 7 同时引入完整 Global Hotkey 配置系统。

---

## 4. Settings Persistence Contract

Phase 7 不把所有 Settings 塞进 `workbench.db`。

设置分层：

```text
WorkbenchSettings
├─ General Preferences
├─ Notes Preferences
├─ AI Non-secret Preferences
├─ Backup Preferences
└─ Shortcut Preferences
```

V1 优先使用：

```text
SharedPreferences
```

保存轻量本地偏好。

现有 Appearance 继续由 ThemeController 管理。

敏感数据：

```text
API Key
```

必须与普通 Preferences 分离。

Phase 7 原则上不需要升级到 schema v7。

只有确认出现必须进入关系数据库的业务状态时，才允许新增 schema migration。

---

## 5. Settings Application Layer

新增统一：

```text
WorkbenchSettingsService
```

职责：

```text
load()
updateGeneral()
updateNotes()
updateAI()
updateBackup()
resetSection()
```

UI 不直接散落调用 SharedPreferences。

建议模型：

```text
WorkbenchSettingsModel
├─ GeneralSettings
├─ NotesSettings
├─ AISettings
└─ BackupSettings
```

Appearance 继续由 ThemeController 独立管理，Settings Page 只调用它。

---

## 6. Backup Contract

新增：

```text
BackupService
```

备份目标必须覆盖真正的 Workbench 数据源：

```text
workbench.db
Workspace Markdown Notes
Knowledge Markdown
Attachments
Workbench Preferences
Backup Manifest
```

不备份：

```text
API Key / secret
临时缓存
可重新构建的运行时状态
```

Backup Archive 建议格式：

```text
PersonalWorkbench_Backup_YYYYMMDD_HHmmss.zip
```

内部：

```text
manifest.json
data/workbench.db
workspaces/...
knowledge/...
attachments/...
settings/settings.json
```

`manifest.json` 至少包含：

```text
format_version
app_version
schema_version
created_at
platform
included_paths
```

关键安全原则：

```text
不能在 SQLite 正在写入时简单复制可能不一致的 DB 文件
```

实现时必须生成一致性数据库快照，再打包。

---

## 7. Auto Backup

V1 支持：

```text
Off
Daily
Weekly
```

触发策略以“应用启动 / 正常运行时检查上次备份时间”优先。

不引入：

```text
Windows 后台常驻调度器
系统级 Task Scheduler
云端定时任务
```

保留数量：

```text
默认 10 个自动备份
```

超过后仅删除最旧的 Auto Backup，不自动删除 Manual Backup。

---

## 8. Export Contract

Export 与 Backup 必须区分。

### Backup

```text
目标：完整恢复应用状态
格式：Workbench Backup Archive
面向：Restore
```

### Export

```text
目标：让用户拿走自己的内容
格式：Portable ZIP
面向：人 / 外部工具
```

Export V1 包含：

```text
Workspace Metadata JSON
Task / Issue / Resource / Decision JSON
Developer Context JSON
Notes Markdown
Knowledge Markdown
AI conversation metadata / messages JSON
attachments（可选）
export_manifest.json
```

Export 不要求可以 Restore。

不导出：

```text
API Key
Provider Secret Headers
```

---

## 9. Restore Contract

Restore 只接受：

```text
Workbench Backup Archive
```

不接受普通 Export ZIP 作为 Restore 输入。

流程：

```text
Select Backup
→ Validate Manifest
→ Validate Backup Format Version
→ Validate DB / Required Files
→ Create Safety Backup of Current Data
→ Restore
→ Rebuild Derived Index
→ Restart / Reload Runtime
→ Verify
```

任何校验失败：

```text
禁止覆盖当前数据
```

Restore 前必须明确提示：

```text
当前本地数据将被替换
系统会先创建 Safety Backup
```

---

## 10. Danger Zone

旧原型有：

```text
Reset Local Data
```

Phase 7 V1 可以保留，但不能做成普通按钮行为。

要求：

```text
二次确认
明确说明不可逆影响
Reset 前自动 Safety Backup
API Key 默认不删除，除非用户明确选择
```

如果 Reset 会显著扩大实现与测试风险，可在 P7.6 验收时决定推迟到 Hardening；它不是 Backup / Restore 完成的前置条件。

---

## 11. Settings UI Structure

入口继续使用现有：

```text
/setting
```

不新增第二套 Settings Route。

页面结构：

```text
Settings
┌────────────────┬──────────────────────────────────┐
│ General        │                                  │
│ Appearance     │      Current Settings Section    │
│ Notes          │                                  │
│ AI             │                                  │
│ Data & Backup  │                                  │
│ Shortcuts      │                                  │
└────────────────┴──────────────────────────────────┘
```

交互原则：

```text
普通 Toggle / Select → 即时保存
文本配置 → Save / Apply
危险操作 → 单独确认 Dialog
Backup / Export / Restore → 显示执行状态与结果路径
```

继续复用：

```text
ThemePalette
WorkbenchCard / 同类视觉 token
Fluent UI
```

---

## 12. Phase 7 不做

```text
Cloud Sync
Dropbox / OneDrive / Google Drive Sync
多人协作
账号云备份
跨设备实时同步
CRDT
完整快捷键编辑器
Windows 全局 Hotkey Manager
自动文件系统迁移
任意 Workbench Root 修改
导入第三方知识库格式
自动上传 Backup
AI Secret 导出
```

---

## 13. 开发顺序

```text
P7.1 Settings Contract + Scope
P7.2 Settings Shell + Appearance Integration
P7.3 General + Notes + Shortcuts
P7.4 AI Provider Settings
P7.5 Backup + Export
P7.6 Restore + Data Safety
P7.7 Windows Acceptance
P7.8 Baseline
```

说明：

`P7.1` 本文完成后即结束。

---

## 14. Definition of Done

```text
[ ] Settings Shell 使用旧 HTML 信息架构
[ ] Appearance 复用现有 ThemeController
[ ] General Preferences 可保存 / 重启恢复
[ ] Notes Preferences 可保存 / 重启恢复
[ ] Shortcuts 页面可展示实际快捷键
[ ] AI Provider 非敏感参数可配置
[ ] API Key 不落普通明文 Preferences / SQLite
[ ] AI 配置可测试连接
[ ] Manual Backup 可创建
[ ] Auto Backup 可按策略创建
[ ] Backup 包含 DB + Markdown + Attachments + Preferences
[ ] Export 可生成 Portable ZIP
[ ] Restore 有完整校验
[ ] Restore 前自动 Safety Backup
[ ] Restore 后 Search Index 可恢复
[ ] Windows 重启后 Settings 保留
[ ] Phase 1–6 smoke regression
[ ] flutter analyze 无 Phase 7 新增 error
```

---

## 15. Desktop V1 完成条件

Phase 7 封版后：

```text
Personal Workbench Windows Desktop V1
= Complete
```

之后进入独立阶段：

```text
Phase 8 — Mobile Adaptation
```

Mobile 不阻塞 Windows Desktop V1 封版。