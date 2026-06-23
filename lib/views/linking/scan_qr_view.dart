import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../services/linking_service.dart';

class ScanQrView extends StatefulWidget {
  const ScanQrView({super.key});

  @override
  State<ScanQrView> createState() => _ScanQrViewState();
}

class _ScanQrViewState extends State<ScanQrView> {
  final LinkingService linkingService = LinkingService();

  bool scanned = false;

  Future<void> processQr(String rawValue) async {
    if (scanned) return;

    scanned = true;

    try {
      final data = jsonDecode(rawValue);

      final patientUid = data['uid'];

      final caregiverUid =
          FirebaseAuth.instance.currentUser!.uid;

      await linkingService.linkPatientAndCaregiver(
        patientUid: patientUid,
        caregiverUid: caregiverUid,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paciente vinculado correctamente'),
        ),
      );

      Navigator.pop(context);

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );

      scanned = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR'),
        backgroundColor: Colors.teal,
      ),
      body: MobileScanner(
        onDetect: (capture) {

          final barcode = capture.barcodes.first;

          final value = barcode.rawValue;

          if (value != null) {
            processQr(value);
          }
        },
      ),
    );
  }
}