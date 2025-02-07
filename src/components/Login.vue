<template>
  <div>
    <h1>Login</h1>
    <form @submit.prevent="onLogin">
      <div>
        <label for="email">Email:</label>
        <input v-model="email" id="email" type="email" required />
      </div>
      <div>
        <label for="password">Password:</label>
        <input v-model="password" id="password" type="password" required />
      </div>
      <button type="submit">Login</button>
    </form>
  </div>
</template>

<script lang="ts">
import { defineComponent, ref } from "vue";
import { getAuth, signInWithEmailAndPassword } from "firebase/auth";
import { useRouter } from "vue-router";

export default defineComponent({
  name: "Login",
  setup() {
    const email = ref("");
    const password = ref("");
    const router = useRouter();

    const onLogin = async () => {
      try {
        const auth = getAuth();
        await signInWithEmailAndPassword(auth, email.value, password.value);
        alert("Login successful!");
        router.push("/"); // Redirect after login
      } catch (error) {
        console.error("Login failed:", error);
        alert("Invalid email or password. Please try again.");
      }
    };

    return {
      email,
      password,
      onLogin,
    };
  },
});
</script>
