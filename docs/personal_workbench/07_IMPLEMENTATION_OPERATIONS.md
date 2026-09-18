# Personal Workbench 实施与运行

## 1. 当前验证环境

当前 Windows 验证基线：

~~~text
Flutter 3.47.4 stable
Windows Desktop
~~~

用户当前固定 Flutter SDK 示例：

~~~powershell
D:\person\config\flutter_win\flutter_3_47\flutter_windows_3.47.4-stable\flutter\bin\flutter.bat
~~~

## 2. 初始化

~~~powershell
flutter pub get
~~~

## 3. 运行

~~~powershell
flutter run -d windows
~~~

## 4. 静态检查

~~~powershell
flutter analyze
~~~

当前仓库仍存在历史 lint，主要包括：

- file_names
- prefer_const
- avoid_print
- 少量 legacy warning

验收重点：

- 无 compile error
- 无本阶段新增关键 warning

## 5. Windows Release Build

~~~powershell
flutter build windows
~~~

当前已验证输出：

~~~text
build/windows/x64/runner/Release/cloud_disk.exe
~~~

## 6. AI 配置

可以在 Settings → AI 配置：

- Provider
- Base URL
- Model
- Chat Path
- Timeout
- Session API Key

也保留 Environment 配置兼容。

常见环境项：

~~~text
WORKBENCH_AI_BASE_URL
WORKBENCH_AI_MODEL
WORKBENCH_AI_API_KEY
WORKBENCH_AI_CHAT_PATH
WORKBENCH_AI_API_KEY_HEADER
WORKBENCH_AI_API_KEY_PREFIX
WORKBENCH_AI_EXTRA_HEADERS_JSON
WORKBENCH_AI_TIMEOUT_SECONDS
~~~

## 7. Backup 操作

Settings → Data & Backup：

- Manual Backup
- Auto Backup
- Retention

建议：

- 升级前手动备份
- Restore 测试前手动备份
- 重要数据变更前保留 Safety Backup

## 8. Restore

Restore 操作：

~~~text
选择 Workbench Backup ZIP
→ Validate
→ 确认
→ Safety Backup
→ Stage Restore
→ 完全退出应用
→ 重新启动
→ 启动前自动应用 Pending Restore
~~~

不要在 Restore Staged 后继续长时间写入旧数据。

## 9. 故障定位

### 搜索搜不到

1. 确认实体已保存。
2. 在 Knowledge 页面执行“重建索引”。
3. 再搜索。
4. 检查 search_index 是否可重建。

### AI 不返回

1. 检查 Provider mode。
2. 检查 Base URL / Model / Chat Path。
3. Test Connection。
4. 检查 API Key。
5. 检查 Gateway 是否 OpenAI-compatible。

### Windows AXTree 日志

历史上 Windows Debug 模式可能输出 accessibility AXTree 日志。

如果 UI 功能正常且日志只是偶发，不作为业务错误处理；持续高频输出时再检查频繁 Semantics Tree 重建、窗口 resize 和 route transition。

## 10. Git 开发流程

当前推荐：

~~~text
main
→ feature/*
→ Windows Run
→ flutter analyze
→ flutter build windows
→ PR
→ squash merge
~~~

文档改动与功能改动应放在同一 PR 或紧随其后的 docs PR 中，避免实现与文档长期漂移。
