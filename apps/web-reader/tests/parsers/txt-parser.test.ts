import { describe, expect, it } from 'vitest'

import { parseTxtFile } from '../../parsers/txtParser'

describe('parseTxtFile', () => {
  it('parses UTF-8 TXT without BOM into metadata, chapters, and paragraphs', async () => {
    const result = await parseTxtFile(txtFile(
      'kokoro.txt',
      '第一章\n先生と私\n\n次の段落',
    ))

    expect(result).toMatchObject({
      ok: true,
      book: {
        title: 'kokoro',
        fileType: 'txt',
        originalFileName: 'kokoro.txt',
      },
    })
    if (!result.ok) {
      throw new Error('Expected TXT parse to succeed')
    }
    expect(result.book.chapters).toHaveLength(1)
    expect(result.book.chapters[0]).toMatchObject({
      chapterIndex: 0,
      title: '第一章',
      paragraphs: ['先生と私', '次の段落'],
      content: '先生と私\n\n次の段落',
    })
  })

  it('removes UTF-8 BOM from the first chapter text', async () => {
    const result = await parseTxtFile(new File([
      new Uint8Array([0xef, 0xbb, 0xbf]),
      '序章\n本文',
    ], 'bom.txt', { type: 'text/plain' }))

    expect(result.ok).toBe(true)
    if (!result.ok) {
      throw new Error('Expected BOM TXT parse to succeed')
    }
    expect(result.book.chapters[0]?.title).toBe('序章')
    expect(result.book.chapters[0]?.content).not.toMatch(/^\ufeff/)
    expect(result.book.chapters[0]?.paragraphs).toEqual(['本文'])
  })

  it('splits common chapter headings including Japanese and English forms', async () => {
    const result = await parseTxtFile(txtFile(
      'headings.txt',
      [
        '序章',
        'はじめに',
        '',
        '第1章',
        '数字の章',
        '',
        '第一章',
        '漢数字の章',
        '',
        'Chapter 1',
        'English chapter',
      ].join('\n'),
    ))

    expect(result.ok).toBe(true)
    if (!result.ok) {
      throw new Error('Expected heading TXT parse to succeed')
    }
    expect(result.book.chapters.map((chapter) => chapter.title)).toEqual([
      '序章',
      '第1章',
      '第一章',
      'Chapter 1',
    ])
    expect(result.book.chapters.map((chapter) => chapter.chapterIndex)).toEqual([0, 1, 2, 3])
    expect(result.book.chapters[0]?.paragraphs).toEqual(['はじめに'])
    expect(result.book.chapters[3]?.paragraphs).toEqual(['English chapter'])
  })

  it('falls back to one chapter when there are no headings', async () => {
    const result = await parseTxtFile(txtFile(
      'plain.txt',
      '最初の段落\n\n二つ目の段落',
    ))

    expect(result.ok).toBe(true)
    if (!result.ok) {
      throw new Error('Expected fallback TXT parse to succeed')
    }
    expect(result.book.chapters).toHaveLength(1)
    expect(result.book.chapters[0]?.title).toBe('Chapter 1')
    expect(result.book.chapters[0]?.paragraphs).toEqual(['最初の段落', '二つ目の段落'])
  })

  it('normalizes CRLF to LF and splits blank-line groups into paragraphs', async () => {
    const result = await parseTxtFile(txtFile(
      'paragraphs.txt',
      'line one\r\nline two\r\n\r\n\r\nline three',
    ))

    expect(result.ok).toBe(true)
    if (!result.ok) {
      throw new Error('Expected paragraph TXT parse to succeed')
    }
    expect(result.book.chapters[0]?.paragraphs).toEqual(['line one\nline two', 'line three'])
    expect(result.book.chapters[0]?.content).toBe('line one\nline two\n\nline three')
  })

  it('returns typed failure for empty or whitespace-only TXT', async () => {
    const result = await parseTxtFile(txtFile('empty.txt', ' \r\n\t\n '))

    expect(result).toEqual({
      ok: false,
      error: {
        code: 'empty_txt',
        message: 'TXT file is empty.',
      },
    })
  })

  it('returns typed failure for invalid UTF-8 bytes', async () => {
    const result = await parseTxtFile(new File([
      new Uint8Array([0xff, 0xfe, 0xfd]),
    ], 'invalid.txt', { type: 'text/plain' }))

    expect(result).toEqual({
      ok: false,
      error: {
        code: 'invalid_utf8',
        message: 'TXT file must be UTF-8 encoded.',
      },
    })
  })
})

function txtFile(name: string, content: string): File {
  return new File([content], name, { type: 'text/plain' })
}
