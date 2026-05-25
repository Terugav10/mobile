import 'package:flutter/material.dart';
import 'quizMyBrain.dart';

class Aprender extends StatelessWidget {
  const Aprender({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: Text('')),
        drawer: Drawer(
          child: ListView(
            children: [
              Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Aprender(),
                        ),
                      );
                    },
                    child: Icon(
                      Icons.arrow_back,
                      size: 30,
                      color: Color(0XFF3C00A7),
                    ),
                  ),
                ],
              ),
              Icon(Icons.account_circle, size: 200, color: Color(0XFF3C00A7)),
              ListTile(
                title: Text(
                  'home',
                  style: TextStyle(
                    color: Color(0XFF3C00A7),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Aprender()),
                  );
                },
              ),
              Divider(
                endIndent: 20,
                indent: 20,
                thickness: 1,
                color: Color(0XFF3C00A7),
              ),
              ListTile(
                title: Text(
                  'QuizMyBrain',
                  style: TextStyle(
                    color: Color(0XFF3C00A7),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QuizMyBrain(),
                    ),
                  );
                },
              ),
              Divider(
                endIndent: 20,
                indent: 20,
                thickness: 1,
                color: Color(0XFF3C00A7),
              ),
              ListTile(
                title: Text(
                  'GeniusPLay',
                  style: TextStyle(
                    color: Color(0XFF3C00A7),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Aprender()),
                  );
                },
              ),
              Divider(
                endIndent: 20,
                indent: 20,
                thickness: 1,
                color: Color(0XFF3C00A7),
              ),
              ListTile(
                title: Text(
                  'MemoCheck',
                  style: TextStyle(
                    color: Color(0XFF3C00A7),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Aprender()),
                  );
                },
              ),
              Divider(
                endIndent: 20,
                indent: 20,
                thickness: 1,
                color: Color(0XFF3C00A7),
              ),
              ListTile(
                title: Text(
                  'sair',
                  style: TextStyle(
                    color: Color(0XFF3C00A7),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Aprender()),
                  );
                },
              ),
            ],
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo.png', width: 300, height: 300),
              Text('Bem-vindo ao Aprender+'),
            ],
          ),
        ),
      ),
    );
  }
}
