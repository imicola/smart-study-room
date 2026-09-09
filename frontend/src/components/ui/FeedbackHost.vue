<script setup>
import { nextTick, ref, watch } from 'vue'
import { useDialogFocus } from '../../composables/useDialogFocus'
import SButton from './SButton.vue'
import SInput from './SInput.vue'
import {
  feedbackState, dismissToast, resolveBox, rejectBox
} from './feedback'

const inputRef = ref(null)
const panelRef = ref(null)
const { trap } = useDialogFocus(() => Boolean(feedbackState.box), panelRef)
const promptValue = ref('')
const promptError = ref('')

watch(
  () => feedbackState.box?.id,
  () => {
    promptError.value = ''
    if (feedbackState.box?.mode === 'prompt') {
      promptValue.value = feedbackState.box.inputValue
      nextTick(() => inputRef.value?.querySelector('input')?.focus())
    }
  }
)

function validate() {
  const box = feedbackState.box
  if (box?.inputPattern && !box.inputPattern.test(promptValue.value)) {
    promptError.value = box.inputErrorMessage
    return false
  }
  promptError.value = ''
  return true
}

function onConfirm() {
  const box = feedbackState.box
  if (!box) return
  if (box.mode === 'prompt') {
    if (!validate()) return
    resolveBox(box, { value: promptValue.value })
  } else {
    resolveBox(box)
  }
}

function onCancel() {
  const box = feedbackState.box
  if (box) rejectBox(box)
}

function onInputKeydown(e) {
  if (e.key === 'Enter') {
    e.preventDefault()
    onConfirm()
  }
}

function onBoxKeydown(e) {
  trap(e)
  if (e.key === 'Escape') {
    e.stopPropagation()
    onCancel()
  }
}

const boxIcons = {
  success: { d: 'm8.7 12.1 2.1 2.1 4.7-4.8', cls: 'icon-success' },
  info: { d: 'M12 10.5v5M12 7.4v.1', cls: 'icon-info' },
  warning: { d: 'M12 8.2v5.5M12 16.7v.1', cls: 'icon-warning' },
  error: { d: 'M9 9l6 6M15 9l-6 6', cls: 'icon-error' }
}
</script>

<template>
  <Teleport to="body">
    <!-- Toast 消息 -->
    <TransitionGroup name="s-toast" tag="div" class="toast-region" aria-live="polite">
      <div v-for="t in feedbackState.toasts" :key="t.id" class="toast" :class="`toast--${t.type}`" @click="dismissToast(t.id)">
        <svg class="toast__icon" viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
          <template v-if="t.type === 'success'">
            <path d="M4.5 12.5a7.5 7.5 0 1 0 15 0 7.5 7.5 0 1 0-15 0Z" stroke-width="1.7" />
            <path d="m8.7 12.1 2.1 2.1 4.7-4.8" />
          </template>
          <template v-else-if="t.type === 'error'">
            <path d="M4.5 12.5a7.5 7.5 0 1 0 15 0 7.5 7.5 0 1 0-15 0Z" stroke-width="1.7" />
            <path d="M9 9l6 6M15 9l-6 6" />
          </template>
          <template v-else-if="t.type === 'warning'">
            <path d="M12 3.5 21 19H3L12 3.5Z" stroke-width="1.7" />
            <path d="M12 8.2v5.5M12 16.7v.1" />
          </template>
          <template v-else>
            <path d="M4.5 12.5a7.5 7.5 0 1 0 15 0 7.5 7.5 0 1 0-15 0Z" stroke-width="1.7" />
            <path d="M12 10.5v5M12 7.4v.1" />
          </template>
        </svg>
        <span class="toast__content">{{ t.content }}</span>
      </div>
    </TransitionGroup>

    <!-- 确认 / 输入弹窗 -->
    <Transition name="s-msgbox">
      <div
        v-if="feedbackState.box"
        class="msgbox"
        role="alertdialog"
        aria-modal="true"
        :aria-label="feedbackState.box.title"
        @keydown="onBoxKeydown"
      >
        <div class="msgbox__backdrop" @pointerdown="onCancel" />
        <div ref="panelRef" tabindex="-1" class="msgbox__panel">
          <div class="msgbox__head">
            <span class="msgbox__icon" :class="boxIcons[feedbackState.box.type]?.cls" aria-hidden="true">
              <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path :d="boxIcons[feedbackState.box.type]?.d" />
              </svg>
            </span>
            <h3 class="msgbox__title">{{ feedbackState.box.title }}</h3>
          </div>
          <p class="msgbox__content">{{ feedbackState.box.content }}</p>

          <div v-if="feedbackState.box.mode === 'prompt'" ref="inputRef" class="msgbox__input">
            <SInput
              v-model="promptValue"
              :aria-invalid="!!promptError"
              :placeholder="feedbackState.box.inputPlaceholder"
              @keydown="onInputKeydown"
              @input="promptError = ''"
            />
            <div v-if="promptError" class="msgbox__error">{{ promptError }}</div>
          </div>

          <div class="msgbox__actions">
            <SButton variant="secondary" @click="onCancel">{{ feedbackState.box.cancelText }}</SButton>
            <SButton
              :variant="feedbackState.box.type === 'warning' || feedbackState.box.type === 'error' ? 'danger' : 'primary'"
              @click="onConfirm"
            >
              {{ feedbackState.box.confirmText }}
            </SButton>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
/* =============== Toast =============== */
.toast-region {
  position: fixed;
  top: 18px;
  left: 50%;
  transform: translateX(-50%);
  z-index: var(--z-message);
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  pointer-events: none;
}

.toast {
  display: flex;
  align-items: center;
  gap: 9px;
  max-width: min(88vw, 480px);
  padding: 9px 16px;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--r-full);
  box-shadow: var(--shadow-3);
  font-size: var(--fs-body-sm);
  color: var(--text-1);
  cursor: pointer;
  pointer-events: auto;
}

.toast__content {
  line-height: 1.5;
}

.toast__icon {
  flex: 0 0 auto;
}

.toast--success .toast__icon { color: var(--green); }
.toast--error   .toast__icon { color: var(--red); }
.toast--warning .toast__icon { color: var(--amber); }
.toast--info    .toast__icon { color: var(--primary); }

.s-toast-enter-active,
.s-toast-leave-active {
  transition: opacity var(--dur-2) var(--ease), transform var(--dur-2) var(--ease-out);
}

.s-toast-enter-from {
  opacity: 0;
  transform: translateY(-10px) scale(.97);
}

.s-toast-leave-to {
  opacity: 0;
  transform: translateY(-6px) scale(.97);
}

.s-toast-move {
  transition: transform var(--dur-3) var(--ease-out);
}

/* =============== MessageBox =============== */
.msgbox {
  position: fixed;
  inset: 0;
  z-index: var(--z-message);
  display: grid;
  place-items: center;
  padding: 24px;
}

.msgbox__backdrop {
  position: absolute;
  inset: 0;
  background: rgba(23, 32, 54, .5);
  backdrop-filter: blur(3px);
}

.msgbox__panel {
  position: relative;
  width: 400px;
  max-width: calc(100vw - 24px);
  max-height: calc(100vh - 48px);
  overflow-y: auto;
  background: var(--surface);
  border-radius: var(--r-xl);
  border: 1px solid var(--border);
  box-shadow: var(--shadow-4);
  padding: 22px 24px;
}

.msgbox__head {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 10px;
}

.msgbox__title {
  font-size: 16px;
  font-weight: 600;
  color: var(--text-1);
}

.msgbox__icon {
  display: grid;
  place-items: center;
  width: 30px;
  height: 30px;
  border-radius: var(--r-md);
  flex: 0 0 auto;
}

.icon-success { background: var(--green-weak); color: var(--green); }
.icon-info    { background: var(--primary-weak); color: var(--primary); }
.icon-warning { background: var(--amber-weak); color: var(--amber); }
.icon-error   { background: var(--red-weak); color: var(--red); }

.msgbox__content {
  font-size: var(--fs-body-sm);
  color: var(--text-2);
  line-height: 1.7;
  white-space: pre-line;
  margin: 0 0 18px;
}

.msgbox__input {
  margin: -6px 0 18px;
}

.msgbox__error {
  margin-top: 6px;
  font-size: var(--fs-caption);
  color: var(--red-strong);
}

.msgbox__actions {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}

.s-msgbox-enter-active,
.s-msgbox-leave-active {
  transition: opacity var(--dur-2) var(--ease);
}

.s-msgbox-enter-active .msgbox__panel,
.s-msgbox-leave-active .msgbox__panel {
  transition: transform var(--dur-3) var(--ease-out), opacity var(--dur-2) var(--ease);
}

.s-msgbox-enter-from,
.s-msgbox-leave-to {
  opacity: 0;
}

.s-msgbox-enter-from .msgbox__panel,
.s-msgbox-leave-to .msgbox__panel {
  transform: translateY(10px) scale(.98);
  opacity: 0;
}
</style>
