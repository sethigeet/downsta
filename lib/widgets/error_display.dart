import 'package:flutter/material.dart';

class ErrorDisplay extends StatelessWidget {
  const ErrorDisplay({Key? key, required this.message}) : super(key: key);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(children: [
      const Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red),
          Text("An error occurred!")
        ],
      ),
      Text(message)
    ]));
  }
}
