import { initializeApp } from "firebase/app";

// Deine Firebase-Konfiguration
const firebaseConfig = {
  apiKey: "AIzaSyARN2G7LjWTweGtHggYXyltXtDvds_epIE",
  authDomain: "exercise-tracker-7b3c9.firebaseapp.com",
  projectId: "exercise-tracker-7b3c9",
  storageBucket: "exercise-tracker-7b3c9.firebasestorage.app",
  messagingSenderId: "1025706093303",
  appId: "1:1025706093303:web:3a4d8b164d8f98180f41f2"
};

// Initialisierung der Firebase-App
const app = initializeApp(firebaseConfig);

// Exportiere die Firebase-App, damit sie in anderen Dateien verwendet werden kann
export { app };