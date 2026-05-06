import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quthon/Auth/widgets.dart';
import 'package:quthon/Contest/Page/contest_live.dart' hide ProfileDrawer;
import 'package:quthon/DashBoard/RegistrationPage/participates_screen.dart';
import 'package:quthon/Widgets/widgets.dart';

class Dashboard extends ConsumerStatefulWidget {
  const Dashboard({super.key});

  @override
  ConsumerState<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends ConsumerState<Dashboard> {
  final PageController _pageController = PageController();
  final GlobalKey<ScaffoldState> dashboardScaffold = GlobalKey<ScaffoldState>();

  int _currentIndex = 0;

  final pages = const [ContestLive(), ParticipatedScreen()];
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        // if (!didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          _pageController.jumpToPage(0);
          return;
        }

        if (!didPop) {
          final shouldExit = await _showExitBottomSheet(context);
          if (shouldExit) {
            // Actually exit the app
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        key: dashboardScaffold,
        body: PageView(
          controller: _pageController,

          onPageChanged: (index) {
            setState(() => _currentIndex = index);
          },
          children: pages,
        ),
        bottomNavigationBar: _bottomNavbar(context: context),
      ),
    );
  }

  Card _bottomNavbar({required BuildContext context}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: NavigationBar(
        animationDuration: const Duration(milliseconds: 400),
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        backgroundColor: colorScheme.surfaceContainerLowest,
        indicatorColor: colorScheme.primaryContainer,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.local_activity_outlined),
            selectedIcon: Icon(Icons.local_activity),
            label: 'Contests',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'participates',
          ),
        ],
      ),
    );
  }

  Future<bool> _showExitBottomSheet(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      barrierColor: Colors.black12,
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surfaceContainerLowest.withAlpha(0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final mediaPadding = MediaQuery.paddingOf(context);
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: EdgeInsets.only(
              top: 10,
              bottom: mediaPadding.bottom + 12,
              left: 20,
              right: 20,
            ),
            child: StyledContainer(
              border: Border.fromBorderSide(
                BorderSide(
                  // TODO make sure to update this so we only as we are only using th styled container property:
                  color: colorScheme.surfaceContainer,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              padding: EdgeInsets.all(12),
              color: colorScheme.surfaceContainerLowest,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Exit App?",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Are you sure you want to close the app?",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    spacing: 12,
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: ButtonStyle(
                            side: WidgetStatePropertyAll(
                              BorderSide(color: colorScheme.surfaceContainer),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text("Exit"),
                        ),
                      ),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text("Cancel"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    return result ?? false; // false = do not exit
  }
}
