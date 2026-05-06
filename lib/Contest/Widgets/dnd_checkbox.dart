import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quthon/Widgets/widgets.dart';

import '../../Service/dnd_service.dart';

class DndCheckTile extends ConsumerStatefulWidget {
  const DndCheckTile({super.key, required this.onChanged});
  final ValueChanged<bool> onChanged;
  @override
  ConsumerState<DndCheckTile> createState() => _DndCheckTileState();
}

class _DndCheckTileState extends ConsumerState<DndCheckTile> {
  @override
  void initState() {
    super.initState();
    // initailzing it will call the function once only.
    Future.microtask(() async {
      isDndPermitted = await DndService.isPermissionGranted();
      if (isDndPermitted) {
        await DndService.disableDnd();
      }
    });
  }

  @override
  void dispose() {
    // _stopDndMonitoring();
    super.dispose();
  }

  StreamSubscription<DndFilter>? _dndSub;

  ///ensuring the app enabled the dnd
  bool dndAppEnable = false;

  /// to reflect ui properly
  bool dndModeToggle = false;

  /// ddn permission is available?
  late bool isDndPermitted;

  ///ensuring show dialog based on filter state and user interaction ,to provider a bette ux when user encounter an error:
  bool _dndDialogVisible = false;

  Future<void> _dndModeToggle(bool input) async {
    widget.onChanged(input);

    /// this is simple implementation for the off the dnd:
    ///if input false user try to achieve off go from input true->false:
    if (!input) {
      await _stopDndMonitoring(); // dnd disable called in dispose :
      //call the setState to reflect the changes
      setState(() {
        dndAppEnable = false;
        dndModeToggle = false;
      });
      return;
    }

    ///when user tries to enable the dnd mode first try to check permission
    //check permission store permission in variable or persist it for future instead of calling the function each time or toggle
    //not granted
    final granted = await DndService.isPermissionGranted();
    if (!granted) {
      _showPermissionDialog();
      return;
    }

    //step event listen to get the current filter
    final filter = await DndService.getCurrentFilter();

    //current filter is 1
    if (filter == DndFilter.all) {
      await _startDndMonitoring();
      return;
    }

    //current filter is 3 and app enabled
    if (filter == DndFilter.none && dndAppEnable) {
      return;
    }
    // //falling to system dialog
    _showReEnableDialog(context, filter);
    return;
  }

  Future<void> _startDndMonitoring() async {
    await _dndSub?.cancel(); // cancel previous stream if any
    await DndService.enableDnd();

    /// helps in setting up value faster totally optional
    setState(() {
      dndAppEnable = true;
      dndModeToggle = true;
    });
    _dndSub = DndService.dndFilterStream.listen((filter) {
      if (!mounted) return;
      final isDndActive = filter == DndFilter.none;

      if (dndModeToggle && _dndDialogVisible) {
        Navigator.of(context).pop();

        /// when dialog is active and pop then the value of [_dndDialogVisible] is being updated by callback of dialog. you can verify by the _showReEnableDialog sheet function that call then to set it [false]
      }
      if (dndModeToggle != isDndActive) {
        setState(() {
          dndAppEnable = isDndActive;
          dndModeToggle = isDndActive;
        });
      }

      // If user expected DND to be ON but it was disabled externally
      if (!isDndActive && !_dndDialogVisible) {
        _showReEnableDialog(context, filter);
      }
    });
  }

  void _showReEnableDialog(BuildContext context, DndFilter filter) {
    if (filter == DndFilter.none) return;
    _dndDialogVisible = true;
    String message = switch (filter) {
      DndFilter.all =>
        "DND was turned off outside the app. Please enable it again to continue.",
      DndFilter.priority || DndFilter.alarms =>
        "System DND is active.Check if DND mode, Focus or Bedtime mode is on and turn it off to continue.",
      DndFilter.unknown =>
        "Unable to detect current DND state. Please try enabling again.",
      DndFilter.none => "Seems like you continuously play with DND button",
    };

    String title = switch (filter) {
      DndFilter.all => "DND Disabled",
      DndFilter.priority || DndFilter.alarms => "System DND Detected",
      DndFilter.none => "DND User Warning",
      DndFilter.unknown => "DND Status Unknown",
    };

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions:
              filter == DndFilter.all
                  ? [
                    TextButton(
                      onPressed: () async {
                        final granted = await DndService.isPermissionGranted();
                        Navigator.of(context).pop();
                        if (!granted) {
                          _showPermissionDialog();
                          return;
                        }
                        await DndService.enableDnd();
                      },
                      child: const Text("Enable"),
                    ),
                  ]
                  : [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("Ok"),
                    ),
                  ],
        );
      },
    ).then((_) {
      _dndDialogVisible = false; // reset after dialog closes
    });
  }

  Future<void> _stopDndMonitoring() async {
    await _dndSub?.cancel();

    await DndService.disableDnd();
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Permission Required"),
            content: const Text(
              "This app needs permission to control Do Not Disturb.",
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await DndService.requestPermission();
                },
                child: const Text("Open Settings"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomCheckTile(
      toggleBool: dndModeToggle,
      onChanged: (val) async {
        if (val == null) return;
        await _dndModeToggle(val);
      },
      title: "DND Mode",
    );
  }
}
