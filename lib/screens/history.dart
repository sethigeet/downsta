import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:downsta/services/services.dart';
import 'package:downsta/widgets/widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  static const routeName = "/history";

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _scrollController = ScrollController();
  List<HistoryItem>? historyItems;
  int? totalHistoryItems;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_scrollListener);

    final db = Provider.of<DB>(context, listen: false);
    db
        .getHistoryItems()
        .then((items) => db.getTotalHistoryItems().then((total) => setState(() {
              historyItems = items;
              totalHistoryItems = total;
            })));
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();

    super.dispose();
  }

  void _scrollListener() async {
    if (historyItems == null ||
        totalHistoryItems == null ||
        historyItems!.length == totalHistoryItems!) {
      return;
    }

    // if (_scrollController.position.extentAfter <= 100) {
    if (_scrollController.position.extentAfter == 0) {
      final db = Provider.of<DB>(context, listen: false);
      db
          .getHistoryItems(offset: historyItems!.length)
          .then((items) => setState(() => historyItems!.addAll(items)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("History"),
      ),
      body: historyItems == null
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              controller: _scrollController,
              itemCount: historyItems!.length,
              itemBuilder: (context, index) {
                return HistoryItemCard(item: historyItems![index]);
              },
            ),
    );
  }
}
