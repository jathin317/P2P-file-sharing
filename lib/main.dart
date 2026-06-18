import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "P2P File Sharing",
      theme: ThemeData.dark(useMaterial3: true),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(padding: const EdgeInsets.all(24), child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("P2P File Sharing", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24,),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "Enter Your Name",
                border: OutlineInputBorder()
              ),
            ),
            const SizedBox(height: 16,),
            ElevatedButton(onPressed: () {
              if(_controller.text.trim().isEmpty)
              {
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => HomeScreen(username: _controller.text.trim()),)
              );
            },
            child: const Text("Join Network"),
            )
          ],
        ),),
      ),
    );
  }
}
