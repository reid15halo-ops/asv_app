import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignInScreen extends StatefulWidget {
  /// [initialBusy] is provided to make it easy to test the disabled state.
  const SignInScreen({super.key, this.initialBusy = false});

  final bool initialBusy;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _pw = TextEditingController();
  bool _pwVisible = false;
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    _busy = widget.initialBusy;
  }

  bool _validateForm() {
    final form = _formKey.currentState;
    if (form == null) return false;
    return form.validate();
  }

  Future<void> _signIn() async {
    if (!_validateForm()) return;
    setState(() {
      _busy = true;
      _err = null;
    });
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
    if (!_validateForm()) return;
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      await Supabase.instance.client.auth.signUp(
        email: _email.text.trim(),
        password: _pw.text,
      );
      if (mounted) setState(() => _err = 'Registrierung ok. Bitte ggf. E-Mail bestätigen, dann Anmelden.');
    } on AuthException catch (e) {
      setState(() => _err = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _emailValidator(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'E-Mail darf nicht leer sein.';
    final emailReg = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}");
    if (!emailReg.hasMatch(s)) return 'Bitte gültige E-Mail eingeben.';
    return null;
  }

  String? _pwValidator(String? v) {
    final s = v ?? '';
    if (s.isEmpty) return 'Passwort darf nicht leer sein.';
    if (s.length < 6) return 'Passwort muss mindestens 6 Zeichen lang sein.';
    return null;
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
            child: Form(
              key: _formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'E-Mail'),
                  validator: _emailValidator,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pw,
                  obscureText: !_pwVisible,
                  decoration: InputDecoration(
                    labelText: 'Passwort',
                    suffixIcon: IconButton(
                      icon: Icon(_pwVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _pwVisible = !_pwVisible),
                    ),
                  ),
                  validator: _pwValidator,
                ),
                const SizedBox(height: 16),
                if (_err != null) Text(_err!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _busy ? null : _signIn,
                      child: _busy ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Anmelden'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : () => context.go('/auth/signup'),
                      child: _busy ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Registrieren'),
                    ),
                  ),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _pw.dispose();
    super.dispose();
  }
}
