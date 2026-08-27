// Minimal service worker for Web Push only. Deliberately scoped to /push/
// (see its registration in web/index.html) so it never controls page
// navigation or asset fetches -- Flutter's own generated service worker
// keeps doing that at the root scope. This one only ever reacts to two
// events: a push message arriving, and the user tapping the notification.

self.addEventListener('push', (event) => {
  let payload = { title: 'Werkly', body: 'New job match', jobId: null };
  if (event.data) {
    try {
      payload = { ...payload, ...event.data.json() };
    } catch (_) {
      payload.body = event.data.text();
    }
  }
  event.waitUntil(
    self.registration.showNotification(payload.title, {
      body: payload.body,
      icon: '/icons/Icon-192.png',
      badge: '/icons/Icon-192.png',
      data: { jobId: payload.jobId },
    }),
  );
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clients) => {
      for (const client of clients) {
        if ('focus' in client) return client.focus();
      }
      if (self.clients.openWindow) return self.clients.openWindow('/');
    }),
  );
});
