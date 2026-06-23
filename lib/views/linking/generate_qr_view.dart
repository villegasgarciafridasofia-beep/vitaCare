import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../services/firestore_service.dart';

class GenerateQrView extends StatefulWidget {
  const GenerateQrView({super.key});

  @override
  State<GenerateQrView> createState() => _GenerateQrViewState();
}

class _GenerateQrViewState extends State<GenerateQrView> {
  final FirestoreService firestoreService = FirestoreService();

  String qrData = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadQr();
  }

  Future<void> loadQr() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final user = await firestoreService.getUser(uid);

      if (user == null) return;

      final qrJson = jsonEncode({
        'uid': uid,
        'code': user.linkCode,
      });

      setState(() {
        qrData = qrJson;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi QR de Vinculación'),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Comparte este QR con tu cuidador',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),

            QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 280,
            ),

            const SizedBox(height: 20),

            SelectableText(
              qrData,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}