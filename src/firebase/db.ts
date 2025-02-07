// src/firebase/db.ts
import { getFirestore, addDoc, query, where, getDocs, collection, orderBy, limit } from "firebase/firestore";
import { getAuth } from "firebase/auth";
import { app } from "./firebase";

const db = getFirestore(app);

const saveLift = async (liftData: {
  exercise: string;
  weight: number;
  reps: number;
  date: string;
  rpe: number
}) => {
  const auth = getAuth();
  const user = auth.currentUser;

  if (!user) {
    throw new Error("User is not logged in");
  }

  try {
    await addDoc(collection(db, "lifts"), {
      ...liftData,
      uid: user.uid, // Add the user's ID to the lift entry
      createdAt: new Date().toISOString(), // Optional: Timestamp for when the lift was added
    });
    console.log("Lift saved successfully!");
  } catch (error) {
    console.error("Error saving lift:", error);
    throw error;
  }
};

export { saveLift };

// Fetch exercise suggestions
export const fetchSuggestions = async (searchTerm: string = ""): Promise<string[]> => {
  const q = query(collection(db, "lifts"));
  const querySnapshot = await getDocs(q);
  const exercises: Set<string> = new Set();

  querySnapshot.forEach((doc) => {
    const exercise = doc.data().exercise;
    if (exercise.toLowerCase().includes(searchTerm.toLowerCase())) {
      exercises.add(exercise);
    }
  });

  return Array.from(exercises).slice(0, 5); // Limit to 5 results
};

// Fetch the last exercise used
export const fetchLastExercise = async (): Promise<string> => {
    const auth = getAuth();
    const user = auth.currentUser;
    if (user) {
      const q = query(
        collection(db, "lifts"),
        where("uid", "==", user.uid),
        orderBy("date", "desc"),
        limit(1)
      );
      const querySnapshot = await getDocs(q);
      if (!querySnapshot.empty) {
        const lastLift = querySnapshot.docs[0].data();
        return lastLift.exercise[0];
      }
      else {
      return ""
    }
    }
    else {
      return ""
    }
};

// Fetch the most recent workout for a given exercise
export const fetchMostRecentWorkout = async (exercise: string) => {
  const auth = getAuth();
  const user = auth.currentUser;
  if (user) {
    const q = query(
      collection(db, "lifts"),
      where("exercise", "==", exercise),
      where("uid", "==", user.uid),
          orderBy("date", "desc"),
      //limit(1)
    );
    const querySnapshot = await getDocs(q);
    if (!querySnapshot.empty) {
      const allSets = querySnapshot.docs.map(doc => doc.data());

      // Find the last date
      const lastDate = allSets[0].date;

      // Filter all sets for this date
      const setsForLastDate = allSets.filter(set => set.date === lastDate);

      return setsForLastDate;
    }
  else return []
  }

  return [];
};

export async function fetchUserExerciseData(uid: string, exercise: string) {
  const exerciseRef = query(
    collection(db, "lifts"),
    where("uid", "==", uid),
    where("exercise", "==", exercise),
    orderBy("date", "asc")
  );

  const snapshot = await getDocs(exerciseRef);
  const groupedData: Record<string, { weight: number; reps: number; rpe: number }> = {};

  snapshot.forEach((doc) => {
    const { date, weight, reps, rpe } = doc.data();
    if (!groupedData[date] || weight > groupedData[date].weight) {
      groupedData[date] = { weight, reps, rpe };
    }
  });

  return Object.keys(groupedData).map((date) => {
    const { weight, reps } = groupedData[date];
    const oneRepMax = weight * (1 + reps / 30);
    return { date, oneRepMax };
  });
}