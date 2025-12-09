import 'package:flutter/material.dart';

class CgpaPage extends StatelessWidget {
  const CgpaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CGPA'),
      ),
      body: const Center(
        child: Text(
          'This is the CGPA page',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}