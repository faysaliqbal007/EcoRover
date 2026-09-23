// ============================================================
//  EcoRover — Settings Screen
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../app/theme.dart';
import '../app/constants.dart';
import '../providers/settings_provider.dart';
import '../providers/rover_provider.dart';
import '../providers/motion_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _controllerIpCtrl;
  late TextEditingController _cameraIpCtrl;
  late TextEditingController _udpPortCtrl;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider).valueOrNull ?? const EcoSettings();
    _controllerIpCtrl =
        TextEditingController(text: settings.controllerIp);
    _cameraIpCtrl = TextEditingController(text: settings.cameraIp);
    _udpPortCtrl =
        TextEditingController(text: settings.udpPort.toString());

    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() => _appVersion = '${info.version}+${info.buildNumber}');
      }
    });
  }

  @override
  void dispose() {
    _controllerIpCtrl.dispose();
    _cameraIpCtrl.dispose();
    _udpPortCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conn = ref.watch(connectionNotifierProvider);
    final motionState = ref.watch(motionProvider);

    return Scaffold(
      backgroundColor: EcoColors.background,
      appBar: AppBar(
        backgroundColor: EcoColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: EcoColors.navy),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: EcoColors.navy,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text(
              'SAVE',
              style: TextStyle(
                color: EcoColors.blue,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Connection section
          _SectionHeader('Connection'),
          _SettingsCard(children: [
            _IpField(
              label: 'Controller IP',
              controller: _controllerIpCtrl,
              hint: EcoConstants.defaultControllerIp,
            ),
            _IpField(
              label: 'Camera IP',
              controller: _cameraIpCtrl,
              hint: EcoConstants.defaultCameraIp,
            ),
            _IpField(
              label: 'UDP Port',
              controller: _udpPortCtrl,
              hint: EcoConstants.defaultUdpPort.toString(),
              isPort: true,
            ),
          ]),
          const SizedBox(height: 16),

          // Diagnostics
          _SectionHeader('Diagnostics'),
          _SettingsCard(children: [
            _DiagRow(
              label: 'Controller',
              value: conn.isOnline ? 'ONLINE' : 'OFFLINE',
              valueColor:
                  conn.isOnline ? EcoColors.green : EcoColors.red,
            ),
            _DiagRow(
              label: 'Camera',
              value: conn.cameraOnline ? 'ONLINE' : 'OFFLINE',
              valueColor: conn.cameraOnline
                  ? EcoColors.green
                  : EcoColors.red,
            ),
            _DiagRow(
              label: 'Last contact',
              value: conn.lastSuccess != null
                  ? _formatTime(conn.lastSuccess!)
                  : '—',
            ),
          ]),
          const SizedBox(height: 16),

          // Motion diagnostics
          _SectionHeader('Motion Diagnostics'),
          _SettingsCard(children: [
            _DiagRow(
              label: 'Motion active',
              value: motionState.active ? 'YES' : 'NO',
              valueColor: motionState.active
                  ? EcoColors.green
                  : EcoColors.muted,
            ),
            _DiagRow(
                label: 'Raw X',
                value: motionState.rawX.toStringAsFixed(3)),
            _DiagRow(
                label: 'Raw Y',
                value: motionState.rawY.toStringAsFixed(3)),
            _DiagRow(
                label: 'Raw Z',
                value: motionState.rawZ.toStringAsFixed(3)),
            _DiagRow(
                label: 'Sent X',
                value: motionState.sentX.toStringAsFixed(3)),
            _DiagRow(
                label: 'Sent Y',
                value: motionState.sentY.toStringAsFixed(3)),
            _DiagRow(
                label: 'Sent Z',
                value: motionState.sentZ.toStringAsFixed(3)),
            _DiagRow(
                label: 'Packets sent',
                value: motionState.packetCount.toString()),
          ]),
          const SizedBox(height: 16),

          // Reset
          _SettingsCard(children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.restore, color: EcoColors.muted),
              title: const Text('Reset to defaults',
                  style: TextStyle(color: EcoColors.navy)),
              onTap: () async {
                await ref
                    .read(settingsProvider.notifier)
                    .resetToDefaults();
                final settings =
                    ref.read(settingsProvider).valueOrNull ??
                        const EcoSettings();
                _controllerIpCtrl.text = settings.controllerIp;
                _cameraIpCtrl.text = settings.cameraIp;
                _udpPortCtrl.text = settings.udpPort.toString();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Settings reset to defaults')),
                  );
                }
              },
            ),
          ]),
          const SizedBox(height: 16),

          // About
          _SectionHeader('About'),
          _SettingsCard(children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: EcoColors.navyGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/ecorover_logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.directions_car,
                        color: Colors.white),
                  ),
                ),
              ),
              title: const Text(
                EcoConstants.appName,
                style: TextStyle(
                  color: EcoColors.navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    EcoConstants.appTagline,
                    style: TextStyle(
                      color: EcoColors.muted,
                      fontSize: 10,
                      letterSpacing: 1.5,
                    ),
                  ),
                  if (_appVersion.isNotEmpty)
                    Text(
                      'v$_appVersion',
                      style: const TextStyle(
                        color: EcoColors.muted,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    final notifier = ref.read(settingsProvider.notifier);
    final ip = _controllerIpCtrl.text.trim();
    final cam = _cameraIpCtrl.text.trim();
    final port = int.tryParse(_udpPortCtrl.text.trim()) ??
        EcoConstants.defaultUdpPort;

    if (ip.isNotEmpty) await notifier.setControllerIp(ip);
    if (cam.isNotEmpty) await notifier.setCameraIp(cam);
    await notifier.setUdpPort(port);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved. Restart may be needed.'),
          backgroundColor: EcoColors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

// ---- Helpers ----------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: EcoColors.muted,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: EcoShadows.card,
      ),
      child: Column(children: children),
    );
  }
}

class _IpField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool isPort;

  const _IpField({
    required this.label,
    required this.controller,
    required this.hint,
    this.isPort = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label,
          style: const TextStyle(color: EcoColors.navy, fontSize: 14)),
      trailing: SizedBox(
        width: 140,
        child: TextField(
          controller: controller,
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: EcoColors.blue,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          keyboardType: isPort
              ? TextInputType.number
              : const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: isPort
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: EcoColors.muted),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}

class _DiagRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DiagRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(label,
          style: const TextStyle(color: EcoColors.navy, fontSize: 13)),
      trailing: Text(
        value,
        style: TextStyle(
          color: valueColor ?? EcoColors.muted,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
