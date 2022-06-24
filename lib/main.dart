import 'package:downsta/globals.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:downsta/screens/login.dart';
import "package:downsta/screens/home.dart";
import "package:downsta/screens/profile.dart";
import 'package:downsta/screens/post.dart';
import 'package:downsta/services/api.dart';
import 'package:downsta/services/db.dart';
import 'package:downsta/services/downloader.dart';

Future main() async {
  // NOTE: This is required for `path_provider` to work properly!
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the db
  await DB.initDB();

  final db = await DB.create();
  var lastLoggedInUser = await db.getLastLoggedInUser();
  if (lastLoggedInUser == null) {
    final loggedInUsers = await db.getLoggedInUsers();
    if (loggedInUsers.isEmpty) {
      lastLoggedInUser = "";
    } else {
      lastLoggedInUser = loggedInUsers[0];
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
            value: await Api.create(lastLoggedInUser, db)),
        ChangeNotifierProvider.value(value: db),
        ChangeNotifierProvider.value(value: await Downloader.create(db))
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
      scaffoldMessengerKey: scaffoldMessengerKey,
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
