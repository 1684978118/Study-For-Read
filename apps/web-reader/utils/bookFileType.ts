import type { BookFileTypeResult } from '../types/import'

const unsupportedFileType = {
  code: 'unsupported_file_type',
  message: 'Only TXT and EPUB files are supported.',
} as const

export function detectBookFileType(file: File): BookFileTypeResult {
  const normalizedName = file.name.toLowerCase()

  if (normalizedName.endsWith('.txt')) {
    return { ok: true, fileType: 'txt' }
  }

  if (normalizedName.endsWith('.epub')) {
    return { ok: true, fileType: 'epub' }
  }

  return {
    ok: false,
    error: unsupportedFileType,
  }
}
