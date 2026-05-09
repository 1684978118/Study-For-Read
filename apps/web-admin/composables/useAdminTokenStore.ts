export interface AdminTokenStore {
  getToken(): Promise<string | null>
  setToken(token: string): Promise<void>
  clearToken(): Promise<void>
}

const adminTokenKey = 'study_for_read_admin_access_token'

export function createAdminTokenStore(storage = resolveStorage()): AdminTokenStore {
  return {
    async getToken() {
      return storage?.getItem(adminTokenKey) ?? null
    },

    async setToken(token) {
      storage?.setItem(adminTokenKey, token)
    },

    async clearToken() {
      storage?.removeItem(adminTokenKey)
    },
  }
}

export function useAdminTokenStore(): AdminTokenStore {
  return createAdminTokenStore()
}

function resolveStorage(): Storage | null {
  if (typeof window === 'undefined') return null
  return window.localStorage
}
