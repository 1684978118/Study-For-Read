import type { BookFingerprintResult } from '../types/import'
import { detectBookFileType } from './bookFileType'

export async function calculateBookFingerprint(file: File): Promise<BookFingerprintResult> {
  const fileTypeResult = detectBookFileType(file)
  if (!fileTypeResult.ok) {
    return fileTypeResult
  }

  const digest = await digestSha256(file)
  if (!digest) {
    return {
      ok: false,
      error: {
        code: 'fingerprint_unavailable',
        message: 'SHA-256 fingerprinting is unavailable in this browser.',
      },
    }
  }

  return {
    ok: true,
    fingerprint: bytesToLowercaseHex(digest),
    metadata: {
      fileName: file.name,
      fileSize: file.size,
      fileType: fileTypeResult.fileType,
      mimeType: file.type,
    },
  }
}

async function digestSha256(file: File): Promise<ArrayBuffer | undefined> {
  const subtle = globalThis.crypto?.subtle
  if (!subtle) {
    return undefined
  }

  return subtle.digest('SHA-256', await file.arrayBuffer())
}

function bytesToLowercaseHex(buffer: ArrayBuffer): string {
  return Array.from(new Uint8Array(buffer))
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('')
}
