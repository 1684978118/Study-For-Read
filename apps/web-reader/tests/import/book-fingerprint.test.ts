import { describe, expect, it } from 'vitest'

import { calculateBookFingerprint } from '../../utils/bookFingerprint'

describe('calculateBookFingerprint', () => {
  it('calculates a stable lowercase SHA-256 fingerprint for file bytes', async () => {
    const file = new File(['hello'], 'hello.txt', { type: 'text/plain' })

    const result = await calculateBookFingerprint(file)

    expect(result).toEqual({
      ok: true,
      fingerprint: '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824',
      metadata: {
        fileName: 'hello.txt',
        fileSize: 5,
        fileType: 'txt',
        mimeType: 'text/plain',
      },
    })
    if (!result.ok) {
      throw new Error('Expected fingerprint calculation to succeed')
    }
    expect(result.fingerprint).toMatch(/^[0-9a-f]{64}$/)
  })

  it('returns only metadata and fingerprint, never file text, bytes, object URLs, or paths', async () => {
    const file = new File(['private book text'], 'private.epub', {
      type: 'application/epub+zip',
    })

    const result = await calculateBookFingerprint(file)

    expect(result.ok).toBe(true)
    expect(Object.keys(result).sort()).toEqual(['fingerprint', 'metadata', 'ok'])
    expect(JSON.stringify(result)).not.toContain('private book text')
    expect(JSON.stringify(result)).not.toContain('blob:')
    expect(JSON.stringify(result)).not.toContain('filePath')
    expect(JSON.stringify(result)).not.toContain('bytes')
    expect(JSON.stringify(result)).not.toContain('arrayBuffer')
  })

  it('returns the typed import failure for unsupported files', async () => {
    const result = await calculateBookFingerprint(new File(['pdf'], 'book.pdf', {
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
