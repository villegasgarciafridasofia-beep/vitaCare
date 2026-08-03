import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';



class MedicationImageStorageService {


  static final MedicationImageStorageService _instance =
  MedicationImageStorageService._internal();


  factory MedicationImageStorageService(){

    return _instance;

  }


  MedicationImageStorageService._internal();




  final FirebaseStorage _storage =
      FirebaseStorage.instance;





  Future<String> uploadMedicationImage({

    required File image,

    required String patientUid,

  }) async {



    try{


      final fileName =

          "${DateTime.now().millisecondsSinceEpoch}.jpg";




      final reference =

      _storage

          .ref()

          .child(
        "medications/$patientUid/images/$fileName",
      );





      final uploadTask =

      await reference.putFile(image);





      final url =

      await uploadTask.ref.getDownloadURL();





      return url;



    }

    catch(e){


      throw Exception(

          "Error subiendo imagen medicamento: $e"

      );


    }


  }







  Future<void> deleteMedicationImage(

      String imageUrl

      ) async {



    try{


      final reference =

      _storage.refFromURL(
        imageUrl,
      );



      await reference.delete();



    }

    catch(e){


      throw Exception(

          "Error eliminando imagen: $e"

      );


    }


  }



}