part of 'global_ai_drawer.dart';

extension _GlobalAiDrawerWidgets on _GlobalAiDrawerState {
  Widget _header(FluentThemeData theme, ThemePalette palette) {
    final providerName = _runtime?.aiProvider.name ?? '正在加载';
    final isPreview = providerName.toLowerCase().contains('preview');
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 11),
      decoration: BoxDecoration(
        color: palette.appBarBackground,
        border: Border(bottom: BorderSide(color: palette.cardBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: palette.successSoft,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: palette.cardBorder),
            ),
            child: Icon(
              FluentIcons.chat_bot,
              size: 16,
              color: theme.accentColor.normal,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI 助手',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _headerContextLabel(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: theme.typography.body?.color?.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          _statusBadge(isPreview ? '预览' : _shortProviderName(providerName), palette),
          const SizedBox(width: 4),
          if (_threads.isNotEmpty)
            Tooltip(
              message: '历史会话',
              child: IconButton(
                icon: const Icon(FluentIcons.history, size: 13),
                onPressed: _showHistoryDialog,
              ),
            ),
          Tooltip(
            message: '新建会话',
            child: IconButton(
              icon: const Icon(FluentIcons.add, size: 13),
              onPressed: _newThread,
            ),
          ),
          Tooltip(
            message: '关闭',
            child: IconButton(
              icon: const Icon(FluentIcons.chrome_close, size: 13),
              onPressed: widget.onClose,
            ),
          ),
        ],
      ),
    );
  }

  Widget _scopeSection(FluentThemeData theme, ThemePalette palette) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: palette.appBackground,
        border: Border(bottom: BorderSide(color: palette.cardBorder)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: palette.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.cardBorder),
            ),
            child: Row(
              children: AIContextScope.values.map((scope) {
                final selected = scope == _scope;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _setScope(scope),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? palette.navItemSelected : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _scopeShortLabel(scope),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected ? theme.accentColor.normal : null,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
          ),
          const SizedBox(height: 10),
          _anchorControls(),
        ],
      ),
    );
  }

  Widget _anchorControls() {
    final buttonLabel = _previewing
        ? '整理中…'
        : _preview == null
            ? '查看上下文'
            : '刷新';

    if (_scope == AIContextScope.global) {
      return Align(
        alignment: Alignment.centerRight,
        child: Button(
          onPressed: _previewing ? null : _previewContext,
          child: Text(buttonLabel),
        ),
      );
    }

    final controls = <Widget>[];
    if (_scope == AIContextScope.workspace || _scope == AIContextScope.task) {
      controls.add(
        Expanded(
          child: ComboBox<String>(
            value: _workspaceId,
            isExpanded: true,
            placeholder: const Text('选择工作区'),
            items: _workspaces
                .map((item) => ComboBoxItem(value: item.id, child: Text(item.name)))
                .toList(),
            onChanged: _setWorkspace,
          ),
        ),
      );
    }

    if (_scope == AIContextScope.task) {
      if (controls.isNotEmpty) controls.add(const SizedBox(width: 8));
      controls.add(
        Expanded(
          child: ComboBox<String>(
            value: _taskId,
            isExpanded: true,
            placeholder: const Text('选择任务'),
            items: _tasks
                .map((item) => ComboBoxItem(value: item.id, child: Text(item.title)))
                .toList(),
            onChanged: _setTask,
          ),
        ),
      );
    }

    if (_scope == AIContextScope.knowledge) {
      controls.add(
        Expanded(
          child: ComboBox<String>(
            value: _knowledgeId,
            isExpanded: true,
            placeholder: const Text('选择知识'),
            items: _knowledge
                .map((item) => ComboBoxItem(value: item.id, child: Text(item.title)))
                .toList(),
            onChanged: _setKnowledge,
          ),
        ),
      );
    }

    controls.add(const SizedBox(width: 8));
    controls.add(
      Button(
        onPressed: _previewing ? null : _previewContext,
        child: Text(buttonLabel),
      ),
    );
    return Row(children: controls);
  }

  Widget _body(FluentThemeData theme, ThemePalette palette) {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      children: [
        if (_preview != null) _contextPreview(theme, palette, _preview!),
        if (_messages.isEmpty && _preview == null && !_sending)
          _emptyState(theme, palette),
        ..._messages.map((message) => _messageBubble(theme, palette, message)),
        if (_pendingUserMessage != null)
          _pendingUserBubble(palette, _pendingUserMessage!),
        if (_sending) _thinkingBubble(theme, palette),
        if (_failedMessage != null && !_sending)
          _failureBubble(theme, palette),
      ],
    );
  }

  Widget _emptyState(FluentThemeData theme, ThemePalette palette) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 24),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Column(
        children: [
          Icon(
            FluentIcons.chat_bot,
            size: 25,
            color: theme.accentColor.normal.withValues(alpha: 0.72),
          ),
          const SizedBox(height: 10),
          const Text(
            '开始对话',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 5),
          Text(
            _emptyStateText(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              height: 1.45,
              color: theme.typography.body?.color?.withValues(alpha: 0.56),
            ),
          ),
        ],
      ),
    );
  }


  Widget _contextRow(ThemePalette palette, AIContextPreviewItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              'P${item.priority}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              '${_entityLabel(item.ref.entityType)} · ${item.ref.title}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10),
            ),
          ),
          IconButton(
            icon: const Icon(FluentIcons.remove, size: 10),
            onPressed: () => _excludeContext(item.ref),
          ),
        ],
      ),
    );
  }

  Widget _contextChip(String text, ThemePalette palette) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 9.5),
      ),
    );
  }

  Widget _messageBubble(
    FluentThemeData theme,
    ThemePalette palette,
    AIMessageModel message,
  ) {
    final user = message.role == 'user';
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: user ? palette.navItemSelected : palette.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.cardBorder),
        ),
        child: user
            ? SelectableText(
                message.content,
                style: const TextStyle(fontSize: 11.5, height: 1.45),
              )
            : AssistantMarkdown(data: message.content),
      ),
    );
  }

  Widget _pendingUserBubble(ThemePalette palette, String message) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: palette.navItemSelected,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.cardBorder),
        ),
        child: Text(message, style: const TextStyle(fontSize: 11.5, height: 1.45)),
      ),
    );
  }

  Widget _thinkingBubble(FluentThemeData theme, ThemePalette palette) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: palette.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: ProgressRing(strokeWidth: 1.5),
            ),
            const SizedBox(width: 8),
            Text(
              '正在思考…',
              style: TextStyle(
                fontSize: 10.5,
                color: theme.typography.body?.color?.withValues(alpha: 0.62),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _failureBubble(FluentThemeData theme, ThemePalette palette) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: palette.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD13438).withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI 回复失败',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              _readableError(_failedError ?? 'Unknown provider error.'),
              style: TextStyle(
                fontSize: 10,
                height: 1.4,
                color: theme.typography.body?.color?.withValues(alpha: 0.62),
              ),
            ),
            const SizedBox(height: 8),
            Button(onPressed: _retryFailed, child: const Text('重试')),
          ],
        ),
      ),
    );
  }

  Widget _composer(FluentThemeData theme, ThemePalette palette) {
    final contextCount = _preview?.included.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 11),
      decoration: BoxDecoration(
        color: palette.appBarBackground,
        border: Border(top: BorderSide(color: palette.cardBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _composerContextLabel(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: theme.typography.body?.color?.withValues(alpha: 0.50),
                    ),
                  ),
                ),
                if (contextCount != null)
                  Text(
                    '$contextCount 条上下文',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: theme.typography.body?.color?.withValues(alpha: 0.50),
                    ),
                  ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextBox(
                  controller: _messageController,
                  minLines: 2,
                  maxLines: 5,
                  placeholder: '问问当前工作上下文…',
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 38,
                child: FilledButton(
                  onPressed: _sending ? null : _send,
                  child: Text(_sending ? '处理中…' : '发送'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Ctrl + Enter 发送',
                style: TextStyle(
                  fontSize: 8.5,
                  color: theme.typography.body?.color?.withValues(alpha: 0.38),
                ),
              ),
              const Spacer(),
              Text(
                'Esc 关闭',
                style: TextStyle(
                  fontSize: 8.5,
                  color: theme.typography.body?.color?.withValues(alpha: 0.32),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String text, ThemePalette palette) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 92),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 8.5),
      ),
    );
  }

  String _headerContextLabel() {
    return switch (_scope) {
      AIContextScope.task => _taskId == null
          ? '当前任务'
          : '当前任务 · ${_taskTitle(_taskId!)}',
      AIContextScope.workspace => _workspaceId == null
          ? '工作区'
          : '工作区 · ${_workspaceName(_workspaceId!)}',
      AIContextScope.knowledge => _knowledgeId == null
          ? '知识'
          : '知识 · ${_knowledgeTitle(_knowledgeId!)}',
      AIContextScope.global => '全局',
    };
  }

  String _composerContextLabel() {
    return switch (_scope) {
      AIContextScope.global => '全局 · 自动检索相关上下文',
      _ => _headerContextLabel(),
    };
  }

  String _emptyStateText() {
    return switch (_scope) {
      AIContextScope.task => _taskId == null
          ? '请选择一个任务'
          : '围绕当前任务提问，我会自动组织相关上下文',
      AIContextScope.workspace => _workspaceId == null
          ? '请选择一个工作区'
          : '围绕当前工作区提问，我会组织相关工作上下文',
      AIContextScope.knowledge => _knowledgeId == null
          ? '请选择一条知识'
          : '围绕当前知识提问，并结合它的来源上下文',
      AIContextScope.global => '输入问题，我会根据当前范围组织相关上下文',
    };
  }

  String _workspaceName(String id) {
    for (final item in _workspaces) {
      if (item.id == id) return item.name;
    }
    return id;
  }

  String _taskTitle(String id) {
    for (final item in _tasks) {
      if (item.id == id) return item.title;
    }
    return id;
  }

  String _knowledgeTitle(String id) {
    for (final item in _knowledge) {
      if (item.id == id) return item.title;
    }
    return id;
  }
}
