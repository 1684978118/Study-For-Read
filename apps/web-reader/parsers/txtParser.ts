import type { ParsedBook, ParsedBookResult, ParsedChapter } from './parsedBook'

type DecodeTxtResult =
  | { ok: true, text: string }
  | { ok: false, error: { code: 'invalid_utf8', message: string } }

const emptyTxtFailure = {
  code: 'empty_txt',
  message: 'TXT file is empty.',
} as const

const invalidUtf8Failure = {
  code: 'invalid_utf8',
  message: 'TXT file must be UTF-8 encoded.',
} as const

export async function parseTxtFile(file: File): Promise<ParsedBookResult> {
  const decoded = await decodeUtf8(file)
  if (!decoded.ok) {
    return decoded
  }

  const normalizedText = normalizeLineEndings(stripBom(decoded.text)).trim()
  if (!normalizedText) {
    return {
      ok: false,
      error: emptyTxtFailure,
    }
  }

  const chapters = splitChapters(normalizedText)
  const book: ParsedBook = {
    title: titleFromFileName(file.name),
    fileType: 'txt',
    originalFileName: file.name,
    chapters,
  }

  return { ok: true, book }
}

async function decodeUtf8(file: File): Promise<DecodeTxtResult> {
  try {
    const decoder = new TextDecoder('utf-8', { fatal: true })
    return {
      ok: true,
      text: decoder.decode(await file.arrayBuffer()),
    }
  } catch {
    return {
      ok: false,
      error: invalidUtf8Failure,
    }
  }
}

function splitChapters(text: string): ParsedChapter[] {
  const lines = text.split('\n')
  const sections: Array<{ title: string, lines: string[] }> = []
  let current: { title: string, lines: string[] } | undefined
  let fallbackLines: string[] = []

  for (const line of lines) {
    const trimmedLine = line.trim()
    if (isChapterHeading(trimmedLine)) {
      if (current) {
        sections.push(current)
      } else if (fallbackLines.some((fallbackLine) => fallbackLine.trim())) {
        sections.push({
          title: 'Chapter 1',
          lines: fallbackLines,
        })
        fallbackLines = []
      }
      current = {
        title: trimmedLine,
        lines: [],
      }
      continue
    }

    if (current) {
      current.lines.push(line)
    } else {
      fallbackLines.push(line)
    }
  }

  if (current) {
    sections.push(current)
  } else {
    sections.push({
      title: 'Chapter 1',
      lines: fallbackLines,
    })
  }

  return sections.map((section, chapterIndex) => {
    const content = normalizeChapterContent(section.lines)
    return {
      chapterIndex,
      title: section.title,
      content,
      paragraphs: splitParagraphs(content),
    }
  })
}

function isChapterHeading(line: string): boolean {
  return /^(序章|第[0-9０-９一二三四五六七八九十百千]+章|Chapter\s+[0-9]+)$/i.test(line)
}

function splitParagraphs(content: string): string[] {
  return content
    .split(/\n\s*\n+/)
    .map((paragraph) => paragraph.trim())
    .filter(Boolean)
}

function normalizeChapterContent(lines: string[]): string {
  return lines
    .join('\n')
    .replace(/[ \t]+\n/g, '\n')
    .replace(/\n{3,}/g, '\n\n')
    .trim()
}

function normalizeLineEndings(text: string): string {
  return text.replace(/\r\n/g, '\n').replace(/\r/g, '\n')
}

function stripBom(text: string): string {
  return text.replace(/^\ufeff/, '')
}

function titleFromFileName(fileName: string): string {
  const dotIndex = fileName.lastIndexOf('.')
  const baseName = dotIndex > 0 ? fileName.slice(0, dotIndex) : fileName
  return baseName.trim() || 'Untitled'
}
