export type ParsedBookFileType = 'txt' | 'epub'

export interface ParsedChapter {
  chapterIndex: number
  title: string
  content: string
  paragraphs: string[]
}

export interface ParsedBook {
  title: string
  author?: string
  fileType: ParsedBookFileType
  originalFileName: string
  chapters: ParsedChapter[]
}

export type ParseFailureCode =
  | 'empty_txt'
  | 'invalid_utf8'
  | 'missing_container'
  | 'missing_package'
  | 'empty_spine'
  | 'unreadable_xhtml'

export interface ParseFailure {
  code: ParseFailureCode
  message: string
}

export type ParsedBookResult =
  | { ok: true, book: ParsedBook }
  | { ok: false, error: ParseFailure }
