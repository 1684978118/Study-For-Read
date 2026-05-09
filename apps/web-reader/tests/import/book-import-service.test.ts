import 'fake-indexeddb/auto'

import JSZip from 'jszip'
import { afterEach, beforeEach, describe, expect, it } from 'vitest'

import { createWebReaderDb, type WebReaderDb } from '../../db/webReaderDb'
import { importBookFile } from '../../services/bookImportService'

describe('importBookFile', () => {
  let db: WebReaderDb

  beforeEach(async () => {
    db = createWebReaderDb(`book-import-service-test-${crypto.randomUUID()}`)
    await db.open()
  })

  afterEach(async () => {
    await db.delete()
  })

  it('imports a TXT file into local book, chapter, reading position, and metadata sync rows', async () => {
    const file = new File([
      'Chapter 1\n\nFirst paragraph.\n\nSecond paragraph.',
    ], 'kokoro.txt', { type: 'text/plain' })

    const result = await importBookFile({
      db,
      file,
      ownerUserId: 'user-1',
      sourceLang: 'ja',
      targetLang: 'zh-CN',
    })

    expect(result.book).toMatchObject({
      ownerUserId: 'user-1',
      title: 'kokoro',
      fileType: 'txt',
      originalFileName: 'kokoro.txt',
      chapterCount: 1,
      metadataSyncStatus: 'local_only',
    })
    await expect(db.web_books.toArray()).resolves.toHaveLength(1)
    await expect(db.web_chapters.where('bookId').equals(result.book.id).toArray()).resolves.toHaveLength(1)
    await expect(db.web_reading_positions.where('bookId').equals(result.book.id).first()).resolves.toMatchObject({
      currentChapterIndex: 0,
      currentParagraphIndex: 0,
      currentCharOffset: 0,
      progressSyncStatus: 'local_only',
    })

    const events = await db.web_pending_sync_events.where('ownerUserId').equals('user-1').toArray()
    expect(events).toHaveLength(1)
    expect(events[0]).toMatchObject({
      eventType: 'book_metadata',
      status: 'pending',
      payloadJson: {
        localBookId: result.book.id,
        fingerprint: result.book.bookFingerprint,
        title: 'kokoro',
        fileType: 'txt',
        sourceLang: 'ja',
        targetLang: 'zh-CN',
        chapterCount: 1,
      },
    })
    expect(JSON.stringify(events[0]?.payloadJson)).not.toMatch(
      /chapter content|kokoro\.txt|First paragraph|Second paragraph|translatedText|originalFileName|fileName|bytes|path/i,
    )
  })

  it('imports an EPUB file through the EPUB parser', async () => {
    const file = await epubFile()

    const result = await importBookFile({
      db,
      file,
      ownerUserId: 'user-1',
      sourceLang: 'ja',
      targetLang: 'zh-CN',
    })

    expect(result.book).toMatchObject({
      title: 'Fixture EPUB',
      author: 'Fixture Author',
      fileType: 'epub',
      chapterCount: 2,
    })
    const chapters = (await db.web_chapters.where('bookId').equals(result.book.id).toArray())
      .sort((a, b) => a.chapterIndex - b.chapterIndex)
    expect(chapters.map((chapter) => chapter.title)).toEqual(['Second', 'First'])
  })

  it('re-imports the same owner and fingerprint without duplicating the book and replaces chapters', async () => {
    const firstFile = new File(['First title\n\nFirst body.'], 'same.txt', { type: 'text/plain' })
    const secondFile = new File(['First title\n\nFirst body.'], 'renamed.txt', { type: 'text/plain' })

    const first = await importBookFile({ db, file: firstFile, ownerUserId: 'user-1' })
    await db.web_chapters.add({
      id: 'stale-chapter',
      bookId: first.book.id,
      chapterIndex: 9,
      title: 'Stale',
      content: 'stale local content',
      paragraphCount: 1,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    })
    const second = await importBookFile({ db, file: secondFile, ownerUserId: 'user-1' })

    expect(second.book.id).toBe(first.book.id)
    await expect(db.web_books.where('ownerUserId').equals('user-1').toArray()).resolves.toHaveLength(1)
    const chapters = await db.web_chapters.where('bookId').equals(first.book.id).toArray()
    expect(chapters).toHaveLength(1)
    expect(chapters.some((chapter) => chapter.id === 'stale-chapter')).toBe(false)
    await expect(db.web_reading_positions.where('bookId').equals(first.book.id).toArray()).resolves.toHaveLength(1)
  })
})

async function epubFile(): Promise<File> {
  const zip = new JSZip()
  zip.file('META-INF/container.xml', `<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml" />
  </rootfiles>
</container>`)
  zip.file('OEBPS/content.opf', `<?xml version="1.0"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>Fixture EPUB</dc:title>
    <dc:creator>Fixture Author</dc:creator>
  </metadata>
  <manifest>
    <item id="first" href="first.xhtml" media-type="application/xhtml+xml" />
    <item id="second" href="second.xhtml" media-type="application/xhtml+xml" />
  </manifest>
  <spine>
    <itemref idref="second" />
    <itemref idref="first" />
  </spine>
</package>`)
  zip.file('OEBPS/first.xhtml', xhtml('First', 'First body.'))
  zip.file('OEBPS/second.xhtml', xhtml('Second', 'Second body.'))
  return new File([await zip.generateAsync({ type: 'arraybuffer' })], 'fixture.epub', {
    type: 'application/epub+zip',
  })
}

function xhtml(title: string, body: string): string {
  return `<?xml version="1.0"?>
<html xmlns="http://www.w3.org/1999/xhtml">
  <body><h1>${title}</h1><p>${body}</p></body>
</html>`
}
