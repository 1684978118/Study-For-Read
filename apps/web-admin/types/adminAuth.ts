export type AdminRole = 'admin' | 'operator'
export type AdminStatus = 'active' | 'disabled'

export interface AdminProfile {
  id: string
  username: string
  role: AdminRole
  status: AdminStatus
}

export interface AdminLoginRequest {
  username: string
  password: string
}

export interface AdminLoginResponse {
  admin: AdminProfile
  accessToken: string
}
