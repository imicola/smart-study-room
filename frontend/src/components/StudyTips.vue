<script setup>
import { ref, onMounted, onUnmounted, useId } from 'vue'
import AppIcon from './AppIcon.vue'

defineProps({ title: { type: String, default: '使用小贴士' } })
const open = ref(false)
const root = ref(null)
const trigger = ref(null)
const panelId = useId()
function toggle() { open.value = !open.value }
function close(restore = true) {
  open.value = false
  if (restore) trigger.value?.focus({ preventScroll: true })
}
function outside(event) { if (open.value && !root.value?.contains(event.target)) close(false) }
function focusOut(event) { if (open.value && event.relatedTarget && !root.value?.contains(event.relatedTarget)) close(false) }
onMounted(() => document.addEventListener('pointerdown', outside))
onUnmounted(() => document.removeEventListener('pointerdown', outside))
</script>

<template>
  <div ref="root" class="tips-card" :class="{ 'is-open': open }" @keydown.esc.stop="close()" @focusout="focusOut">
    <!-- This surface and its header persist through both states. Its bottom
         stays anchored while the content track expands the same card upward. -->
    <section class="tips-surface" :aria-label="title">
      <button ref="trigger" class="tips-toggle" type="button" :aria-expanded="open" :aria-controls="panelId" @click="toggle">
        <span class="tips-title"><AppIcon name="book" :size="18" />{{ title }}</span>
        <span class="tips-hint">{{ open ? '收起' : '查看须知' }}<span class="tips-arrow" aria-hidden="true">↗</span></span>
      </button>
      <div :id="panelId" class="tips-body" :inert="!open" :aria-hidden="!open">
        <div class="tips-clip"><div class="tips-copy"><slot /></div></div>
      </div>
    </section>
  </div>
</template>

<style scoped>
.tips-card { position: relative; min-width: 0; width: 100%; height: 54px; align-self: end; }
.tips-card.is-open { z-index: 25; }
.tips-surface { position: absolute; left: 0; bottom: 0; width: 100%; overflow: hidden; border: 1px solid var(--border); border-radius: var(--r-xl); background: var(--surface); transition: border-color .28s, background .28s, box-shadow .28s; }
.is-open .tips-surface { border-color: var(--border-strong); background: var(--surface); box-shadow: var(--shadow-3); }
.tips-toggle { width: 100%; height: 52px; display: flex; justify-content: space-between; align-items: center; gap: 12px; padding: 0 18px; border: 0; border-radius: inherit; color: var(--text-2); background: transparent; transition: background .22s; }
.tips-toggle:focus-visible { outline-offset: -3px; }
.tips-title { display: flex; align-items: center; gap: 10px; font-weight: 550; }
.tips-toggle:hover, .is-open .tips-toggle { background: var(--primary-faint); }
.tips-hint { display: flex; align-items: center; gap: 8px; font-size: 12px; color: var(--text-3); }
.tips-arrow { display: inline-block; transition: transform .28s var(--ease-out); }
.is-open .tips-arrow { transform: rotate(180deg); }
.tips-body { display: grid; grid-template-rows: 0fr; opacity: 0; transition: grid-template-rows .3s var(--ease-out), opacity .18s var(--ease); }
.is-open .tips-body { grid-template-rows: 1fr; opacity: 1; }
.tips-clip { min-height: 0; overflow: hidden; }
.tips-copy { padding: 18px; max-height: min(340px, 60dvh); overflow-y: auto; transform: translateY(6px); transition: transform .3s var(--ease-out); }
.is-open .tips-copy { transform: none; }
@media (prefers-reduced-motion: reduce) { .tips-surface, .tips-toggle, .tips-arrow, .tips-body, .tips-copy { transition: none; } .tips-copy { transform: none; } }
</style>
