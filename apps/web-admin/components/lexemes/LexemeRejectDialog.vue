<template>
  <form class="reject-dialog" @submit.prevent="$emit('reject', { reason })">
    <h2>Reject lexeme</h2>
    <label>
      Reason
      <textarea v-model="reason" name="reason" rows="3" />
    </label>
    <button type="submit">Reject</button>
  </form>
</template>

<script setup lang="ts">
import { ref } from 'vue'

import type { AdminLexemeRejectRequest } from '../../types/adminLexeme'

const reason = ref('')

defineEmits<{
  reject: [AdminLexemeRejectRequest]
}>()
</script>

<style scoped>
.reject-dialog {
  display: grid;
  gap: 12px;
  max-width: 460px;
}

.reject-dialog h2 {
  margin: 0;
  font-size: 1rem;
}

.reject-dialog label {
  display: grid;
  gap: 5px;
  color: #384256;
  font-size: 0.9rem;
}

.reject-dialog textarea {
  border: 1px solid #c8cfda;
  border-radius: 6px;
  padding: 8px 10px;
  font: inherit;
}

.reject-dialog button {
  width: fit-content;
  min-height: 34px;
  border: 0;
  border-radius: 6px;
  padding: 0 14px;
  background: #7a2e2a;
  color: #ffffff;
  font: inherit;
}
</style>
