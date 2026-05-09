import { XMLParser } from 'fast-xml-parser'
import JSZip from 'jszip'

import type { ParsedBook, ParsedBookResult, ParsedChapter, ParseFailure } from './parsedBook'

const xmlParser = new XMLParser({
  ignoreAttributes: false,
  attributeNamePrefix: '',
  textNodeName: '#text',
  trimValues: true,
})

const failures = {
  missingContainer: {
    code: 'missing_container',
    message: 'EPUB container.xml is missing.',
  },
  missingPackage: {
    code: 'missing_package',
    message: 'EPUB package file is missing.',
  },
  emptySpine: {
    code: 'empty_spine',
    message: 'EPUB spine is empty.',
  },
  unreadableXhtml: {
    code: 'unreadable_xhtml',
    message: 'EPUB chapter XHTML is unreadable.',
  },
} as const satisfies Record<string, ParseFailure>

interface ManifestItem {
  id: string
  href: string
  mediaType?: string
}

export async function parseEpubFile(file: File): Promise<ParsedBookResult> {
  const zip = await JSZip.loadAsync(await file.arrayBuffer())
  const containerXml = await readZipText(zip, 'META-INF/container.xml')
  if (!containerXml) {
    return { ok: false, error: failures.missingContainer }
  }

  const packagePath = findPackagePath(parseXml(containerXml))
  if (!packagePath) {
    return { ok: false, error: failures.missingPackage }
  }

  const packageXml = await readZipText(zip, packagePath)
  if (!packageXml) {
    return { ok: false, error: failures.missingPackage }
  }

  const packageDocument = getObjectChild(parseXml(packageXml), 'package')
  const metadata = getObjectChild(packageDocument, 'metadata')
  const manifestItems = readManifestItems(getObjectChild(packageDocument, 'manifest'))
  const spineIds = readSpineIds(getObjectChild(packageDocument, 'spine'))
  if (spineIds.length === 0) {
    return { ok: false, error: failures.emptySpine }
  }

  const opfDirectory = directoryName(packagePath)
  const chapters: ParsedChapter[] = []
  for (const idref of spineIds) {
    const item = manifestItems.find((manifestItem) => manifestItem.id === idref)
    if (!item || !isReadableXhtml(item)) {
      continue
    }

    const chapterPath = resolveRelativePath(opfDirectory, item.href)
    const xhtml = await readZipText(zip, chapterPath)
    if (!xhtml) {
      return { ok: false, error: failures.unreadableXhtml }
    }

    const chapter = parseXhtmlChapter(xhtml, chapters.length)
    if (!chapter) {
      return { ok: false, error: failures.unreadableXhtml }
    }
    chapters.push(chapter)
  }

  if (chapters.length === 0) {
    return { ok: false, error: failures.emptySpine }
  }

  const book: ParsedBook = {
    title: readTextChild(metadata, 'title') ?? titleFromFileName(file.name),
    author: readTextChild(metadata, 'creator'),
    fileType: 'epub',
    originalFileName: file.name,
    chapters,
  }
  return { ok: true, book }
}

async function readZipText(zip: JSZip, path: string): Promise<string | undefined> {
  return zip.file(path)?.async('string')
}

function parseXml(xml: string): unknown {
  return xmlParser.parse(xml)
}

function findPackagePath(containerDocument: unknown): string | undefined {
  const container = getObjectChild(containerDocument, 'container')
  const rootfiles = getObjectChild(container, 'rootfiles')
  const rootfile = firstChild(getChild(rootfiles, 'rootfile'))
  const fullPath = readStringProperty(rootfile, 'full-path')
  return fullPath?.trim() || undefined
}

function readManifestItems(manifest: Record<string, unknown> | undefined): ManifestItem[] {
  return toArray(getChild(manifest, 'item'))
    .map((item) => ({
      id: readStringProperty(item, 'id') ?? '',
      href: readStringProperty(item, 'href') ?? '',
      mediaType: readStringProperty(item, 'media-type'),
    }))
    .filter((item) => item.id && item.href)
}

function readSpineIds(spine: Record<string, unknown> | undefined): string[] {
  return toArray(getChild(spine, 'itemref'))
    .map((item) => readStringProperty(item, 'idref')?.trim())
    .filter((idref): idref is string => Boolean(idref))
}

function isReadableXhtml(item: ManifestItem): boolean {
  return !item.mediaType || item.mediaType === 'application/xhtml+xml' || item.href.endsWith('.xhtml')
}

function parseXhtmlChapter(xhtml: string, chapterIndex: number): ParsedChapter | undefined {
  const body = extractBody(xhtml)
  if (!body) {
    return undefined
  }

  const text = htmlToVisibleText(body)
  const paragraphs = text
    .split(/\n\s*\n+/)
    .map((paragraph) => paragraph.trim())
    .filter(Boolean)
  if (paragraphs.length === 0) {
    return undefined
  }

  return {
    chapterIndex,
    title: paragraphs[0] ?? `Chapter ${chapterIndex + 1}`,
    content: paragraphs.join('\n\n'),
    paragraphs,
  }
}

function extractBody(xhtml: string): string | undefined {
  return /<body\b[^>]*>([\s\S]*?)<\/body>/i.exec(xhtml)?.[1]
}

function htmlToVisibleText(html: string): string {
  return decodeHtmlEntities(html)
    .replace(/<script\b[\s\S]*?<\/script>/gi, '')
    .replace(/<style\b[\s\S]*?<\/style>/gi, '')
    .replace(/<img\b[^>]*>/gi, '')
    .replace(/<(h[1-6]|p|div|section|article|li|blockquote)\b[^>]*>/gi, '\n')
    .replace(/<\/(h[1-6]|p|div|section|article|li|blockquote)>/gi, '\n')
    .replace(/<br\b[^>]*\/?>/gi, '\n')
    .replace(/<[^>]+>/g, '')
    .split('\n')
    .map((line) => line.replace(/\s+/g, ' ').trim())
    .filter(Boolean)
    .join('\n\n')
}

function decodeHtmlEntities(text: string): string {
  return text
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&#x([0-9a-f]+);/gi, (_, hex: string) => String.fromCodePoint(Number.parseInt(hex, 16)))
    .replace(/&#([0-9]+);/g, (_, decimal: string) => String.fromCodePoint(Number.parseInt(decimal, 10)))
}

function readTextChild(parent: Record<string, unknown> | undefined, localName: string): string | undefined {
  const child = firstChild(getChild(parent, localName))
  if (typeof child === 'string') {
    return child.trim() || undefined
  }
  if (isRecord(child)) {
    return readStringProperty(child, '#text')?.trim() || undefined
  }
  return undefined
}

function getObjectChild(parent: unknown, localName: string): Record<string, unknown> | undefined {
  const child = firstChild(getChild(parent, localName))
  return isRecord(child) ? child : undefined
}

function getChild(parent: unknown, localName: string): unknown {
  if (!isRecord(parent)) {
    return undefined
  }
  const matchingKey = Object.keys(parent).find((key) => key === localName || key.endsWith(`:${localName}`))
  return matchingKey ? parent[matchingKey] : undefined
}

function firstChild(child: unknown): unknown {
  return Array.isArray(child) ? child[0] : child
}

function toArray(child: unknown): unknown[] {
  if (child === undefined) {
    return []
  }
  return Array.isArray(child) ? child : [child]
}

function readStringProperty(value: unknown, key: string): string | undefined {
  if (!isRecord(value)) {
    return undefined
  }
  const property = value[key]
  return typeof property === 'string' ? property : undefined
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null
}

function directoryName(path: string): string {
  const slashIndex = path.lastIndexOf('/')
  return slashIndex === -1 ? '' : path.slice(0, slashIndex)
}

function resolveRelativePath(baseDirectory: string, href: string): string {
  const parts = [...baseDirectory.split('/'), ...href.split('/')]
  const resolved: string[] = []
  for (const part of parts) {
    if (!part || part === '.') {
      continue
    }
    if (part === '..') {
      resolved.pop()
      continue
    }
    resolved.push(part)
  }
  return resolved.join('/')
}

function titleFromFileName(fileName: string): string {
  const dotIndex = fileName.lastIndexOf('.')
  const baseName = dotIndex > 0 ? fileName.slice(0, dotIndex) : fileName
  return baseName.trim() || 'Untitled'
}
