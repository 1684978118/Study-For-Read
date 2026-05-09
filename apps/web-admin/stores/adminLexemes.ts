import { defineStore } from 'pinia'

import { AdminApiError } from '../composables/useAdminApiClient'
import {
  adminLexemeFormError,
  type AdminLexemeApiClient,
  useAdminLexemeApiClient,
} from '../services/adminLexemeApiClient'
import type {
  AdminLexeme,
  AdminLexemeListQuery,
  AdminLexemeRejectRequest,
  AdminLexemeRejectResponse,
  AdminLexemeUpsertRequest,
} from '../types/adminLexeme'

interface LoadDeps {
  apiClient?: AdminLexemeApiClient
  accessToken: string
}

export const emptyLexemeForm = (): AdminLexemeUpsertRequest => ({
  surface: '',
  reading: null,
  sourceLang: 'ja',
  targetLang: 'zh-CN',
  entryType: 'word',
  partOfSpeech: null,
  definition: '',
  shortDefinition: null,
  example: null,
  status: 'active',
})

export const useAdminLexemesStore = defineStore('adminLexemes', {
  state: () => ({
    items: [] as AdminLexeme[],
    page: 0,
    size: 20,
    total: 0,
    loading: false,
    listError: null as string | null,
    formError: null as string | null,
    lastSaved: null as AdminLexeme | null,
    lastRejected: null as AdminLexemeRejectResponse | null,
  }),

  actions: {
    async loadLexemes(query: AdminLexemeListQuery = {}, deps: LoadDeps) {
      const apiClient = deps.apiClient ?? useAdminLexemeApiClient()
      this.loading = true
      this.listError = null
      try {
        const response = await apiClient.listLexemes(query, deps.accessToken)
        this.items = response.items
        this.page = response.page
        this.size = response.size
        this.total = response.total
      } catch {
        this.items = []
        this.listError = 'Unable to load lexemes.'
      } finally {
        this.loading = false
      }
    },

    async createLexeme(request: AdminLexemeUpsertRequest, deps: LoadDeps) {
      const apiClient = deps.apiClient ?? useAdminLexemeApiClient()
      this.formError = null
      try {
        this.lastSaved = await apiClient.createLexeme(request, deps.accessToken)
        return this.lastSaved
      } catch (error) {
        this.formError = toFormError(error)
        return null
      }
    },

    async updateLexeme(lexemeId: string, request: AdminLexemeUpsertRequest, deps: LoadDeps) {
      const apiClient = deps.apiClient ?? useAdminLexemeApiClient()
      this.formError = null
      try {
        this.lastSaved = await apiClient.updateLexeme(lexemeId, request, deps.accessToken)
        return this.lastSaved
      } catch (error) {
        this.formError = toFormError(error)
        return null
      }
    },

    async rejectLexeme(lexemeId: string, request: AdminLexemeRejectRequest, deps: LoadDeps) {
      const apiClient = deps.apiClient ?? useAdminLexemeApiClient()
      this.formError = null
      try {
        this.lastRejected = await apiClient.rejectLexeme(lexemeId, request, deps.accessToken)
        return this.lastRejected
      } catch (error) {
        this.formError = toFormError(error)
        return null
      }
    },
  },
})

function toFormError(error: unknown): string {
  if (error instanceof AdminApiError) return adminLexemeFormError(error.code)
  return 'Unable to save lexeme.'
}
