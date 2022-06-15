import 'dart:async';

import 'package:downsta/screens/login.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import "package:downsta/screens/home.dart";
import "package:downsta/screens/profile.dart";
import 'package:downsta/screens/post.dart';
import 'package:downsta/services/api.dart';

Future main() async {
  // NOTE: This is required for `path_provider` to work properly!
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        // TODO: Save the username to the disk and add support for multiple users
        ChangeNotifierProvider.value(value: await Api.create("<username>"))
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Downsta',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
      initialRoute: LoginScreen.routeName,
      routes: {
        LoginScreen.routeName: (_) => const LoginScreen(),
        HomeScreen.routeName: (_) => const HomeScreen(),
        ProfileScreen.routeName: (_) => const ProfileScreen(),
        PostScreen.routeName: (_) => const PostScreen(),
      },
    );
  }
}
