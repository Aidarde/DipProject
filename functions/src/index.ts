import * as admin from 'firebase-admin';
import { setGlobalOptions } from 'firebase-functions/v2';
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions';

admin.initializeApp();
const db        = admin.firestore();
const messaging = admin.messaging();

/**  общие настройки для всех функций  */
setGlobalOptions({
  region: 'europe-west3',
  timeoutSeconds: 20,
  memory: '256MiB',
});

/**
 * notifyOrderReady
 * ─────────────────
 * Триггер: любое обновление документа orders/{orderId}.
 * Если статус переходит в "готов", отправляем push владельцу заказа.
 */
export const notifyOrderReady = onDocumentUpdated(
  'orders/{orderId}',
  async (event) => {
    // event.data может быть undefined (удаление документа), проверяем
    if (!event.data) return;

    const before = event.data.before?.data();
    const after  = event.data.after?.data();
    if (!before || !after) return;

    // реагируем только на переход в состояние «готов»
    if (before.status === 'готов' || after.status !== 'готов') return;

    const userId = after.userId as string | undefined;
    if (!userId) {
      logger.warn('order without userId', { orderId: event.params.orderId });
      return;
    }

    // читаем FCM-токен пользователя
    const userSnap = await db.doc(`users/${userId}`).get();
    const token    = userSnap.get('fcmToken') as string | undefined;
    if (!token) {
      logger.warn('no FCM token for user', { userId });
      return;
    }

    const orderId = event.params.orderId as string;

    await messaging.send({
      token,
      notification: {
        title: 'Ваш заказ готов!',
        body : `Филиал: ${after.branchName ?? '—'}.`,
      },
      data: { orderId },
    });

    logger.info('push sent', { userId, orderId });
  },
);
