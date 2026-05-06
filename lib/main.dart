import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quthon/Auth/Pages/auth_page.dart';
import 'package:quthon/Auth/auth_notifier.dart';
import 'package:quthon/Repository/auth_repository.dart';
import 'package:quthon/Theme/theme.dart';
import 'package:quthon/Theme/util.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  final repo = await AuthRepository.getInstance();
  GoogleFonts.config.allowRuntimeFetching = false;
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith((ref) {
          return AuthNotifier.initial(repository: repo, user: repo.user);
        }),
      ],
      child: MyApp(),
    ),
  );
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
      title: "Tikcy",

      theme: theme.light(),

      darkTheme: theme.dark().copyWith(
        scaffoldBackgroundColor: Color(0xff000000),
      ),
      themeMode: ThemeMode.system,
      home: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          // statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
          // statusBarIconBrightness: Brightness.light,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: AuthPage(key: ValueKey('The_first_page')),
      ),
    );
  }
}
