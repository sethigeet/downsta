import 'package:flutter/material.dart';

import 'package:downsta/services/services.dart';

class HistoryItemCard extends StatelessWidget {
  const HistoryItemCard({
    Key? key,
    required this.item,
  }) : super(key: key);

  final HistoryItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Card(
        child: SizedBox(
          height: 100,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              width: 100,
              child: item.coverImgBytes != null
                  ? Image.memory(
                      item.coverImgBytes!,
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.username,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        )),
                    const SizedBox(height: 5),
                    Text("#${item.postId}",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        )),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_vert),
            )
          ]),
        ),
      ),
      onTap: () {},
    );
  }
}
