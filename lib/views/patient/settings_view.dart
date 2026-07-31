import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/user_settings_model.dart';
import '../../services/user_settings_service.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  static const Color primaryDark = Color(0xFF285F50);
  static const Color primaryLight = Color(0xFFE4F1EA);
  static const Color background = Color(0xFFF4F8F5);
  static const Color textDark = Color(0xFF24463E);
  static const Color textSoft = Color(0xFF64756E);
  static const Color borderColor = Color(0xFFE1EAE5);

  final UserSettingsService _settingsService = UserSettingsService();

  UserSettingsModel? _settings;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No existe una sesión activa.';
      });
      return;
    }

    try {
      final settings = await _settingsService.getSettings(user.uid);
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'No fue posible cargar la configuración: $error';
      });
    }
  }

  Future<void> _saveSettings(UserSettingsModel settings) async {
    setState(() {
      _settings = settings;
      _isSaving = true;
    });

    try {
      await _settingsService.saveSettings(
        settings.copyWith(updatedAt: DateTime.now()),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('No se pudo guardar la configuración: $error'),
        ),
      );
      await _loadSettings();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: Colors.white,
        foregroundColor: textDark,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 18),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: primaryDark,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: primaryDark),
      );
    }

    if (_errorMessage != null || _settings == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 54, color: textSoft),
              const SizedBox(height: 14),
              Text(
                _errorMessage ?? 'No fue posible cargar la configuración.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: textDark),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _loadSettings,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Intentar nuevamente'),
              ),
            ],
          ),
        ),
      );
    }

    final settings = _settings!;

    return RefreshIndicator(
      color: primaryDark,
      onRefresh: _loadSettings,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Notificaciones y alarmas',
            style: TextStyle(
              color: textDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _SettingSwitch(
            icon: Icons.notifications_active_outlined,
            title: 'Notificaciones',
            subtitle: 'Recibir recordatorios de medicamentos',
            value: settings.notificationsEnabled,
            onChanged: (value) {
              _saveSettings(
                settings.copyWith(notificationsEnabled: value),
              );
            },
          ),
          _SettingSwitch(
            icon: Icons.volume_up_outlined,
            title: 'Sonido de alarma',
            subtitle: 'Reproducir sonido en los recordatorios',
            value: settings.alarmSoundEnabled,
            onChanged: (value) {
              _saveSettings(
                settings.copyWith(alarmSoundEnabled: value),
              );
            },
          ),
          _SettingSwitch(
            icon: Icons.vibration_rounded,
            title: 'Vibración',
            subtitle: 'Activar vibración en las alarmas',
            value: settings.vibrationEnabled,
            onChanged: (value) {
              _saveSettings(
                settings.copyWith(vibrationEnabled: value),
              );
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Aplicación',
            style: TextStyle(
              color: textDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _SettingOption(
            icon: Icons.language_rounded,
            title: 'Idioma',
            subtitle: settings.language == 'es' ? 'Español' : settings.language,
            onTap: () => _showPending(context, 'Idioma'),
          ),
          _SettingOption(
            icon: Icons.lock_outline_rounded,
            title: 'Privacidad y seguridad',
            subtitle: 'Permisos y protección de datos',
            onTap: () => _showPending(context, 'Privacidad y seguridad'),
          ),
          _SettingOption(
            icon: Icons.info_outline_rounded,
            title: 'Acerca de VitaCare AI',
            subtitle: 'Versión e información de la aplicación',
            onTap: () => _showPending(context, 'Acerca de VitaCare AI'),
          ),
          const SizedBox(height: 14),
          const Text(
            'Tus preferencias se guardan en Firebase y se recuperan al iniciar sesión en otro dispositivo.',
            style: TextStyle(
              color: textSoft,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _showPending(BuildContext context, String option) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('$option se implementará en el siguiente paso.'),
      ),
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _SettingsViewState.borderColor),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: _SettingsViewState.primaryDark,
        secondary: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _SettingsViewState.primaryLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: _SettingsViewState.primaryDark),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: _SettingsViewState.textDark,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: _SettingsViewState.textSoft,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _SettingOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _SettingsViewState.borderColor),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _SettingsViewState.primaryLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: _SettingsViewState.primaryDark),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: _SettingsViewState.textDark,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: _SettingsViewState.textSoft,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
