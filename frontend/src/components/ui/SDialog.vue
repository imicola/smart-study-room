<script setup>
import { ref } from 'vue'
import { useDialogFocus } from '../../composables/useDialogFocus'

const props = defineProps({
  modelValue: { type: Boolean, default: false },
  title: { type: String, default: '' },
  width: { type: String, default: '480px' },
  closeOnClickModal: { type: Boolean, default: true },
  showClose: { type: Boolean, default: true }
})

const emit = defineEmits(['update:modelValue', 'close'])

const panelRef = ref(null)
const { trap } = useDialogFocus(() => props.modelValue, panelRef)

function close() {
  emit('update:modelValue', false)
  emit('close')
}

function onBackdrop() {
  if (props.closeOnClickModal) close()
}

function onKeydown(e) {
  trap(e)
  if (e.key === 'Escape' && props.modelValue) {
    e.stopPropagation()
    close()
  }
}

</script>

<template>
  <Teleport to="body">
    <Transition name="s-dialog">
      <div v-if="modelValue" class="s-dialog" role="dialog" aria-modal="true" :aria-label="title">
        <div class="s-dialog__backdrop" @pointerdown="onBackdrop" />
        <div
          ref="panelRef"
          tabindex="-1"
          class="s-dialog__panel"
          :style="{ width, maxWidth: 'calc(100vw - 24px)' }"
          @keydown="onKeydown"
        >
          <header class="s-dialog__header">
            <h3 class="s-dialog__title">{{ title }}</h3>
            <button v-if="showClose" type="button" class="s-dialog__close" aria-label="关闭" @click="close">
              <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="m6 6 12 12M18 6 6 18" /></svg>
            </button>
          </header>
          <div class="s-dialog__body">
            <slot />
          </div>
          <footer v-if="$slots.footer" class="s-dialog__footer">
            <slot name="footer" />
          </footer>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
.s-dialog {
  position: fixed;
  inset: 0;
  z-index: var(--z-dialog);
  display: grid;
  place-items: center;
  padding: 24px;
}

.s-dialog__backdrop {
  position: absolute;
  inset: 0;
  background: var(--backdrop);
  backdrop-filter: blur(3px);
}

.s-dialog__panel {
  position: relative;
  display: flex;
  flex-direction: column;
  max-height: calc(100vh - 48px);
  background: var(--surface);
  border-radius: var(--r-xl);
  border: 1px solid var(--border);
  box-shadow: var(--shadow-4);
  overflow: hidden;
}

.s-dialog__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 16px 20px;
  border-bottom: 1px solid var(--hairline);
  flex: 0 0 auto;
}

.s-dialog__title {
  font-size: 16px;
  font-weight: 600;
  color: var(--text-1);
  letter-spacing: -.005em;
}

.s-dialog__close {
  display: grid;
  place-items: center;
  width: 28px;
  height: 28px;
  border: 0;
  border-radius: var(--r-sm);
  background: transparent;
  color: var(--text-4);
  transition: background var(--dur-1) var(--ease), color var(--dur-1) var(--ease);
}

.s-dialog__close:hover {
  background: var(--surface-3);
  color: var(--text-2);
}

.s-dialog__body {
  padding: 20px;
  overflow-y: auto;
  min-height: 0;
}

.s-dialog__footer {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  gap: 10px;
  padding: 14px 20px;
  border-top: 1px solid var(--hairline);
  background: var(--surface-2);
  flex: 0 0 auto;
}

/* 过渡 */
.s-dialog-enter-active,
.s-dialog-leave-active {
  transition: opacity var(--dur-2) var(--ease);
}

.s-dialog-enter-active .s-dialog__panel,
.s-dialog-leave-active .s-dialog__panel {
  transition: transform var(--dur-3) var(--ease-out), opacity var(--dur-2) var(--ease);
}

.s-dialog-enter-from,
.s-dialog-leave-to {
  opacity: 0;
}

.s-dialog-enter-from .s-dialog__panel,
.s-dialog-leave-to .s-dialog__panel {
  transform: translateY(10px) scale(.98);
  opacity: 0;
}
</style>
