import 'package:flutter/material.dart';

class MemberAvatar extends StatelessWidget {
  final String name;

  const MemberAvatar({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      child: Text(name[0].toUpperCase()),
    );
  }
}
