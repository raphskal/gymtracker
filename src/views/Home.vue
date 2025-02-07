<template>
  <div>
    <h1>Welcome to My Lifts</h1>
    <p>Track your lifts and view your progress!</p>
    <div v-if="user">
      <p>Welcome, {{ user.email }}</p>
      <button @click="logout">Logout</button>
      <router-link to="/lifts">Add a Lift</router-link>
    </div>
    <div v-else>
      <p>Please log in to continue.</p>
      <router-link to="/login">Login</router-link>
    </div>
  </div>
</template>

<script lang="ts">
import { defineComponent, ref, onMounted } from "vue";
import { getAuth, signOut, onAuthStateChanged } from "firebase/auth";

export default defineComponent({
  name: "Home",
  setup() {
    const user = ref<any>(null); // Track the authenticated user

    const auth = getAuth();

    // Monitor authentication state
    onMounted(() => {
      onAuthStateChanged(auth, (currentUser) => {
        user.value = currentUser;
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

    return {
      user,
      logout,
    };
  },
});
</script>

<style scoped>
h1 {
  font-size: 2rem;
  color: #333;
}
p {
  margin: 1rem 0;
}
button {
  margin-right: 1rem;
  padding: 0.5rem 1rem;
  background-color: #007bff;
  color: white;
  border: none;
  border-radius: 5px;
  cursor: pointer;
}
button:hover {
  background-color: #0056b3;
}
</style>
