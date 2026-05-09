<script setup lang="ts">
import { onMounted } from 'vue'

import VocabularyCardTile from '../components/vocabulary/VocabularyCardTile.vue'
import VocabularyTabs from '../components/vocabulary/VocabularyTabs.vue'
import { useAuthStore } from '../stores/auth'
import { useVocabularyStore } from '../stores/vocabulary'
import type { VocabularyTab } from '../stores/vocabulary'

const auth = useAuthStore()
const vocabulary = useVocabularyStore()

onMounted(async () => {
  if (auth.user) {
    await vocabulary.loadForOwner(auth.user.id)
  }
})

async function review(payload: { localCardId: string, known: boolean }) {
  if (!auth.user) {
    return
  }
  await vocabulary.reviewCard({
    ownerUserId: auth.user.id,
    localCardId: payload.localCardId,
    known: payload.known,
  })
}

function selectTab(tab: VocabularyTab) {
  vocabulary.setActiveTab(tab)
}
</script>

<template>
  <main class="vocabulary-page">
    <header>
      <h1>Vocabulary</h1>
    </header>

    <p v-if="!auth.user">
      Sign in required
    </p>
    <template v-else>
      <VocabularyTabs :active-tab="vocabulary.activeTab" @select="selectTab" />
      <p v-if="vocabulary.isLoading">
        Loading vocabulary...
      </p>
      <p v-else-if="vocabulary.errorMessage">
        {{ vocabulary.errorMessage }}
      </p>
      <p v-else-if="vocabulary.visibleCards.length === 0">
        No cards in this tab.
      </p>
      <div v-else class="cards">
        <VocabularyCardTile
          v-for="card in vocabulary.visibleCards"
          :key="card.id"
          :card="card"
          @review="review"
        />
      </div>
    </template>
  </main>
</template>

<style scoped>
.vocabulary-page {
  margin: 0 auto;
  max-width: 920px;
  padding: 32px 20px;
}

h1 {
  font-size: 1.75rem;
  margin: 0 0 20px;
}

.cards {
  display: grid;
  gap: 12px;
}
</style>
