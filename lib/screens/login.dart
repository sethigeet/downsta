import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:downsta/screens/home.dart';
import 'package:downsta/services/api.dart';

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

  @override
  void initState() {
    super.initState();

    if (widget.addingUser != null && widget.addingUser!) {
      loading = false;
      return;
    }

    final api = Provider.of<Api>(context, listen: false);
    api.getIsLoggedIn().then((res) {
      if (res) {
        gotoHomeScreen();
        return;
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
      return const Center(child: CircularProgressIndicator());
    }

    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Center(
          child: Container(
        constraints: BoxConstraints(
          maxHeight: screenSize.height * 0.6,
          maxWidth: screenSize.width * 0.75,
        ),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              Image.asset(
                "assets/icon.png",
                height: 100,
                width: 100,
                fit: BoxFit.cover,
              ),
              Text(
                "Login",
                style: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: const [
                  Icon(Icons.person, size: 15),
                  SizedBox(width: 5),
                  Text("Username", style: TextStyle(fontSize: 15)),
                ],
              ),
              TextFormField(
                controller: _usernameFieldController,
                decoration: const InputDecoration(
                  hintText: "Enter your username",
                ),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return "Username is required!";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: const [
                  Icon(Icons.lock, size: 15),
                  SizedBox(width: 5),
                  Text("Password", style: TextStyle(fontSize: 15)),
                ],
              ),
              TextFormField(
                controller: _passwordFieldController,
                decoration: const InputDecoration(
                  hintText: "Enter your password",
                ),
                obscureText: true,
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return "Password is required!";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: handleLogin,
                icon: const Icon(
                  Icons.arrow_right_rounded,
                  size: 25,
                ),
                label: const Text("Submit"),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
        ),
      )),
    );
  }

  Future<void> handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final snackbarController = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Trying to log in..."),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(days: 365),
      ),
    );

    final api = Provider.of<Api>(context, listen: false);
    final res = await api.login(
        _usernameFieldController.text, _passwordFieldController.text);
    snackbarController.close();
    if (res == null) {
      gotoHomeScreen();
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Login error!"),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text(res),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Okay"),
              onPressed: () {
                Navigator.of(context).pop();
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
