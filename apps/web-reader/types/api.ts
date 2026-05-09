export interface ApiErrorPayload {
  code: string
  message: string
}

export interface ApiEnvelope<T> {
  success: boolean
  data: T | null
  error: ApiErrorPayload | null
}

export class WebApiError extends Error {
  constructor(
    public readonly code: string,
    message: string,
  ) {
    super(message)
    this.name = 'WebApiError'
  }
}
