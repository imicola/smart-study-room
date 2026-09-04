import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth'

// 应用路由表(页面随迭代逐步补充)
const routes = [
  {
    path: '/login',
    name: 'login',
    component: () => import('../views/LoginView.vue'),
    meta: { guest: true }
  },
  {
    path: '/',
    component: () => import('../layouts/MainLayout.vue'),
    children: [
      {
        path: '',
        name: 'home',
        component: () => import('../views/HomeView.vue'),
        meta: { title: '首页', allowedRoles: ['student', 'admin'] }
      },
      {
        path: '/booking',
        name: 'booking',
        component: () => import('../views/BookingView.vue'),
        meta: { title: '座位预约', requiresAuth: true, allowedRoles: ['student'] }
      },
      {
        path: '/mine',
        name: 'mine',
        component: () => import('../views/MyReservationsView.vue'),
        meta: { title: '我的预约', requiresAuth: true, allowedRoles: ['student'] }
      },
      {
        path: '/waitlist',
        name: 'waitlist',
        component: () => import('../views/WaitlistView.vue'),
        meta: { title: '我的候补', requiresAuth: true, allowedRoles: ['student'] }
      },
      {
        path: '/analytics',
        name: 'analytics',
        component: () => import('../views/AnalyticsView.vue'),
        meta: { title: '热力图与统计', requiresAuth: true, allowedRoles: ['admin'] }
      },
      {
        path: '/notifications',
        name: 'notifications',
        component: () => import('../views/NotificationsView.vue'),
        meta: { title: '消息中心', requiresAuth: true, allowedRoles: ['student'] }
      },
      {
        path: '/profile',
        name: 'profile',
        component: () => import('../views/ProfileView.vue'),
        meta: { title: '个人中心', requiresAuth: true, allowedRoles: ['student', 'admin'] }
      },
      {
        path: '/admin',
        name: 'admin',
        component: () => import('../views/admin/AdminView.vue'),
        meta: { title: '管理端', requiresAuth: true, allowedRoles: ['admin'] }
      }
    ]
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// 全局前置守卫: 登录校验与角色校验
router.beforeEach((to) => {
  const auth = useAuthStore()
  if (to.meta.requiresAuth !== false && !auth.isLoggedIn && to.name !== 'login') {
    return { name: 'login', query: { redirect: to.fullPath } }
  }
  if (auth.isLoggedIn && !auth.isAdmin && !auth.isStudent) {
    auth.logout()
    return { name: 'login' }
  }
  if (to.meta.guest && auth.isLoggedIn) {
    return auth.roleHomePath
  }
  if (to.meta.allowedRoles && !to.meta.allowedRoles.includes(auth.user?.role)) {
    return auth.roleHomePath
  }
  document.title = to.meta.title
    ? `${to.meta.title} - 智能共享自习室预约系统`
    : '智能共享自习室预约系统'
})

export default router
