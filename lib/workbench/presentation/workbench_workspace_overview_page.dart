import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme_controller.dart';
import '../core/models.dart';
import '../workbench_runtime.dart';
import 'workbench_ui.dart';
import 'workbench_workspace_admin_dialog.dart';


part 'workbench_workspace_navigation.dart';
part 'workbench_workspace_overview_content.dart';

class WorkbenchWorkspaceFrame extends StatefulWidget {
  const WorkbenchWorkspaceFrame({
    super.key,
    required this.workspaceId,
    required this.section,
    required this.child,
  });

  final String workspaceId;
  final String section;
  final Widget child;

  @override
  State<WorkbenchWorkspaceFrame> createState() =>
      _WorkbenchWorkspaceFrameState();
}

class _WorkbenchWorkspaceFrameState
    extends State<WorkbenchWorkspaceFrame> {
  late Future<WorkspaceOverviewModel> _overview;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant WorkbenchWorkspaceFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workspaceId != widget.workspaceId) _reload();
  }

  void _reload() {
    _overview = WorkbenchRuntime.instance.then(
      (runtime) => runtime.overviewService.loadOverview(widget.workspaceId),
    );
  }

  Future<void> _openSettings(WorkspaceModel workspace) async {
    final result = await showWorkspaceSettingsDialog(context, workspace);
    if (!mounted || result == null) return;
    if (result == 'archived') {
      context.go('/workspace');
      return;
    }
    if (result == 'saved') setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;

    return Container(
      color: palette.appBackground,
      child: Column(
        children: [
          FutureBuilder<WorkspaceOverviewModel>(
            future: _overview,
            builder: (context, snapshot) {
              final overview = snapshot.data;
              return _WorkspaceNavigation(
                workspaceId: widget.workspaceId,
                section: widget.section,
                onSettings: overview == null
                    ? null
                    : () => _openSettings(overview.workspace),
              );
            },
          ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}

