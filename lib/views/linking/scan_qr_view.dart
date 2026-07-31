import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/linking_service.dart';

class ScanQrView extends StatefulWidget { const ScanQrView({super.key}); @override State<ScanQrView> createState()=>_ScanQrViewState(); }
class _ScanQrViewState extends State<ScanQrView>{
  static const primary=Color(0xFF168C7E); final LinkingService _linking=LinkingService(); final MobileScannerController _scanner=MobileScannerController(); bool _processing=false;
  @override void dispose(){_scanner.dispose();super.dispose();}
  Future<void> _process(String raw) async{
    if(_processing)return; setState(()=>_processing=true);
    try{
      final dynamic decoded=jsonDecode(raw); if(decoded is! Map) throw Exception('El QR no pertenece a VitaCare AI.');
      final patientUid=decoded['uid']?.toString().trim()??''; if(patientUid.isEmpty) throw Exception('El QR no contiene un paciente válido.');
      final caregiverUid=FirebaseAuth.instance.currentUser?.uid; if(caregiverUid==null) throw Exception('Tu sesión terminó. Inicia sesión nuevamente.');
      await _linking.linkPatientAndCaregiver(patientUid:patientUid,caregiverUid:caregiverUid);
      if(!mounted)return; ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Paciente vinculado correctamente.'))); Navigator.pop(context,true);
    }catch(e){if(!mounted)return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Exception: ','')))); setState(()=>_processing=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(backgroundColor:const Color(0xFFF4F8F7),appBar:AppBar(backgroundColor:primary,foregroundColor:Colors.white,title:const Text('Vincular paciente',style:TextStyle(fontWeight:FontWeight.w800))),body:SafeArea(child:Padding(padding:const EdgeInsets.all(18),child:Column(children:[
    const Text('Coloca el código QR dentro del recuadro',style:TextStyle(fontSize:19,fontWeight:FontWeight.w800,color:Color(0xFF253238))),const SizedBox(height:7),const Text('La vinculación es privada y el paciente puede tener hasta 3 familiares.',textAlign:TextAlign.center,style:TextStyle(color:Color(0xFF687A78),height:1.4)),const SizedBox(height:20),
    Expanded(child:ClipRRect(borderRadius:BorderRadius.circular(28),child:Stack(fit:StackFit.expand,children:[MobileScanner(controller:_scanner,onDetect:(capture){for(final barcode in capture.barcodes){final value=barcode.rawValue;if(value!=null){_process(value);break;}}}),Container(decoration:BoxDecoration(border:Border.all(color:Colors.white,width:3),borderRadius:BorderRadius.circular(28))),if(_processing)Container(color:Colors.black45,child:const Center(child:CircularProgressIndicator(color:Colors.white))) ]))),
    const SizedBox(height:18),Container(padding:const EdgeInsets.all(15),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18),border:Border.all(color:const Color(0xFFE1ECE8))),child:const Row(children:[Icon(Icons.verified_user_rounded,color:primary),SizedBox(width:11),Expanded(child:Text('Verifica el nombre del paciente después de vincularlo.',style:TextStyle(color:Color(0xFF526864))))]))
  ]))));
}
