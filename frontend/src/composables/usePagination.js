import { computed, ref, watch } from 'vue'

export function usePagination(items, filter, pageSize = 10) {
  const page = ref(1)
  const pages = computed(() => Math.max(1, Math.ceil(items.value.length / pageSize)))
  const pageItems = computed(() => items.value.slice((page.value - 1) * pageSize, page.value * pageSize))
  if (filter) watch(filter, () => { page.value = 1 }, { flush: 'sync' })
  watch(pages, count => { page.value = Math.min(page.value, count) }, { flush: 'sync' })
  return { page, pages, pageItems }
}
