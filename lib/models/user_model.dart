
import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String? vehicleModel;
  final String? vehiclePlate; // Matrícula do veículo
  final String? vehicleColor; // Cor do veículo

  AppUser({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    this.vehicleModel,
    this.vehiclePlate,
    this.vehicleColor,
  });

  // Converte um Documento do Firestore num objeto AppUser
  factory AppUser.fromMap(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      vehicleModel: data['vehicleModel'],
      vehiclePlate: data['vehiclePlate'], // Ler a matrícula
      vehicleColor: data['vehicleColor'], // Ler a cor
    );
  }

  // Converte um objeto AppUser num Map para o Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'vehicleModel': vehicleModel,
      'vehiclePlate': vehiclePlate, // Adicionar a matrícula ao map
      'vehicleColor': vehicleColor, // Adicionar a cor ao map
    };
  }
}
