export interface AdminPlatformStatsSummary {
  userCount: number
  activeUserCount: number
  disabledUserCount: number
  bookMetadataCount: number
  lexemeCount: number
  wordCardCount: number
  readingMinutes: number
  lookupCount: number
  paragraphTranslationCount: number
  cardsCreated: number
  cardsReviewed: number
}

export interface AdminUserSummary {
  id: string
  email: string
  displayName: string
  sourceLang: string
  targetLang: string
  status: 'active' | 'disabled'
  createdAt: string
  updatedAt: string
}

export interface AdminUserListQuery {
  page?: number
  size?: number
  status?: 'active' | 'disabled' | ''
  q?: string
}

export interface AdminUserListResponse {
  items: AdminUserSummary[]
  page: number
  size: number
  total: number
}

export interface AdminAuditLog {
  id: string
  adminUserId: string
  adminUsername: string
  action: string
  targetType: string
  targetId: string
  details: Record<string, unknown>
  createdAt: string
}

export interface AdminAuditLogListQuery {
  page?: number
  size?: number
  adminUserId?: string
  targetType?: string
  action?: string
}

export interface AdminAuditLogListResponse {
  items: AdminAuditLog[]
  page: number
  size: number
  total: number
}
