<script setup>
import { computed, ref, onMounted, onUnmounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import { useAuthStore } from '../stores/auth'
import { unreadCount } from '../api/notification'

const router = useRouter()
const route = useRoute()
const auth = useAuthStore()

// 未读消息角标(60s 轮询)
const unread = ref(0)
let timer = null

async function refreshUnread() {
  if (!auth.isLoggedIn) return
  try {
    const resp = await unreadCount()
    unread.value = resp.data?.count || 0
  } catch { /* 忽略轮询失败 */ }
}

// 菜单：首页 / 预约 / 我的预约 / 候补 / 统计 / 消息 / 个人中心 / 管理端
const menus = computed(() => {
  const items = [
    { index: '/',          title: '首页',     icon: '🏠' },
    { index: '/booking',   title: '座位预约', icon: '🪑' },
    { index: '/mine',      title: '我的预约', icon: '📑' },
    { index: '/waitlist',  title: '我的候补', icon: '⏳' },
    { index: '/analytics', title: '热力图统计', icon: '📊' },
    { index: '/notifications', title: '消息中心', icon: '🔔' },
    { index: '/profile',   title: '个人中心', icon: '👤' }
  ]
  if (auth.isAdmin) {
    items.push({ index: '/admin', title: '管理端', icon: '⚙️' })
  }
  return items
})

function handleSelect(index) {
  if (route.path !== index) router.push(index)
}

function onLogout() {
  auth.logout()
  ElMessage.success('已退出登录')
  router.push('/login')
}

// 当前页标题（用于右栏顶部 page-header）
const pageTitle = computed(() => {
  const hit = menus.value.find((m) => m.index === route.path)
  return hit?.title || route.meta?.title || '智能共享自习室'
})

onMounted(() => {
  refreshUnread()
  timer = setInterval(refreshUnread, 60000)
})
onUnmounted(() => clearInterval(timer))
</script>

<template>
  <!-- 第一层双栏：外壳 = 左 Sidebar | 右 Content Column -->
  <div class="shell">
    <!-- ============== 左栏（导航 / 品牌 / 用户） ============== -->
    <aside class="sidebar">
      <!-- 品牌 -->
      <div class="brand">
        <div class="brand-logo">📚</div>
        <div>
          <div class="brand-name">智能自习室</div>
          <div class="brand-sub">Smart Study Room</div>
        </div>
      </div>

      <!-- 菜单 -->
      <nav class="menu">
        <button
          v-for="m in menus"
          :key="m.index"
          class="menu-item"
          :class="{ active: route.path === m.index }"
          @click="handleSelect(m.index)"
        >
          <span class="menu-icon">{{ m.icon }}</span>
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

      <!-- 底部：用户 + 通知 + 退出 -->
      <div class="sidebar-footer">
        <router-link to="/notifications" class="footer-btn" title="消息中心">
          <el-badge :value="unread" :hidden="unread === 0" :max="99">
            <span class="footer-btn-icon">🔔</span>
          </el-badge>
          <span class="footer-btn-text">消息</span>
        </router-link>

        <el-dropdown
          v-if="auth.isLoggedIn"
          @command="(cmd) => cmd === 'logout' && onLogout()"
          trigger="click"
        >
          <div class="user-card">
            <div class="avatar">
              {{ (auth.user?.real_name || auth.user?.username || '?').slice(0, 1) }}
            </div>
            <div class="user-meta">
              <div class="user-name">
                {{ auth.user?.real_name || auth.user?.username }}
              </div>
              <el-tag size="small" effect="plain" :type="auth.isAdmin ? 'danger' : 'primary'">
                {{ auth.isAdmin ? '管理员' : '学生' }}
              </el-tag>
            </div>
            <span class="chev">▾</span>
          </div>
          <template #dropdown>
            <el-dropdown-menu>
              <el-dropdown-item command="profile" @click="router.push('/profile')">
                个人中心
              </el-dropdown-item>
              <el-dropdown-item command="logout" divided>退出登录</el-dropdown-item>
            </el-dropdown-menu>
          </template>
        </el-dropdown>
      </div>
    </aside>

    <!-- ============== 右栏（页面标题行 + 主体） ============== -->
    <section class="content">
      <!-- 右栏顶部：页面标题 + 辅助操作 -->
      <header class="page-header">
        <div>
          <div class="page-crumb">
            智能共享自习室预约系统 <span class="crumb-sep">/</span> {{ pageTitle }}
          </div>
          <h1 class="page-title">{{ pageTitle }}</h1>
        </div>
        <div class="page-header-right">
          <slot name="header-actions" />
        </div>
      </header>

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
  background: #f2f4f8;
}

/* ============== 左栏 Sidebar ============== */
.sidebar {
  display: flex;
  flex-direction: column;
  background:
    linear-gradient(180deg, #ffffff 0%, #fbfcfe 100%);
  border-right: 1px solid #e5e9f0;
  padding: 22px 16px 14px;
  min-height: 0;
}
.brand {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 4px 10px 18px;
  border-bottom: 1px solid #eef1f6;
}
.brand-logo {
  width: 42px;
  height: 42px;
  border-radius: 12px;
  display: grid;
  place-items: center;
  font-size: 20px;
  background: linear-gradient(145deg, #dfe7f2, #eff3f8);
  border: 1px solid #e3e9f2;
  box-shadow: inset 0 1px 0 #ffffff;
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

/* 菜单 */
.menu {
  margin-top: 14px;
  display: flex;
  flex-direction: column;
  gap: 4px;
  overflow: auto;
  padding: 4px 2px;
}
.menu-item {
  all: unset;
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 12px;
  border-radius: 10px;
  cursor: pointer;
  color: #5c6778;
  font-size: 14px;
  transition: background .18s ease, color .18s ease, transform .18s ease;
  position: relative;
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
  font-size: 16px;
  width: 22px;
  text-align: center;
  flex-shrink: 0;
}
.menu-text {
  flex: 1;
  min-width: 0;
}
.menu-badge {
  margin-right: 2px;
}

.sidebar-spacer {
  flex: 1;
  min-height: 8px;
}

/* 底部用户卡 */
.sidebar-footer {
  padding-top: 10px;
  border-top: 1px solid #eef1f6;
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.footer-btn {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 12px;
  border-radius: 10px;
  text-decoration: none;
  color: #5c6778;
  font-size: 13px;
}
.footer-btn:hover {
  background: #eef2f8;
  color: #374151;
}
.footer-btn-icon {
  font-size: 16px;
  width: 22px;
  text-align: center;
}

.user-card {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 12px;
  border-radius: 12px;
  background: linear-gradient(150deg, #f5f7fb, #eef2f8);
  border: 1px solid #e6ebf3;
  cursor: pointer;
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
  gap: 4px;
}
.user-name {
  font-size: 13px;
  font-weight: 600;
  color: #2f3a4d;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.chev {
  color: #9aa3b2;
  font-size: 12px;
}

/* ============== 右栏 Content ============== */
.content {
  min-width: 0;
  min-height: 0;
  display: flex;
  flex-direction: column;
  padding: 18px 24px 24px;
}
.page-header {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  padding: 4px 4px 16px;
}
.page-crumb {
  font-size: 12px;
  color: #94a0b2;
  letter-spacing: 0.3px;
}
.crumb-sep {
  margin: 0 6px;
  color: #cfd5df;
}
.page-title {
  margin: 4px 0 0;
  font-size: 22px;
  font-weight: 700;
  color: #243044;
  letter-spacing: 0.2px;
}
.page-header-right {
  display: flex;
  align-items: center;
  gap: 10px;
}
.page-body {
  flex: 1;
  min-height: 0;
  overflow: auto;
}

/* 窄屏：侧栏折叠（简化为56px图标栏），右栏占满 */
@media (max-width: 1024px) {
  .shell {
    grid-template-columns: 68px 1fr;
  }
  .brand > div:last-child,
  .menu-text,
  .footer-btn-text,
  .user-meta,
  .chev {
    display: none;
  }
  .brand {
    justify-content: center;
    padding: 4px 0 18px;
  }
  .user-card {
    justify-content: center;
  }
}
</style>
