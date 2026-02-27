import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:downsta/globals.dart';
import 'package:downsta/theme.dart';
import 'package:downsta/screens/screens.dart';
import 'package:downsta/services/services.dart';

Future main() async {
  // NOTE: This is required for `path_provider` to work properly!
  WidgetsFlutterBinding.ensureInitialized();

  final db = DB();
  final loggedInUsers = await db.getLoggedInUsers() ?? [];

  // Determine initial user for the Api
  String initialUser;
  if (loggedInUsers.length > 1) {
    // Multiple accounts: defer selection to AccountSelectionScreen
    initialUser = "";
  } else {
    initialUser = await db.getLastLoggedInUser() ?? 
        (loggedInUsers.isNotEmpty ? loggedInUsers[0] : "");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: await Api.create(initialUser, db),
        ),
        Provider<DB>(
          create: (context) => db,
          dispose: (context, db) => db.close(),
        ),
        ChangeNotifierProvider.value(value: await Downloader.create(db)),
      ],
      child: MyApp(loggedInUsers: loggedInUsers),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key, required this.loggedInUsers}) : super(key: key);

  final List<String> loggedInUsers;

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
          showDialog<void>(
            // ignore: use_build_context_synchronously
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Storage Permission"),
                content: const SingleChildScrollView(
                  child: ListBody(
                    children: [
                      Text(
                        "Permission for storage access is required for downloading!",
                      ),
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
    final showAccountSelection = widget.loggedInUsers.length > 1;

    return MaterialApp(
      title: 'Downsta',
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: AppTheme.darkTheme,
      initialRoute: showAccountSelection
          ? AccountSelectionScreen.routeName
          : LoginScreen.routeName,
      routes: {
        AccountSelectionScreen.routeName: (_) => AccountSelectionScreen(
              loggedInUsers: widget.loggedInUsers,
            ),
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
