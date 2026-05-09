import { defineStore } from 'pinia'

import { createWebReaderDb, type WebReaderDb } from '../db/webReaderDb'
import { importBookFile } from '../services/bookImportService'
import type { WebBook } from '../types/localData'
import { createBookRepository } from '../repositories/bookRepository'

interface ImportBookInput {
  file: File
  ownerUserId: string
  sourceLang?: string
  targetLang?: string
}

interface LibraryDependencies {
  listBooks(ownerUserId: string): Promise<WebBook[]>
  importBook(input: ImportBookInput): Promise<WebBook>
}

let testDependencies: LibraryDependencies | null = null
let defaultDb: WebReaderDb | null = null

export const useLibraryStore = defineStore('library', {
  state: () => ({
    books: [] as WebBook[],
    isLoading: false,
    isImporting: false,
    errorMessage: null as string | null,
  }),
  actions: {
    async load(ownerUserId: string) {
      this.isLoading = true
      this.errorMessage = null
      try {
        this.books = await libraryDependencies().listBooks(ownerUserId)
      }
      catch (error) {
        this.errorMessage = messageFromError(error)
      }
      finally {
        this.isLoading = false
      }
    },
    async importLocalFile(input: ImportBookInput) {
      this.isImporting = true
      this.errorMessage = null
      try {
        await libraryDependencies().importBook(input)
        this.books = await libraryDependencies().listBooks(input.ownerUserId)
      }
      catch (error) {
        this.errorMessage = messageFromError(error)
      }
      finally {
        this.isImporting = false
      }
    },
  },
})

export function setLibraryDependenciesForTesting(dependencies: LibraryDependencies): void {
  testDependencies = dependencies
}

export function resetLibraryDependenciesForTesting(): void {
  testDependencies = null
}

function libraryDependencies(): LibraryDependencies {
  if (testDependencies) {
    return testDependencies
  }
  const db = getDefaultDb()
  const books = createBookRepository(db)
  return {
    listBooks(ownerUserId: string) {
      return books.listByOwnerUserId(ownerUserId)
    },
    async importBook(input: ImportBookInput) {
      const result = await importBookFile({ ...input, db })
      return result.book
    },
  }
}

function getDefaultDb(): WebReaderDb {
  defaultDb ??= createWebReaderDb()
  return defaultDb
}

function messageFromError(error: unknown): string {
  if (error instanceof Error && error.message) {
    return error.message
  }
  return 'Library action failed.'
}
