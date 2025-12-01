
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'models/delivery_model.dart';
import 'models/user_model.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthService(this._firebaseAuth) : _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<Delivery?> getDeliveryDetails(String deliveryId) async {
    try {
      final doc = await _firestore.collection('deliveries').doc(deliveryId).get();
      if (doc.exists) {
        return Delivery.fromMap(doc.id, doc.data()!); 
      }
      return null;
    } catch (e, s) {
      developer.log(
        'Erro ao obter detalhes da entrega',
        name: 'auth_service',
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }

  Future<AppUser?> getUserDetails(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return AppUser.fromMap(doc);
      }
      return null;
    } catch (e, s) {
      developer.log(
        'Erro ao obter detalhes do utilizador',
        name: 'auth_service',
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      return "Success";
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> signUp({
    required String fullName,
    required String phoneNumber,
    required String email,
    required String password,
    String? vehicleModel,
    String? vehiclePlate,
    String? vehicleColor,
  }) async {
    try {
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;

      if (user != null) {
        await user.sendEmailVerification();

        final newUser = AppUser(
          uid: user.uid,
          email: email,
          fullName: fullName,
          phoneNumber: phoneNumber,
          vehicleModel: vehicleModel,
          vehiclePlate: vehiclePlate,
          vehicleColor: vehicleColor,
        );
        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());

        return "Success";
      }
      return 'Utilizador não foi criado.';
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }
   // Novo método para atualizar o estado da entrega
  Future<String?> updateDeliveryStatus(String deliveryId, DeliveryStatus newStatus) async {
    try {
      await _firestore.collection('deliveries').doc(deliveryId).update({
        'status': newStatus.name,
      });
      return "Success";
    } catch (e) {
      developer.log('Erro ao atualizar o estado da entrega: $e');
      return 'Ocorreu um erro ao atualizar a entrega.';
    }
  }


  Future<String?> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return "Success";
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
