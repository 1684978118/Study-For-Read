export type AdminLexemeEntryType = 'word' | 'phrase' | 'idiom'
export type AdminLexemeStatus = 'active' | 'candidate' | 'rejected'

export interface AdminLexeme {
  id: string
  surface: string
  normalizedSurface: string
  reading: string | null
  sourceLang: string
  targetLang: string
  entryType: AdminLexemeEntryType
  partOfSpeech: string | null
  definition: string
  shortDefinition: string | null
  example: string | null
  status: AdminLexemeStatus
  createdAt?: string
  updatedAt?: string
}

export interface AdminLexemeListQuery {
  page?: number
  size?: number
  q?: string
  sourceLang?: string
  targetLang?: string
  entryType?: AdminLexemeEntryType | ''
  status?: AdminLexemeStatus | ''
}

export interface AdminLexemeListResponse {
  items: AdminLexeme[]
  page: number
  size: number
  total: number
}

export interface AdminLexemeUpsertRequest {
  surface: string
  reading: string | null
  sourceLang: string
  targetLang: string
  entryType: AdminLexemeEntryType
  partOfSpeech: string | null
  definition: string
  shortDefinition: string | null
  example: string | null
  status: AdminLexemeStatus
}

export interface AdminLexemeRejectRequest {
  reason: string
}

export interface AdminLexemeRejectResponse {
  id: string
  status: 'rejected'
}
