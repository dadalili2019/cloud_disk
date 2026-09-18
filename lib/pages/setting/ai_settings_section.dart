import 'package:fluent_ui/fluent_ui.dart';

import '../../theme/theme_controller.dart';
import '../../workbench/application/configurable_ai_provider.dart';
import '../../workbench/core/workbench_settings.dart';
import '../../workbench/workbench_runtime.dart';

class AISettingsSection extends StatefulWidget {
  const AISettingsSection({
    super.key,
    required this.runtime,
    required this.settings,
    required this.onSettingsChanged,
  });

  final WorkbenchRuntime runtime;
  final AISettings settings;
  final VoidCallback onSettingsChanged;

  @override
  State<AISettingsSection> createState() => _AISettingsSectionState();
}

class _AISettingsSectionState extends State<AISettingsSection> {
  late AIProviderMode _mode;
  late final TextEditingController _baseUrlController;
  late final TextEditingController _modelController;
  late final TextEditingController _chatPathController;
  late final TextEditingController _timeoutController;
  late final TextEditingController _apiKeyController;

  bool _saving = false;
  bool _testing = false;
  bool _obscureKey = true;
  String? _success;
  String? _error;

  @override
  void initState() {
    super.initState();
    _mode = widget.settings.mode;
    _baseUrlController = TextEditingController(text: widget.settings.baseUrl);
    _modelController = TextEditingController(text: widget.settings.model);
    _chatPathController = TextEditingController(text: widget.settings.chatPath);
    _timeoutController = TextEditingController(
      text: widget.settings.timeoutSeconds.toString(),
    );
    _apiKeyController = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant AISettingsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings && !_saving && !_testing) {
      _mode = widget.settings.mode;
      _baseUrlController.text = widget.settings.baseUrl;
      _modelController.text = widget.settings.model;
      _chatPathController.text = widget.settings.chatPath;
      _timeoutController.text = widget.settings.timeoutSeconds.toString();
    }
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _modelController.dispose();
    _chatPathController.dispose();
    _timeoutController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  bool get _customProvider =>
      _mode == AIProviderMode.deepseek ||
      _mode == AIProviderMode.openAICompatible;

  Future<AISettings?> _settingsFromForm() async {
    final timeout = int.tryParse(_timeoutController.text.trim());
    if (timeout == null || timeout < 5 || timeout > 600) {
      _setError('超时时间必须是 5–600 秒之间的整数。');
      return null;
    }

    final model = _modelController.text.trim();
    final baseUrl = _baseUrlController.text.trim();
    if (_customProvider && model.isEmpty) {
      _setError('请填写模型名称。');
      return null;
    }
    if (_mode == AIProviderMode.openAICompatible && baseUrl.isEmpty) {
      _setError('OpenAI 兼容服务需要填写服务地址。');
      return null;
    }

    return AISettings(
      mode: _mode,
      baseUrl: baseUrl,
      model: model,
      chatPath: _chatPathController.text.trim(),
      timeoutSeconds: timeout,
    );
  }

  Future<bool> _apply({bool showSuccess = true}) async {
    final value = await _settingsFromForm();
    if (value == null) return false;

    setState(() {
      _saving = true;
      _error = null;
      _success = null;
    });

    try {
      await widget.runtime.settingsService.updateAI(value);
      final key = _apiKeyController.text.trim();
      if (key.isNotEmpty) {
        widget.runtime.settingsService.setSessionAIKey(key);
        _apiKeyController.clear();
      }
      widget.onSettingsChanged();
      if (!mounted) return true;
      setState(() {
        _success = showSuccess ? 'AI 配置已保存，并立即应用到 AI 助手。' : null;
      });
      return true;
    } catch (error) {
      if (mounted) _setError(error.toString());
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _testConnection() async {
    if (_testing || _saving) return;
    final applied = await _apply(showSuccess: false);
    if (!applied || !mounted) return;

    setState(() {
      _testing = true;
      _error = null;
      _success = null;
    });

    try {
      final provider = widget.runtime.aiProvider;
      if (provider is! ConfigurableAIProvider) {
        throw StateError('当前 AI 服务提供方不支持连接测试。');
      }
      final response = await provider.testConnection();
      if (!mounted) return;
      setState(() {
        _success = response.isEmpty
            ? '连接测试成功。'
            : '连接测试成功：${_short(response)}';
      });
    } catch (error) {
      if (mounted) _setError(_readableError(error));
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  void _clearSessionKey() {
    widget.runtime.settingsService.clearSessionAIKey();
    _apiKeyController.clear();
    setState(() {
      _success = '本次会话 API Key 已清除。';
      _error = null;
    });
  }

  void _selectMode(AIProviderMode? value) {
    if (value == null) return;
    setState(() {
      _mode = value;
      _success = null;
      _error = null;
      if (value == AIProviderMode.deepseek) {
        if (_baseUrlController.text.trim().isEmpty) {
          _baseUrlController.text = 'https://api.deepseek.com';
        }
        if (_chatPathController.text.trim().isEmpty) {
          _chatPathController.text = '/chat/completions';
        }
      } else if (value == AIProviderMode.openAICompatible) {
        if (_chatPathController.text.trim().isEmpty ||
            _chatPathController.text.trim() == '/chat/completions') {
          _chatPathController.text = '/v1/chat/completions';
        }
      }
    });
  }

  void _setError(String value) {
    setState(() {
      _error = value;
      _success = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final textColor = FluentTheme.of(context).typography.body?.color;
    final hasSessionKey = widget.runtime.settingsService.sessionAIKey.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(2, 2, 2, 12),
          child: Text(
            'AI',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: palette.cardBackground,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: palette.cardBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GroupTitle('服务提供方', palette: palette),
              _Divider(palette),
              _Row(
                title: '服务提供方',
                subtitle: '环境变量模式兼容原有环境变量和 dart-define 配置。',
                control: SizedBox(
                  width: 300,
                  child: ComboBox<AIProviderMode>(
                    value: _mode,
                    isExpanded: true,
                    items: const [
                      ComboBoxItem(
                        value: AIProviderMode.environment,
                        child: Text('环境变量'),
                      ),
                      ComboBoxItem(
                        value: AIProviderMode.preview,
                        child: Text('预览'),
                      ),
                      ComboBoxItem(
                        value: AIProviderMode.deepseek,
                        child: Text('DeepSeek'),
                      ),
                      ComboBoxItem(
                        value: AIProviderMode.openAICompatible,
                        child: Text('OpenAI 兼容'),
                      ),
                    ],
                    onChanged: _selectMode,
                  ),
                ),
              ),
              _Divider(palette),
              _Row(
                title: '当前状态',
                subtitle: 'AI 助手当前实际使用的服务提供方。',
                control: _Badge(_displayProviderName(widget.runtime.aiProvider.name)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: palette.cardBackground,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: palette.cardBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GroupTitle('连接配置', palette: palette),
              _Divider(palette),
              _Row(
                title: '服务地址',
                subtitle: _mode == AIProviderMode.deepseek
                    ? 'DeepSeek 默认使用 https://api.deepseek.com。'
                    : _customProvider
                        ? 'OpenAI 兼容接口的根地址。'
                        : '当前模式由 AI 服务提供方自行管理。',
                control: SizedBox(
                  width: 360,
                  child: TextBox(
                    controller: _baseUrlController,
                    enabled: _customProvider,
                    placeholder: _mode == AIProviderMode.deepseek
                        ? 'https://api.deepseek.com'
                        : 'https://api.example.com',
                  ),
                ),
              ),
              _Divider(palette),
              _Row(
                title: '模型',
                control: SizedBox(
                  width: 360,
                  child: TextBox(
                    controller: _modelController,
                    enabled: _customProvider,
                    placeholder: _mode == AIProviderMode.deepseek
                        ? '例如 deepseek-chat'
                        : '模型名称',
                  ),
                ),
              ),
              _Divider(palette),
              _Row(
                title: '请求路径',
                subtitle: '留空时按当前服务提供方使用默认路径。',
                control: SizedBox(
                  width: 360,
                  child: TextBox(
                    controller: _chatPathController,
                    enabled: _customProvider,
                    placeholder: _mode == AIProviderMode.deepseek
                        ? '/chat/completions'
                        : '/v1/chat/completions',
                  ),
                ),
              ),
              _Divider(palette),
              _Row(
                title: '超时时间',
                subtitle: '允许范围 5–600 秒。',
                control: SizedBox(
                  width: 160,
                  child: TextBox(
                    controller: _timeoutController,
                    enabled: _customProvider,
                    suffix: const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Text('秒'),
                    ),
                  ),
                ),
              ),
              _Divider(palette),
              _Row(
                title: 'API Key',
                subtitle: '仅保存在当前应用会话内存；不会写入 SQLite、普通偏好、备份或导出文件。',
                control: SizedBox(
                  width: 360,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextBox(
                          controller: _apiKeyController,
                          enabled: _customProvider,
                          obscureText: _obscureKey,
                          placeholder: hasSessionKey
                              ? '本次会话已设置 Key；留空表示继续使用'
                              : '输入本次会话 API Key',
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: Icon(
                          _obscureKey
                              ? FluentIcons.red_eye
                              : FluentIcons.hide3,
                          size: 13,
                        ),
                        onPressed: _customProvider
                            ? () => setState(() => _obscureKey = !_obscureKey)
                            : null,
                      ),
                      if (hasSessionKey) ...[
                        const SizedBox(width: 4),
                        Button(
                          onPressed: _clearSessionKey,
                          child: const Text('清除'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_error != null)
          InfoBar(
            title: const Text('AI 配置失败'),
            content: Text(_error!),
            severity: InfoBarSeverity.error,
            isLong: true,
          ),
        if (_success != null)
          InfoBar(
            title: const Text('AI 配置'),
            content: Text(_success!),
            severity: InfoBarSeverity.success,
            isLong: true,
          ),
        if (_error != null || _success != null) const SizedBox(height: 10),
        Row(
          children: [
            FilledButton(
              onPressed: _saving || _testing ? null : () => _apply(),
              child: Text(_saving ? '保存中…' : '保存配置'),
            ),
            const SizedBox(width: 8),
            Button(
              onPressed: _saving || _testing ? null : _testConnection,
              child: Text(_testing ? '测试中…' : '测试连接'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _mode == AIProviderMode.environment
                    ? '环境变量模式继续读取 WORKBENCH_AI_* 配置。'
                    : _mode == AIProviderMode.preview
                        ? '预览模式不会访问外部模型。'
                        : hasSessionKey
                            ? '本次会话 Key 已设置。'
                            : '未填写本次会话 Key 时，可回退使用环境变量中的 API Key。',
                style: TextStyle(
                  fontSize: 9.5,
                  color: textColor?.withValues(alpha: 0.52),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.title, required this.control, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget control;

  @override
  Widget build(BuildContext context) {
    final textColor = FluentTheme.of(context).typography.body?.color;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: textColor?.withValues(alpha: 0.48),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 18),
          control,
        ],
      ),
    );
  }
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle(this.title, {required this.palette});

  final String title;
  final ThemePalette palette;

  @override
  Widget build(BuildContext context) {
    final textColor = FluentTheme.of(context).typography.body?.color;
    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
          color: textColor?.withValues(alpha: 0.48),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider(this.palette);

  final ThemePalette palette;

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: palette.cardBorder);
}

class _Badge extends StatelessWidget {
  const _Badge(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 10),
      ),
    );
  }
}

String _short(String value) {
  final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.length <= 120) return normalized;
  return '${normalized.substring(0, 120)}…';
}

String _readableError(Object error) {
  var value = error.toString().trim();
  value = value.replaceFirst(RegExp(r'^(StateError|Exception):\s*'), '');
  if (value.length > 360) value = '${value.substring(0, 360)}…';
  return value;
}

String _displayProviderName(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.contains('preview')) return '预览';
  if (normalized.contains('environment')) return '环境变量';
  if (normalized.contains('openai')) return 'OpenAI 兼容';
  return value;
}
