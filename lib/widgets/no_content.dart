import 'package:flutter/material.dart';

class NoContent extends StatelessWidget {
  const NoContent({
    Key? key,
    required this.message,
    required this.icon,
  }) : super(key: key);

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 25),
          const SizedBox(width: 5),
          Text(message, style: const TextStyle(fontSize: 20))
        ],
      ),
    );
  }
}
