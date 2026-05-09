<script setup lang="ts">
const auth = useAuthStore()
const email = ref('')
const password = ref('')
const errorMessage = ref<string | null>(null)

async function submitSignIn() {
  errorMessage.value = null
  try {
    await auth.signIn({
      email: email.value,
      password: password.value,
    })
    await navigateTo('/library')
  }
  catch {
    errorMessage.value = auth.errorMessage ?? 'Sign in failed.'
  }
}
</script>

<template>
  <main>
    <h1>Sign In</h1>
    <form @submit.prevent="submitSignIn">
      <label>
        Email
        <input
          v-model="email"
          name="email"
          autocomplete="email"
          type="email"
        >
      </label>
      <label>
        Password
        <input
          v-model="password"
          name="password"
          autocomplete="current-password"
          type="password"
        >
      </label>
      <p
        v-if="errorMessage"
        role="alert"
      >
        {{ errorMessage }}
      </p>
      <button type="submit">
        Sign in
      </button>
      <NuxtLink to="/register">
        Create account
      </NuxtLink>
    </form>
  </main>
</template>
