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
    <g v-else-if="name === 'refresh'">
      <path d="M19.2 8.1A8 8 0 1 0 20 14" stroke="currentColor" stroke-width="1.8" />
      <path d="M19.2 3.9v4.6h-4.6" stroke="currentColor" stroke-width="1.8" />
    </g>
    <g v-else-if="name === 'sparkles'">
      <path d="m12 3 1.15 3.35L16.5 7.5l-3.35 1.15L12 12l-1.15-3.35L7.5 7.5l3.35-1.15L12 3Z" fill="#f5ead8" stroke="currentColor" stroke-width="1.5" />
      <path d="m18.1 12.5.7 2 .7.25-.7.7-.7 2-.7-2-.7-.7.7-.25.7-2ZM5.7 13.8l.75 2.15 2.15.75-2.15.75L5.7 19.6l-.75-2.15-2.15-.75 2.15-.75.75-2.15Z" stroke="currentColor" stroke-width="1.35" />
    </g>
    <g v-else-if="name === 'seat'">
      <path d="M7 4.3h10v7.2H7z" fill="#e2f0e0" stroke="currentColor" stroke-width="1.7" />
      <path d="M5 10.5v4.2c0 1.1.9 2 2 2h10c1.1 0 2-.9 2-2v-4.2M7.5 16.8v3M16.5 16.8v3" stroke="currentColor" stroke-width="1.8" />
    </g>
    <g v-else-if="name === 'eye'">
      <path d="M3.2 12s3.1-5.2 8.8-5.2 8.8 5.2 8.8 5.2-3.1 5.2-8.8 5.2S3.2 12 3.2 12Z" fill="#e8eef7" stroke="currentColor" stroke-width="1.6" />
      <circle cx="12" cy="12" r="2.5" stroke="currentColor" stroke-width="1.7" />
    </g>
    <g v-else-if="name === 'inbox'">
      <path d="M4 5.2h16v13.6H4z" fill="#e3eaf4" stroke="currentColor" stroke-width="1.7" />
      <path d="M4.5 13h4l1.5 2h4l1.5-2h4" stroke="currentColor" stroke-width="1.7" />
    </g>
    <g v-else-if="name === 'circle-wait' || name === 'circle-success' || name === 'circle-muted'">
      <circle cx="12" cy="12" r="7.5" :fill="name === 'circle-success' ? '#dcecdc' : name === 'circle-wait' ? '#f5ead8' : '#e7ebf1'" stroke="currentColor" stroke-width="1.7" />
      <path v-if="name === 'circle-success'" d="m8.7 12.1 2.1 2.1 4.7-4.8" stroke="#5f9b68" stroke-width="1.9" />
      <path v-else-if="name === 'circle-wait'" d="M12 7.8v4.6l2.8 1.7" stroke="#b08045" stroke-width="1.8" />
      <path v-else d="M8.5 12h7" stroke="#7f8b9c" stroke-width="1.8" />
    </g>
    <g v-else-if="name === 'warning'">
      <path d="M12 3.5 21 19H3L12 3.5Z" fill="#f5ead8" stroke="currentColor" stroke-width="1.6" />
      <path d="M12 8.2v5.5M12 16.7v.1" stroke="#a87437" stroke-width="2" />
    </g>
    <g v-else-if="name === 'credit'">
      <rect x="3.5" y="5.2" width="17" height="13.6" rx="2.5" fill="#eee7f7" stroke="currentColor" stroke-width="1.7" />
      <path d="M4 9.4h16M7.2 14.6h4" stroke="currentColor" stroke-width="1.7" />
    </g>
    <g v-else-if="name === 'ticket'">
      <path d="M4 6h16v4a2 2 0 0 0 0 4v4H4v-4a2 2 0 0 0 0-4V6Z" fill="#f2e2e4" stroke="currentColor" stroke-width="1.6" />
      <path d="M12 8v1.4M12 11.3v1.4M12 14.6V16" stroke="currentColor" stroke-width="1.5" />
    </g>
    <g v-else-if="name === 'announcement'">
      <path d="m4 11 11-4v10L4 13v-2Z" fill="#e3eaf4" stroke="currentColor" stroke-width="1.7" />
      <path d="m7 14 1.2 5h3L10 15M18 9.2c.9.7 1.4 1.6 1.4 2.8s-.5 2.1-1.4 2.8" stroke="currentColor" stroke-width="1.7" />
    </g>
    <g v-else-if="name === 'building'">
      <path d="M5 20V4h10v16M15 9h4v11M3 20h18" fill="#e3eaf4" stroke="currentColor" stroke-width="1.7" />
      <path d="M8 8h1M12 8h1M8 12h1M12 12h1M8 16h1M12 16h1" stroke="currentColor" stroke-width="1.8" />
    </g>
    <g v-else-if="name === 'users'">
      <circle cx="9" cy="8.3" r="3" fill="#dfe9f6" stroke="currentColor" stroke-width="1.6" />
      <path d="M3.5 19c.5-3.5 2.4-5.3 5.5-5.3s5 1.8 5.5 5.3" fill="#e8eef7" stroke="currentColor" stroke-width="1.6" />
      <path d="M15 6.2a2.7 2.7 0 0 1 0 5.2M15.5 14c2.7.2 4.3 1.9 4.7 4.8" stroke="currentColor" stroke-width="1.6" />
    </g>
    <g v-else-if="name === 'add'">
      <circle cx="12" cy="12" r="8.5" fill="#e2f0e0" stroke="currentColor" stroke-width="1.7" />
      <path d="M12 8v8M8 12h8" stroke="currentColor" stroke-width="1.9" />
    </g>
    <g v-else-if="name === 'walk'">
      <circle cx="13" cy="4.8" r="2" fill="#e3eaf4" stroke="currentColor" stroke-width="1.5" />
      <path d="m11.5 8-2 4 3 2 1.4 5M11 13l-2.5 6M12 9l3 2.2 2.5-.7" stroke="currentColor" stroke-width="1.7" />
    </g>
    <g v-else-if="name === 'book'">
      <path d="M4 5.2c3.5-.8 6.1.1 8 2.1v12c-2-1.8-4.6-2.5-8-1.8V5.2Z" fill="#dfe9f6" stroke="currentColor" stroke-width="1.6" />
      <path d="M20 5.2c-3.5-.8-6.1.1-8 2.1v12c2-1.8 4.6-2.5 8-1.8V5.2Z" fill="#e2f0e0" stroke="currentColor" stroke-width="1.6" />
    </g>
    <g v-else-if="name === 'chevron-right'">
      <path d="m9 5 7 7-7 7" stroke="currentColor" stroke-width="2" />
    </g>
    <g v-else-if="name === 'check'">
      <path d="m5 12.5 4.2 4.2L19 7" stroke="currentColor" stroke-width="2.2" />
    </g>
    <g v-else-if="name === 'info'">
      <circle cx="12" cy="12" r="8.5" fill="#dfe9f6" stroke="currentColor" stroke-width="1.7" />
      <path d="M12 10.5v5M12 7.4v.1" stroke="currentColor" stroke-width="2" />
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
