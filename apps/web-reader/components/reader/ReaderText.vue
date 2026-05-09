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
    </p>
  </article>
</template>

<script setup lang="ts">
const props = defineProps<{
  content: string
  fontSize: number
  theme: 'light' | 'sepia' | 'dark'
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
</style>
