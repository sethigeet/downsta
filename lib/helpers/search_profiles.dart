import 'dart:async';

import 'package:flutter/material.dart';

import 'package:downsta/widgets/widgets.dart';
import 'package:downsta/services/services.dart';
import 'package:downsta/helpers/helpers.dart';

class SearchProfiles extends SearchDelegate {
  late Completer<List<dynamic>> _completer;
  late Debouncer<String> _debouncer;
  Api api;

  String prevVal = "";
  List<dynamic> prevRes = [];

  SearchProfiles({required this.api}) {
    _completer = Completer<List<dynamic>>();
    _debouncer = Debouncer<String>(
        duration: const Duration(milliseconds: 500),
        cb: (value) async {
          if (value == null || value == "") {
            value = "--recent-searches--";
          }

          if (value == prevVal) {
            _completer.complete(prevRes);

            // reset the completer for the next future!
            _completer = Completer<List<dynamic>>();
            return;
          }

          final res = await api.getSearchRes(value);
          if (res["users"] == null) {
            _completer.complete([]);

            // reset the completer for the next future!
            _completer = Completer<List<dynamic>>();
            return;
          }

          final users = res["users"];
          prevRes = users;
          _completer.complete(users);

          // reset the completer for the next future!
          _completer = Completer<List<dynamic>>();
        });
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () => query = "",
        icon: const Icon(Icons.clear_rounded),
      )
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        query = "";
        close(context, null);
      },
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _build();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _build();
  }

  Widget _build() {
    _debouncer.value = query;

    return FutureBuilder<List<dynamic>>(
      future: _completer.future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorDisplay(message: "${snapshot.error}");
        } else if (snapshot.hasData) {
          final items = snapshot.data!;
          return ListView.builder(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              itemCount: items.length,
              itemBuilder: (context, index) {
                var user = items[index]["user"];
                return UserCard(
                    fullName: user["full_name"],
                    username: user["username"],
                    profilePicUrl: user["profile_pic_url"]);
              });
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
