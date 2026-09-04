<script setup>
defineProps({
  name: { type: String, required: true },
  size: { type: [Number, String], default: 20 }
})
</script>

<template>
  <svg
    class="app-icon"
    :width="size"
    :height="size"
    viewBox="0 0 24 24"
    fill="none"
    xmlns="http://www.w3.org/2000/svg"
    aria-hidden="true"
  >
    <g v-if="name === 'home'">
      <path d="M3.5 10.7 12 3.8l8.5 6.9v8.2a1.6 1.6 0 0 1-1.6 1.6H5.1a1.6 1.6 0 0 1-1.6-1.6v-8.2Z" fill="#dfe9f6" stroke="currentColor" stroke-width="1.7" />
      <path d="M9 20.2v-6.1h6v6.1" fill="#f8fbff" stroke="currentColor" stroke-width="1.7" />
    </g>
    <g v-else-if="name === 'booking'">
      <rect x="4" y="3.8" width="16" height="16.5" rx="3" fill="#e2f0e0" stroke="currentColor" stroke-width="1.7" />
      <path d="M8 2.8v3M16 2.8v3M4.4 8.2h15.2" stroke="currentColor" stroke-width="1.7" />
      <path d="m8.2 14 2.3 2.2 5.1-5.1" stroke="#5f9b68" stroke-width="2" />
    </g>
    <g v-else-if="name === 'reservations'">
      <rect x="5" y="3.5" width="14" height="17" rx="2.5" fill="#e3eaf4" stroke="currentColor" stroke-width="1.7" />
      <path d="M8.5 8h7M8.5 12h7M8.5 16h4" stroke="currentColor" stroke-width="1.7" />
      <circle cx="7" cy="8" r=".7" fill="#7794b8" />
    </g>
    <g v-else-if="name === 'waitlist'">
      <circle cx="12" cy="12" r="8.5" fill="#f5ead8" stroke="currentColor" stroke-width="1.7" />
      <path d="M12 7.2v5.3l3.4 2" stroke="#b08045" stroke-width="1.9" />
    </g>
    <g v-else-if="name === 'notification' || name === 'notification-empty'">
      <path d="M6.2 16.8h11.6l-1.3-2V10a4.5 4.5 0 0 0-9 0v4.8l-1.3 2Z" fill="#eee7f7" stroke="currentColor" stroke-width="1.7" />
      <path d="M10 19a2.1 2.1 0 0 0 4 0" stroke="#8b72b5" stroke-width="1.8" />
      <circle v-if="name === 'notification'" cx="17.7" cy="5.6" r="2.2" fill="#c8787e" stroke="#fff" stroke-width="1.2" />
    </g>
    <g v-else-if="name === 'analytics'">
      <rect x="3.5" y="4" width="17" height="16" rx="3" fill="#f6ead9" stroke="currentColor" stroke-width="1.7" />
      <path d="M7.5 16v-3M12 16V8M16.5 16v-5.5" stroke="#b17d3d" stroke-width="2.2" />
    </g>
    <g v-else-if="name === 'admin'">
      <path d="M12 3.2 19 6v5.2c0 4.4-2.9 7.8-7 9.6-4.1-1.8-7-5.2-7-9.6V6l7-2.8Z" fill="#f2e2e4" stroke="currentColor" stroke-width="1.7" />
      <path d="M9.2 12.1 11 14l4.1-4.3" stroke="#a85f68" stroke-width="2" />
    </g>
    <g v-else-if="name === 'profile'">
      <circle cx="12" cy="8" r="3.5" fill="#dfe9f6" stroke="currentColor" stroke-width="1.7" />
      <path d="M5 20c.5-4 3.1-6.2 7-6.2s6.5 2.2 7 6.2" fill="#e8eef7" stroke="currentColor" stroke-width="1.7" />
    </g>
    <g v-else-if="name === 'sidebar-collapse'">
      <rect x="3.5" y="4" width="17" height="16" rx="2.5" fill="#e5ebf4" stroke="currentColor" stroke-width="1.6" />
      <path d="M8.5 4.5v15M15.5 9l-3 3 3 3" stroke="currentColor" stroke-width="1.7" />
    </g>
    <g v-else-if="name === 'sidebar-expand'">
      <rect x="3.5" y="4" width="17" height="16" rx="2.5" fill="#e5ebf4" stroke="currentColor" stroke-width="1.6" />
      <path d="M8.5 4.5v15M12.5 9l3 3-3 3" stroke="currentColor" stroke-width="1.7" />
    </g>
    <g v-else-if="name === 'more'">
      <circle cx="12" cy="5.5" r="1.8" fill="#8aa0ba" />
      <circle cx="12" cy="12" r="1.8" fill="currentColor" />
      <circle cx="12" cy="18.5" r="1.8" fill="#8aa0ba" />
    </g>
  </svg>
</template>

<style scoped>
.app-icon {
  display: block;
  color: inherit;
  overflow: visible;
}
.app-icon * {
  stroke-linecap: round;
  stroke-linejoin: round;
}
</style>
