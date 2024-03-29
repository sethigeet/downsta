import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:downsta/globals.dart';
import 'package:downsta/screens/screens.dart';
import 'package:downsta/services/services.dart';

Future main() async {
  // NOTE: This is required for `path_provider` to work properly!
  WidgetsFlutterBinding.ensureInitialized();

  final db = DB();
  var lastLoggedInUser = await db.getLastLoggedInUser();
  if (lastLoggedInUser == null) {
    final loggedInUsers = await db.getLoggedInUsers() ?? [];
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
        Provider<DB>(
          create: (context) => db,
          dispose: (context, db) => db.close(),
        ),
        ChangeNotifierProvider.value(value: await Downloader.create(db)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // ask for permissions
    if (kIsMobile) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (await Permission.storage.request().isGranted) {
        } else if (await Permission.speech.isPermanentlyDenied) {
          // ignore: use_build_context_synchronously
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Storage Permission"),
                content: const SingleChildScrollView(
                  child: ListBody(
                    children: [
                      Text(
                          "Permission for storage access is required for downloading!"),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text("Okay"),
                    onPressed: () => openAppSettings(),
                  ),
                ],
              );
            },
          );
        }
      });
    }
  }

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
        ReelScreen.routeName: (_) => const ReelScreen(),
        StoryScreen.routeName: (_) => const StoryScreen(),
        HighlightItemsScreen.routeName: (_) => const HighlightItemsScreen(),
        VideoScreen.routeName: (_) => const VideoScreen(),
        HistoryScreen.routeName: (_) => const HistoryScreen(),
      },
    );
  }
}
