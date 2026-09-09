import { nextTick, onUnmounted, watch } from 'vue'

const stack = []
let savedOverflow = ''

export function useDialogFocus(isOpen, panel) {
  const owner = {}
  let previous = null
  const focusables = () => [...(panel.value?.querySelectorAll('button:not(:disabled), input:not(:disabled), textarea:not(:disabled), select:not(:disabled), [tabindex="0"]') || [])]
    .filter(el => el.getClientRects().length && !el.closest('[inert]'))
  function release() {
    const index = stack.indexOf(owner)
    if (index < 0) return
    const wasTop = index === stack.length - 1
    stack.splice(index, 1)
    if (!stack.length) document.body.style.overflow = savedOverflow
    if (wasTop && previous?.isConnected) previous.focus({ preventScroll: true })
  }
  function trap(event) {
    if (event.key !== 'Tab' || stack.at(-1) !== owner) return
    const elements = focusables(), first = elements[0], last = elements.at(-1)
    if (!first) { event.preventDefault(); panel.value?.focus(); return }
    if (!panel.value.contains(document.activeElement) || (!event.shiftKey && document.activeElement === last)) {
      event.preventDefault(); first.focus()
    } else if (event.shiftKey && document.activeElement === first) {
      event.preventDefault(); last.focus()
    }
  }
  watch(isOpen, async value => {
    if (!value) { release(); return }
    if (!stack.includes(owner)) {
      previous = document.activeElement
      if (!stack.length) savedOverflow = document.body.style.overflow
      stack.push(owner)
      document.body.style.overflow = 'hidden'
    }
    await nextTick()
    if (stack.at(-1) === owner) (panel.value?.querySelector('input, textarea') || focusables()[0] || panel.value)?.focus({ preventScroll: true })
  }, { immediate: true })
  onUnmounted(release)
  return { trap }
}
