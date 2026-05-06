import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quthon/Auth/auth_notifier.dart';
import 'package:quthon/Widgets/animations.dart';
import 'package:quthon/Widgets/widgets.dart';

class UserProfile extends ConsumerStatefulWidget {
  const UserProfile({super.key});

  @override
  ConsumerState<UserProfile> createState() => _ProfileDrawerState();
}

class _ProfileDrawerState extends ConsumerState<UserProfile> {
  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;
    // final textTheme = Theme.of(context).textTheme;
    // final mediaPadding = MediaQuery.paddingOf(context);
    return SafeArea(
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Hero(
            tag: 'profile-card',
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 400),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        //top padding for appbar:
                        SizedBox(height: 8 + 40),
                        Material(
                          // elevation: 1,
                          color: colorScheme.surfaceContainerLowest,
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadiusGeometry.circular(24),
                            side: BorderSide(
                              color: colorScheme.surfaceContainer,
                              strokeAlign: BorderSide.strokeAlignInside,
                            ),
                          ),
                          child: Column(
                            children: [
                              //user:
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 16,
                                  bottom: 24,
                                ),
                                child: Column(
                                  spacing: 12,
                                  children: [
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: 100,
                                        maxHeight: 100,
                                      ),
                                      child: ClipPath(
                                        clipper: WavyCircleClipper(
                                          amplitude: 1.4,
                                          frequency: 10,
                                        ),
                                        child: Container(
                                          color:
                                              colorScheme.surfaceContainerLow,
                                          width: double.maxFinite,
                                          height: double.maxFinite,
                                          child: Icon(
                                            Icons.person_2_rounded,
                                            size: 50,
                                            color: colorScheme.outline,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${auth.user?.firstName ?? ''} ${auth.user?.lastName ?? ''}',
                                      style: TextTheme.of(context).bodyLarge,
                                    ),
                                  ],
                                ),
                              ),

                              // details:
                              Column(
                                spacing: 10,
                                children: [
                                  _detailContainer(
                                    context: context,
                                    label: 'User name',
                                    data: auth.user?.username ?? '',
                                  ),
                                  _detailContainer(
                                    context: context,
                                    label: 'Email',
                                    data: auth.user?.email ?? '',
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),

                              //buttton:
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: 350),
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: 24,
                                    left: 16,
                                    right: 16,
                                  ),
                                  child: AsyncButton(
                                    onPressedAsync: () async {
                                      await ref
                                          .read(authNotifierProvider.notifier)
                                          .signOut();
                                      if (!mounted) return '';
                                      // ignore: use_build_context_synchronously
                                      Navigator.of(context).pop();

                                      return '';
                                    },

                                    childText: 'Sign Out',
                                    retryText: 'Try Again',
                                    // continueText: '',
                                    needContinue: false,
                                  ),
                                ),
                              ),
                            ],
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
    );
  }

  Container _detailContainer({
    required BuildContext context,
    required String label,
    required String data,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),

      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextTheme.of(context).labelSmall),
          Text(data, style: TextTheme.of(context).bodyLarge),
        ],
      ),
    );
  }
}
