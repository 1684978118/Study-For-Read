export type ImportableBookFileType = 'txt' | 'epub'

export type BookImportFailureCode =
  | 'unsupported_file_type'
  | 'fingerprint_unavailable'

export interface BookImportFailure {
  code: BookImportFailureCode
  message: string
}

export type BookFileTypeResult =
  | { ok: true, fileType: ImportableBookFileType }
  | { ok: false, error: BookImportFailure }

export interface BookFingerprintMetadata {
  fileName: string
  fileSize: number
  fileType: ImportableBookFileType
  mimeType: string
}

export type BookFingerprintResult =
  | {
    ok: true
    fingerprint: string
    metadata: BookFingerprintMetadata
  }
  | { ok: false, error: BookImportFailure }
