import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:asv_app/models/member.dart';
import 'package:asv_app/models/member_group.dart';
import 'package:asv_app/providers/member_provider.dart';

/// Profile Edit Screen - Bearbeiten von Profildaten
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  DateTime? _selectedBirthDate;
  DateTime? _selectedJoinedDate;
  bool _isLoading = false;
  bool _isCreatingNew = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMemberData();
    });
  }

  void _loadMemberData() {
    final memberAsync = ref.read(memberNotifierProvider);
    memberAsync.whenData((member) {
      if (member != null) {
        _firstNameController.text = member.firstName ?? '';
        _lastNameController.text = member.lastName ?? '';
        _emailController.text = member.email ?? '';
        _phoneController.text = member.phone ?? '';
        setState(() {
          _selectedBirthDate = member.birthDate;
          _selectedJoinedDate = member.joinedAt;
          _isCreatingNew = false;
        });
      } else {
        // Neues Member erstellen
        final user = Supabase.instance.client.auth.currentUser;
        if (user?.email != null) {
          _emailController.text = user!.email!;
        }
        setState(() {
          _isCreatingNew = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isCreatingNew ? 'Profil erstellen' : 'Profil bearbeiten'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Card
                if (_isCreatingNew)
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Erstelle dein Mitgliedsprofil, um alle Funktionen der App zu nutzen.',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Vorname
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'Vorname *',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Bitte Vornamen eingeben';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Nachname
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nachname *',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Bitte Nachnamen eingeben';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // E-Mail
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-Mail',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(value)) {
                        return 'Bitte gültige E-Mail eingeben';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Telefon
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Telefon',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                // Geburtstag
                InkWell(
                  onTap: () => _selectBirthDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Geburtstag',
                      prefixIcon: Icon(Icons.cake),
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _selectedBirthDate != null
                          ? '${_selectedBirthDate!.day}.${_selectedBirthDate!.month}.${_selectedBirthDate!.year}'
                          : 'Datum auswählen',
                      style: TextStyle(
                        color: _selectedBirthDate != null ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Beitrittsdatum (nur bei neuem Profil)
                if (_isCreatingNew)
                  InkWell(
                    onTap: () => _selectJoinedDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Beitrittsdatum',
                        prefixIcon: Icon(Icons.event),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _selectedJoinedDate != null
                            ? '${_selectedJoinedDate!.day}.${_selectedJoinedDate!.month}.${_selectedJoinedDate!.year}'
                            : 'Datum auswählen',
                        style: TextStyle(
                          color: _selectedJoinedDate != null ? Colors.black : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                // Speichern Button
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleSave,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isCreatingNew ? 'Profil erstellen' : 'Änderungen speichern'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                // Abbrechen Button
                OutlinedButton(
                  onPressed: _isLoading ? null : () => context.pop(),
                  child: const Text('Abbrechen'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(2000),
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
      helpText: 'Geburtstag auswählen',
    );

    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  Future<void> _selectJoinedDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedJoinedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Beitrittsdatum auswählen',
    );

    if (picked != null && picked != _selectedJoinedDate) {
      setState(() {
        _selectedJoinedDate = picked;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Nicht angemeldet');
      }

      final memberAsync = ref.read(memberNotifierProvider);
      final existingMember = memberAsync.value;

      if (_isCreatingNew || existingMember == null) {
        // Neues Member erstellen
        final newMember = Member(
          userId: user.id,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          birthDate: _selectedBirthDate,
          memberGroup: MemberGroup.aktive, // Default
          joinedAt: _selectedJoinedDate,
          createdAt: DateTime.now(),
        );

        final created = await ref.read(memberNotifierProvider.notifier).createMember(newMember);

        if (created != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profil erfolgreich erstellt!'),
                backgroundColor: Colors.green,
              ),
            );
            context.go('/profile');
          }
        } else {
          throw Exception('Fehler beim Erstellen des Profils');
        }
      } else {
        // Existierendes Member aktualisieren
        final updatedMember = existingMember.copyWith(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          birthDate: _selectedBirthDate,
          updatedAt: DateTime.now(),
        );

        final success = await ref.read(memberNotifierProvider.notifier).updateMember(updatedMember);

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profil erfolgreich aktualisiert!'),
                backgroundColor: Colors.green,
              ),
            );
            context.pop();
          }
        } else {
          throw Exception('Fehler beim Aktualisieren des Profils');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
