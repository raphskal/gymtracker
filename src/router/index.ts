import { createRouter, createWebHistory } from "vue-router";
import { getAuth, onAuthStateChanged } from "firebase/auth";
import Home from "@/views/Home.vue";
import LiftForm from "@/components/LiftForm.vue";
import Login from "@/components/Login.vue";
import Analytics from "@/components/Analytics.vue"; 

const routes = [
  {
    path: "/",
    name: "Home",
    component: Home,
  },
  {
    path: "/lifts",
    name: "LiftForm",
    component: LiftForm,
    meta: { requiresAuth: true }, // Protect this route
  },
  {
    path: "/login",
    name: "Login",
    component: Login,
  },
  { path: "/analytics", 
  name: "Analytics", 
  component: Analytics 
  }
];

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
});

// Add navigation guard to enforce login
router.beforeEach((to, from, next) => {
  const auth = getAuth();
  const requiresAuth = to.meta.requiresAuth;

  if (requiresAuth) {
    // Check if user is authenticated
    const unsubscribe = onAuthStateChanged(auth, (user) => {
      unsubscribe(); // Unsubscribe after first check
      if (user) {
        next(); // User is authenticated
      } else {
        next("/login"); // Redirect to login page
      }
    });
  } else {
    next(); // No auth required for the route
  }
});

export default router;
