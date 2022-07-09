import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:downsta/services/services.dart';
import 'package:downsta/widgets/widgets.dart';

class HighlightItemsScreenArguments {
  dynamic highlight;
  String username;

  HighlightItemsScreenArguments({
    required this.highlight,
    required this.username,
  });
}

class HighlightItemsScreen extends StatefulWidget {
  const HighlightItemsScreen({Key? key}) : super(key: key);
  static const routeName = "/highlightItems";

  @override
  State<HighlightItemsScreen> createState() => _HighlightItemsScreenState();
}

class _HighlightItemsScreenState extends State<HighlightItemsScreen> {
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments
        as HighlightItemsScreenArguments;
    final highlight = args.highlight;
    final username = args.username;

    final api = context.watch<Api>();
    final items = api.cache.highlightItems[highlight["id"]];
    if (items == null) {
      api.getHighlightItems(highlight["id"]);

      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(),
      body: Stories(
        username: username,
        showHighlights: false,
        stories: items,
      ),
    );
  }
}
