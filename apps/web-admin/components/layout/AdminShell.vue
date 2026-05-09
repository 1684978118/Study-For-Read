<template>
  <div class="admin-shell">
    <header class="admin-shell__header">
      <div>
        <p class="admin-shell__eyebrow">Study For Read</p>
        <h1>Admin</h1>
      </div>
      <p class="admin-shell__status">Signed in</p>
    </header>
    <main class="admin-shell__main">
      <slot />
    </main>
  </div>
</template>

<style scoped>
.admin-shell {
  min-height: 100vh;
  background: #f6f7f9;
  color: #1d2433;
  font-family:
    Inter,
    ui-sans-serif,
    system-ui,
    -apple-system,
    BlinkMacSystemFont,
    "Segoe UI",
    sans-serif;
}

.admin-shell__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20px 28px;
  border-bottom: 1px solid #d8dde6;
  background: #ffffff;
}

.admin-shell__eyebrow,
.admin-shell__status {
  margin: 0;
  color: #647084;
  font-size: 0.82rem;
}

.admin-shell__header h1 {
  margin: 4px 0 0;
  font-size: 1.35rem;
  font-weight: 650;
}

.admin-shell__main {
  padding: 28px;
}
</style>
