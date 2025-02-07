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
    <label for="exerciseSelect">Select Exercise:</label>
    <select id="exerciseSelect" v-model="selectedExercise" @change="updateGraph">
      <option v-for="exercise in exercises" :key="exercise" :value="exercise">
        {{ exercise }}
      </option>
    </select>
    <canvas id="progressionChart"></canvas>
  </div>
</template>

<script lang="ts">
import { defineComponent, ref, onMounted } from "vue";
import { Chart, registerables } from "chart.js";
import { fetchUserExerciseData, fetchSuggestions } from "@/firebase/db";
import { getAuth, onAuthStateChanged } from "firebase/auth";
import { useRouter } from "vue-router";

Chart.register(...registerables);

export default defineComponent({
  name: "ExerciseProgression",
  setup() {
    const router = useRouter();
    const selectedExercise = ref<string>("");
    const exercises = ref<string[]>([]);
    const chart = ref<Chart | null>(null);
    const uid = ref<string | null>(null);
    const isMenuOpen = ref(false);

    const fetchExercises = async () => {
      if (!uid.value) return;

      exercises.value = await fetchSuggestions();

      // Automatically select the first exercise
      if (exercises.value.length > 0) {
        selectedExercise.value = exercises.value[0];
        updateGraph();
      }
    };

    const updateGraph = async () => {
      if (!uid.value || !selectedExercise.value) return;

      const data = await fetchUserExerciseData(uid.value, selectedExercise.value);

      // Prepare data for Chart.js
      const labels = data.map((item) => item.date);
      const oneRepMaxData = data.map((item) => item.oneRepMax);

      if (chart.value) chart.value.destroy(); // Destroy old chart
      const ctx = document.getElementById("progressionChart") as HTMLCanvasElement;
      chart.value = new Chart(ctx, {
        type: "line",
        data: {
          labels,
          datasets: [
            {
              label: `Estimated 1RM for ${selectedExercise.value}`,
              data: oneRepMaxData,
              borderColor: "#00ff00",
              backgroundColor: "rgba(0, 255, 0, 0.1)",
            },
          ],
        },
        options: {
          responsive: true,
          plugins: {
            legend: { display: true },
          },
          scales: {
            x: {
              title: { display: true, text: "Date" },
              grid: { color: "#444" },
              ticks: { color: "#00ff00" },
            },
            y: {
              title: { display: true, text: "1RM (kg)" },
              beginAtZero: true,
              grid: { color: "#444" },
              ticks: { color: "#00ff00" },
            },
          },
        },
      });
    };

    const initializeAuth = () => {
      const auth = getAuth();
      onAuthStateChanged(auth, (user) => {
        if (user) {
          uid.value = user.uid; // Set the current user's UID
          fetchExercises(); // Fetch exercises once the user is authenticated
        } else {
          uid.value = null; // Handle unauthenticated state (e.g., redirect to login)
        }
      });
    };

    onMounted(() => {
      initializeAuth();
    });

    const toggleMenu = () => {
      isMenuOpen.value = !isMenuOpen.value;
    };

    const navigateTo = (path: string) => {
      router.push(path);
      isMenuOpen.value = false; // Close the menu after navigation
    };

    return { selectedExercise, exercises, updateGraph, toggleMenu, navigateTo, isMenuOpen };
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

label {
  margin-right: 10px;
}

select {
  margin-bottom: 20px;
  background-color: #444;
  color: #00ff00;
  border: 1px solid #00ff00;
}

canvas {
  max-width: 100%;
  height: auto;
}
</style>