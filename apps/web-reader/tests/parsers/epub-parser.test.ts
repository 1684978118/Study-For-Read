import JSZip from 'jszip'
import { describe, expect, it } from 'vitest'

import { parseEpubFile } from '../../parsers/epubParser'

describe('parseEpubFile', () => {
  it('parses minimal EPUB metadata and spine-ordered XHTML chapters', async () => {
    const file = await epubFile({
      opfPath: 'OEBPS/content.opf',
      title: 'Kokoro',
      author: 'Natsume Soseki',
      manifest: [
        { id: 'chap2', href: 'chapters/chapter2.xhtml' },
        { id: 'chap1', href: 'chapters/chapter1.xhtml' },
        { id: 'style', href: 'styles/book.css', mediaType: 'text/css' },
        { id: 'cover', href: 'images/cover.jpg', mediaType: 'image/jpeg' },
      ],
      spine: ['chap2', 'chap1'],
      files: {
        'OEBPS/chapters/chapter1.xhtml': xhtml({
          title: 'Chapter One',
          body: '<h1>Chapter One</h1><p>First chapter first.</p><p>First chapter second.</p>',
        }),
        'OEBPS/chapters/chapter2.xhtml': xhtml({
          title: 'Chapter Two',
          body: '<h1>Chapter Two</h1><p>Second chapter first.</p><p>Second chapter second.</p>',
        }),
        'OEBPS/styles/book.css': 'body { color: red; }',
        'OEBPS/images/cover.jpg': 'not image bytes',
      },
    })

    const result = await parseEpubFile(file)

    expect(result).toMatchObject({
      ok: true,
      book: {
        title: 'Kokoro',
        author: 'Natsume Soseki',
        fileType: 'epub',
        originalFileName: 'fixture.epub',
      },
    })
    if (!result.ok) {
      throw new Error('Expected EPUB parse to succeed')
    }
    expect(result.book.chapters.map((chapter) => chapter.title)).toEqual([
      'Chapter Two',
      'Chapter One',
    ])
    expect(result.book.chapters.map((chapter) => chapter.chapterIndex)).toEqual([0, 1])
    expect(result.book.chapters[0]?.paragraphs).toEqual([
      'Chapter Two',
      'Second chapter first.',
      'Second chapter second.',
    ])
  })

  it('strips XHTML tags and ignores scripts, CSS, images, and remote resources', async () => {
    const file = await epubFile({
      files: {
        'OEBPS/chapter.xhtml': xhtml({
          title: 'Visible Title',
          body: [
            '<style>.hidden { display: none; }</style>',
            '<h1>Visible Title</h1>',
            '<p>Hello <strong>reader</strong>.</p>',
            '<img src="images/local.jpg" alt="cover text should not leak" />',
            '<img src="https://example.invalid/remote.jpg" alt="remote text should not leak" />',
            '<script>hiddenScriptText()</script>',
            '<p>Final line.</p>',
          ].join(''),
        }),
        'OEBPS/images/local.jpg': 'image data',
      },
    })

    const result = await parseEpubFile(file)

    expect(result.ok).toBe(true)
    if (!result.ok) {
      throw new Error('Expected EPUB parse to succeed')
    }
    expect(result.book.chapters[0]?.content).toBe('Visible Title\n\nHello reader.\n\nFinal line.')
    expect(result.book.chapters[0]?.content).not.toContain('hiddenScriptText')
    expect(result.book.chapters[0]?.content).not.toContain('cover text should not leak')
    expect(result.book.chapters[0]?.content).not.toContain('remote text should not leak')
    expect(result.book.chapters[0]?.content).not.toContain('https://example.invalid')
  })

  it('returns typed failure when container.xml is missing', async () => {
    const zip = new JSZip()
    zip.file('OEBPS/content.opf', opf({ spine: ['chap1'] }))
    const file = new File([await zip.generateAsync({ type: 'arraybuffer' })], 'missing.epub', {
      type: 'application/epub+zip',
    })

    const result = await parseEpubFile(file)

    expect(result).toEqual({
      ok: false,
      error: {
        code: 'missing_container',
        message: 'EPUB container.xml is missing.',
      },
    })
  })

  it('returns typed failure when spine is empty', async () => {
    const file = await epubFile({
      spine: [],
      files: {
        'OEBPS/chapter.xhtml': xhtml({ body: '<p>Unused.</p>' }),
      },
    })

    const result = await parseEpubFile(file)

    expect(result).toEqual({
      ok: false,
      error: {
        code: 'empty_spine',
        message: 'EPUB spine is empty.',
      },
    })
  })
})

interface ManifestItem {
  id: string
  href: string
  mediaType?: string
}

async function epubFile(options: {
  opfPath?: string
  title?: string
  author?: string
  manifest?: ManifestItem[]
  spine?: string[]
  files?: Record<string, string>
}): Promise<File> {
  const opfPath = options.opfPath ?? 'OEBPS/content.opf'
  const zip = new JSZip()
  zip.file('META-INF/container.xml', container(opfPath))
  zip.file(opfPath, opf({
    title: options.title ?? 'Fixture Book',
    author: options.author ?? 'Fixture Author',
    manifest: options.manifest ?? [{ id: 'chap1', href: 'chapter.xhtml' }],
    spine: options.spine ?? ['chap1'],
  }))

  for (const [path, content] of Object.entries(options.files ?? {
    'OEBPS/chapter.xhtml': xhtml({ body: '<h1>Chapter One</h1><p>Hello.</p>' }),
  })) {
    zip.file(path, content)
  }

  return new File([await zip.generateAsync({ type: 'arraybuffer' })], 'fixture.epub', {
    type: 'application/epub+zip',
  })
}

function container(opfPath: string): string {
  return `<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="${opfPath}" media-type="application/oebps-package+xml" />
  </rootfiles>
</container>`
}

function opf(options: {
  title?: string
  author?: string
  manifest?: ManifestItem[]
  spine: string[]
}): string {
  const manifest = options.manifest ?? [{ id: 'chap1', href: 'chapter.xhtml' }]
  return `<?xml version="1.0"?>
<package xmlns="http://www.idpf.org/2007/opf" unique-identifier="bookid" version="3.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>${options.title ?? 'Fixture Book'}</dc:title>
    <dc:creator>${options.author ?? 'Fixture Author'}</dc:creator>
  </metadata>
  <manifest>
    ${manifest.map((item) => `<item id="${item.id}" href="${item.href}" media-type="${item.mediaType ?? 'application/xhtml+xml'}" />`).join('\n')}
  </manifest>
  <spine>
    ${options.spine.map((idref) => `<itemref idref="${idref}" />`).join('\n')}
  </spine>
</package>`
}

function xhtml(options: { title?: string, body: string }): string {
  return `<?xml version="1.0"?>
<html xmlns="http://www.w3.org/1999/xhtml">
  <head><title>${options.title ?? 'Chapter'}</title></head>
  <body>${options.body}</body>
</html>`
}
