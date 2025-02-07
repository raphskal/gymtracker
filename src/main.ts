// src/main.ts
import { createApp } from "vue";
import App from "./App.vue";
import router from "./router";
import "@/styles/main.css"; // Importiere das Stylesheet

const app = createApp(App);
app.use(router);
app.mount("#app");
