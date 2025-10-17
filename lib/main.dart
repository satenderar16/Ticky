import 'dart:async';
// import 'dart:js_interop';
// import 'dart:nativewrappers/_internal/vm/lib/ffi_allocation_patch.dart';
// import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quthon/Auth/Pages/auth_page.dart';
import 'package:quthon/Auth/auth_provider.dart';
import 'package:quthon/Auth/auth_repository.dart';
import 'package:quthon/Auth/http_manager.dart';
// import 'package:quthon/Test/contest_page.dart';
import 'package:quthon/Theme/theme.dart';
import 'package:quthon/Theme/util.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = createTextTheme(context, "Inter", "Poppins");

    MaterialTheme theme = MaterialTheme(textTheme);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Tiixs",

      theme: theme.light(),

      darkTheme: theme.dark().copyWith(
        scaffoldBackgroundColor: Color(0xff000000),
      ),
      themeMode: ThemeMode.system,
      home: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: SplashPage(),
      ),
    );
  }
}

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  Object? _error; // <-- store potential error
  bool _showSplash = true;
  bool _readyToShowMain = false; // <-- NEW: build main screen early

  void _onSplashPhase({Object? error, required bool finished}) {
    setState(() {
      _error = error;
      if (!finished) {
        // Task finished but animation still running → build main screen
        _readyToShowMain = true;
      } else {
        // Outgoing animation done → remove splash

        _showSplash = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_readyToShowMain) ...[AuthPage(key: ValueKey('The_first_page'))],
        if (_showSplash)
          LogoSplashScreen(
            key: ValueKey('splash'),
            task: () async {
              // final repo =
              await AuthRepository.getInstance(); // ensures the auth repository have instance to use , authNotifier:

              final authState = ref.read(authNotifierProvider).isAuthenticated;
              final authNotifier = ref.read(authNotifierProvider.notifier);
              if (!authState) return;

              // when user is authenticated:
              await authNotifier.scheduleRefresh(
                accessTime:
                    authNotifier.repository.accessTokenExpiry ??
                    DateTime.now().toUtc(),
              );
            },
            onPhase: _onSplashPhase, // <-- renamed callback
          ),
      ],
    );
  }
}

/// Splash screen widget
class LogoSplashScreen extends StatefulWidget {
  final void Function({Object? error, required bool finished})
  onPhase; // <-- new

  final Future<void> Function()? task;
  const LogoSplashScreen({
    required this.onPhase,
    super.key,
    required this.task,
  });
  @override
  State createState() => _LogoSplashScreenState();
}

class _LogoSplashScreenState extends State<LogoSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _dotsController;
  late Animation<double> _zoomAnimation;
  late Animation<double> _logoOpacityAnimation;
  Timer? _dotsTimer;
  bool _showDots = false;
  bool _shouldAnimateOutgoing = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );
    _zoomAnimation = Tween<double>(
      begin: 1.0,
      end: 20.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _logoOpacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _dotsController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    )..repeat();
    _startAsyncTask();
  }

  Future<void> _startAsyncTask() async {
    bool dotsShown = false;
    Object? taskError;

    _dotsTimer = Timer(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _showDots = true;
          dotsShown = true;
          _shouldAnimateOutgoing = true;
        });
        _dotsController.repeat();
      }
    });

    try {
      await Future.wait([
        widget.task?.call() ?? Future.value(),
        Future.delayed(Duration(milliseconds: 700)),
      ]);
    } catch (e, st) {
      // debugPrint(' performAsyncTask error: $e\n$st');
      taskError = e;
    }

    _dotsTimer?.cancel();
    _dotsTimer = null;

    // Notify patent: task completed (build main screen)
    if (mounted) widget.onPhase(error: taskError, finished: false);

    if (!dotsShown) {
      // Quick task <1s → skip zoom, just fade
      if (mounted) {
        _controller.forward().whenComplete(() {
          if (mounted) widget.onPhase(error: taskError, finished: true);
        });
      }
      return;
    }

    if (mounted) {
      setState(() => _showDots = false);
      _dotsController.stop();
    }
    await Future.delayed(Duration(milliseconds: 300));

    if (!mounted) return;

    _controller.forward().whenComplete(() {
      if (mounted) widget.onPhase(error: taskError, finished: true);
    });
  }

  /// Animated dots below the logo
  Widget _buildAnimatedDots() {
    final colorScheme = Theme.of(context).colorScheme;
    final dotColors = [
      colorScheme.primary.withAlpha(80),
      colorScheme.primary.withAlpha(150),
      colorScheme.primary,
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _dotsController,
          builder: (context, child) {
            double t = (_dotsController.value + index / 3) % 1.0;
            int colorIndex = (t * dotColors.length).floor() % dotColors.length;
            Color color = dotColors[colorIndex];

            return AnimatedOpacity(
              duration: Duration(milliseconds: 300),
              opacity: _showDots ? 1.0 : 0.0,
              child: Container(
                width: 6,
                height: 6,
                margin: EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            );
          },
        );
      }),
    );
  }

  @override
  void dispose() {
    _dotsTimer?.cancel();
    _controller.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo outgoing animation (only if task >1s)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                double scale =
                    _shouldAnimateOutgoing ? _zoomAnimation.value : 1.0;
                double opacity =
                    _shouldAnimateOutgoing ? _logoOpacityAnimation.value : 1.0;

                return Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 100,
                      height: 100,
                      child: Image.network(
                        'https://media.istockphoto.com/id/814423752/photo/eye-of-model-with-colorful-art-make-up-close-up.jpg?s=612x612&w=0&k=20&c=l15OdMWjgCKycMMShP8UK94ELVlEGvt7GmB_esHWPYE=',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            // Animated dots
            _buildAnimatedDots(),
          ],
        ),
      ),
    );
  }
}
