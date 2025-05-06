/* eslint-disable no-undef */
importScripts("https://www.gstatic.com/firebasejs/9.22.2/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.22.2/firebase-messaging-compat.js");

// ВСТАВЬТЕ ↓ свои значения из Firebase → Project settings → SDK config
firebase.initializeApp({
    apiKey: "AIzaSyAWSOaSkezf_yeFRFWMv2STSV2mBA3N5MQ",
    authDomain: "enjoy-b49ea.firebaseapp.com",
    projectId: "enjoy-b49ea",
    storageBucket: "enjoy-b49ea.firebasestorage.app",
    messagingSenderId: "929559084297",
    appId: "1:929559084297:web:8cdb20bf58de2086fde7d8",
});

const messaging = firebase.messaging();
