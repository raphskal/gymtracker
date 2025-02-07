// src/firebase/myAuth.ts
import { getAuth, signInWithEmailAndPassword } from "firebase/auth";
import { app } from "./firebase"; // Import Firebase app

// Initialize Firebase Auth
const auth = getAuth();

const login = async (email: string, password: string) => {
  try {
    await signInWithEmailAndPassword(auth, email, password);
    console.log("Logged in successfully");
  } catch (error) {
    console.error("Error during login:", error);
    throw error; // Re-throw error for further handling in the component
  }
};

export { login };
