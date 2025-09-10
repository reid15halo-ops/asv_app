import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _pw = TextEditingController();
  bool _busy = false;
  String? _err;

  Future<void> _signIn() async {
    setState(() { _busy = true; _err = null; });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _email.text.trim(),
        password: _pw.text,
      );
      if (mounted) context.go('/');
    } on AuthException catch (e) {
      setState(() => _err = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signUp() async {
    setState(() { _busy = true; _err = null; });
    try {
      await Supabase.instance.client.auth.signUp(
        email: _email.text.trim(),
        password: _pw.text,
      );
      if (mounted) _err = 'Registrierung ok. Bitte ggf. E-Mail bestätigen, dann Anmelden.';
    } on AuthException catch (e) {
      setState(() => _err = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Anmelden')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: _email, decoration: const InputDecoration(labelText: 'E-Mail')),
              const SizedBox(height: 12),
              TextField(controller: _pw, obscureText: true, decoration: const InputDecoration(labelText: 'Passwort')),
              const SizedBox(height: 16),
              if (_err != null) Text(_err!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: ElevatedButton(onPressed: _busy ? null : _signIn, child: const Text('Anmelden')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(onPressed: _busy ? null : _signUp, child: const Text('Registrieren')),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
