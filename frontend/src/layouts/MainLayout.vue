<script setup>
import { computed, ref, onMounted, onUnmounted, nextTick, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import { gsap } from 'gsap'
import { ScrollTrigger } from 'gsap/ScrollTrigger'
import { useAuthStore } from '../stores/auth'
import { unreadCount } from '../api/notification'
import AppIcon from '../components/AppIcon.vue'
import MobileTopbar from '../components/MobileTopbar.vue'

const router = useRouter()
const route = useRoute()
const auth = useAuthStore()
const narrowMediaQuery = window.matchMedia('(max-width: 1024px)')
const isNarrowScreen = ref(narrowMediaQuery.matches)
const isSidebarCollapsed = ref(narrowMediaQuery.matches)
const isAtTop = ref(true)
const mobileTitleProgress = ref(0)
const mobilePageTitle = ref('')
const contentRef = ref(null)
const isDesktopCollapsed = computed(() => !isNarrowScreen.value && isSidebarCollapsed.value)
let titleMedia = null

// 未读消息角标(60s 轮询)
const unread = ref(0)
let timer = null

async function refreshUnread() {
  if (!auth.isLoggedIn || !auth.isStudent) return
  try {
    const resp = await unreadCount()
    unread.value = resp.data?.count || 0
  } catch { /* 忽略轮询失败 */ }
}

// 菜单：首页 / 预约 / 我的预约 / 候补 / 统计 / 消息 / 个人中心 / 管理端
const menus = computed(() => {
  const common = [
    { index: '/', title: '首页', icon: 'home' }
  ]
  const roleMenus = auth.isAdmin
    ? [
        { index: '/analytics', title: '热力图统计', icon: 'analytics' },
        { index: '/admin', title: '管理端', icon: 'admin' }
      ]
    : [
        { index: '/booking', title: '座位预约', icon: 'booking' },
        { index: '/mine', title: '我的预约', icon: 'reservations' },
        { index: '/waitlist', title: '我的候补', icon: 'waitlist' },
        { index: '/notifications', title: '消息中心', icon: unread.value > 0 ? 'notification' : 'notification-empty' }
      ]
  return [...common, ...roleMenus, { index: '/profile', title: '个人中心', icon: 'profile' }]
})

async function handleSelect(index) {
  if (route.path !== index) await router.push(index)
  if (isNarrowScreen.value) closeSidebar()
}

function onLogout() {
  auth.logout()
  ElMessage.success('已退出登录')
  router.push('/login')
}

function handleAccountCommand(command) {
  if (command === 'profile') {
    router.push('/profile')
    if (isNarrowScreen.value) closeSidebar()
  }
  if (command === 'logout') onLogout()
}

function openSidebar() {
  isSidebarCollapsed.value = false
}

function closeSidebar() {
  isSidebarCollapsed.value = true
}

function toggleSidebar() {
  isSidebarCollapsed.value = !isSidebarCollapsed.value
}

function onNarrowChange(event) {
  isNarrowScreen.value = event.matches
  isSidebarCollapsed.value = event.matches
  isAtTop.value = event.matches ? (contentRef.value?.scrollTop || 0) <= 1 : true
  nextTick(setupMobileTitleAnimation)
}

function onContentScroll(event) {
  if (!isNarrowScreen.value) return
  isAtTop.value = event.currentTarget.scrollTop <= 1
}

function onKeydown(event) {
  if (event.key === 'Escape' && isNarrowScreen.value && !isSidebarCollapsed.value) {
    closeSidebar()
  }
}

function cleanupMobileTitleAnimation() {
  titleMedia?.revert()
  titleMedia = null
  mobileTitleProgress.value = 0
}

function setupMobileTitleAnimation() {
  cleanupMobileTitleAnimation()
  const scroller = contentRef.value
  const heading = scroller?.querySelector('[data-page-title]')
  if (!scroller || !heading) return
  mobilePageTitle.value = heading.textContent?.trim() || route.meta?.title || ''

  titleMedia = gsap.matchMedia()
  titleMedia.add(
    {
      isNarrow: '(max-width: 1024px)',
      reduceMotion: '(prefers-reduced-motion: reduce)'
    },
    (context) => {
      const { isNarrow, reduceMotion } = context.conditions
      if (!isNarrow) return

      if (reduceMotion) {
        const trigger = ScrollTrigger.create({
          trigger: heading,
          scroller,
          start: 'top 52px',
          onEnter: () => {
            gsap.set(heading, { autoAlpha: 0, y: 0 })
            mobileTitleProgress.value = 1
          },
          onLeaveBack: () => {
            gsap.set(heading, { autoAlpha: 1, y: 0 })
            mobileTitleProgress.value = 0
          }
        })
        return () => trigger.kill()
      }

      const tween = gsap.fromTo(
        heading,
        { autoAlpha: 1, y: 0 },
        {
          autoAlpha: 0,
          y: -12,
          ease: 'none',
          scrollTrigger: {
            trigger: heading,
            scroller,
            start: 'top 72px',
            end: 'top 32px',
            scrub: 0.18,
            invalidateOnRefresh: true,
            onUpdate: (self) => {
              mobileTitleProgress.value = self.progress
            }
          }
        }
      )
      return () => tween.kill()
    },
    scroller
  )
  ScrollTrigger.refresh()
}

watch(() => route.fullPath, async () => {
  cleanupMobileTitleAnimation()
  mobilePageTitle.value = ''
  if (contentRef.value) contentRef.value.scrollTop = 0
  await nextTick()
  setupMobileTitleAnimation()
})

onMounted(() => {
  narrowMediaQuery.addEventListener('change', onNarrowChange)
  window.addEventListener('keydown', onKeydown)
  if (auth.isStudent) {
    refreshUnread()
    timer = setInterval(refreshUnread, 60000)
  }
  nextTick(setupMobileTitleAnimation)
})
onUnmounted(() => {
  cleanupMobileTitleAnimation()
  narrowMediaQuery.removeEventListener('change', onNarrowChange)
  window.removeEventListener('keydown', onKeydown)
  if (timer) clearInterval(timer)
})
</script>

<template>
  <!-- 第一层双栏：外壳 = 左 Sidebar | 右 Content Column -->
  <div
    class="shell"
    :class="{
      'sidebar-collapsed': isSidebarCollapsed,
      'narrow-screen': isNarrowScreen,
      'mobile-sidebar-open': isNarrowScreen && !isSidebarCollapsed
    }"
  >
    <MobileTopbar
      v-if="isNarrowScreen"
      :sidebar-collapsed="isSidebarCollapsed"
      :at-top="isAtTop"
      :menus="menus"
      :current-path="route.path"
      :page-title="mobilePageTitle"
      :title-progress="mobileTitleProgress"
      @open-sidebar="openSidebar"
      @navigate="handleSelect"
    />

    <div
      v-if="isNarrowScreen && !isSidebarCollapsed"
      class="sidebar-backdrop"
      aria-hidden="true"
      @click="closeSidebar"
      @wheel.prevent
      @touchmove.prevent
    />

    <!-- ============== 左栏（导航 / 品牌 / 用户） ============== -->
    <aside class="sidebar" :class="{ collapsed: isSidebarCollapsed }">
      <!-- 品牌 -->
      <div class="brand">
        <div v-show="!isDesktopCollapsed" class="brand-copy">
          <div class="brand-name">智能自习室</div>
          <div class="brand-sub">Smart Study Room</div>
        </div>
        <button
          class="sidebar-toggle"
          type="button"
          :title="isDesktopCollapsed ? '展开侧栏' : '折叠侧栏'"
          :aria-label="isDesktopCollapsed ? '展开侧栏' : '折叠侧栏'"
          :aria-expanded="!isSidebarCollapsed"
          @click="toggleSidebar"
        >
          <AppIcon :name="isDesktopCollapsed ? 'sidebar-expand' : 'sidebar-collapse'" :size="20" />
        </button>
      </div>

      <!-- 菜单 -->
      <nav class="menu">
        <button
          v-for="m in menus"
          :key="m.index"
          class="menu-item"
          :class="{ active: route.path === m.index }"
          :title="isDesktopCollapsed ? m.title : undefined"
          :aria-label="m.title"
          @click="handleSelect(m.index)"
        >
          <span class="menu-icon"><AppIcon :name="m.icon" :size="20" /></span>
          <span class="menu-text">{{ m.title }}</span>
          <el-badge
            v-if="m.index === '/notifications' && unread > 0"
            :value="unread"
            :max="99"
            class="menu-badge"
          />
        </button>
      </nav>

      <div class="sidebar-spacer" />

      <!-- 底部：账户入口 -->
      <div class="sidebar-footer">
        <el-dropdown
          v-if="auth.isLoggedIn"
          class="user-dropdown"
          @command="handleAccountCommand"
          trigger="click"
        >
          <div class="user-card" :title="isDesktopCollapsed ? (auth.user?.real_name || auth.user?.username) : undefined">
            <div class="avatar-slot">
              <div class="avatar">
                {{ (auth.user?.real_name || auth.user?.username || '?').slice(0, 1) }}
              </div>
            </div>
            <div v-show="!isDesktopCollapsed" class="user-meta">
              <div class="user-name">
                {{ auth.user?.real_name || auth.user?.username }}
              </div>
              <el-tag class="role-tag" size="small" effect="plain" :type="auth.isAdmin ? 'danger' : 'primary'">
                {{ auth.isAdmin ? '管理员' : '学生' }}
              </el-tag>
            </div>
          </div>
          <template #dropdown>
            <el-dropdown-menu>
              <el-dropdown-item command="profile">
                个人中心
              </el-dropdown-item>
              <el-dropdown-item command="logout" divided>退出登录</el-dropdown-item>
            </el-dropdown-menu>
          </template>
        </el-dropdown>
      </div>
    </aside>

    <!-- ============== 右栏（页面正文；标题由各页面自己维护） ============== -->
    <section ref="contentRef" class="content" @scroll="onContentScroll">
      <!-- 每个页面自行使用 .split 实现"页面级双栏" -->
      <main class="page-body">
        <router-view />
      </main>
    </section>
  </div>
</template>

<style scoped>
/* ---- 外壳级双栏（全局） ---- */
.shell {
  height: 100%;
  display: grid;
  grid-template-columns: 272px 1fr;
  background: var(--app-canvas-background);
  transition: grid-template-columns .22s ease;
}
.shell:not(.narrow-screen).sidebar-collapsed {
  grid-template-columns: 68px 1fr;
}
.sidebar-backdrop {
  position: fixed;
  z-index: 40;
  inset: 0;
  background: rgba(24, 34, 49, .34);
  backdrop-filter: blur(1px);
}

/* ============== 左栏 Sidebar ============== */
.sidebar {
  display: flex;
  flex-direction: column;
  background:
    linear-gradient(180deg, #ffffff 0%, #fbfcfe 100%);
  border-right: 1px solid #e5e9f0;
  padding: 22px 12px 14px;
  min-height: 0;
  overflow: hidden;
}
.brand {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 10px;
  padding: 4px 10px 10px;
  min-height: 51px;
  white-space: nowrap;
}
.shell:not(.narrow-screen) .sidebar.collapsed .brand {
  justify-content: center;
  padding: 4px 0 10px;
}
.brand-copy {
  min-width: 0;
}
.brand-name {
  font-size: 16px;
  font-weight: 700;
  color: #334155;
  letter-spacing: 0.2px;
}
.brand-sub {
  font-size: 11px;
  color: #94a0b2;
  margin-top: 2px;
  letter-spacing: 0.4px;
  text-transform: uppercase;
}
.sidebar-toggle {
  appearance: none;
  border: 1px solid transparent;
  background: transparent;
  color: #657892;
  width: 32px;
  height: 32px;
  padding: 0;
  border-radius: 9px;
  display: grid;
  place-items: center;
  flex: 0 0 auto;
  cursor: pointer;
  transition: color .16s ease, background .16s ease, border-color .16s ease;
}
.sidebar-toggle:hover {
  color: #3f5878;
  background: #eef2f8;
  border-color: #e0e6ef;
}
.sidebar-toggle:focus-visible {
  outline: 3px solid rgba(95, 126, 163, .22);
  outline-offset: 2px;
}

/* 菜单 */
.menu {
  margin-top: 8px;
  display: flex;
  flex-direction: column;
  gap: 4px;
  overflow-x: hidden;
  overflow-y: auto;
  padding: 4px 0;
}
.menu-item {
  all: unset;
  display: flex;
  align-items: center;
  gap: 0;
  padding: 10px 0;
  border-radius: 10px;
  cursor: pointer;
  color: #5c6778;
  font-size: 14px;
  transition: background .18s ease, color .18s ease, transform .18s ease;
  position: relative;
  width: 100%;
  min-height: 42px;
  box-sizing: border-box;
}
.menu-item:hover {
  background: #eef2f8;
  color: #374151;
}
.menu-item.active {
  background: linear-gradient(135deg, #cfdae8 0%, #e3eaf4 100%);
  color: #2f4462;
  font-weight: 600;
  box-shadow: inset 0 1px 0 #ffffff, 0 1px 2px rgba(108,128,160,.08);
}
.menu-icon {
  width: 44px;
  height: 22px;
  display: grid;
  place-items: center;
  flex: 0 0 44px;
}
.menu-text {
  flex: 1;
  min-width: 0;
  height: 22px;
  display: flex;
  align-items: center;
  line-height: 22px;
  white-space: nowrap;
  overflow: hidden;
  opacity: 1;
  padding-left: 0;
  transition: opacity .14s ease;
}
.menu-badge {
  margin-right: 2px;
}
.shell:not(.narrow-screen) .sidebar.collapsed .menu-item {
  padding: 10px 0;
}
.shell:not(.narrow-screen) .sidebar.collapsed .menu-text {
  display: none;
  opacity: 0;
}
.shell:not(.narrow-screen) .sidebar.collapsed .menu-badge {
  position: absolute;
  top: 3px;
  right: 1px;
  margin: 0;
  transform: scale(.82);
  transform-origin: top right;
}

.sidebar-spacer {
  flex: 1;
  min-height: 8px;
}

/* 底部用户卡 */
.sidebar-footer {
  padding-top: 10px;
  display: flex;
  flex-direction: column;
}
.user-dropdown {
  width: 100%;
}
.user-dropdown :deep(.el-tooltip__trigger) {
  display: flex;
  width: 100%;
}

.user-card {
  display: flex;
  align-items: center;
  gap: 0;
  height: 64px;
  padding: 9px 0;
  border-radius: 10px;
  background: transparent;
  border: 1px solid transparent;
  cursor: pointer;
  transition: background .16s ease;
  outline: none;
}
.user-card:hover {
  background: #f1f4f8;
}
.user-card:focus-visible {
  box-shadow: 0 0 0 3px rgba(95, 126, 163, .2);
}
.avatar-slot {
  width: 44px;
  flex: 0 0 44px;
  display: grid;
  place-items: center;
}
.avatar {
  width: 36px;
  height: 36px;
  border-radius: 10px;
  background: linear-gradient(145deg, #8ea6c4, #6581a5);
  color: #fff;
  display: grid;
  place-items: center;
  font-weight: 700;
  font-size: 14px;
  box-shadow: inset 0 1px 0 rgba(255,255,255,.2);
}
.user-meta {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 4px;
  padding-left: 6px;
}
.role-tag {
  width: fit-content;
  max-width: 100%;
  flex: 0 0 auto;
}
.user-name {
  font-size: 13px;
  font-weight: 600;
  color: #2f3a4d;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
/* ============== 右栏 Content ============== */
.content {
  min-width: 0;
  min-height: 0;
  display: flex;
  flex-direction: column;
  padding: 0;
  overflow: hidden;
}
.page-body {
  flex: 1;
  min-height: 0;
  overflow: auto;
}

/* ============== 窄屏：透明 Topbar + 覆盖式侧栏 ============== */
@media (max-width: 1024px) {
  .shell,
  .shell.sidebar-collapsed {
    display: block;
    position: relative;
    height: 100%;
  }

  .sidebar {
    position: fixed;
    z-index: 50;
    inset: 0 auto 0 0;
    width: 272px;
    min-height: 100%;
    transform: translateX(0);
    visibility: visible;
    pointer-events: auto;
    box-shadow: 12px 0 30px rgba(36, 48, 68, .16);
    transition: transform .22s ease, visibility 0s linear 0s;
  }
  .sidebar.collapsed {
    transform: translateX(-100%);
    visibility: hidden;
    pointer-events: none;
    box-shadow: none;
    transition: transform .22s ease, visibility 0s linear .22s;
  }

  .content {
    display: block;
    width: 100%;
    height: 100%;
    padding: 0;
    overflow-x: hidden;
    overflow-y: auto;
    overscroll-behavior: contain;
  }
  .mobile-sidebar-open .content {
    overflow: hidden;
  }
  .page-body {
    min-height: 0;
    overflow: visible;
  }
}

</style>
