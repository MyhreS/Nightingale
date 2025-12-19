import { initializeApp } from "firebase/app";
import { getDatabase } from "firebase/database";
import { getStorage } from "firebase/storage";
import { getAuth } from "firebase/auth";

const firebaseConfig = {
  apiKey: "AIzaSyAEPvhbuplTxffwwbkMcMJE6DkMYkdslfs",
  authDomain: "nightingale-ed86a.firebaseapp.com",
  databaseURL: "https://nightingale-ed86a-default-rtdb.europe-west1.firebasedatabase.app",
  projectId: "nightingale-ed86a",
  storageBucket: "nightingale-ed86a.firebasestorage.app",
  messagingSenderId: "886865187698",
  appId: "1:886865187698:web:ed4ab0de35d8310a3903eb",
  measurementId: "G-PQXX1ZEYFG",
};

const app = initializeApp(firebaseConfig);

export const database = getDatabase(app);
export const storage = getStorage(app);
export const auth = getAuth(app);

export default app;
