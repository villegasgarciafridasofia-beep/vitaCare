import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import 'patient_location_view.dart';

class MyPatientsView extends StatefulWidget {
  const MyPatientsView({super.key});
  @override State<MyPatientsView> createState() => _MyPatientsViewState();
}
class _MyPatientsViewState extends State<MyPatientsView> {
  static const primary = Color(0xFF168C7E);
  final FirestoreService _firestore = FirestoreService();
  late Future<List<UserModel>> _future;
  @override void initState(){super.initState(); _future=_load();}
  Future<List<UserModel>> _load() async {
    final auth=FirebaseAuth.instance.currentUser;
    if(auth==null) throw Exception('No existe una sesión activa.');
    final caregiver=await _firestore.getUser(auth.uid);
    if(caregiver==null || caregiver.patients.isEmpty) return [];
    return _firestore.getPatients(caregiver.patients);
  }
  Future<void> _refresh() async {setState(()=>_future=_load()); await _future;}
  String _age(DateTime birth){final now=DateTime.now(); var years=now.year-birth.year; if(now.month<birth.month || (now.month==birth.month && now.day<birth.day)) years--; return '$years años';}
  @override Widget build(BuildContext context)=>Scaffold(
    backgroundColor: const Color(0xFFF4F8F7),
    appBar: AppBar(backgroundColor: primary, foregroundColor: Colors.white, title: const Text('Personas a mi cargo', style: TextStyle(fontWeight: FontWeight.w800))),
    body: FutureBuilder<List<UserModel>>(future:_future,builder:(context,snapshot){
      if(snapshot.connectionState==ConnectionState.waiting) return const Center(child:CircularProgressIndicator(color:primary));
      if(snapshot.hasError) return _StateView(icon:Icons.error_outline_rounded,title:'No pudimos cargar tus pacientes',subtitle:snapshot.error.toString().replaceFirst('Exception: ',''),button:'Reintentar',onTap:_refresh);
      final patients=snapshot.data??[];
      if(patients.isEmpty) return const _StateView(icon:Icons.people_outline_rounded,title:'Aún no tienes pacientes',subtitle:'Escanea el código QR de un paciente para comenzar a acompañarlo.');
      return RefreshIndicator(onRefresh:_refresh,color:primary,child:ListView(padding:const EdgeInsets.all(18),children:[
        Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF168C7E),Color(0xFF43B2A2)]),borderRadius:BorderRadius.circular(25)),child:Text(patients.length==1?'1 persona bajo tu cuidado':'${patients.length} personas bajo tu cuidado',style:const TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.w800))),
        const SizedBox(height:18),
        ...patients.map((p)=>Container(margin:const EdgeInsets.only(bottom:13),padding:const EdgeInsets.all(17),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22),border:Border.all(color:const Color(0xFFE1ECE8))),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
          CircleAvatar(radius:28,backgroundColor:const Color(0xFFE4F4F0),child:Text(p.name.isEmpty?'?':p.name[0].toUpperCase(),style:const TextStyle(color:primary,fontSize:22,fontWeight:FontWeight.w800))),const SizedBox(width:14),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${p.name} ${p.paternalLastName}'.trim(),style:const TextStyle(fontSize:17,fontWeight:FontWeight.w800,color:Color(0xFF253238))),const SizedBox(height:6),Text(_age(p.birthDate),style:const TextStyle(color:Color(0xFF687A78))),const SizedBox(height:5),Text(p.diseases.isEmpty?'Sin enfermedades registradas':'Padecimientos: ${p.diseases.join(', ')}',style:const TextStyle(color:Color(0xFF687A78),height:1.35)),const SizedBox(height:5),Text('Contacto de emergencia: ${p.emergencyContact.isEmpty?'No registrado':p.emergencyContact}',style:const TextStyle(color:Color(0xFF687A78),height:1.35))])),
          IconButton(
            tooltip: 'Ver ubicación',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PatientLocationView(
                    patient: p,
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.location_on_rounded,
              color: primary,
            ),
          ),
        ])))
      ]));
    }),
  );
}
class _StateView extends StatelessWidget{const _StateView({required this.icon,required this.title,required this.subtitle,this.button,this.onTap});final IconData icon;final String title,subtitle;final String? button;final VoidCallback? onTap;@override Widget build(BuildContext context)=>Center(child:Padding(padding:const EdgeInsets.all(28),child:Column(mainAxisSize:MainAxisSize.min,children:[CircleAvatar(radius:38,backgroundColor:const Color(0xFFE4F4F0),child:Icon(icon,size:38,color:const Color(0xFF168C7E))),const SizedBox(height:18),Text(title,textAlign:TextAlign.center,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w800)),const SizedBox(height:8),Text(subtitle,textAlign:TextAlign.center,style:const TextStyle(color:Color(0xFF687A78),height:1.4)),if(button!=null)...[const SizedBox(height:18),FilledButton(onPressed:onTap,child:Text(button!))]])));
}
