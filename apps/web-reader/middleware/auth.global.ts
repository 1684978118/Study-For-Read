import type { RouteLocationNormalized } from 'vue-router'

import { useAuthStore } from '../stores/auth'

interface AuthGateState {
  isSignedIn: boolean
  restoreSession: () => Promise<void>
}

const publicPaths = new Set(['/sign-in', '/register'])

export function shouldRedirectToSignIn(
  path: string,
  auth: Pick<AuthGateState, 'isSignedIn'>,
): boolean {
  return !auth.isSignedIn && !publicPaths.has(path)
}

export default defineNuxtRouteMiddleware(async (to: RouteLocationNormalized) => {
  const auth = useAuthStore()
  await auth.restoreSession()
  if (!shouldRedirectToSignIn(to.path, auth)) {
    return
  }

  const globalNavigate = (globalThis as typeof globalThis & {
    navigateTo?: (path: string) => ReturnType<typeof navigateTo>
  }).navigateTo
  if (globalNavigate != null) {
    return globalNavigate('/sign-in')
  }
  return navigateTo('/sign-in')
})
