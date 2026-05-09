<script setup lang="ts">
import { computed, onMounted } from 'vue'

import StatsSummary from '../components/stats/StatsSummary.vue'
import { useAuthStore } from '../stores/auth'
import { useStatsStore } from '../stores/stats'

const props = defineProps<{
  today?: string
}>()

const auth = useAuthStore()
const stats = useStatsStore()
const effectiveToday = computed(() => props.today ?? new Date().toISOString().slice(0, 10))

onMounted(async () => {
  if (auth.user) {
    await stats.load(auth.user.id, effectiveToday.value)
  }
})
</script>

<template>
  <main class="stats-page">
    <header>
      <h1>Stats</h1>
    </header>

    <p v-if="!auth.user">
      Sign in required
    </p>
    <p v-else-if="stats.isLoading">
      Loading stats...
    </p>
    <p v-else-if="stats.errorMessage">
      {{ stats.errorMessage }}
    </p>
    <div v-else class="summaries">
      <StatsSummary title="Today" :summary="stats.summaries.today" />
      <StatsSummary title="Last 7 Days" :summary="stats.summaries.last7Days" />
      <StatsSummary title="All Time" :summary="stats.summaries.allTime" />
    </div>
  </main>
</template>

<style scoped>
.stats-page {
  margin: 0 auto;
  max-width: 960px;
  padding: 32px 20px;
}

h1 {
  font-size: 1.75rem;
  margin: 0 0 20px;
}

.summaries {
  display: grid;
  gap: 16px;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
}
</style>
