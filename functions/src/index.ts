import * as admin from 'firebase-admin';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { onMessagePublished } from 'firebase-functions/v2/pubsub';
import { logger } from 'firebase-functions/v2';
import { GoogleAuth } from 'google-auth-library';

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

// Escucha el topic de Pub/Sub que Firebase Budget Alerts publica.
// Cuando el coste supera el presupuesto configurado, desactiva la facturación
// del proyecto para evitar cargos inesperados.
// Pasos manuales necesarios (solo una vez):
//   1. En Firebase Console > Billing > Budgets & alerts: crear budget de 0 € y
//      activar "Connect a Pub/Sub topic" → crear topic "billing-alerts"
//   2. En Google Cloud Console > IAM: dar rol "Billing Account Administrator"
//      a la cuenta de servicio del proyecto (PROJECT_ID@appspot.gserviceaccount.com)
export const disableBillingOnBudgetExceeded = onMessagePublished(
  'billing-alerts',
  async (event) => {
    const PROJECT_ID = 'fir-proyecto-intermodular';

    let budgetData: { costAmount?: number; budgetAmount?: number } = {};
    try {
      const raw = event.data.message.data
        ? Buffer.from(event.data.message.data, 'base64').toString()
        : '{}';
      budgetData = JSON.parse(raw);
    } catch {
      logger.warn('[Billing] No se pudo parsear el mensaje del budget alert');
      return;
    }

    const { costAmount = 0, budgetAmount = 0 } = budgetData;

    if (costAmount <= budgetAmount) {
      logger.info(`[Billing] Coste ${costAmount}€ dentro del presupuesto ${budgetAmount}€, sin acción`);
      return;
    }

    logger.warn(`[Billing] ¡Coste ${costAmount}€ supera el presupuesto ${budgetAmount}€! Desactivando facturación...`);

    try {
      const auth = new GoogleAuth({
        scopes: ['https://www.googleapis.com/auth/cloud-billing'],
      });
      const client = await auth.getClient();
      const url = `https://cloudbilling.googleapis.com/v1/projects/${PROJECT_ID}/billingInfo`;

      await client.request({
        url,
        method: 'PUT',
        data: { billingAccountName: '' },
      });

      logger.info('[Billing] Facturación desactivada correctamente. El proyecto continúa en capa gratuita.');
    } catch (e) {
      logger.error('[Billing] Error al desactivar facturación:', e);
    }
  }
);
