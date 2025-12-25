import 'dart:async';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'models/delivery_model.dart';
import 'models/user_model.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthService(this._firebaseAuth)
      : _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<String?> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return "Success";
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<Delivery?> getDeliveryDetails(String deliveryId) async {
    try {
      final doc = await _firestore.collection('deliveries').doc(deliveryId).get();
      if (doc.exists) {
        return Delivery.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e, s) {
      developer.log('Erro ao obter detalhes da entrega', name: 'auth_service', error: e, stackTrace: s);
      return null;
    }
  }

  Stream<Delivery?> getDeliveryStream(String deliveryId) {
    final controller = StreamController<Delivery?>();
    final subscription = _firestore
        .collection('deliveries')
        .doc(deliveryId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        controller.add(Delivery.fromMap(snapshot.id, snapshot.data()!));
      } else {
        controller.add(null);
      }
    }, onError: (e, s) {
      developer.log('Erro no stream da entrega', name: 'auth_service', error: e, stackTrace: s);
      controller.addError(e, s);
    });

    controller.onCancel = () {
      subscription.cancel();
    };

    return controller.stream;
  }

  Future<AppUser?> getUserDetails(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return AppUser.fromMap(doc);
      }
      return null;
    } catch (e, s) {
      developer.log('Erro ao obter detalhes do utilizador', name: 'auth_service', error: e, stackTrace: s);
      return null;
    }
  }

  Future<String?> signIn({ required String email, required String password }) async {
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
    } catch (e, s) {
      developer.log('Erro ao atualizar o estado da entrega', name: 'auth_service', error: e, stackTrace: s);
      return 'Ocorreu um erro ao atualizar a entrega.';
    }
  }

  Future<String?> requestCancellation(User user, String deliveryId, String reason) async {
    final deliveryRef = _firestore.collection('deliveries').doc(deliveryId);

    try {
      final deliveryDoc = await deliveryRef.get();
      if (!deliveryDoc.exists) return "Entrega não encontrada.";
      final delivery = Delivery.fromMap(deliveryDoc.id, deliveryDoc.data()!);

      if (delivery.status != DeliveryStatus.inProgress) {
        return "O cancelamento só pode ser solicitado para entregas em progresso.";
      }

      final isClient = user.uid == delivery.userId;
      final isDriver = user.uid == delivery.driverId;

      DeliveryStatus newStatus;
      if (isClient) {
        newStatus = DeliveryStatus.cancellationRequestedByClient;
      } else if (isDriver) {
        newStatus = DeliveryStatus.cancellationRequestedByDriver;
      } else {
        return "Apenas o cliente ou o motorista podem solicitar o cancelamento.";
      }

      await deliveryRef.update({
        'status': newStatus.name,
        'cancellationReason': reason,
      });

      return "Success";
    } on FirebaseException catch (e) {
      developer.log('Erro ao solicitar cancelamento', name: 'auth_service', error: e);
      return e.message ?? "Erro desconhecido ao solicitar cancelamento.";
    } catch (e) {
      developer.log('Erro inesperado ao solicitar cancelamento', name: 'auth_service', error: e);
      return "Ocorreu um erro inesperado.";
    }
  }

  Future<String?> confirmCancellation(User user, String deliveryId) async {
    final deliveryRef = _firestore.collection('deliveries').doc(deliveryId);
    
    try {
      return _firestore.runTransaction((transaction) async {
        final deliveryDoc = await transaction.get(deliveryRef);
        if (!deliveryDoc.exists) return "Entrega não encontrada.";
        final delivery = Delivery.fromMap(deliveryDoc.id, deliveryDoc.data()!);

        final isClient = user.uid == delivery.userId;
        final isDriver = user.uid == delivery.driverId;

        if (delivery.status == DeliveryStatus.cancellationRequestedByDriver && isClient) {
          // Cliente confirma o pedido do motorista. A entrega volta a estar disponível.
          transaction.update(deliveryRef, {
            'status': DeliveryStatus.available.name,
            'driverId': null,
            'cancellationReason': FieldValue.delete(),
          });
          return "Cancelamento confirmado. A entrega está novamente disponível.";
        } else if (delivery.status == DeliveryStatus.cancellationRequestedByClient && isDriver) {
          // Motorista confirma o pedido do cliente. A entrega é cancelada permanentemente.
          transaction.update(deliveryRef, {
            'status': DeliveryStatus.cancelled.name,
          });
          return "Cancelamento confirmado. A entrega foi cancelada.";
        } else {
          return "Você não tem permissão para confirmar este cancelamento ou o estado da entrega não permite.";
        }
      });
    } on FirebaseException catch (e) {
      developer.log('Erro ao confirmar cancelamento', name: 'auth_service', error: e);
      return e.message ?? "Erro desconhecido ao confirmar cancelamento.";
    } catch (e) {
      developer.log('Erro inesperado ao confirmar cancelamento', name: 'auth_service', error: e);
      return "Ocorreu um erro inesperado.";
    }
  }


  Future<String?> rejectCancellation(User user, String deliveryId) async {
    final deliveryRef = _firestore.collection('deliveries').doc(deliveryId);

    try {
      final deliveryDoc = await deliveryRef.get();
      if (!deliveryDoc.exists) return "Entrega não encontrada.";
      final delivery = Delivery.fromMap(deliveryDoc.id, deliveryDoc.data()!);

      final isClient = user.uid == delivery.userId;
      final isDriver = user.uid == delivery.driverId;

      if (!((delivery.status == DeliveryStatus.cancellationRequestedByClient && isDriver) ||
          (delivery.status == DeliveryStatus.cancellationRequestedByDriver && isClient))) {
        return "Você não tem permissão para rejeitar este pedido.";
      }

      await deliveryRef.update({
        'status': DeliveryStatus.inProgress.name,
        'cancellationReason': FieldValue.delete(),
      });

      return "Success";
    } on FirebaseException catch (e) {
      developer.log('Erro ao rejeitar cancelamento', name: 'auth_service', error: e);
      return e.message ?? "Erro desconhecido ao rejeitar cancelamento.";
    } catch (e,s) {
      developer.log('Erro inesperado ao rejeitar cancelamento', name: 'auth_service', error: e, stackTrace: s);
      return "Ocorreu um erro inesperado.";
    }
  }

  Future<String?> deleteDelivery(User user, String deliveryId) async {
    final deliveryRef = _firestore.collection('deliveries').doc(deliveryId);

    try {
      return _firestore.runTransaction((transaction) async {
        final deliveryDoc = await transaction.get(deliveryRef);
        if (!deliveryDoc.exists) {
          throw Exception("Entrega não encontrada.");
        }

        final delivery = Delivery.fromMap(deliveryDoc.id, deliveryDoc.data()!);

        if (delivery.userId != user.uid) {
          throw Exception("Apenas o criador da entrega a pode apagar.");
        }

        if (delivery.status != DeliveryStatus.available) {
          throw Exception("A entrega só pode ser apagada se ainda estiver disponível.");
        }

        transaction.delete(deliveryRef);
        return "Success";
      });
    } on FirebaseException catch (e) {
      developer.log('Erro ao apagar entrega', name: 'auth_service', error: e);
      return e.message ?? "Erro desconhecido ao apagar entrega.";
    } catch (e) {
      developer.log('Erro inesperado ao apagar entrega', name: 'auth_service', error: e);
      return e.toString();
    }
  }
}
