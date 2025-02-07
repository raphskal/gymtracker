<!-- src/App.vue -->
<template>
  <div>
    <h1>My Lifts</h1>
    <router-view></router-view>
  </div>
</template>

<script lang="ts">
import { defineComponent } from "vue";

export default defineComponent({
  name: "App",
});
</script>
