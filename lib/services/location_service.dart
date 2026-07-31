import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../models/location_model.dart';

class LocationService {
  LocationService({
    FirebaseFirestore? firestore,
  }) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _collection {
    return _db.collection('locations');
  }

  Future<bool> ensurePermission() async {
    final bool serviceEnabled =
    await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception(
        'Activa la ubicación del teléfono para continuar.',
      );
    }

    LocationPermission permission =
    await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception(
        'El permiso de ubicación fue rechazado.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'El permiso de ubicación está bloqueado. '
            'Actívalo desde los ajustes de VitaCare.',
      );
    }

    return true;
  }

  Future<LocationModel> updateCurrentLocation({
    required String patientUid,
    required bool isSharing,
  }) async {
    final String uid = patientUid.trim();

    if (uid.isEmpty) {
      throw ArgumentError(
        'El identificador del paciente está vacío.',
      );
    }

    await ensurePermission();

    final Position position =
    await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );

    final LocationModel location = LocationModel(
      patientUid: uid,
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      altitude: position.altitude,
      speed: position.speed,
      heading: position.heading,
      isSharing: isSharing,
      updatedAt: DateTime.now(),
    );

    await _collection.doc(uid).set(
      location.toMap(),
      SetOptions(merge: true),
    );

    return location;
  }

  Future<void> setSharing({
    required String patientUid,
    required bool isSharing,
  }) async {
    final String uid = patientUid.trim();

    if (uid.isEmpty) {
      throw ArgumentError(
        'El identificador del paciente está vacío.',
      );
    }

    await _collection.doc(uid).set(
      <String, dynamic>{
        'patientUid': uid,
        'isSharing': isSharing,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    if (isSharing) {
      await updateCurrentLocation(
        patientUid: uid,
        isSharing: true,
      );
    }
  }

  Future<LocationModel?> getPatientLocation(
      String patientUid,
      ) async {
    final String uid = patientUid.trim();

    if (uid.isEmpty) return null;

    final DocumentSnapshot<Map<String, dynamic>> document =
    await _collection.doc(uid).get();

    final Map<String, dynamic>? data = document.data();

    if (!document.exists || data == null) {
      return null;
    }

    return LocationModel.fromMap(data);
  }

  Stream<LocationModel?> watchPatientLocation(
      String patientUid,
      ) {
    final String uid = patientUid.trim();

    if (uid.isEmpty) {
      return Stream<LocationModel?>.value(null);
    }

    return _collection.doc(uid).snapshots().map(
          (DocumentSnapshot<Map<String, dynamic>> document) {
        final Map<String, dynamic>? data = document.data();

        if (!document.exists || data == null) {
          return null;
        }

        return LocationModel.fromMap(data);
      },
    );
  }
}
