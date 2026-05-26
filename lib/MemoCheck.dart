import 'package:aprender/aprender.dart';
import 'package:flutter/material.dart';
import 'aprender.dart';

class Memocheck extends StatelessWidget {
  const Memocheck({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Aprender()),
              );
            },
            icon: Icon(Icons.arrow_back_ios),
          ),
          title: const Text('MemoCheck'),
        ),
        
      ),
    );
  }
}
