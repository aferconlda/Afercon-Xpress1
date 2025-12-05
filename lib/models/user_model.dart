
import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String fullName;
  final String phoneNumber;
  final DateTime? dateOfBirth;
  final String? nationality;

  // Informações do Veículo
  final String? vehicleType; // 'Carro' ou 'Moto'
  final String? vehicleMake; // Marca (ex: Toyota)
  final String? vehicleModel; // Modelo (ex: Yaris)
  final int? vehicleYear; // Ano de fabrico
  final String? vehiclePlate; 
  final String? vehicleColor; 
  final String? driverLicenseNumber; // Número da carta de condução

  AppUser({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    this.dateOfBirth,
    this.nationality,
    this.vehicleType,
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleYear,
    this.vehiclePlate,
    this.vehicleColor,
    this.driverLicenseNumber,
  });

  factory AppUser.fromMap(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      dateOfBirth: (data['dateOfBirth'] as Timestamp?)?.toDate(),
      nationality: data['nationality'],
      vehicleType: data['vehicleType'],
      vehicleMake: data['vehicleMake'],
      vehicleModel: data['vehicleModel'],
      vehicleYear: data['vehicleYear'],
      vehiclePlate: data['vehiclePlate'],
      vehicleColor: data['vehicleColor'],
      driverLicenseNumber: data['driverLicenseNumber'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth,
      'nationality': nationality,
      'vehicleType': vehicleType,
      'vehicleMake': vehicleMake,
      'vehicleModel': vehicleModel,
      'vehicleYear': vehicleYear,
      'vehiclePlate': vehiclePlate,
      'vehicleColor': vehicleColor,
      'driverLicenseNumber': driverLicenseNumber,
    };
  }
}
