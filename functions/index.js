
const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Cloud Function to send a notification when a delivery is accepted.
 *
 * This function is triggered when a document in the 'deliveries' collection is updated.
 * It checks if the status of the delivery has changed to 'inProgress'.
 * If it has, it creates a notification document in the client's 'notifications' subcollection.
 */
exports.sendDeliveryNotification = functions.firestore
    .document("deliveries/{deliveryId}")
    .onUpdate(async (change, context) => {
      const newValue = change.after.data();
      const previousValue = change.before.data();

      // Log para depuração
      console.log(`Delivery ${context.params.deliveryId} updated.`);
      console.log("Previous status:", previousValue.status);
      console.log("New status:", newValue.status);

      // Verifica se o estado mudou de 'available' para 'inProgress'
      if (previousValue.status === "available" && newValue.status === "inProgress") {
        const userId = newValue.userId; // ID do cliente
        const deliveryId = context.params.deliveryId;
        const deliveryTitle = newValue.title || "O seu pedido";

        if (!userId) {
          console.error("User ID is missing in the delivery document.");
          return null;
        }

        // Cria a notificação para o cliente
        const notificationData = {
          title: "O seu pedido foi aceite!",
          body: `Um motorista está a caminho para recolher a encomenda "${deliveryTitle}".`,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          isRead: false,
          deliveryId: deliveryId,
        };

        try {
          const notificationRef = await admin.firestore()
              .collection("users")
              .doc(userId)
              .collection("notifications")
              .add(notificationData);

          console.log(`Notification sent successfully to user ${userId}. Notification ID: ${notificationRef.id}`);
          return null;
        } catch (error) {
          console.error(`Error sending notification to user ${userId}:`, error);
          return null;
        }
      }

      console.log("Status did not change to inProgress, no notification sent.");
      return null;
    });
