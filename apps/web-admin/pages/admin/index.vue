<template>
  <AdminShell>
    <section class="admin-home">
      <h2>Signed in</h2>
      <p>Admin shell ready.</p>
    </section>
  </AdminShell>
</template>

<script setup lang="ts">
import AdminShell from '../../components/layout/AdminShell.vue'
</script>

<style scoped>
.admin-home {
  max-width: 720px;
}

.admin-home h2 {
  margin: 0 0 8px;
  font-size: 1.1rem;
}

.admin-home p {
  margin: 0;
  color: #657184;
}
</style>
