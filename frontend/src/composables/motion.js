import { gsap } from 'gsap'

const reduced = () => window.matchMedia('(prefers-reduced-motion: reduce)').matches

export const pageMotion = {
  enter(el, done) {
    gsap.killTweensOf(el)
    gsap.fromTo(el, { opacity: 0 }, { opacity: 1, duration: reduced() ? .06 : .22, clearProps: 'opacity', onComplete: done })
  },
  leave(el, done) {
    gsap.killTweensOf(el)
    gsap.to(el, { opacity: 0, duration: reduced() ? 0 : .1, onComplete: done })
  },
  cancel(el) { gsap.killTweensOf(el); gsap.set(el, { clearProps: 'opacity' }) }
}

// Explicitly applied to page roots, never to streaming AI content or 3D scenes.
export const revealDirective = {
  mounted(el) {
    const media = gsap.matchMedia()
    media.add('(prefers-reduced-motion: no-preference)', () => {
      const targets = [...el.querySelectorAll('.split-left > .card, .split-right > .card, .hero-brand, .study-art, .hero-title, .hero-desc, .auth-card')].slice(0, 7)
      gsap.from(targets, { y: 8, opacity: 0, duration: .23, stagger: .035, ease: 'power2.out', clearProps: 'transform,opacity' })
    }, el)
    el._revealMedia = media
  },
  unmounted(el) { el._revealMedia?.revert() }
}

export const listMotionDirective = {
  mounted(el) { el._listContext = gsap.context(() => {}, el) },
  updated(el, binding) {
    if (binding.value === binding.oldValue || reduced()) return
    el._listContext.revert()
    el._listContext = gsap.context(() => {
      const rows = [...el.querySelectorAll('tbody tr, .msg-item')].slice(0, 8)
      gsap.fromTo(rows, { opacity: .25, y: 4 }, { opacity: 1, y: 0, duration: .18, stagger: .025, clearProps: 'transform,opacity' })
    }, el)
  },
  unmounted(el) { el._listContext?.revert() }
}

// A single moving background, with resize support for wrapping filter tabs.
export const activeTrackDirective = {
  mounted(el) {
    const track = document.createElement('span')
    track.className = 'active-track'
    track.setAttribute('aria-hidden', 'true')
    el.prepend(track)
    el.classList.add('tracked-nav')
    const update = () => {
      const active = el.querySelector('button.active')
      if (!active) { track.style.opacity = '0'; return }
      const parent = el.getBoundingClientRect(), rect = active.getBoundingClientRect()
      gsap.to(track, { x: rect.left - parent.left + el.scrollLeft, y: rect.top - parent.top + el.scrollTop, width: rect.width, height: rect.height, opacity: 1, duration: reduced() || !el._trackReady ? 0 : .24, ease: 'power2.out', overwrite: true })
      el._trackReady = true
    }
    const observer = new MutationObserver(update)
    observer.observe(el, { attributes: true, subtree: true, attributeFilter: ['class'] })
    const resize = new ResizeObserver(update)
    resize.observe(el)
    el._trackCleanup = () => { observer.disconnect(); resize.disconnect(); gsap.killTweensOf(track); track.remove() }
    update()
  },
  unmounted(el) { el._trackCleanup?.() }
}
