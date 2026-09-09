<script setup>
import { onMounted, onUnmounted, ref } from 'vue'
import HeaderPanel from './HeaderPanel.vue'

defineProps({ title: String })
const media = window.matchMedia('(max-width: 1024px)')
const narrow = ref(media.matches)
const panel = ref(null)
const isHelpOpen = ref(false)
function sync() { panel.value?.close(); narrow.value = media.matches }
onMounted(() => media.addEventListener('change', sync))
onUnmounted(() => media.removeEventListener('change', sync))
</script>

<template>
  <Teleport to="body" :disabled="!narrow">
    <div class="page-help" :class="{ 'page-help-mobile': narrow, 'has-expanded-panel': isHelpOpen }">
      <HeaderPanel ref="panel" :title="title" @toggle="isHelpOpen = $event"><slot /></HeaderPanel>
    </div>
  </Teleport>
</template>

<style scoped>
.page-help { position: absolute; right: 0; top: 0; z-index: 26; }
.page-help-mobile { position: fixed; top: 11px; right: 66px; z-index: 30; --panel-available: calc(100vw - 82px); }
.page-help-mobile.has-expanded-panel,
.page-help-mobile:has(.is-expanded) { z-index: 35; }
</style>
