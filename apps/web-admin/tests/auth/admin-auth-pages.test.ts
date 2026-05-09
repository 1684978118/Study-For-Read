import { createPinia, setActivePinia } from 'pinia'
import { readFile } from 'node:fs/promises'
import { resolve } from 'node:path'
import { describe, expect, it, vi } from 'vitest'

import adminAuthMiddleware from '../../middleware/admin-auth.global'
import { useAdminAuthStore } from '../../stores/adminAuth'

describe('admin auth pages', () => {
  const source = (path: string) =>
    readFile(resolve(process.cwd(), path), 'utf8')

  it('defines an admin sign-in form without dashboard management UI', async () => {
    const page = await source('pages/admin/sign-in.vue')

    expect(page).toContain('Admin sign in')
    expect(page).toContain('Username')
    expect(page).toContain('Password')
    expect(page).not.toContain('Lexeme management')
    expect(page).not.toContain('User management')
  })

  it('defines the protected admin shell placeholder only', async () => {
    const page = await source('pages/admin/index.vue')

    expect(page).toContain('Admin')
    expect(page).toContain('AdminShell')
    expect(page).toContain('Dashboard')
    expect(page).toContain('AdminMetricGrid')
    expect(page).not.toContain('Signed in')
    expect(page).not.toContain('Audit logs')
    expect(page).not.toContain('Lexemes')
  })

  it('redirects signed-out admins from /admin to /admin/sign-in', async () => {
    setActivePinia(createPinia())
    const store = useAdminAuthStore()
    const navigateTo = vi.fn((path: string) => path)
    vi.stubGlobal('navigateTo', navigateTo)

    const result = await adminAuthMiddleware(
      { path: '/admin' },
      { path: '/admin/sign-in' },
      {
        authStore: store,
        restore: async () => undefined,
      },
    )

    expect(result).toBe('/admin/sign-in')
    expect(navigateTo).toHaveBeenCalledWith('/admin/sign-in')
    vi.unstubAllGlobals()
  })
})
