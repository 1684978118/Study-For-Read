<template>
  <main class="sign-in-page">
    <form class="sign-in-form" @submit.prevent="submit">
      <div>
        <p class="sign-in-form__eyebrow">Study For Read</p>
        <h1>Admin sign in</h1>
      </div>

      <label>
        <span>Username</span>
        <input v-model="username" name="username" autocomplete="username" />
      </label>

      <label>
        <span>Password</span>
        <input
          v-model="password"
          name="password"
          type="password"
          autocomplete="current-password"
        />
      </label>

      <p v-if="errorMessage" class="sign-in-form__error" role="alert">
        {{ errorMessage }}
      </p>

      <button type="submit" :disabled="auth.loading">
        Sign in
      </button>
    </form>
  </main>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'

import { useAdminAuthStore } from '../../stores/adminAuth'

const auth = useAdminAuthStore()
const username = ref('')
const password = ref('')

const errorMessage = computed(() => {
  if (auth.uiError === 'invalid_credentials') return 'Invalid username or password.'
  if (auth.uiError === 'admin_disabled') return 'Admin account is disabled.'
  if (auth.uiError === 'admin_required') return 'Admin access is required.'
  if (auth.uiError === 'request_failed') return 'Sign in failed. Try again.'
  return null
})

async function submit() {
  try {
    await auth.login({
      username: username.value,
      password: password.value,
    })
    await navigateTo('/admin')
  } catch {
    // Stable UI state is stored in the auth store.
  }
}
</script>

<style scoped>
.sign-in-page {
  min-height: 100vh;
  display: grid;
  place-items: center;
  background: #f6f7f9;
  color: #1d2433;
  font-family:
    Inter,
    ui-sans-serif,
    system-ui,
    -apple-system,
    BlinkMacSystemFont,
    "Segoe UI",
    sans-serif;
}

.sign-in-form {
  width: min(100% - 32px, 360px);
  display: grid;
  gap: 16px;
  padding: 28px;
  border: 1px solid #d8dde6;
  border-radius: 8px;
  background: #ffffff;
}

.sign-in-form__eyebrow {
  margin: 0 0 4px;
  color: #647084;
  font-size: 0.82rem;
}

.sign-in-form h1 {
  margin: 0;
  font-size: 1.35rem;
}

.sign-in-form label {
  display: grid;
  gap: 6px;
  color: #384256;
  font-size: 0.9rem;
}

.sign-in-form input {
  min-height: 38px;
  border: 1px solid #c8cfda;
  border-radius: 6px;
  padding: 0 10px;
  font: inherit;
}

.sign-in-form button {
  min-height: 40px;
  border: 0;
  border-radius: 6px;
  background: #24324a;
  color: #ffffff;
  font: inherit;
  font-weight: 650;
}

.sign-in-form__error {
  margin: 0;
  color: #a33b36;
  font-size: 0.9rem;
}
</style>
