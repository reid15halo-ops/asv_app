import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _email = TextEditingController();
  final _pw = TextEditingController();
  final _pwConfirm = TextEditingController();
  String? _emailStatus; // null=unknown, 'ok', 'taken', 'checking'
  Timer? _debounceTimer;
  bool _pwVisible = false;
  bool _pwConfirmVisible = false;
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;
  String? _err;

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

  String? _pwConfirmValidator(String? v) {
    final s = v ?? '';
    if (s.isEmpty) return 'Bitte Passwortbestätigung eingeben.';
    if (s != _pw.text) return 'Passwörter stimmen nicht überein.';
    return null;
  }

  double _passwordStrength() {
    final s = _pw.text;
    if (s.length >= 12 && RegExp(r'[A-Z]').hasMatch(s) && RegExp(r'[0-9]').hasMatch(s)) return 1.0;
    if (s.length >= 8) return 0.66;
    if (s.length >= 6) return 0.33;
    return 0.0;
  }

  String _strengthLabel() {
    final v = _passwordStrength();
    if (v >= 1.0) return 'Strong';
    if (v >= 0.66) return 'Good';
    if (v >= 0.33) return 'Weak';
    return 'Very weak';
  }

  double _passwordStrength() {
    // stronger scoring: points for length, uppercase, digit, symbol
    final s = _pw.text;
    int score = 0;
    if (s.length >= 8) score += 2;
    if (s.length >= 12) score += 2;
    if (RegExp(r'[A-Z]').hasMatch(s)) score += 1;
    if (RegExp(r'[0-9]').hasMatch(s)) score += 1;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(s)) score += 1;
    final max = 7;
    return (score / max).clamp(0.0, 1.0);
  }

  void _onEmailChanged(String v) {
    _emailStatus = 'checking';
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final email = _email.text.trim();
      if (email.isEmpty) {
        setState(() => _emailStatus = null);
        return;
      }
      setState(() => _emailStatus = 'checking');
      final taken = await _checkEmailTaken(email);
      if (mounted) setState(() => _emailStatus = taken ? 'taken' : 'ok');
    });
  }

  Future<bool> _checkEmailTaken(String email) async {
    try {
      // Rufe die Supabase RPC-Funktion auf
      final response = await Supabase.instance.client
          .rpc('check_email_exists', params: {'email_to_check': email});

      // Response ist true wenn E-Mail existiert, false wenn verfügbar
      return response as bool;
    } catch (e) {
      // Bei Fehler (z.B. Netzwerkfehler) geben wir false zurück
      // damit der User nicht blockiert wird
      debugPrint('Error checking email: $e');
      return false;
    }
  }

  Future<void> _signUp() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    setState(() { _busy = true; _err = null; });
    try {
      await Supabase.instance.client.auth.signUp(
        email: _email.text.trim(),
        password: _pw.text,
      );
      if (mounted) {
        // After signup we redirect to the sign-in page where the user can login
        // (or confirm their email first if required by Supabase settings).
        context.go('/auth');
      }
    } on AuthException catch (e) {
      setState(() => _err = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrieren')),
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
                  onChanged: _onEmailChanged,
                ),
                const SizedBox(height: 6),
                if (_emailStatus != null) Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _emailStatus == 'checking' ? 'Prüfe E-Mail...' : (_emailStatus == 'taken' ? 'E-Mail bereits vergeben' : 'E-Mail verfügbar'),
                    style: TextStyle(fontSize: 12, color: _emailStatus == 'taken' ? Colors.red : Colors.green),
                  ),
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
                const SizedBox(height: 8),
                // password strength
                AnimatedBuilder(
                  animation: _pw,
                  builder: (_, __) => Column(children: [
                    LinearProgressIndicator(value: _passwordStrength(), minHeight: 6),
                    const SizedBox(height: 6),
                    Align(alignment: Alignment.centerRight, child: Text(_strengthLabel(), style: const TextStyle(fontSize: 12))),
                  ]),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pwConfirm,
                  obscureText: !_pwConfirmVisible,
                  decoration: InputDecoration(
                    labelText: 'Passwort bestätigen',
                    suffixIcon: IconButton(
                      icon: Icon(_pwConfirmVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _pwConfirmVisible = !_pwConfirmVisible),
                    ),
                  ),
                  validator: _pwConfirmValidator,
                ),
                const SizedBox(height: 16),
                if (_err != null) Text(_err!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: ElevatedButton(onPressed: _busy ? null : _signUp, child: _busy ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Registrieren'))),
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
