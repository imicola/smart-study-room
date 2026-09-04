<script setup>
import { computed, onMounted, onUnmounted, ref, watch } from 'vue'
import AppIcon from './AppIcon.vue'

const props = defineProps({
  sidebarCollapsed: { type: Boolean, default: true },
  atTop: { type: Boolean, default: true },
  menus: { type: Array, default: () => [] },
  currentPath: { type: String, default: '/' }
})

const emit = defineEmits(['open-sidebar', 'navigate'])
const isQuickMenuOpen = ref(false)

const quickMenus = computed(() => props.menus.filter((item) => item.index !== props.currentPath))
const menuHeight = computed(() => 58 + quickMenus.value.length * 44 + 10)

function closeQuickMenu() {
  isQuickMenuOpen.value = false
}

function toggleQuickMenu() {
  isQuickMenuOpen.value = !isQuickMenuOpen.value
}

function openSidebar() {
  closeQuickMenu()
  emit('open-sidebar')
}

function navigate(path) {
  closeQuickMenu()
  emit('navigate', path)
}

function onKeydown(event) {
  if (event.key === 'Escape' && isQuickMenuOpen.value) closeQuickMenu()
}

watch(() => props.currentPath, closeQuickMenu)
watch(() => props.sidebarCollapsed, (collapsed) => {
  if (!collapsed) closeQuickMenu()
})

onMounted(() => window.addEventListener('keydown', onKeydown))
onUnmounted(() => window.removeEventListener('keydown', onKeydown))
</script>

<template>
  <header class="mobile-topbar" aria-label="移动端快捷导航">
    <button
      v-if="sidebarCollapsed"
      type="button"
      class="topbar-action sidebar-action"
      :class="{ 'at-top': atTop }"
      aria-label="展开侧栏"
      title="展开侧栏"
      @click="openSidebar"
    >
      <AppIcon name="sidebar-expand" :size="21" />
    </button>
    <span v-else class="topbar-placeholder" />

    <div
      v-if="isQuickMenuOpen"
      class="quick-menu-dismiss"
      aria-hidden="true"
      @click="closeQuickMenu"
    />

    <section
      class="quick-menu-shell"
      :class="{ expanded: isQuickMenuOpen, 'at-top': atTop && !isQuickMenuOpen }"
      :style="{ '--quick-menu-height': `${menuHeight}px` }"
      aria-label="全部页面快捷导航"
    >
      <button
        type="button"
        class="quick-menu-trigger"
        :aria-label="isQuickMenuOpen ? '收起快捷导航' : '展开快捷导航'"
        :title="isQuickMenuOpen ? '收起快捷导航' : '更多'"
        :aria-expanded="isQuickMenuOpen"
        @click="toggleQuickMenu"
      >
        <AppIcon name="more" :size="21" />
      </button>

      <div class="quick-menu-content" :aria-hidden="!isQuickMenuOpen">
        <div class="quick-menu-title">快捷导航</div>
        <nav class="quick-menu-list">
          <button
            v-for="item in quickMenus"
            :key="item.index"
            type="button"
            class="quick-menu-item"
            :tabindex="isQuickMenuOpen ? 0 : -1"
            @click="navigate(item.index)"
          >
            <span class="quick-menu-icon"><AppIcon :name="item.icon" :size="19" /></span>
            <span>{{ item.title }}</span>
          </button>
        </nav>
      </div>
    </section>
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
.mobile-topbar,
.mobile-topbar * {
  box-sizing: border-box;
}
.mobile-topbar button {
  margin: 0;
  font-family: inherit;
}
.topbar-action,
.quick-menu-shell {
  border: 1px solid #94a3b8;
  background: var(--app-canvas-background);
  color: #35465e;
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
  transition: border-color .16s ease, color .16s ease, background .16s ease;
}
.topbar-action.at-top,
.quick-menu-shell.at-top {
  border-color: transparent;
}
.topbar-action:hover,
.quick-menu-shell:not(.expanded):hover {
  color: #203149;
  background: var(--app-canvas-background);
  border-color: #7f91a8;
}
.topbar-action.at-top:hover,
.quick-menu-shell.at-top:not(.expanded):hover {
  border-color: transparent;
}
.topbar-action:focus-visible,
.quick-menu-trigger:focus-visible,
.quick-menu-item:focus-visible {
  outline: 3px solid rgba(100, 116, 139, .22);
  outline-offset: 2px;
}
.topbar-placeholder {
  width: 42px;
  height: 42px;
}
.quick-menu-dismiss {
  position: fixed;
  z-index: 1;
  inset: 0;
  pointer-events: auto;
  background: transparent;
}
.quick-menu-shell {
  position: relative;
  z-index: 3;
  width: 42px;
  height: 42px;
  max-width: calc(100vw - 32px);
  max-height: calc(100vh - 22px);
  border-radius: 50%;
  overflow: hidden;
  pointer-events: auto;
  transform-origin: top right;
  transition: width .24s ease, height .24s ease, border-radius .24s ease, border-color .16s ease, background .16s ease;
}
.quick-menu-shell.expanded {
  width: 228px;
  height: var(--quick-menu-height);
  border-radius: 16px;
  border-color: #94a3b8;
  background: #fff;
}
.quick-menu-trigger {
  appearance: none;
  position: absolute;
  z-index: 2;
  top: 0;
  right: 0;
  width: 40px;
  height: 40px;
  padding: 0;
  border: 0;
  border-radius: 50%;
  display: grid;
  place-items: center;
  color: inherit;
  background: var(--app-canvas-background);
  cursor: pointer;
}
.quick-menu-content {
  height: 100%;
  padding: 13px 8px 8px;
  opacity: 0;
  visibility: hidden;
  transform: translateY(-5px);
  transition: opacity .13s ease, transform .2s ease, visibility 0s linear .24s;
}
.quick-menu-shell.expanded .quick-menu-content {
  opacity: 1;
  visibility: visible;
  transform: translateY(0);
  transition: opacity .18s ease .08s, transform .2s ease .04s, visibility 0s linear 0s;
}
.quick-menu-title {
  height: 34px;
  padding: 3px 44px 0 8px;
  display: flex;
  align-items: center;
  font-size: 13px;
  font-weight: 700;
  color: #445269;
  white-space: nowrap;
}
.quick-menu-list {
  max-height: calc(100% - 34px);
  overflow-x: hidden;
  overflow-y: auto;
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
  border-radius: 9px;
  background: transparent;
  color: #526075;
  font: inherit;
  font-size: 13px;
  text-align: left;
  cursor: pointer;
  white-space: nowrap;
  transition: color .14s ease, background .14s ease;
}
.quick-menu-item:hover {
  color: #27384f;
  background: #eef2f7;
}
.quick-menu-icon {
  width: 30px;
  height: 30px;
  flex: 0 0 30px;
  display: grid;
  place-items: center;
  border-radius: 8px;
  background: #f3f6fa;
}
</style>
