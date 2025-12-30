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
    } catch (e) {
      return e.toString();
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
    return _firestore.collection('deliveries').doc(deliveryId).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return Delivery.fromMap(snapshot.id, snapshot.data()!);
      } else {
        return null;
      }
    }).handleError((e, s) {
       developer.log('Erro no stream da entrega', name: 'auth_service', error: e, stackTrace: s);
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
      developer.log('Erro ao obter detalhes do utilizador', name: 'auth_service', error: e, stackTrace: s);
      return null;
    }
  }

  Future<String?> signIn({ required String email, required String password }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      return "Success";
    } catch (e) {
      return e.toString();
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
    } catch (e) {
      return e.toString();
    }
  }

    Future<String?> acceptDelivery(Delivery delivery, User driver) async {
    try {
      final driverData = await getUserDetails(driver.uid);
      if (driverData == null) {
        return "Não foi possível carregar os dados do motorista para verificação.";
      }

      // Regra de Segurança: Garante que o perfil do motorista está 100% completo.
      final isDriverProfileComplete = (driverData.vehicleType?.isNotEmpty ?? false) && 
                                      (driverData.vehicleMake?.isNotEmpty ?? false) &&
                                      (driverData.vehicleModel?.isNotEmpty ?? false) &&
                                      (driverData.vehicleYear != null) &&
                                      (driverData.vehiclePlate?.isNotEmpty ?? false) &&
                                      (driverData.vehicleColor?.isNotEmpty ?? false) &&
                                      (driverData.driverLicenseNumber?.isNotEmpty ?? false);

      if (!isDriverProfileComplete) {
        // Retorna um código específico para a UI saber que o perfil está incompleto.
        return "Perfil Incompleto"; 
      }

      if (delivery.userId == driver.uid) {
        return "Não pode aceitar a sua própria entrega.";
      }

      // Regra de Segurança: Verifica se o motorista já tem uma entrega ativa.
      final activeDeliveriesQuery = await _firestore
          .collection('deliveries')
          .where('driverId', isEqualTo: driver.uid)
          .where('status', whereIn: [
              DeliveryStatus.inProgress.name, 
              DeliveryStatus.pendingConfirmation.name,
              DeliveryStatus.cancellationRequestedByClient.name,
              DeliveryStatus.cancellationRequestedByDriver.name
            ])
          .limit(1)
          .get();

      if (activeDeliveriesQuery.docs.isNotEmpty) {
        // Retorna um código específico para a UI saber que já existe uma entrega ativa.
        return "Entrega Ativa"; 
      }
      
      // Partilha de Confiança: Cria o mapa com as informações a serem partilhadas.
      final driverInfo = {
        'fullName': driverData.fullName,
        'phoneNumber': driverData.phoneNumber,
        'vehicleType': driverData.vehicleType,
        'vehicleMake': driverData.vehicleMake,
        'vehicleModel': driverData.vehicleModel,
        'vehicleYear': driverData.vehicleYear,
        'vehiclePlate': driverData.vehiclePlate,
        'vehicleColor': driverData.vehicleColor,
        // O número da carta de condução (driverLicenseNumber) NÃO é incluído.
      };

      // Atualiza a entrega com os dados do motorista e o novo estado.
      await _firestore.collection('deliveries').doc(delivery.id).update({
        'driverId': driver.uid,
        'status': DeliveryStatus.inProgress.name,
        'driverInfo': driverInfo, // Adiciona o mapa de informações à entrega.
      });

      return "Success";
    } catch (e, s) {
      developer.log('Erro ao aceitar entrega', name: 'auth_service', error: e, stackTrace: s);
      return e.toString();
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
    } catch (e) {
      developer.log('Erro ao solicitar cancelamento', name: 'auth_service', error: e);
      return e.toString();
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
          transaction.update(deliveryRef, {
            'status': DeliveryStatus.available.name,
            'driverId': null,
            'cancellationReason': FieldValue.delete(),
             'driverInfo': FieldValue.delete(), // Remove os dados do motorista
          });
          return "Cancelamento confirmado. A entrega está novamente disponível.";
        } else if (delivery.status == DeliveryStatus.cancellationRequestedByClient && isDriver) {
          transaction.update(deliveryRef, {
            'status': DeliveryStatus.cancelled.name,
          });
          return "Cancelamento confirmado. A entrega foi cancelada.";
        } else {
          return "Você não tem permissão para confirmar este cancelamento ou o estado da entrega não permite.";
        }
      });
    } catch (e) {
      developer.log('Erro ao confirmar cancelamento', name: 'auth_service', error: e);
      return e.toString();
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
    } catch (e,s) {
      developer.log('Erro ao rejeitar cancelamento', name: 'auth_service', error: e, stackTrace: s);
      return e.toString();
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
    } catch (e) {
      developer.log('Erro ao apagar entrega', name: 'auth_service', error: e);
      return e.toString();
    }
  }
}
