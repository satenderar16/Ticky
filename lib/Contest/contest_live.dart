import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:quthon/Auth/auth_provider.dart';
// import 'package:quthon/Auth/auth_provider.dart';
import 'package:quthon/Contest/contest_notifier.dart';
// import 'package:quthon/Service/window_service.dart';
// import 'package:quthon/Contest/widgets.dart';
import 'package:quthon/Test/contest_page.dart';
import 'package:quthon/Test/contest_page_notifier.dart';
// import 'package:quthon/Theme/provider.dart';
import 'package:quthon/Widgets/animated_loading.dart';
// import 'package:quthon/main.dart';
import 'package:quthon/Widgets/utils.dart';
import 'package:quthon/Widgets/widgets.dart';
// import 'package:flutter_windowmanager/flutter_windowmanager.dart';
// import '../Test/countdown_notifier.dart';
import 'contest_model.dart';

class ContestLive extends ConsumerWidget {
  ContestLive({super.key});
  final GlobalKey<ScaffoldState> contextLiveScaffold =
      GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authProvider = ref.watch(authNotifierProvider.notifier);
    final contestNotifier = ref.watch(contestProvider.notifier);
    final double paddingBottom = MediaQuery.paddingOf(context).bottom;
    final colorScheme = Theme.of(context).colorScheme;
    // final auth = ref.watch(authNotifierProvider);
    // final authNotifier = ref.watch(authNotifierProvider.notifier);
    final double size =
        MediaQuery.sizeOf(context).width >= 600
            ? 300
            : MediaQuery.sizeOf(context).width * .6;

    return Scaffold(
      // extendBodyBehindAppBar: true,
      key: contextLiveScaffold,
      extendBody: true,
      endDrawerEnableOpenDragGesture: false,
      endDrawer: ProfileDrawer(),
      appBar: AppBar(
        clipBehavior: Clip.antiAlias,
        // scrolledUnderElevation: 5,
        bottom: PreferredSize(
          preferredSize: Size(double.infinity, 1),
          child: Divider(height: 1, color: colorScheme.surfaceContainer),
        ),
        // floating: true,
        surfaceTintColor: colorScheme.surfaceContainer,

        backgroundColor: colorScheme.surfaceContainerLowest,

        elevation: 4,
        shadowColor: colorScheme.scrim.withAlpha(40),
        title: Material(
          color: colorScheme.surfaceContainerLowest,
          child: Image.asset(
            'assets/ic_launcher192.png',
            fit: BoxFit.cover,
            height: kToolbarHeight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await authProvider.repository.refreshTokens(autoRefresh: false);
              } catch (e) {
                debugPrint(e.toString());
              }
            },
            child: Text('http'),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Material(
              clipBehavior: Clip.hardEdge,
              color: colorScheme.surfaceContainerLowest,
              shape: CircleBorder(
                side: BorderSide(color: colorScheme.surfaceContainer),
              ),
              child: InkWell(
                onTap: () {
                  contextLiveScaffold.currentState?.openEndDrawer();
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(Icons.person, color: colorScheme.outline),
                ),
              ),
            ),
          ),
        ],
      ),

      body: Builder(
        builder: (context) {
          final contestState = ref.watch(contestProvider);

          if (contestState.isLoading) {
            return Center(
              child: SingleChildScrollView(
                child: RepaintBoundary(child: QuestionLoaderAnimation()),
              ),
            );
          }
          if (contestState.onError != null) {
            return Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    Center(
                      child: Image.asset(
                        "assets/error_page.png",
                        fit: BoxFit.contain,
                        height: 250,
                      ),
                    ),
                    Text(contestState.onError ?? 'Something Went wrong'),
                    TextButton(
                      style: ButtonStyle(
                        side: WidgetStatePropertyAll(
                          BorderSide(color: colorScheme.surfaceContainer),
                        ),
                      ),

                      onPressed: contestNotifier.refreshContests,
                      child: Text("Retry"),
                    ),
                  ],
                ),
              ),
            );
          }

          if (contestState.contests.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                // physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  spacing: 8,
                  children: [
                    Image.asset(
                      "assets/home_page_empty_contest.png",
                      width: size,
                    ),
                    Center(
                      child: Text(
                        "No Upcoming Tests Available",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    TextButton(
                      style: ButtonStyle(
                        side: WidgetStatePropertyAll(
                          BorderSide(color: colorScheme.surfaceContainer),
                        ),
                      ),

                      onPressed: contestNotifier.refreshContests,
                      child: Text("Retry"),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            /// avoid loading when data and user refresh instead just use utilize the data or error state at the end:
            onRefresh: () async {
              await contestNotifier.silentRefreshContests();
              ref.invalidate(
                contestPageProvider,
              ); // invalide or dispose the provider to remove any cache value :optional
            },

            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 700),
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: paddingBottom + 16,
                  ),
                  itemCount: contestState.contests.length,
                  itemBuilder: (context, index) {
                    final contest = contestState.contests[index];
                    return ContestCard(
                      contest: contest,
                      key: ValueKey(contest.id),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ContestCard extends ConsumerWidget {
  final ContestDetailModel contest;

  const ContestCard({super.key, required this.contest});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formattedDate = DateFormat('dd MMM').format(contest.startAt);
    final formattedTime = DateFormat('h:mm a').format(contest.startAt);

    final day = DateFormat('EEE').format(contest.startAt);
    final colorScheme = Theme.of(context).colorScheme;

    void cardTap() {
      ref.read(contestProvider.notifier).setSelectedContest(contest);
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => ContestPage()));
    }

    return StyledContainer(
      margin: EdgeInsetsGeometry.only(top: 12),
      padding: EdgeInsetsGeometry.all(0),
      child: InkWell(
        borderRadius: BorderRadius.circular(19), //outer -1:
        onTap: cardTap,
        child: Container(
          padding: EdgeInsets.all(12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text.rich(
                      textAlign: TextAlign.center,
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '$day\n',
                            style: TextTheme.of(context).labelSmall,
                          ),
                          TextSpan(
                            text: '$formattedTime\n',
                            style: TextTheme.of(
                              context,
                            ).bodyLarge?.copyWith(color: colorScheme.primary),
                          ),

                          TextSpan(
                            text: formattedDate,
                            style: TextTheme.of(context).labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                VerticalDivider(
                  color: colorScheme.surfaceContainer,
                  indent: 6,
                  endIndent: 6,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 4,
                    children: [
                      Text(
                        contest.name,

                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: colorScheme.primary),
                      ),
                      Text(
                        contest.description ?? 'description',
                        style: TextTheme.of(context).bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileDrawer extends ConsumerStatefulWidget {
  const ProfileDrawer({super.key});

  @override
  ConsumerState<ProfileDrawer> createState() => _ProfileDrawerState();
}

class _ProfileDrawerState extends ConsumerState<ProfileDrawer> {
  bool _isSigningOut = false;
  String? _errorMessage;

  Future<void> _handleSignOut(BuildContext context) async {
    final authNotifier = ref.read(authNotifierProvider.notifier);

    setState(() {
      _isSigningOut = true;
      _errorMessage = null;
    });

    try {
      await authNotifier.signOut();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Drawer(
      backgroundColor: colorScheme.surfaceContainerLowest,
      child: SafeArea(
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  // --- Profile Section ---
                  Material(
                    color: colorScheme.surfaceContainerLowest,
                    clipBehavior: Clip.antiAlias,
                    shape: CircleBorder(
                      side: BorderSide(color: colorScheme.surfaceContainer),
                    ),
                    child: const SizedBox(
                      height: 100,
                      width: 100,
                      child: Icon(Icons.person, size: 80),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: 'Name\n', style: textTheme.labelSmall),
                        TextSpan(
                          text:
                              '${auth.user?.firstName ?? ''} ${auth.user?.lastName ?? ''}',
                          style: textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  Divider(color: colorScheme.surfaceContainer),

                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Username\n',
                          style: textTheme.labelSmall,
                        ),
                        TextSpan(
                          text: auth.user?.username ?? '',
                          style: textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  Divider(color: colorScheme.surfaceContainer),

                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: 'Email\n', style: textTheme.labelSmall),
                        TextSpan(
                          text: auth.user?.email ?? '',
                          style: textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),

            // --- Sign Out Button + Inline Error ---
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ),

                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed:
                      _isSigningOut ? null : () => _handleSignOut(context),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: SizedBox(
                      width: double.infinity,
                      child: StyledContainer(
                        margin: const EdgeInsets.only(
                          bottom: 24,
                          left: 12,
                          right: 12,
                        ),
                        offset: const Offset(0, 12),
                        child: Center(
                          child:
                              _isSigningOut
                                  ? SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeCap: StrokeCap.round,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.logout_rounded),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Sign Out',
                                        style: textTheme.labelLarge?.copyWith(
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
