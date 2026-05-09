export default defineNuxtConfig({
  modules: ['@pinia/nuxt'],
  devtools: { enabled: false },
  typescript: {
    strict: true,
    typeCheck: true,
  },
})
