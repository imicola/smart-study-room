<script setup>
import { onUnmounted, reactive, watch } from 'vue'
import { gsap } from 'gsap'
const props = defineProps({ value: { type: Number, default: 0 }, decimals: { type: Number, default: 0 } })
const state = reactive({ value: 0 })
const media = window.matchMedia('(prefers-reduced-motion: reduce)')
function settle() { gsap.killTweensOf(state); state.value = props.value }
media.addEventListener('change', settle)
watch(() => props.value, value => {
  gsap.killTweensOf(state)
  if (media.matches) { state.value = value; return }
  gsap.to(state, { value, duration: .55, ease: 'power2.out', overwrite: true })
}, { immediate: true })
onUnmounted(() => { gsap.killTweensOf(state); media.removeEventListener('change', settle) })
</script>
<template><span :aria-label="value.toFixed(decimals)"><span aria-hidden="true">{{ state.value.toFixed(decimals) }}</span></span></template>
