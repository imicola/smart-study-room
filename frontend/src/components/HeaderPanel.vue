<script setup>
import { computed, onMounted, onUnmounted, ref, useId, watch } from 'vue'
import AppIcon from './AppIcon.vue'
import { activeHeaderPanel } from '../composables/headerPanel'

defineProps({ title: String, icon: { type: String, default: 'info' }, width: { type: Number, default: 340 } })
const emit = defineEmits(['toggle'])
const id = useId()
const root = ref(null)
const trigger = ref(null)
const content = ref(null)
const height = ref(42)
const open = computed(() => activeHeaderPanel.value === id)
let observer
function close(restore = false) {
  if (!open.value) return
  activeHeaderPanel.value = null
  if (restore) trigger.value?.focus({ preventScroll: true })
}
function toggle() { activeHeaderPanel.value = open.value ? null : id }
function outside(event) { if (!root.value?.contains(event.target)) close() }
function focusOut(event) { if (event.relatedTarget && !root.value?.contains(event.relatedTarget)) close() }
watch(open, (val) => emit('toggle', val), { immediate: true })
onMounted(() => {
  observer = new ResizeObserver(() => { height.value = Math.ceil(content.value.getBoundingClientRect().height) + 2 })
  observer.observe(content.value)
  document.addEventListener('pointerdown', outside)
})
onUnmounted(() => { close(); observer?.disconnect(); document.removeEventListener('pointerdown', outside) })
defineExpose({ close, open })
</script>

<template>
  <div ref="root" class="header-panel-anchor" :class="{ 'is-expanded': open }" :style="{ '--panel-width': `${width}px`, '--panel-height': `${height}px` }" @keydown.esc.stop="close(true)" @focusout="focusOut">
    <section class="header-panel-surface" :aria-label="title">
      <button ref="trigger" type="button" class="header-panel-trigger" :title="title" :aria-label="`${open ? '收起' : '展开'}${title}`" :aria-expanded="open" :aria-controls="id" @click="toggle">
        <span class="header-panel-icon" :class="{ 'is-more': icon === 'more' }"><AppIcon :name="icon" :size="21" /></span>
      </button>
      <div :id="id" class="header-panel-viewport" :inert="!open" :aria-hidden="!open">
        <div ref="content" class="header-panel-content">
          <h3>{{ title }}</h3>
          <slot :close="close" />
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
.header-panel-anchor { position: relative; width: 42px; height: 42px; flex: 0 0 42px; z-index: 3; pointer-events: auto; }
.header-panel-anchor.is-expanded { z-index: 5; }
.header-panel-surface { position: absolute; right: 0; top: 0; width: 42px; height: 42px; border: 1px solid transparent; border-radius: 50%; overflow: hidden; background: transparent; color: var(--text-2); transform-origin: top right; box-sizing: border-box; transition: width .26s var(--ease-out), height .26s var(--ease-out), border-radius .26s, border-color .18s, background .18s, box-shadow .22s; }
.is-expanded .header-panel-surface { width: min(var(--panel-width), var(--panel-available, calc(100vw - 32px))); height: min(var(--panel-height), var(--panel-max-height, calc(100dvh - 96px))); border-color: var(--border); border-radius: var(--r-xl); background: var(--surface); box-shadow: var(--shadow-3); }
.header-panel-trigger { position: absolute; z-index: 2; right: 0; top: 0; display: grid; place-items: center; width: 40px; height: 40px; padding: 0; border: 0; border-radius: 50%; background: transparent; color: inherit; cursor: pointer; }
.header-panel-trigger:hover { background: var(--surface-hover); }
.header-panel-trigger:focus-visible { outline: 2px solid var(--primary); outline-offset: -3px; }
.header-panel-icon { display: grid; place-items: center; transition: transform .26s var(--ease-out); }
.header-panel-icon.is-more { transform: rotate(-90deg); }
.is-expanded .header-panel-icon { transform: rotate(0); color: var(--primary); }
.header-panel-viewport { position: absolute; right: 0; top: 0; width: calc(min(var(--panel-width), var(--panel-available, calc(100vw - 32px))) - 2px); max-height: 100%; overflow-x: hidden; overflow-y: auto; scrollbar-width: none; overscroll-behavior-y: contain; opacity: 0; visibility: hidden; transform: translateY(-5px); transition: opacity .13s, transform .2s, visibility 0s linear .26s; }
.is-expanded .header-panel-viewport { opacity: 1; visibility: visible; transform: none; transition: opacity .18s .06s, transform .22s .04s, visibility 0s; }
.header-panel-viewport::-webkit-scrollbar { display: none; width: 0; height: 0; }
.header-panel-content { box-sizing: border-box; padding: 12px 14px 14px; overflow-wrap: anywhere; }
@media (max-width: 1024px) { .header-panel-anchor { --panel-max-height: calc(100dvh - 24px - env(safe-area-inset-bottom)); } }
.header-panel-content h3 { min-height: 30px; padding-right: 34px; margin: 0 0 10px; font-size: 14px; line-height: 22px; color: var(--text-1); }
@media (prefers-reduced-motion: reduce) { .header-panel-surface, .header-panel-viewport, .header-panel-icon, .is-expanded .header-panel-viewport { transition: none; transform: none; } }
</style>
