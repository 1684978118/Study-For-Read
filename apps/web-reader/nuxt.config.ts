export default defineNuxtConfig({
  modules: ['@pinia/nuxt'],
  devtools: { enabled: false },
  nitro: {
    preset: 'static',
  },
  runtimeConfig: {
    public: {
      apiBaseUrl: process.env.WEB_READER_PUBLIC_API_BASE ?? '/api/v1',
    },
  },
  typescript: {
    strict: true,
  },
})
