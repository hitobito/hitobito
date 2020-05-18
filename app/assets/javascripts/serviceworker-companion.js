if (navigator.serviceWorker) {
  navigator.serviceWorker.register('/serviceworker.js')
    .then(function(reg) {
      console.log('[Companion]', 'Service worker registered!');
    });
}
