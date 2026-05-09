import { useAdminAuthStore } from '../stores/adminAuth'

interface AdminAuthMiddlewareDeps {
  authStore?: ReturnType<typeof useAdminAuthStore>
  restore?: () => Promise<void>
}

export default async function adminAuthMiddleware(
  to: { path: string },
  _from?: { path: string },
  deps: AdminAuthMiddlewareDeps = {},
) {
  if (!to.path.startsWith('/admin') || to.path === '/admin/sign-in') {
    return undefined
  }

  const authStore = deps.authStore ?? useAdminAuthStore()
  const restore = deps.restore ?? (() => authStore.restore())

  if (!authStore.restored) {
    await restore()
  }

  if (!authStore.isAuthenticated) {
    const navigate = resolveNavigate()
    return navigate('/admin/sign-in')
  }

  return undefined
}

function resolveNavigate(): (path: string) => unknown {
  const globalNavigate = (globalThis as { navigateTo?: (path: string) => unknown }).navigateTo
  if (globalNavigate) return globalNavigate
  if (typeof navigateTo === 'function') return navigateTo
  return (path: string) => path
}
