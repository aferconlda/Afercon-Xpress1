
import 'dart:developer' as developer;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseMessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  final AndroidNotificationChannel _androidChannel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'Notificações de Alta Importância', // title
    description: 'Este canal é usado para notificações importantes.', // description
    importance: Importance.max,
  );

  Future<void> initialize() async {
    await _initializeLocalNotifications();

    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      developer.log('Permissão de notificação concedida pelo utilizador.');
      
      await _getTokenAndSave();

      _firebaseMessaging.onTokenRefresh.listen((token) {
        _saveTokenToDatabase(token);
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        developer.log('Recebida uma mensagem em primeiro plano: ${message.messageId}');
        
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null && android != null) {
          _localNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                _androidChannel.id,
                _androidChannel.name,
                channelDescription: _androidChannel.description,
                icon: 'ic_notification', // Usar o ícone de notificação definitivo
              ),
            ),
          );
        }
      });

    } else {
      developer.log('Permissão de notificação negada pelo utilizador.');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification'); // Usar o ícone de notificação definitivo

    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotificationsPlugin.initialize(initializationSettings);

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
  }


  Future<void> _getTokenAndSave() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveTokenToDatabase(token);
      }
    } catch (e) {
      developer.log('Erro ao obter o token FCM: $e');
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    User? user = _auth.currentUser;

    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'fcmTokens': FieldValue.arrayUnion([token])
        }, SetOptions(merge: true));
        developer.log('Token FCM guardado com sucesso para o utilizador: ${user.uid}');
      } catch (e) {
        developer.log('Erro ao guardar o token FCM na base de dados: $e');
      }
    }
  }

  Future<void> removeTokenOnSignOut() async {
     User? user = _auth.currentUser;
     if (user == null) return;

     try {
        String? token = await _firebaseMessaging.getToken();
        if (token != null) {
          await _firestore.collection('users').doc(user.uid).update({
            'fcmTokens': FieldValue.arrayRemove([token])
          });
           developer.log('Token FCM removido com sucesso durante o logout.');
        }
     } catch (e) {
        developer.log('Erro ao remover o token FCM: $e');
     }
  }
}
