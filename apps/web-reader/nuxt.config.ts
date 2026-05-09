export default defineNuxtConfig({
  modules: ['@pinia/nuxt'],
  devtools: { enabled: false },
  runtimeConfig: {
    public: {
      apiBaseUrl: '',
    },
  },
  typescript: {
    strict: true,
    typeCheck: true,
  },
})
