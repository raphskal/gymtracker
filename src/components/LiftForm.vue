<template>
  <div class="dark-theme">
    <!-- Burger Menu -->
    <nav class="burger-menu">
      <button @click="toggleMenu" class="burger-button">
        ☰
      </button>
      <div v-if="isMenuOpen" class="menu-content">
        <ul>
          <li><a @click="navigateTo('/')">Home</a></li>
          <li><a @click="navigateTo('/analytics')">Analytics</a></li>
          <li><a @click="navigateTo('/lifts')">Lifts</a></li>
        </ul>
      </div>
    </nav>

    <!-- Form -->
    <form @submit.prevent="onSubmit">
      <div>
        <label for="exercise">Exercise:</label>
        <input 
          v-model="exercise" 
          id="exercise" 
          type="text" 
          list="exerciseSuggestions" 
          @input="fetchRecentWorkout" 
          required 
        />
        <datalist id="exerciseSuggestions">
          <option v-for="item in suggestions" :key="item" :value="item" />
        </datalist>
      </div>
      <div>
        <label for="weight">Weight (kg):</label>
        <input v-model.number="weight" id="weight" type="number" required />
      </div>
      <div>
        <label for="reps">Reps:</label>
        <input v-model.number="reps" id="reps" type="number" required />
      </div>
      <div>
        <label for="rpe">RPE:</label>
        <input v-model.number="rpe" id="rpe" type="number" required />
      </div>
      <div>
        <label for="date">Date:</label>
        <input v-model="date" id="date" type="date" required />
      </div>
      <button type="submit">Save Lift</button>
      <button type="button" @click="fetchRecentWorkout">Load Most Recent</button>

      <div v-if="recentWorkoutSets.length" class="recent-workout">
        <h3>Most Recent Workout</h3>
        <ul>
          <li v-for="(set, index) in recentWorkoutSets" :key="index">
            <strong>Set {{ index + 1 }}:</strong> 
            Weight: {{ set.weight }} kg, 
            Reps: {{ set.reps }}, 
            RPE: {{ set.rpe }}
          </li>
        </ul>
      </div>

      <!-- Logout Button -->
      <button type="button" @click="logout" class="logout-btn">Logout</button>
    </form>
  </div>
</template>

<script lang="ts">
import { defineComponent, ref, onMounted, watchEffect } from "vue";
import { saveLift, fetchSuggestions, fetchMostRecentWorkout,fetchLastExercise } from "@/firebase/db";
import { getAuth, signOut, onAuthStateChanged } from "firebase/auth";
import { useRouter } from "vue-router";
import { query, collection, where, limit, orderBy, getDocs } from "firebase/firestore";

export default defineComponent({
  name: "LiftForm",
  setup() {
    const router = useRouter();
    const exercise = ref("");
    const weight = ref<number | null>(null);
    const reps = ref<number | null>(null);
    const last = ref<string | null>(null);
    const rpe = ref<number | null>(null);
    const date = ref(new Date().toISOString().split("T")[0]);
    const suggestions = ref<string[]>([]);
    const selectedExercise = ref('');
    const recentWorkoutSets = ref<any[]>([]);
    const isMenuOpen = ref(false);

    const user = ref<any>(null); // Track the authenticated user

    const auth = getAuth();

    // Monitor authentication state
    onMounted(() => {
      onAuthStateChanged(auth, (currentUser) => {
        user.value = currentUser;
        if (currentUser) {
          fetchSuggestionsForUser();
          fetchLastExercise();
        }
      });
    });

    const logout = async () => {
      try {
        await signOut(auth);
        user.value = null;
        alert("You have been logged out.");
      } catch (error) {
        console.error("Logout failed:", error);
        alert("Logout failed. Please try again.");
      }
    };

    const fetchSuggestionsForUser = async () => {
      if (selectedExercise.value.length > 0) { 
        try {
          suggestions.value = await fetchSuggestions(selectedExercise.value);
        } catch (error) {
          console.error('Error fetching suggestions:', error);
        }
      } else {
        suggestions.value = []; // Clear suggestions if input is empty
      }
    };

    // Re-fetch suggestions dynamically as the user types
    watchEffect(() => {
      fetchSuggestionsForUser();
    });

    // Fetch all sets for the most recent day for a given exercise
    const fetchRecentWorkout = async () => {
      try {
        if (exercise.value) {
          recentWorkoutSets.value = await fetchMostRecentWorkout(exercise.value);
          if (["Squats", "Bench", "Deadlift"].includes(exercise.value)) {
            suggestWeights();
          }
        }
      } catch (error) {
        console.error("Error fetching recent workout:", error);
      }
    };

    // Suggest weights for 1, 3, and 5 reps
    const suggestWeights = () => {
      if (recentWorkoutSets.value.length > 0) {
        const maxSet = recentWorkoutSets.value.reduce((max, set) => set.weight > max.weight ? set : max);
        const maxWeight = maxSet.weight;
        const maxReps = maxSet.reps;

        const oneRepMax = maxWeight * (1 + maxReps / 30);
        const suggestedWeights = {
          reps1: Math.floor((oneRepMax * 0.95+5)/2.5) * 2.5,
          reps3: Math.floor((oneRepMax * 0.9+5)/2.5) * 2.5,
          reps5: Math.floor((oneRepMax * 0.85+5)/2.5) * 2.5,
        };

        alert(`Suggested weights for ${exercise.value}:
          1 Rep: ${suggestedWeights.reps1.toFixed(2)} kg
          3 Reps: ${suggestedWeights.reps3.toFixed(2)} kg
          5 Reps: ${suggestedWeights.reps5.toFixed(2)} kg`);
      }
    };

    const onSubmit = async () => {
      if (weight.value && reps.value) {
        try {
          await saveLift({
            exercise: exercise.value,
            weight: weight.value,
            reps: reps.value,
            rpe: rpe.value ?? 0,
            date: date.value,
          });
          alert("Lift saved successfully!");
          exercise.value = "";
          weight.value = null;
          reps.value = null;
          rpe.value = null;
          date.value = new Date().toISOString().split("T")[0];
          fetchSuggestionsForUser(); // Refresh suggestions
        } catch (error) {
          console.error(error);
          alert("Failed to save lift. Please try again.");
        }
      }
    };

    const toggleMenu = () => {
      isMenuOpen.value = !isMenuOpen.value;
    };

    const navigateTo = (path: string) => {
      router.push(path);
      isMenuOpen.value = false; // Close the menu after navigation
    };

    return {
      exercise,
      weight,
      reps,
      rpe,
      date,
      suggestions,
      recentWorkoutSets,
      fetchRecentWorkout,
      onSubmit,
      user,
      logout,
      toggleMenu,
      navigateTo,
      isMenuOpen
    };
  },
});
</script>

<style scoped>
.dark-theme {
  background-color: #333;
  color: #00ff00;
  padding: 20px;
}

.burger-menu {
  position: relative;
}

.burger-button {
  background: none;
  border: none;
  font-size: 1.5rem;
  cursor: pointer;
  color: #00ff00;
}

.menu-content {
  position: absolute;
  top: 2rem;
  left: 0;
  background-color: #444;
  border: 1px solid #ddd;
  box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
  z-index: 1000;
}

.menu-content ul {
  list-style: none;
  margin: 0;
  padding: 0;
}

.menu-content li {
  padding: 0.5rem 1rem;
}

.menu-content li a {
  text-decoration: none;
  color: #00ff00;
  cursor: pointer;
}

.menu-content li a:hover {
  color: #00cc00;
}

form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

label {
  font-weight: bold;
}

button {
  background-color: #4caf50;
  color: white;
  border: none;
  padding: 0.5rem 1rem;
  cursor: pointer;
}

button:hover {
  background-color: #45a049;
}

input {
  background-color: #444;
  color: #00ff00;
  border: 1px solid #00ff00;
  padding: 0.5rem;
}

.recent-workout {
  margin-top: 1rem;
}

.recent-workout h3 {
  color: #00ff00;
}

.recent-workout ul {
  list-style: none;
  padding: 0;
}

.recent-workout li {
  margin-bottom: 0.5rem;
}

.logout-btn {
  background-color: #ff4444;
  margin-top: 1rem;
}

.logout-btn:hover {
  background-color: #cc0000;
}
</style>