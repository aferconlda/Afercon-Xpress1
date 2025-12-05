
import 'package:cloud_firestore/cloud_firestore.dart';

enum DeliveryStatus { available, inProgress, pendingConfirmation, completed, cancelled }

class Delivery {
  final String id;
  final String title;
  final String description;
  final String? packagePhotoUrl;
  final String pickupAddress;
  final String deliveryAddress;
  final String recipientName;
  final String recipientPhone;
  final double price;
  final DeliveryStatus status;
  final String userId; // ID do cliente que criou a entrega
  final String? driverId; // ID do motorista que aceitou
  final DateTime createdAt;
  final String? cancellationRequestedBy; // 'client' ou 'driver'
  final String? cancellationStatus; // 'pending', 'confirmed'
  final String? cancellationReason;

  Delivery({
    required this.id,
    required this.title,
    required this.description,
    this.packagePhotoUrl,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.recipientName,
    required this.recipientPhone,
    required this.price,
    required this.status,
    required this.userId,
    this.driverId,
    required this.createdAt,
    this.cancellationRequestedBy,
    this.cancellationStatus,
    this.cancellationReason,
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
      price: (data['price'] ?? 0).toDouble(),
      status: _statusFromString(data['status'] ?? 'available'),
      userId: data['userId'] ?? '',
      driverId: data['driverId'],
      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      cancellationRequestedBy: data['cancellationRequestedBy'],
      cancellationStatus: data['cancellationStatus'],
      cancellationReason: data['cancellationReason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'packagePhotoUrl': packagePhotoUrl,
      'pickupAddress': pickupAddress,
      'deliveryAddress': deliveryAddress,
      'recipientName': recipientName,
      'recipientPhone': recipientPhone,
      'price': price,
      'status': status.name,
      'userId': userId,
      'driverId': driverId,
      'createdAt': FieldValue.serverTimestamp(),
      'cancellationRequestedBy': cancellationRequestedBy,
      'cancellationStatus': cancellationStatus,
      'cancellationReason': cancellationReason,
    };
  }

  static DeliveryStatus _statusFromString(String status) {
    return DeliveryStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => DeliveryStatus.available,
    );
  }
}
