<template>
  <article
    class="reader-text"
    :class="`reader-text--${theme}`"
    :style="{ fontSize: `${fontSize}px` }"
  >
    <p
      v-for="(paragraph, index) in paragraphs"
      :key="index"
    >
      {{ paragraph }}
      <button
        type="button"
        class="reader-text__translate"
        :data-testid="`translate-paragraph-${index}`"
        @click="onTranslateParagraph?.(paragraph, index)"
      >
        +
      </button>
      <ParagraphTranslationPanel
        v-if="translations?.[index]"
        :translated-text="translations[index]"
      />
    </p>
    <button
      v-if="lookupText"
      type="button"
      data-testid="lookup-selected-text"
      class="reader-text__lookup"
      @click="onLookup?.(lookupText, paragraphs[0] ?? '')"
    >
      Lookup
    </button>
  </article>
</template>

<script setup lang="ts">
import ParagraphTranslationPanel from '../study/ParagraphTranslationPanel.vue'

const props = defineProps<{
  content: string
  fontSize: number
  theme: 'light' | 'sepia' | 'dark'
  lookupText?: string
  translations?: Record<number, string>
  onLookup?: (selectedText: string, paragraphContext?: string) => void
  onTranslateParagraph?: (paragraph: string, paragraphIndex: number) => void
}>()

const paragraphs = computed(() =>
  props.content
    .split(/\n\s*\n+/)
    .map((paragraph) => paragraph.trim())
    .filter(Boolean),
)
</script>

<style scoped>
.reader-text {
  max-inline-size: 46rem;
  padding: 2rem 1.25rem 7rem;
  margin: 0 auto;
  line-height: 1.85;
}

.reader-text--light {
  color: #111827;
  background: #ffffff;
}

.reader-text--sepia {
  color: #2f261d;
  background: #fbf3e4;
}

.reader-text--dark {
  color: #e5e7eb;
  background: #111827;
}

p {
  margin: 0 0 1.25rem;
}

.reader-text__translate,
.reader-text__lookup {
  margin-inline-start: 0.5rem;
}
</style>
