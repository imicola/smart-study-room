<script setup>
import { pageMotion } from '../composables/motion'
import { computed, ref, onMounted, onUnmounted, nextTick, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { gsap } from 'gsap'
import { ScrollTrigger } from 'gsap/ScrollTrigger'
import { message } from '../components/ui/feedback'
import { useAuthStore } from '../stores/auth'
import { useNotificationStore } from '../stores/notification'
import { useThemeStore } from '../stores/theme'
import { logout as logoutApi } from '../api/auth'
import AppIcon from '../components/AppIcon.vue'
import MobileTopbar from '../components/MobileTopbar.vue'
import AIAssistant from '../components/AIAssistant.vue'
import SBadge from '../components/ui/SBadge.vue'

const router = useRouter()
const route = useRoute()
const auth = useAuthStore()
const notifStore = useNotificationStore()
const themeStore = useThemeStore()
const narrowMediaQuery = window.matchMedia('(max-width: 1024px)')
const isNarrowScreen = ref(narrowMediaQuery.matches)
const isSidebarCollapsed = ref(narrowMediaQuery.matches)
const isAtTop = ref(true)
const mobileTitleProgress = ref(0)
const mobilePageTitle = ref('')
const contentRef = ref(null)
const isDesktopCollapsed = computed(() => !isNarrowScreen.value && isSidebarCollapsed.value)
let titleMedia = null

// 未读消息角标(通过 Pinia Store 集中管理与 60s 轮询)
const unread = computed(() => notifStore.unread)
let timer = null

function refreshUnread() {
  notifStore.refresh()
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
  const token = auth.token
  if (token) void logoutApi(token).catch(() => {})
  auth.logout()
  message.success('已退出登录')
  router.push('/login')
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
  mobilePageTitle.value = heading.querySelector('h1')?.textContent?.trim() || heading.textContent?.trim() || route.meta?.title || ''

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
      <!-- 品牌（保留智能自习室与副标题；折叠按钮展开态居右、折叠态居左，纵向高度恒定） -->
      <div class="brand" :class="{ collapsed: isDesktopCollapsed }">
        <div class="brand-copy">
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
          <AppIcon :name="isDesktopCollapsed ? 'sidebar-expand' : 'sidebar-collapse'" :size="24" />
        </button>
      </div>

      <!-- 菜单（加大尺寸） -->
      <nav v-active-track class="menu" aria-label="主导航">
        <button
          v-for="m in menus"
          :key="m.index"
          class="menu-item"
          :class="{ active: route.path === m.index }"
          :title="isDesktopCollapsed ? m.title : undefined"
          :aria-label="m.title"
          @click="handleSelect(m.index)"
        >
          <span class="menu-icon"><AppIcon :name="m.icon" :size="21" /></span>
          <span class="menu-text">{{ m.title }}</span>
          <SBadge
            v-if="m.index === '/notifications' && unread > 0"
            :value="unread"
            :max="99"
            class="menu-badge"
          />
        </button>
      </nav>

      <div class="sidebar-spacer" />

      <!-- 主题模式切换（折叠后整体隐藏） -->
      <div class="sidebar-theme" :class="{ collapsed: isDesktopCollapsed }">
        <div class="theme-switch-group" role="radiogroup" aria-label="主题模式选择">
          <button
            type="button"
            class="theme-btn"
            :class="{ active: themeStore.mode === 'system' }"
            :aria-checked="themeStore.mode === 'system'"
            role="radio"
            title="跟随系统"
            @click="themeStore.setMode('system')"
          >
            <AppIcon name="system" :size="15" />
            <span>系统</span>
          </button>
          <button
            type="button"
            class="theme-btn"
            :class="{ active: themeStore.mode === 'light' }"
            :aria-checked="themeStore.mode === 'light'"
            role="radio"
            title="浅色模式"
            @click="themeStore.setMode('light')"
          >
            <AppIcon name="sun" :size="15" />
            <span>浅色</span>
          </button>
          <button
            type="button"
            class="theme-btn"
            :class="{ active: themeStore.mode === 'dark' }"
            :aria-checked="themeStore.mode === 'dark'"
            role="radio"
            title="深色模式"
            @click="themeStore.setMode('dark')"
          >
            <AppIcon name="moon" :size="15" />
            <span>深色</span>
          </button>
        </div>
      </div>

      <!-- 底部：个人区域（折叠后仅显示头像，展开显示头像+信息+退出登录） -->
      <div v-if="auth.isLoggedIn" class="sidebar-footer">
        <div class="user-row">
          <div class="avatar-slot" :title="auth.user?.real_name || auth.user?.username">
            <div class="avatar">
              {{ (auth.user?.real_name || auth.user?.username || '?').slice(0, 1) }}
            </div>
          </div>
          <div v-show="!isDesktopCollapsed" class="user-meta">
            <div class="user-name" :title="auth.user?.real_name || auth.user?.username">
              {{ auth.user?.real_name || auth.user?.username }}
            </div>
            <span class="role-pill" :class="auth.isAdmin ? 'role-pill--admin' : 'role-pill--student'">
              {{ auth.isAdmin ? '管理员' : '学生' }}
            </span>
          </div>
          <button
            v-show="!isDesktopCollapsed"
            type="button"
            class="sidebar-logout-btn"
            title="退出登录"
            aria-label="退出登录"
            @click="onLogout"
          >
            <AppIcon name="logout" :size="16" />
          </button>
        </div>
      </div>
    </aside>

    <!-- ============== 右栏（页面正文；标题由各页面自己维护） ============== -->
    <section ref="contentRef" class="content" @scroll="onContentScroll">
      <!-- 每个页面自行使用 .split 实现"页面级双栏" -->
      <main class="page-body">
        <router-view v-slot="{ Component }">
          <Transition :css="false" mode="out-in" @enter="pageMotion.enter" @leave="pageMotion.leave" @enter-cancelled="pageMotion.cancel" @leave-cancelled="pageMotion.cancel" @after-enter="setupMobileTitleAnimation">
            <div :key="route.path" class="route-surface"><component :is="Component" /></div>
          </Transition>
        </router-view>
      </main>
    </section>
    <AIAssistant v-if="auth.isLoggedIn && auth.isStudent" />
  </div>
</template>

<style scoped>
/* ---- 外壳级双栏（全局） ---- */
.shell {
  height: 100%;
  display: grid;
  grid-template-columns: 216px minmax(0, 1fr);
  background: var(--canvas);
  transition: grid-template-columns var(--dur-3) var(--ease);
}
.shell:not(.narrow-screen).sidebar-collapsed {
  grid-template-columns: 72px 1fr;
}
.sidebar-backdrop {
  position: fixed;
  z-index: 40;
  inset: 0;
  background: rgba(23, 32, 54, .38);
  backdrop-filter: blur(1px);
}

/* ============== 左栏 Sidebar ============== */
.sidebar {
  display: flex;
  flex-direction: column;
  background: var(--canvas);
  border-right: 1px solid var(--border);
  padding: 16px 12px 12px;
  min-height: 0;
  overflow: hidden;
  box-sizing: border-box;
}

.brand {
  position: relative;
  display: flex;
  align-items: center;
  height: 56px;
  min-height: 56px;
  padding: 0;
  white-space: nowrap;
  box-sizing: border-box;
  overflow: hidden;
}
.brand-copy {
  min-width: 0;
  flex: 1;
  overflow: hidden;
  padding-left: 4px;
  padding-right: 52px;
  transition: opacity var(--dur-2) var(--ease);
}
.brand.collapsed .brand-copy {
  opacity: 0;
  pointer-events: none;
}
.brand-name {
  font-size: 16px;
  font-weight: 700;
  color: var(--text-1);
  letter-spacing: -.01em;
  white-space: nowrap;
}
.brand-sub {
  font-size: 10px;
  color: var(--text-4);
  margin-top: 2px;
  letter-spacing: .08em;
  text-transform: uppercase;
  white-space: nowrap;
}
.sidebar-toggle {
  appearance: none;
  border: 1px solid transparent;
  background: transparent;
  color: var(--text-3);
  position: absolute;
  right: 0;
  top: 10px;
  width: 48px;
  height: 36px;
  padding: 0;
  border-radius: var(--r-md);
  display: grid;
  place-items: center;
  cursor: pointer;
  box-sizing: border-box;
  transition: color var(--dur-1) var(--ease), background var(--dur-1) var(--ease);
}
.brand.collapsed .sidebar-toggle {
  right: auto;
  left: 0;
}
.sidebar-toggle:hover {
  color: var(--text-1);
  background: var(--surface-3);
}
.sidebar-toggle:focus-visible {
  outline: 2px solid var(--primary);
  outline-offset: 1px;
}

/* 菜单（加大尺寸） */
.menu {
  display: flex;
  flex-direction: column;
  gap: 4px;
  overflow-x: hidden;
  overflow-y: auto;
  padding: 6px 0;
  scrollbar-width: none;
}
.menu::-webkit-scrollbar {
  display: none;
}
.menu-item {
  all: unset;
  display: flex;
  align-items: center;
  gap: 0;
  padding: 0;
  border-radius: var(--r-lg);
  cursor: pointer;
  color: var(--text-2);
  font-size: 14.5px;
  font-weight: 500;
  transition: background var(--dur-1) var(--ease), color var(--dur-1) var(--ease);
  position: relative;
  width: 100%;
  min-height: 44px;
  height: 44px;
  box-sizing: border-box;
  overflow: hidden;
}
.menu-item:hover {
  background: var(--surface-hover);
  color: var(--text-1);
}
.menu-item.active {
  background: var(--primary-weak);
  color: var(--primary-active);
  font-weight: 600;
}
.menu-item.active::before {
  content: '';
  position: absolute;
  left: -12px;
  top: 9px;
  bottom: 9px;
  width: 3.5px;
  border-radius: 0 3px 3px 0;
  background: var(--primary);
}
.menu-icon {
  width: 48px;
  min-width: 48px;
  max-width: 48px;
  height: 44px;
  display: grid;
  place-items: center;
  flex: 0 0 48px;
  color: var(--text-4);
  transition: color var(--dur-1) var(--ease);
}
.menu-item:hover .menu-icon {
  color: var(--text-2);
}
.menu-item.active .menu-icon {
  color: var(--primary);
}
.menu-text {
  flex: 1;
  min-width: 0;
  height: 24px;
  display: flex;
  align-items: center;
  line-height: 24px;
  white-space: nowrap;
  overflow: hidden;
  padding-left: 2px;
  transition: opacity var(--dur-2) var(--ease);
}
.menu-badge {
  margin-left: auto;
  margin-right: 10px;
  flex: 0 0 auto;
}
/* 折叠态文字渐隐，图标保持原地不动 */
.shell:not(.narrow-screen) .sidebar.collapsed .menu-text {
  opacity: 0;
  pointer-events: none;
}
/* 折叠态徽标锚定在图标右上角，绝对定位，不影响图标流 */
.shell:not(.narrow-screen) .sidebar.collapsed .menu-badge {
  position: absolute;
  top: 4px;
  left: 30px;
  right: auto;
  margin: 0;
  transform: scale(.82);
  transform-origin: top left;
}

.sidebar-spacer {
  flex: 1;
  min-height: 8px;
}

/* 主题模式切换（折叠后整体隐藏，高度平滑收缩避免弹跳） */
.sidebar-theme {
  display: flex;
  height: 40px;
  width: 100%;
  overflow: hidden;
  box-sizing: border-box;
  transition: height var(--dur-3) var(--ease), opacity var(--dur-2) var(--ease);
}

.sidebar-theme.collapsed {
  height: 0;
  opacity: 0;
}

.theme-switch-group {
  display: flex;
  align-items: stretch;
  gap: 2px;
  padding: 3px;
  background: var(--surface-3);
  border-radius: var(--r-md);
  border: 1px solid var(--hairline);
  box-sizing: border-box;
  width: 100%;
}

.theme-btn {
  all: unset;
  flex: 1;
  height: 100%;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
  padding: 0;
  border-radius: var(--r-sm);
  font-size: 12px;
  font-weight: 500;
  color: var(--text-3);
  cursor: pointer;
  box-sizing: border-box;
  transition: background var(--dur-1) var(--ease), color var(--dur-1) var(--ease), box-shadow var(--dur-1) var(--ease);
}

.theme-btn:hover:not(.active) {
  color: var(--text-1);
}

.theme-btn.active {
  background: var(--surface);
  color: var(--text-1);
  font-weight: 600;
  box-shadow: var(--shadow-1);
}

.theme-btn:focus-visible {
  outline: 2px solid var(--primary);
  outline-offset: -1px;
}

/* 底部用户卡 */
.sidebar-footer {
  padding-top: 6px;
  margin-top: 4px;
  overflow: hidden;
  width: 100%;
}

.user-row {
  display: flex;
  align-items: center;
  gap: 0;
  padding: 4px 0;
  min-height: 48px;
  width: 100%;
  box-sizing: border-box;
  overflow: hidden;
}

.avatar-slot {
  width: 48px;
  min-width: 48px;
  max-width: 48px;
  height: 44px;
  flex: 0 0 48px;
  display: grid;
  place-items: center;
  box-sizing: border-box;
}

.avatar {
  width: 36px;
  height: 36px;
  border-radius: var(--r-md);
  background: var(--primary-weak);
  color: var(--primary-active);
  display: grid;
  place-items: center;
  font-weight: 700;
  font-size: 14px;
  user-select: none;
}

.user-meta {
  flex: 1;
  min-width: 0;
  height: 36px;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  align-items: flex-start;
  gap: 0;
  padding-left: 6px;
  overflow: hidden;
  transition: opacity var(--dur-2) var(--ease);
}

.user-name {
  font-size: 13px;
  font-weight: 600;
  line-height: 16px;
  color: var(--text-1);
  max-width: 100%;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.role-pill {
  display: inline-flex;
  align-items: center;
  height: 17px;
  font-size: 11px;
  font-weight: 500;
  line-height: 1;
  padding: 0 8px;
  border-radius: var(--r-full);
}

.role-pill--student {
  background: var(--primary-weak);
  color: var(--primary-active);
}

.role-pill--admin {
  background: var(--red-weak);
  color: var(--red-strong);
}

.sidebar-logout-btn {
  all: unset;
  width: 32px;
  height: 32px;
  border-radius: var(--r-md);
  display: grid;
  place-items: center;
  color: var(--text-3);
  cursor: pointer;
  flex: 0 0 32px;
  margin-left: auto;
  margin-right: 4px;
  box-sizing: border-box;
  transition: background var(--dur-1) var(--ease), color var(--dur-1) var(--ease), transform var(--dur-1) var(--ease);
}

.sidebar-logout-btn:hover {
  background: var(--red-weak);
  color: var(--red-strong);
  transform: translateX(1px);
}

.sidebar-logout-btn:focus-visible {
  outline: 2px solid var(--red);
  outline-offset: 1px;
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
    box-shadow: 12px 0 32px rgba(23, 32, 54, .18);
    transition: transform var(--dur-3) var(--ease), visibility 0s linear 0s;
  }
  .sidebar.collapsed {
    transform: translateX(-100%);
    visibility: hidden;
    pointer-events: none;
    box-shadow: none;
    transition: transform var(--dur-3) var(--ease), visibility 0s linear .24s;
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
  /* 触控目标：移动端菜单项加高 */
  .menu-item {
    min-height: 46px;
  }
}
</style>
