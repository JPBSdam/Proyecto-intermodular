import * as admin from 'firebase-admin';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';

admin.initializeApp();

const db = admin.firestore();

export const sendPushOnQueueWrite = onDocumentCreated(
  'notification_queue/{docId}',
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const toUserId: string = data.toUserId;
    const title: string = data.title ?? 'SabrosApp';
    const body: string = data.body ?? '';

    logger.info(`[FCM] Procesando notificación para userId: ${toUserId}`);

    if (!toUserId) {
      logger.warn('[FCM] Sin toUserId, ignorando');
      return;
    }

    const userSnap = await db.collection('users').doc(toUserId).get();
    const fcmToken: string | undefined = userSnap.data()?.fcmToken;

    if (!fcmToken) {
      logger.warn(`[FCM] Usuario ${toUserId} no tiene fcmToken, no se puede enviar push`);
      return;
    }

    logger.info(`[FCM] Enviando push a token: ${fcmToken.substring(0, 20)}...`);

    try {
      await admin.messaging().send({
        token: fcmToken,
        notification: { title, body },
        android: { priority: 'high' },
        apns: {
          payload: { aps: { sound: 'default', badge: 1 } },
        },
        data: {
          type: data.type ?? 'default',
          reservationId: data.reservationId ?? '',
        },
      });
      logger.info(`[FCM] Push enviado correctamente a ${toUserId}`);
    } catch (e) {
      logger.error(`[FCM] Error enviando push a ${toUserId}:`, e);
    }
  }
);
