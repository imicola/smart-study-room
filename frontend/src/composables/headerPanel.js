import { ref } from 'vue'

// Only one header surface expands at a time (help or quick navigation).
export const activeHeaderPanel = ref(null)
