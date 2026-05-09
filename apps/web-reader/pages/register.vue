<script setup lang="ts">
const auth = useAuthStore()
const displayName = ref('')
const email = ref('')
const password = ref('')
const errorMessage = ref<string | null>(null)

async function submitRegister() {
  errorMessage.value = null
  try {
    await auth.register({
      displayName: displayName.value,
      email: email.value,
      password: password.value,
    })
    await navigateTo('/library')
  }
  catch {
    errorMessage.value = auth.errorMessage ?? 'Registration failed.'
  }
}
</script>

<template>
  <main>
    <h1>Register</h1>
    <form @submit.prevent="submitRegister">
      <label>
        Display name
        <input
          v-model="displayName"
          name="displayName"
          autocomplete="name"
          type="text"
        >
      </label>
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
          autocomplete="new-password"
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
        Register
      </button>
      <NuxtLink to="/sign-in">
        Sign in
      </NuxtLink>
    </form>
  </main>
</template>
