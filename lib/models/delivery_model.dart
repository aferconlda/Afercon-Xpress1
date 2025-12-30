
import 'package:cloud_firestore/cloud_firestore.dart';

// Enum atualizado para incluir os estados de solicitação de cancelamento.
enum DeliveryStatus {
  available,
  inProgress,
  pendingConfirmation,
  completed,
  cancellationRequestedByClient,
  cancellationRequestedByDriver, cancelled,
}

class Delivery {
  final String id;
  final String title;
  final String description;
  final String? packagePhotoUrl;
  final String pickupAddress;
  final String deliveryAddress;
  final String recipientName;
  final String recipientPhone;
  final double basePrice; // Valor para o motorista
  final double serviceFee; // Taxa de serviço
  final double totalPrice; // Valor total para o cliente
  final DeliveryStatus status;
  final String userId; // ID do cliente que criou a entrega
  final String? driverId; // ID do motorista que aceitou
  final DateTime createdAt;
  final String? cancellationReason; // Mantido para registar o motivo.
  final Map<String, dynamic>? driverInfo; // Informações do motorista para o cliente
  final DateTime? clientLastViewedChat;
  final DateTime? driverLastViewedChat;

  Delivery({
    required this.id,
    required this.title,
    required this.description,
    this.packagePhotoUrl,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.recipientName,
    required this.recipientPhone,
    required this.basePrice,
    required this.serviceFee,
    required this.totalPrice,
    required this.status,
    required this.userId,
    this.driverId,
    required this.createdAt,
    this.cancellationReason,
    this.driverInfo,
    this.clientLastViewedChat,
    this.driverLastViewedChat,
  });

  factory Delivery.fromMap(String id, Map<String, dynamic> data) {
    return Delivery(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      packagePhotoUrl: data['packagePhotoUrl'],
      pickupAddress: data['pickupAddress'] ?? '',
      deliveryAddress: data['deliveryAddress'] ?? '',
      recipientName: data['recipientName'] ?? '',
      recipientPhone: data['recipientPhone'] ?? '',
      basePrice: (data['basePrice'] ?? data['price'] ?? 0).toDouble(),
      serviceFee: (data['serviceFee'] ?? 0).toDouble(),
      totalPrice: (data['totalPrice'] ?? data['price'] ?? 0).toDouble(),
      status: _statusFromString(data['status'] ?? 'available'),
      userId: data['userId'] ?? '',
      driverId: data['driverId'],
      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      cancellationReason: data['cancellationReason'],
      driverInfo: data['driverInfo'] as Map<String, dynamic>?,
      clientLastViewedChat: (data['clientLastViewedChat'] as Timestamp?)?.toDate(),
      driverLastViewedChat: (data['driverLastViewedChat'] as Timestamp?)?.toDate(),
    );
  }

  double get price => totalPrice;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'packagePhotoUrl': packagePhotoUrl,
      'pickupAddress': pickupAddress,
      'deliveryAddress': deliveryAddress,
      'recipientName': recipientName,
      'recipientPhone': recipientPhone,
      'basePrice': basePrice,
      'serviceFee': serviceFee,
      'totalPrice': totalPrice,
      'status': status.name,
      'userId': userId,
      'driverId': driverId,
      'createdAt': FieldValue.serverTimestamp(),
      'cancellationReason': cancellationReason,
      'driverInfo': driverInfo,
      'clientLastViewedChat': clientLastViewedChat != null ? Timestamp.fromDate(clientLastViewedChat!) : null,
      'driverLastViewedChat': driverLastViewedChat != null ? Timestamp.fromDate(driverLastViewedChat!) : null,
    };
  }

  static DeliveryStatus _statusFromString(String status) {
    return DeliveryStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => DeliveryStatus.available,
    );
  }
}
