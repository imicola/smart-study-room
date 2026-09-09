<script setup>
import { computed, ref, watch } from 'vue'
import AppIcon from './AppIcon.vue'
import HeaderPanel from './HeaderPanel.vue'

const props = defineProps({
  sidebarCollapsed: { type: Boolean, default: true },
  atTop: { type: Boolean, default: true },
  menus: { type: Array, default: () => [] },
  currentPath: { type: String, default: '/' },
  pageTitle: { type: String, default: '' },
  titleProgress: { type: Number, default: 0 }
})

const emit = defineEmits(['open-sidebar', 'navigate'])
const quickMenu = ref(null)
const isMenuOpen = ref(false)

const quickMenus = computed(() => props.menus.filter((item) => item.index !== props.currentPath))

function closeQuickMenu() {
  quickMenu.value?.close()
}


function openSidebar() {
  closeQuickMenu()
  emit('open-sidebar')
}

function navigate(path) {
  closeQuickMenu()
  emit('navigate', path)
}


watch(() => props.currentPath, closeQuickMenu)
watch(() => props.sidebarCollapsed, (collapsed) => {
  if (!collapsed) closeQuickMenu()
})

</script>

<template>
  <header
    class="mobile-topbar"
    :class="{ 'has-expanded-panel': isMenuOpen }"
    :style="{
      '--title-progress': Math.max(0, Math.min(1, titleProgress)),
      '--title-offset': `${(1 - Math.max(0, Math.min(1, titleProgress))) * 10}px`
    }"
    aria-label="移动端快捷导航"
  >
    <button
      v-if="sidebarCollapsed"
      type="button"
      class="topbar-action sidebar-action"
      :class="{ 'at-top': atTop }"
      aria-label="展开侧栏"
      title="展开侧栏"
      @click="openSidebar"
    >
      <AppIcon name="sidebar-expand" :size="24" />
    </button>
    <span v-else class="topbar-placeholder" />

    <div class="mobile-page-title" aria-live="polite">
      {{ pageTitle }}
    </div>

    <HeaderPanel ref="quickMenu" title="快捷导航" icon="more" :width="228" @toggle="isMenuOpen = $event">
      <nav class="quick-menu-list">
        <button v-for="item in quickMenus" :key="item.index" type="button" class="quick-menu-item" @click="navigate(item.index)">
          <span class="quick-menu-icon"><AppIcon :name="item.icon" :size="19" /></span>
          <span>{{ item.title }}</span>
        </button>
      </nav>
    </HeaderPanel>
  </header>
</template>

<style>
.mobile-topbar {
  position: fixed;
  z-index: 30;
  inset: 0 0 auto;
  height: 64px;
  padding: 11px 16px;
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  background: transparent;
  border: 0;
  box-shadow: none;
  pointer-events: none;
}
.mobile-topbar.has-expanded-panel,
.mobile-topbar:has(.is-expanded) {
  z-index: 35;
}
.mobile-topbar::before {
  content: '';
  position: absolute;
  z-index: 0;
  inset: 0;
  background: var(--app-canvas-background);
  -webkit-backdrop-filter: blur(14px) saturate(115%);
  backdrop-filter: blur(14px) saturate(115%);
  -webkit-mask-image: linear-gradient(to bottom, #000 0%, rgba(0, 0, 0, .2) 100%);
  mask-image: linear-gradient(to bottom, #000 0%, rgba(0, 0, 0, .2) 100%);
  pointer-events: none;
}
.mobile-topbar,
.mobile-topbar * {
  box-sizing: border-box;
}
.mobile-topbar button {
  margin: 0;
  font-family: inherit;
}
.mobile-page-title {
  position: absolute;
  z-index: 2;
  left: 50%;
  top: 18px;
  max-width: calc(100vw - 226px);
  overflow: hidden;
  color: var(--text-1);
  font-size: 21px;
  font-weight: 700;
  line-height: 28px;
  text-overflow: ellipsis;
  white-space: nowrap;
  opacity: var(--title-progress);
  transform: translate3d(-50%, var(--title-offset), 0);
  pointer-events: none;
  will-change: transform, opacity;
}
.topbar-action {
  border: 0;
  background: transparent;
  color: var(--text-2);
  box-shadow: none;
}
.topbar-action {
  appearance: none;
  position: relative;
  z-index: 3;
  width: 42px;
  height: 42px;
  padding: 0;
  display: grid;
  place-items: center;
  border-radius: 50%;
  cursor: pointer;
  pointer-events: auto;
  transition: color .16s ease, background .16s ease;
}
.topbar-action:hover {
  color: var(--text-1);
  background: rgba(28, 37, 52, .06);
}
.topbar-action:focus-visible,
.quick-menu-item:focus-visible {
  outline: 2px solid var(--primary);
  outline-offset: 2px;
}
.topbar-placeholder {
  width: 42px;
  height: 42px;
}
.quick-menu-list {
  overflow: visible;
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.quick-menu-item {
  appearance: none;
  width: 100%;
  min-height: 42px;
  padding: 5px 8px;
  display: flex;
  align-items: center;
  gap: 9px;
  border: 0;
  border-radius: var(--r-md);
  background: transparent;
  color: var(--text-2);
  font: inherit;
  font-size: 13px;
  text-align: left;
  cursor: pointer;
  white-space: nowrap;
  transition: color .14s ease, background .14s ease;
}
.quick-menu-item:hover {
  color: var(--text-1);
  background: var(--surface-hover);
}
.quick-menu-icon {
  width: 30px;
  height: 30px;
  flex: 0 0 30px;
  display: grid;
  place-items: center;
  border-radius: var(--r-md);
  background: var(--surface-3);
}
</style>
