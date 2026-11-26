import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EmployeeSignIn extends StatefulWidget {
  const EmployeeSignIn({super.key, required this.auth});

  final FirebaseAuth auth;

  @override
  State<EmployeeSignIn> createState() => _EmployeeSignInState();
}

class _EmployeeSignInState extends State<EmployeeSignIn> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  String? error;

  Future<void> signIn() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.auth.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text,
      );
    } on FirebaseAuthException {
      if (mounted) {
        setState(() => error = 'Could not sign in. Check your account.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Employee sign-in')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        AutofillGroup(
          child: Column(
            children: [
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.username],
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: password,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                decoration: const InputDecoration(labelText: 'Password'),
              ),
            ],
          ),
        ),
        if (error != null) Text(error!),
        FilledButton(
          onPressed: busy ? null : signIn,
          child: const Text('Sign in'),
        ),
      ],
    ),
  );
}
