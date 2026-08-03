import 'package:speech_to_text/speech_to_text.dart' as stt;


class SpeechRecognitionService {

  static final SpeechRecognitionService _instance =
  SpeechRecognitionService._internal();


  factory SpeechRecognitionService() {
    return _instance;
  }


  SpeechRecognitionService._internal();



  final stt.SpeechToText _speech =
  stt.SpeechToText();



  bool _initialized = false;



  bool get isListening =>
      _speech.isListening;



  Future<bool> initialize() async {

    if (_initialized) {
      return true;
    }


    _initialized =
    await _speech.initialize(

      onStatus: (status){

        print(
            "Estado voz: $status"
        );

      },


      onError: (error){

        print(
            "Error voz: $error"
        );

      },

    );


    return _initialized;

  }





  Future<void> startListening({

    required Function(String text) onResult,

  }) async {


    final available =
    await initialize();


    if(!available){

      throw Exception(
          "Reconocimiento de voz no disponible"
      );

    }



    await _speech.listen(

      localeId:
      "es_MX",


      listenMode:
      stt.ListenMode.confirmation,


      partialResults:
      true,


      listenFor:
      const Duration(
        seconds: 30,
      ),


      pauseFor:
      const Duration(
        seconds: 3,
      ),



      onResult:
          (result){


        final text =
            result.recognizedWords;



        if(text.isNotEmpty){

          onResult(text);

        }


      },


    );

  }






  Future<void> stopListening() async {


    if(_speech.isListening){

      await _speech.stop();

    }


  }






  Future<void> cancelListening() async {


    if(_speech.isListening){

      await _speech.cancel();

    }


  }





  void dispose(){

    _speech.stop();

  }

}