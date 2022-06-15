import 'dart:async';

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
        // TODO: Get the correct username after loggin in!
        ChangeNotifierProvider.value(value: await Api.create(""))
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
      initialRoute: "/",
      routes: {
        HomeScreen.routeName: (_) => const HomeScreen(),
        ProfileScreen.routeName: (_) => const ProfileScreen(),
        PostScreen.routeName: (_) => const PostScreen(),
      },
    );
  }
}
