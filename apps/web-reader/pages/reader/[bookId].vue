<template>
  <main
    class="reader-page"
    :class="`reader-page--${reader.theme}`"
  >
    <p v-if="reader.status === 'loading'">Loading reader...</p>
    <section
      v-else-if="reader.status === 'not_found'"
      class="reader-page__state"
    >
      <h1>Book not found</h1>
      <p>This local book is not available in this browser.</p>
    </section>
    <section
      v-else-if="reader.status === 'empty'"
      class="reader-page__state"
    >
      <h1>No readable chapters found</h1>
      <p>Import the book again if the local chapter data is missing.</p>
    </section>
    <section
      v-else-if="reader.status === 'error'"
      class="reader-page__state"
    >
      <h1>Reader error</h1>
      <p>{{ reader.errorMessage }}</p>
    </section>
    <template v-else-if="reader.book && reader.currentChapter">
      <ReaderHeader
        :book-title="reader.book.title"
        :chapter-title="reader.currentChapter.title"
        :sync-status="reader.position?.progressSyncStatus ?? 'local_only'"
      />
      <ReaderText
        :content="reader.currentChapter.content"
        :font-size="reader.fontSize"
        :theme="reader.theme"
        :lookup-text="selectedText"
        :translations="paragraphTranslations"
        :on-lookup="lookupSelectedText"
        :on-translate-paragraph="translateParagraph"
      />
      <LookupPopover
        v-if="study.lookupResult"
        :result="study.lookupResult"
        @save="saveLookupResult"
      />
      <ReaderControls
        :can-go-previous="reader.canGoPrevious"
        :can-go-next="reader.canGoNext"
        :font-size="reader.fontSize"
        :theme="reader.theme"
        @previous="goPrevious"
        @next="goNext"
        @font-size-change="reader.setFontSize"
        @theme-change="reader.setTheme"
      />
    </template>
  </main>
</template>

<script setup lang="ts">
import ReaderControls from '../../components/reader/ReaderControls.vue'
import ReaderHeader from '../../components/reader/ReaderHeader.vue'
import ReaderText from '../../components/reader/ReaderText.vue'
import LookupPopover from '../../components/study/LookupPopover.vue'
import { useReaderStore } from '../../stores/reader'
import { useStudyStore } from '../../stores/study'
import { useVocabularyStore } from '../../stores/vocabulary'

const props = defineProps<{
  bookId?: string
}>()

const reader = useReaderStore()
const study = useStudyStore()
const vocabulary = useVocabularyStore()
const selectedText = ref('')
const paragraphTranslations = reactive<Record<number, string>>({})

onMounted(async () => {
  await reader.openBook(resolveBookId())
})

function resolveBookId(): string {
  if (props.bookId) {
    return props.bookId
  }
  try {
    const route = useRoute()
    const value = route.params.bookId
    return Array.isArray(value) ? value[0] ?? '' : String(value ?? '')
  }
  catch {
    return ''
  }
}

async function goPrevious(): Promise<void> {
  await runReaderCommand(() => reader.previousChapter())
}

async function goNext(): Promise<void> {
  await runReaderCommand(() => reader.nextChapter())
}

async function runReaderCommand(command: () => Promise<void>): Promise<void> {
  try {
    await command()
  }
  catch (error) {
    reader.errorMessage = error instanceof Error ? error.message : 'Reader action failed.'
  }
}

async function lookupSelectedText(text: string, paragraphContext?: string): Promise<void> {
  selectedText.value = text
  if (!reader.book) {
    return
  }
  await study.lookupSelectedText({
    ownerUserId: reader.book.ownerUserId,
    text,
    paragraphContext,
    sourceLang: reader.book.sourceLang,
    targetLang: reader.book.targetLang,
  })
}

async function translateParagraph(paragraph: string, paragraphIndex: number): Promise<void> {
  if (!reader.book) {
    return
  }
  await study.translateParagraph({
    ownerUserId: reader.book.ownerUserId,
    paragraph,
    sourceLang: reader.book.sourceLang,
    targetLang: reader.book.targetLang,
  })
  if (study.translationResult?.translatedText) {
    paragraphTranslations[paragraphIndex] = study.translationResult.translatedText
  }
}

async function saveLookupResult(): Promise<void> {
  if (!reader.book || !study.lookupResult?.lexeme) {
    return
  }
  await vocabulary.savePublicLexemeCard({
    ownerUserId: reader.book.ownerUserId,
    lexeme: study.lookupResult.lexeme,
    sourceBookFingerprint: reader.book.bookFingerprint,
    sourceBookTitle: reader.book.title,
  })
}
</script>

<style scoped>
.reader-page {
  min-block-size: 100vh;
}

.reader-page--light {
  background: #ffffff;
}

.reader-page--sepia {
  background: #fbf3e4;
}

.reader-page--dark {
  background: #111827;
}

.reader-page__state {
  max-inline-size: 38rem;
  padding: 3rem 1.25rem;
  margin: 0 auto;
}
</style>
