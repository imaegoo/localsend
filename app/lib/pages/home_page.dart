import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/config/init.dart';
import 'package:localsend_app/config/theme.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/pages/home_page_controller.dart';
import 'package:localsend_app/pages/tabs/receive_tab.dart';
import 'package:localsend_app/pages/tabs/send_tab.dart';
import 'package:localsend_app/pages/tabs/settings_tab.dart';
import 'package:localsend_app/provider/selection/selected_sending_files_provider.dart';
import 'package:localsend_app/util/native/cross_file_converters.dart';
import 'package:localsend_app/util/ui/rail_diagnostics.dart';
import 'package:localsend_app/widget/responsive_builder.dart';
import 'package:refena_flutter/refena_flutter.dart';

enum HomeTab {
  receive(Icons.wifi),
  send(Icons.send),
  settings(Icons.settings);

  const HomeTab(this.icon);

  final IconData icon;

  String get label {
    switch (this) {
      case HomeTab.receive:
        return t.receiveTab.title;
      case HomeTab.send:
        return t.sendTab.title;
      case HomeTab.settings:
        return t.settingsTab.title;
    }
  }
}

class HomePage extends StatefulWidget {
  final HomeTab initialTab;

  /// It is important for the initializing step
  /// because the first init clears the cache
  final bool appStart;

  const HomePage({required this.initialTab, required this.appStart, super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with Refena {
  bool _dragAndDropIndicator = false;

  @override
  void initState() {
    super.initState();

    ensureRef((ref) async {
      ref.redux(homePageControllerProvider).dispatch(ChangeTabAction(widget.initialTab));
      await postInit(context, ref, widget.appStart);
    });
  }

  @override
  Widget build(BuildContext context) {
    Translations.of(context); // rebuild on locale change
    final vm = context.watch(homePageControllerProvider);

    return DropTarget(
      onDragEntered: (_) {
        setState(() {
          _dragAndDropIndicator = true;
        });
      },
      onDragExited: (_) {
        setState(() {
          _dragAndDropIndicator = false;
        });
      },
      onDragDone: (event) async {
        // the drop may contain a mix of files and directories
        final droppedDirectories = event.files.where((file) => Directory(file.path).existsSync()).toList();
        final droppedFiles = event.files.where((file) => !Directory(file.path).existsSync()).toList();

        for (final directory in droppedDirectories) {
          await ref.redux(selectedSendingFilesProvider).dispatchAsync(AddDirectoryAction(directory.path));
        }

        if (droppedFiles.isNotEmpty) {
          await ref
              .redux(selectedSendingFilesProvider)
              .dispatchAsync(AddFilesAction(files: droppedFiles, converter: CrossFileConverters.convertXFile));
        }
        vm.changeTab(HomeTab.send);
      },
      child: ResponsiveBuilder(
        builder: (sizingInformation) {
          if (!railDiagnosticsEnabled) {
            return _buildScaffold(context, vm, sizingInformation, null);
          }
          return ValueListenableBuilder<RailDiagMode>(
            valueListenable: railDiagMode,
            builder: (context, mode, _) => _buildScaffold(context, vm, sizingInformation, mode),
          );
        },
      ),
    );
  }

  /// Builds the scaffold with the navigation rail or the bottom navigation bar.
  ///
  /// [mode] is only set by the diagnostics build.
  Widget _buildScaffold(BuildContext context, HomePageVm vm, SizingInformation sizingInformation, RailDiagMode? mode) {
    final showRail = !sizingInformation.isMobile && (mode?.showsRail ?? true);
    final showBottomBar = sizingInformation.isMobile || (mode != null && !mode.showsRail);

    return Scaffold(
      body: Row(
        children: [
          if (showRail) _buildRail(context, vm, sizingInformation.isDesktop, mode),
          Expanded(
            child: SafeArea(
              left: !showRail,
              child: Stack(
                children: [
                  PageView(
                    controller: vm.controller,
                    physics: const NeverScrollableScrollPhysics(),
                    children: const [ReceiveTab(), SendTab(), SettingsTab()],
                  ),
                  if (_dragAndDropIndicator)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.file_download, size: 128),
                          const SizedBox(height: 30),
                          Text(t.sendTab.placeItems, style: Theme.of(context).textTheme.titleLarge),
                        ],
                      ),
                    ),
                  if (railDiagnosticsEnabled) const RailDiagPanel(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: showBottomBar
          ? NavigationBar(
              selectedIndex: vm.currentTab.index,
              onDestinationSelected: (index) => vm.changeTab(HomeTab.values[index]),
              destinations: HomeTab.values.map((tab) {
                return NavigationDestination(icon: Icon(tab.icon), label: tab.label);
              }).toList(),
            )
          : null,
    );
  }

  /// Builds the navigation rail.
  ///
  /// With `--dart-define=localsend.railDiagnostics=true` the layout can be switched at runtime, so that the
  /// failing layer can be identified on a device without adb. See [railDiagnosticsEnabled].
  Widget _buildRail(BuildContext context, HomePageVm vm, bool extended, RailDiagMode? mode) {
    Widget frameworkRail({bool debugColors = false}) {
      return NavigationRail(
        selectedIndex: vm.currentTab.index,
        onDestinationSelected: (index) => vm.changeTab(HomeTab.values[index]),
        extended: extended,
        backgroundColor: debugColors ? Colors.magenta : Theme.of(context).cardColorWithElevation,
        leading: extended
            ? const Column(
                children: [
                  SizedBox(height: 20),
                  Text(
                    'LocalSend',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                ],
              )
            : null,
        destinations: HomeTab.values.map((tab) {
          return NavigationRailDestination(icon: Icon(tab.icon), label: Text(tab.label));
        }).toList(),
      );
    }

    if (!railDiagnosticsEnabled || mode == null) {
      return frameworkRail();
    }

    switch (mode) {
      case RailDiagMode.baseline:
      case RailDiagMode.bottomBar:
        return frameworkRail();
      case RailDiagMode.custom:
        return RailDiagCustomRail(
          destinations: [for (final tab in HomeTab.values) RailDiagDestination(icon: tab.icon, label: tab.label)],
          selectedIndex: vm.currentTab.index,
          onSelected: (index) => vm.changeTab(HomeTab.values[index]),
          debugColors: false,
        );
      case RailDiagMode.bitmap:
        return RepaintBoundary(child: frameworkRail());
      case RailDiagMode.debugPaint:
        return RepaintBoundary(child: frameworkRail(debugColors: true));
    }
  }
}
