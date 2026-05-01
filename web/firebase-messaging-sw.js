importScripts('https://www.gstatic.com/firebasejs/9.10.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.10.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyAXPSYLzIv1OWfpa4RSPes_RvJM9BqGJfs',
  authDomain: 'cce106-3e137.firebaseapp.com',
  projectId: 'cce106-3e137',
  storageBucket: 'cce106-3e137.firebasestorage.app',
  messagingSenderId: '200583921993',
  appId: '1:200583921993:web:1e0057c76de2eaf5435a98',
  measurementId: 'G-GRZFJNQ3QB',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const notification = payload.notification || {};
  const title = notification.title || 'Pharmacy Marketplace';

  self.registration.showNotification(title, {
    body: notification.body || 'You have a new order update.',
    icon: notification.image || '/icons/Icon-192.png',
    data: payload.data || {},
  });
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  event.waitUntil(
    self.clients
      .matchAll({ type: 'window', includeUncontrolled: true })
      .then((clientList) => {
        for (const client of clientList) {
          if ('focus' in client) {
            return client.focus();
          }
        }

        if (self.clients.openWindow) {
          return self.clients.openWindow('/');
        }

        return undefined;
      }),
  );
});
