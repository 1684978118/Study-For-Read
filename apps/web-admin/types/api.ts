export interface ApiErrorBody {
  code: string
  message: string
}

export type ApiEnvelope<T> =
  | {
      success: true
      data: T
      error: null
    }
  | {
      success: false
      data: null
      error: ApiErrorBody
    }

export type AdminUiError =
  | 'invalid_credentials'
  | 'admin_disabled'
  | 'admin_required'
  | 'request_failed'
