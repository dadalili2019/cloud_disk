import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';

import '../../theme/theme_controller.dart';
import '../application/developer_command_service.dart';
import '../core/developer_models.dart';
import '../core/models.dart';
import '../workbench_runtime.dart';
import 'workbench_ui.dart';


part 'workbench_developer_actions.dart';
part 'workbench_developer_sections.dart';
part 'workbench_developer_support.dart';

class WorkbenchDeveloperPage extends StatefulWidget {
  const WorkbenchDeveloperPage({super.key, required this.workspaceId});

  final String workspaceId;

  @override
  State<WorkbenchDeveloperPage> createState() => _WorkbenchDeveloperPageState();
}

class _WorkbenchDeveloperPageState extends State<WorkbenchDeveloperPage> {
  late Future<DeveloperContextModel> _context;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _context = WorkbenchRuntime.instance.then(
      (runtime) => runtime.developerContextService.load(widget.workspaceId),
    );
  }

  Future<void> _refresh() async {
    _reloadState();
    await _context;
  }

  void _reloadState() {
    if (!mounted) return;
    setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return WorkbenchSectionPage(
      title: '开发',
      child: FutureBuilder<DeveloperContextModel>(
        future: _context,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: ProgressRing());
          }
          if (snapshot.hasError) {
            return Center(child: Text('加载失败：${snapshot.error}'));
          }
          final data = snapshot.data!;
          return Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(0, 4, 6, 24),
                children: [
                  _projectsSection(data),
                  const SizedBox(height: 20),
                  _commandsSection(data),
                  const SizedBox(height: 20),
                  _snippetsSection(data),
                  const SizedBox(height: 20),
                  _resourcesSection(data.devResources),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
