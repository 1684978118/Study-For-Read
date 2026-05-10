export default defineNuxtConfig({
  modules: ['@pinia/nuxt'],
  devtools: { enabled: false },
  nitro: {
    preset: 'static',
    prerender: {
      crawlLinks: false,
      routes: ['/', '/admin/sign-in'],
    },
  },
  runtimeConfig: {
    public: {
      apiBaseUrl: process.env.WEB_ADMIN_PUBLIC_API_BASE ?? '/api/v1',
    },
  },
  typescript: {
    strict: true,
  },
})
