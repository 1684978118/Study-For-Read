export interface AuthTokenStore {
  getAccessToken: () => string | null
  getRefreshToken: () => string | null
  setTokens: (tokens: { accessToken: string, refreshToken: string }) => void
  clearTokens: () => void
}

const accessTokenKey = 'study_for_read_web_reader_access_token'
const refreshTokenKey = 'study_for_read_web_reader_refresh_token'

export function useAuthTokenStore(): AuthTokenStore {
  return {
    getAccessToken() {
      if (!import.meta.client) {
        return null
      }
      return localStorage.getItem(accessTokenKey)
    },
    getRefreshToken() {
      if (!import.meta.client) {
        return null
      }
      return localStorage.getItem(refreshTokenKey)
    },
    setTokens(tokens) {
      if (!import.meta.client) {
        return
      }
      localStorage.setItem(accessTokenKey, tokens.accessToken)
      localStorage.setItem(refreshTokenKey, tokens.refreshToken)
    },
    clearTokens() {
      if (!import.meta.client) {
        return
      }
      localStorage.removeItem(accessTokenKey)
      localStorage.removeItem(refreshTokenKey)
    },
  }
}
