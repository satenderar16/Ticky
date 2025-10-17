import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quthon/Auth/auth_notifier.dart';
// import 'package:intl/intl.dart';
import 'package:quthon/Auth/auth_provider.dart';
// import 'package:quthon/Auth/auth_state.dart';
// import 'package:quthon/Auth/auth_state.dart';
// import 'package:quthon/Auth/user_model.dart';
import 'package:quthon/Contest/contest_live.dart';
import 'package:quthon/Widgets/utils.dart';
import 'package:quthon/Widgets/widgets.dart';

// consider it Home route:
class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage>
    with WidgetsBindingObserver {
  // helps in resycn the time when user uses difference services:
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      debugPrint("app state is paused");
    }
    if (state == AppLifecycleState.inactive) {
      debugPrint("app state is inactive");
    }
    if (state == AppLifecycleState.resumed &&
        ref.read(authNotifierProvider) != AuthState.unauthenticated()) {
      debugPrint("app state is resumed:");
      await ref.read(authNotifierProvider.notifier).reSyncScheduleRefresh();
    }
  }

  bool _hasShownDialog = false;
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    if (authState.sessionExpired != null && !_hasShownDialog) {
      _hasShownDialog = true;
      Future.microtask(() {
        if (context.mounted) sessionExpiryDailog(context, ref);
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldExit = await _showExitBottomSheet(context);
          if (shouldExit) {
            // Actually exit the app
            SystemNavigator.pop();
          }
        }
      },

      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child:
            authState.isAuthenticated
                ? ContestLive(key: ValueKey('contestLive'))
                : const AuthBody(key: ValueKey('authbody')),
      ),
    );
  }

  void sessionExpiryDailog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false, // user must tap OK
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 350),
            child: StyledContainer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- Icon / Visual indicator ---
                  Text(
                    "Session Expired",
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // --- Description ---
                  Text(
                    "It's been a while!, Please re-login",
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: const Text("Re-Login"),

                      style: ButtonStyle(
                        side: WidgetStatePropertyAll(
                          BorderSide(color: colorScheme.surfaceContainer),
                        ),
                        padding: WidgetStatePropertyAll(
                          const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                      onPressed: () {
                        // only shows in while user come to app after a long time and session about to expiry in few seconds or
                        // refresh token is currpted or found null:
                        Navigator.of(context).pop();
                        ref
                            .read(authNotifierProvider.notifier)
                            .sessionTimeOut();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _showExitBottomSheet(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      barrierColor: Colors.transparent,
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

/// --------------------
/// PARENT AUTH SCREEN
/// --------------------
class AuthBody extends StatefulWidget {
  const AuthBody({super.key});

  @override
  State<AuthBody> createState() => _AuthBodyState();
}

class _AuthBodyState extends State<AuthBody> {
  bool isLogin = true;
  bool isLoading = false;
  void toggleLoading(bool value) {
    setState(() {
      isLoading = value;
    });
  }

  void switchForm(bool toLogin) {
    setState(() {
      isLogin = toLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mediaPadding = MediaQuery.paddingOf(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainerLowest.withAlpha(0),
        surfaceTintColor: colorScheme.surfaceContainerLowest.withAlpha(0),
        flexibleSpace: Align(
          alignment: AlignmentGeometry.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 350),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: isLoading ? null : () => switchForm(true),
                    child: StyledContainer(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border:
                          isLogin
                              ? null
                              : Border.fromBorderSide(BorderSide.none),
                      boxShadow: isLogin ? null : [],
                      child: Text(
                        "Login",
                        style: TextTheme.of(context).labelLarge?.copyWith(
                          color:
                              isLogin
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: GestureDetector(
                    onTap: isLoading ? null : () => switchForm(false),
                    child: StyledContainer(
                      boxShadow: isLogin ? [] : null,
                      border:
                          !isLogin
                              ? null
                              : Border.fromBorderSide(BorderSide.none),
                      padding: const EdgeInsets.all(12),

                      child: Text(
                        "Signup",
                        textAlign: TextAlign.center,
                        style: TextTheme.of(context).labelLarge?.copyWith(
                          color:
                              !isLogin
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: 12,
                  left: 12,
                  right: 12,
                  bottom: mediaPadding.bottom + 12,
                ),
                child: StyledContainer(
                  padding: EdgeInsetsGeometry.only(
                    left: 12,
                    right: 12,
                    top: 12,
                    bottom: 0,
                  ),
                  child: AnimatedCrossFade(
                    duration: const Duration(milliseconds: 300),
                    firstChild: LoginForm(isLoading: toggleLoading),
                    secondChild: SignupForm(isLoading: toggleLoading),
                    crossFadeState:
                        isLogin
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                    sizeCurve: Curves.easeInOut,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// --------------------
/// LOGIN FORM
/// --------------------
class LoginForm extends ConsumerStatefulWidget {
  final void Function(bool) isLoading;
  const LoginForm({super.key, required this.isLoading});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final emailOrUsernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  bool isPasswordVisible = false;

  String? emailOrUsernameError;
  String? passwordError;
  String? globalError;

  bool isEmail(String input) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(input.trim());
  }

  Future<void> handleLogin() async {
    setState(() {
      emailOrUsernameError = null;
      passwordError = null;
      globalError = null;
    });

    final input = emailOrUsernameController.text.trim();
    final password = passwordController.text.trim();

    if (input.isEmpty) {
      setState(() => emailOrUsernameError = "Enter email or username");
      return;
    }
    if (password.isEmpty) {
      setState(() => passwordError = "Enter password");
      return;
    }

    final isInputEmail = isEmail(input);
    final email = isInputEmail ? input : null;
    final username = isInputEmail ? null : input;

    setState(() {
      widget.isLoading(true);
      isLoading = true;
    });

    try {
      debugPrint('$email $username $password');
      await Future.delayed(Duration(seconds: 2));
      ;
      await ref
          .read(authNotifierProvider.notifier)
          .signIn(email: email, username: username, password: password);
    } catch (e) {
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains("password")) {
        setState(() => passwordError = "Incorrect password.");
      } else if (errorMsg.contains("user")) {
        setState(() => emailOrUsernameError = "User not found.");
      } else {
        setState(() => globalError = "Login failed. Please try again.");
      }
    } finally {
      setState(() {
        widget.isLoading(false);
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    emailOrUsernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 700),
      child: Column(
        key: const ValueKey('loginForm'),
        children: [
          SizedBox(height: 10),
          CustomTextFormField(
            controller: emailOrUsernameController,
            label: 'Email or Username',
            enabled: !isLoading,
            errorText: emailOrUsernameError,
          ),

          const SizedBox(height: 12),
          CustomTextFormField(
            controller: passwordController,
            label: 'Password',
            enabled: !isLoading,
            errorText: passwordError,
            obscureText: !isPasswordVisible,
            suffixIcon: IconButton(
              icon: Icon(
                !isPasswordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed:
                  () => setState(() => isPasswordVisible = !isPasswordVisible),
            ),
          ),

          const SizedBox(height: 16),
          if (globalError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                globalError!,
                style: TextStyle(color: colorScheme.error),
              ),
            ),
          CupertinoButton(
            padding: const EdgeInsets.all(0),
            onPressed: isLoading ? null : handleLogin,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 300),
              child: SizedBox(
                width: double.infinity,
                child: StyledContainer(
                  margin: EdgeInsetsGeometry.only(bottom: 24),
                  offset: Offset(0, 12),
                  child: Center(
                    child:
                        isLoading
                            ? SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeCap: StrokeCap.round,
                                strokeWidth: 2,
                              ),
                            )
                            : Text(
                              'Login',
                              style: TextTheme.of(context).labelLarge?.copyWith(
                                color: colorScheme.primary,
                              ),
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
}

/// --------------------
/// SIGNUP FORM
/// --------------------
class SignupForm extends ConsumerStatefulWidget {
  final void Function(bool) isLoading;
  const SignupForm({super.key, required this.isLoading});

  @override
  ConsumerState<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends ConsumerState<SignupForm> {
  // to do we can use the form and validators but with this we have more controll :
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool isLoading = false;

  String? firstNameError;
  String? lastNameError;
  String? emailError;
  String? passwordError;
  String? confirmPasswordError;
  String? globalError;

  bool isEmail(String input) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(input.trim());
  }

  Future<void> handleSignup() async {
    setState(() {
      firstNameError = null;
      lastNameError = null;
      emailError = null;
      passwordError = null;
      confirmPasswordError = null;
      globalError = null;
    });

    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (firstName.isEmpty) {
      setState(() => firstNameError = "Enter first name");
      return;
    }
    if (lastName.isEmpty) {
      setState(() => lastNameError = "Enter last name");
      return;
    }
    if (email.isEmpty || !isEmail(email)) {
      setState(() => emailError = "Enter valid email");
      return;
    }
    if (password.isEmpty) {
      setState(() => passwordError = "Enter password");
      return;
    }
    if (confirmPassword.isEmpty) {
      setState(() => confirmPasswordError = "Confirm your password");
      return;
    }
    if (password != confirmPassword) {
      setState(() => confirmPasswordError = "Passwords do not match");
      return;
    }

    setState(() {
      widget.isLoading(true);
      isLoading = true;
    });

    try {
      final user = await ref
          .read(authNotifierProvider.notifier)
          .signUp(
            firstName: firstName,
            lastName: lastName,
            email: email,
            password: password,
          );
      if (user == null) throw "Signup failed";

      await ref
          .read(authNotifierProvider.notifier)
          .signIn(email: email, password: password);
    } catch (e) {
      setState(() => globalError = e.toString());
    } finally {
      setState(() {
        widget.isLoading(false);
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 700),
      child: Column(
        key: const ValueKey('signupForm'),
        children: [
          const SizedBox(height: 10),
          CustomTextFormField(
            controller: firstNameController,
            label: 'First Name',
            enabled: !isLoading,
            errorText: firstNameError,
          ),

          const SizedBox(height: 12),
          CustomTextFormField(
            controller: lastNameController,
            label: 'Last Name',
            enabled: !isLoading,
            errorText: lastNameError,
          ),

          const SizedBox(height: 12),
          CustomTextFormField(
            controller: emailController,
            label: 'Email',
            enabled: !isLoading,
            errorText: emailError,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 12),
          CustomTextFormField(
            controller: passwordController,
            label: 'Password',
            enabled: !isLoading,
            errorText: passwordError,
            obscureText: !isPasswordVisible,
            suffixIcon: IconButton(
              icon: Icon(
                !isPasswordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed:
                  () => setState(() => isPasswordVisible = !isPasswordVisible),
            ),
          ),

          const SizedBox(height: 12),
          CustomTextFormField(
            controller: confirmPasswordController,
            label: 'Confirm Password',
            enabled: !isLoading,

            errorText: confirmPasswordError,
            obscureText: !isConfirmPasswordVisible,
            suffixIcon: IconButton(
              icon: Icon(
                !isConfirmPasswordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed:
                  () => setState(
                    () => isConfirmPasswordVisible = !isConfirmPasswordVisible,
                  ),
            ),
          ),

          const SizedBox(height: 16),
          if (globalError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                globalError!,
                style: TextStyle(color: colorScheme.error),
              ),
            ),
          CupertinoButton(
            padding: const EdgeInsets.all(0),
            onPressed: isLoading ? null : handleSignup,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 300),
              child: SizedBox(
                width: double.infinity,
                child: StyledContainer(
                  margin: EdgeInsetsGeometry.only(bottom: 24),
                  offset: Offset(0, 12),
                  child: Center(
                    child:
                        isLoading
                            ? SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeCap: StrokeCap.round,
                                strokeWidth: 2,
                              ),
                            )
                            : Text(
                              'SignUp',
                              style: TextTheme.of(context).labelLarge?.copyWith(
                                color: colorScheme.primary,
                              ),
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
}

class CustomTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? errorText;
  final bool enabled;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;

  const CustomTextFormField({
    super.key,
    required this.controller,
    required this.label,
    this.errorText,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,

        // filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.surfaceContainer),
          borderRadius: BorderRadius.circular(20),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.primary),
          borderRadius: BorderRadius.circular(20),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.error),
          borderRadius: BorderRadius.circular(20),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
