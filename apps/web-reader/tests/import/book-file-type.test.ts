import { describe, expect, it } from 'vitest'

import { detectBookFileType } from '../../utils/bookFileType'

describe('detectBookFileType', () => {
  it('accepts TXT files by extension', () => {
    const result = detectBookFileType(new File(['hello'], 'Kokoro.TXT', { type: 'text/plain' }))

    expect(result).toEqual({ ok: true, fileType: 'txt' })
  })

  it('accepts EPUB files by extension', () => {
    const result = detectBookFileType(new File(['epub bytes'], 'kokoro.epub', {
      type: 'application/epub+zip',
    }))

    expect(result).toEqual({ ok: true, fileType: 'epub' })
  })

  it('rejects unsupported extensions with a typed import failure', () => {
    const result = detectBookFileType(new File(['pdf bytes'], 'kokoro.pdf', {
      type: 'application/pdf',
    }))

    expect(result).toEqual({
      ok: false,
      error: {
        code: 'unsupported_file_type',
        message: 'Only TXT and EPUB files are supported.',
      },
    })
  })
})
