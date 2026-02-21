import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:downsta/screens/screens.dart';
import 'package:downsta/services/services.dart';
import 'package:downsta/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key, this.addingUser}) : super(key: key);

  static const routeName = "/login";

  final bool? addingUser;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _usernameFieldController = TextEditingController();
  final _passwordFieldController = TextEditingController();

  bool loading = true;
  bool _submitting = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();

    if (widget.addingUser != null && widget.addingUser!) {
      loading = false;
      return;
    }

    final api = Provider.of<Api>(context, listen: false);
    final db = Provider.of<DB>(context, listen: false);
    api.getIsLoggedIn().then((res) async {
      if (res) {
        gotoHomeScreen();
        return;
      }
      if (api.username != "") {
        await api.logout(api.username, makeRequest: false);
        var loggedInUsers = await db.removeLoggedInUser(api.username);
        if (loggedInUsers.isNotEmpty) {
          await api.switchUser(loggedInUsers.first);
          gotoHomeScreen();
          return;
        }
      }

      setState(() => loading = false);
    });
  }

  @override
  void dispose() {
    _usernameFieldController.dispose();
    _passwordFieldController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.surface,
                Color(0xFF12121E),
                Color(0xFF151520),
                AppTheme.surface,
              ],
              stops: [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.surface,
              Color(0xFF12121E),
              Color(0xFF151520),
              AppTheme.surface,
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: screenSize.width > 600 ? 420 : double.infinity,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Logo & Title ──
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.08,
                        ),
                      ),
                      child: Image.asset(
                        "assets/icon.png",
                        height: 72,
                        width: 72,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Downsta",
                      style: AppTheme.displayFont.copyWith(fontSize: 36),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Sign in to continue",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // ── Login Card ──
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainer.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppTheme.outline.withValues(alpha: 0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _usernameFieldController,
                              style: theme.textTheme.bodyLarge,
                              decoration: InputDecoration(
                                hintText: "Username",
                                prefixIcon: Icon(
                                  Icons.person_outline_rounded,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                              ),
                              validator: (String? value) {
                                if (value == null || value.isEmpty) {
                                  return "Username is required!";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordFieldController,
                              obscureText: _obscurePassword,
                              style: theme.textTheme.bodyLarge,
                              decoration: InputDecoration(
                                hintText: "Password",
                                prefixIcon: Icon(
                                  Icons.lock_outline_rounded,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 20,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (String? value) {
                                if (value == null || value.isEmpty) {
                                  return "Password is required!";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _submitting ? null : handleLogin,
                                child:
                                    _submitting
                                        ? SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: theme.colorScheme.onPrimary,
                                          ),
                                        )
                                        : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.login_rounded,
                                              size: 20,
                                              color:
                                                  theme.colorScheme.onPrimary,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              "Sign In",
                                              style: theme.textTheme.labelLarge
                                                  ?.copyWith(
                                                    color:
                                                        theme
                                                            .colorScheme
                                                            .onPrimary,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          ],
                                        ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _submitting = true);

    final snackbarController = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Trying to log in..."),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(days: 365),
      ),
    );

    final api = Provider.of<Api>(context, listen: false);
    final res = await api.login(
      _usernameFieldController.text,
      _passwordFieldController.text,
    );
    snackbarController.close();

    if (res == null) {
      gotoHomeScreen();
      return;
    }

    if (mounted) {
      setState(() => _submitting = false);
    }

    showDialog<void>(
      // ignore: use_build_context_synchronously
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Login error!"),
          content: SingleChildScrollView(
            child: ListBody(children: [Text(res)]),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Okay"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void gotoHomeScreen() {
    Navigator.pushReplacementNamed(context, HomeScreen.routeName);
  }
}
