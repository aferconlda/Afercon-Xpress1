
// Imports a utility that helps set up the service worker.
importScripts("https://www.gstatic.com/firebasejs/8.10.1/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.1/firebase-messaging.js");

// Your web app's Firebase configuration
const firebaseConfig = {
      apiKey: "AIzaSyBBbszxNRri_Lr_6d9cmm0yTamOSfKJawo",
      authDomain: "afercon-lda-24cac.firebaseapp.com",
      projectId: "afercon-lda-24cac",
      storageBucket: "afercon-lda-24cac.appspot.com",
      messagingSenderId: "913969877080",
      appId: "1:913969877080:web:bd35786e707d7065defa2d",
      measurementId: "G-0BY1M8GY39"
};

// Initialize Firebase
firebase.initializeApp(firebaseConfig);

// Retrieve an instance of Firebase Messaging so that it can handle background
// messages.
const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log(
    '[firebase-messaging-sw.js] Received background message ',
    payload
  );
  // Customize notification here
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
