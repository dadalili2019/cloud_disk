# Personal Workbench 实施与运行

## 1. 当前环境

~~~text
Flutter 3.47.4 stable
Windows Desktop
~~~

本机 SDK 示例：

~~~powershell
D:\person\config\flutter_win\flutter_3_47\flutter_windows_3.47.4-stable\flutter\bin\flutter.bat
~~~

## 2. 初始化和运行

~~~powershell
flutter pub get
flutter run -d windows
~~~

## 3. 提交前检查

以后不再只看“能不能跑起来”。

只要碰 Dart、依赖或 Windows 配置，至少执行：

~~~powershell
flutter analyze
flutter test
flutter build windows
~~~

要求：

- 不允许 compile error。
- 新代码不要引入 warning。
- `avoid_print` 已开启，正式代码不要直接 `print()`。
- Dart 文件统一 `snake_case`。
- 测试不能依赖个人电脑绝对路径。
- Release Build 要成功。

纯文档改动可以不 Build。

## 4. Windows Release

~~~powershell
flutter build windows
~~~

当前输出：

~~~text
build/windows/x64/runner/Release/cloud_disk.exe
~~~

可执行文件名字暂时保留历史仓库名字。正式发版前如果要改 package / executable 名称，单独处理。

## 5. AI 配置

Settings → AI：

- Provider
- Base URL
- Model
- Chat Path
- Timeout
- Session API Key

环境变量仍兼容：

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

## 6. Backup / Restore

重要改动、升级和 Restore 测试前先手动备份。

Restore：

~~~text
选择 Workbench Backup ZIP
→ Validate
→ 确认
→ Safety Backup
→ Stage Restore
→ 完全退出
→ 重新启动
→ 启动前应用 Pending Restore
~~~

## 7. 常见问题

### 搜索搜不到

先确认内容已经保存，再重建索引。仍然不对时，检查业务实体和 `search_index` 是否一致。

### AI 不返回

依次检查 Provider、Base URL、Model、Chat Path、API Key、Timeout 和 Gateway 是否 OpenAI-compatible。

### Windows AXTree 日志

Debug 偶尔出现 accessibility AXTree 日志，如果 UI 正常，不先当业务错误处理。持续高频时再看 Semantics Tree、窗口 resize 和 route transition。

## 8. Git 开发方式

~~~text
main
→ feature/* 或 refactor/*
→ 本地 Run
→ flutter analyze
→ flutter test
→ flutter build windows
→ PR
→ merge
~~~

大范围清理不要直接在 main 上做。

代码和文档一起改，详细编码要求看 [11_CODE_DEVELOPMENT_RULES.md](11_CODE_DEVELOPMENT_RULES.md)。
