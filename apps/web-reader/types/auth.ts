export interface AuthUser {
  id: string
  email: string
  displayName: string
  sourceLang: string
  targetLang: string
  status: string
}

export interface AuthSession {
  user: AuthUser
  accessToken: string
  refreshToken: string
}

export interface SignInRequest {
  email: string
  password: string
}

export interface RegisterRequest {
  email: string
  password: string
  displayName: string
}
