
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_messaging_service.dart';
import 'models/delivery_model.dart';
import 'models/user_model.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final FirebaseMessagingService _messagingService;

  AuthService(this._firebaseAuth)
      : _firestore = FirebaseFirestore.instance,
        _messagingService = FirebaseMessagingService();

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

  Stream<Delivery?> getDeliveryStream(String deliveryId) {
    return _firestore
        .collection('deliveries')
        .doc(deliveryId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return Delivery.fromMap(snapshot.id, snapshot.data()!);
      }
      return null;
    }).handleError((e, s) {
        developer.log(
        'Erro no stream da entrega',
        name: 'auth_service',
        error: e,
        stackTrace: s,
      );
    });
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
    required DateTime? dateOfBirth,
    required String? nationality,
    // Parâmetros do veículo
    String? vehicleType,
    String? vehicleMake,
    String? vehicleModel,
    int? vehicleYear,
    String? vehiclePlate,
    String? vehicleColor,
    String? driverLicenseNumber,
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
          dateOfBirth: dateOfBirth,
          nationality: nationality,
          vehicleType: vehicleType,
          vehicleMake: vehicleMake,
          vehicleModel: vehicleModel,
          vehicleYear: vehicleYear,
          vehiclePlate: vehiclePlate,
          vehicleColor: vehicleColor,
          driverLicenseNumber: driverLicenseNumber,
        );
        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());

        return "Success";
      }
      return 'Utilizador não foi criado.';
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

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

  Future<String?> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
      return "Success";
    } catch (e) {
      developer.log('Erro ao atualizar o perfil do utilizador: $e');
      return 'Ocorreu um erro ao atualizar o perfil.';
    }
  }

  Future<String?> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return "Success";
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'auth/invalid-email':
          return 'O endereço de e-mail não é válido.';
        case 'user-not-found':
          return 'Não foi encontrada nenhuma conta com este e-mail.';
        default:
          return 'Ocorreu um erro. Tente novamente mais tarde.';
      }
    } catch (e) {
        developer.log('Erro ao enviar e-mail de redefinição de palavra-passe: $e');
        return 'Ocorreu um erro inesperado.';
    }
  }

  Future<void> signOut() async {
    await _messagingService.removeTokenOnSignOut();
    await _firebaseAuth.signOut();
  }

  // --- NOVOS MÉTODOS PARA CANCELAMENTO ---

  Future<String?> requestCancellation(String deliveryId, String requestedBy, String reason) async {
    try {
      await _firestore.collection('deliveries').doc(deliveryId).update({
        'cancellationRequestedBy': requestedBy,
        'cancellationStatus': 'pending',
        'cancellationReason': reason,
      });
      return 'Success';
    } catch (e, s) {
      developer.log('Erro ao solicitar cancelamento', name: 'auth_service', error: e, stackTrace: s);
      return 'Ocorreu um erro ao processar o seu pedido.';
    }
  }

  Future<String?> confirmCancellation(String deliveryId) async {
    try {
      await _firestore.collection('deliveries').doc(deliveryId).update({
        'status': DeliveryStatus.cancelled.name,
        'cancellationStatus': 'confirmed',
      });
      return 'Success';
    } catch (e, s) {
      developer.log('Erro ao confirmar o cancelamento', name: 'auth_service', error: e, stackTrace: s);
      return 'Ocorreu um erro ao processar o seu pedido.';
    }
  }

  Future<String?> clearCancellationRequest(String deliveryId) async {
    try {
      await _firestore.collection('deliveries').doc(deliveryId).update({
        'cancellationRequestedBy': null,
        'cancellationStatus': null,
        'cancellationReason': null,
      });
      return 'Success';
    } catch (e, s) {
      developer.log('Erro ao limpar o pedido de cancelamento', name: 'auth_service', error: e, stackTrace: s);
      return 'Ocorreu um erro ao processar o seu pedido.';
    }
  }
}
