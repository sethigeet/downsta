import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:downsta/services/db.dart';
import 'package:downsta/models/history_item.dart';
import 'package:downsta/widgets/history_item_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  static const routeName = "/history";

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<DB>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("History"),
      ),
      body: FutureBuilder(
        future: db.getHistoryItems(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(
              child: Column(children: [
                Row(
                  children: const [
                    Text("An error occurred!"),
                    Icon(
                      Icons.error,
                      color: Colors.red,
                    )
                  ],
                ),
                Text(snap.error.toString())
              ]),
            );
          }

          final items = snap.data as List<HistoryItem>;
          if (items.isEmpty) {
            return Center(
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.insert_drive_file_outlined, size: 35),
                    SizedBox(width: 5),
                    Text(
                      "No pictures downloaded yet!",
                      style: TextStyle(fontSize: 20),
                    )
                  ]),
            );
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              return HistoryItemCard(item: items[index]);
            },
          );
        },
      ),
    );
  }
}
