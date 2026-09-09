<script setup>
import StudyTips from '../components/StudyTips.vue'
import SAnimatedNumber from '../components/ui/SAnimatedNumber.vue'
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import { useNotificationStore } from '../stores/notification'
import { getRooms } from '../api/room'
import { getOverview } from '../api/stats'
import { getCreditOverview } from '../api/credit'
import AppIcon from '../components/AppIcon.vue'

const router = useRouter()
const auth = useAuthStore()
const notifStore = useNotificationStore()

const who = computed(() => auth.user?.real_name || auth.user?.username || '同学')
const roleText = computed(() => (auth.isAdmin ? '管理员' : '学生'))
const helloText = computed(() => (auth.isAdmin ? '欢迎回来，请查看今日运营情况' : '今天也要高效学习'))
const todayText = computed(() =>
  new Date().toLocaleDateString('zh-CN', { month: 'long', day: 'numeric', weekday: 'long' })
)
const greeting = computed(() => {
  const h = new Date().getHours()
  if (h < 6) return '夜深了'
  if (h < 12) return '早上好'
  if (h < 14) return '中午好'
  if (h < 18) return '下午好'
  return '晚上好'
})

const rooms = ref([])
const statsOverview = ref(null)
const creditOverview = ref(null)
const unread = computed(() => notifStore.unread)
let unreadTimer = null

const currentCredit = computed(() => creditOverview.value?.score ?? auth.user?.credit_score ?? 100)
const totalSeats = computed(() => statsOverview.value?.total_seats ?? 158)
const inUseNow = computed(() => statsOverview.value?.in_use_now ?? 0)
const availableSeats = computed(() => Math.max(0, totalSeats.value - inUseNow.value))
const roomCount = computed(() => rooms.value.length || 3)
const openHours = computed(() => {
  if (rooms.value.length && rooms.value[0].open_time && rooms.value[0].close_time) {
    return {
      open: rooms.value[0].open_time.slice(0, 5),
      close: rooms.value[0].close_time.slice(0, 5)
    }
  }
  return { open: '08:00', close: '22:00' }
})

function refreshUnread() {
  notifStore.refresh()
}

onMounted(async () => {
  try {
    const roomResp = await getRooms()
    rooms.value = roomResp.data || []
  } catch (e) {
    // 降级使用默认值
  }

  try {
    const statsResp = await getOverview()
    statsOverview.value = statsResp.data
  } catch (e) {
    // 降级使用默认值
  }

  if (auth.isStudent) {
    try {
      const credResp = await getCreditOverview()
      creditOverview.value = credResp.data
    } catch (e) {
      // 降级使用默认值
    }
  }

  refreshUnread()
  unreadTimer = setInterval(refreshUnread, 30000)
})

onUnmounted(() => {
  if (unreadTimer) {
    clearInterval(unreadTimer)
    unreadTimer = null
  }
})

const shortcuts = computed(() => auth.isAdmin
  ? [
      { title: '热力图统计', desc: '座位利用率 · 高峰时段', icon: 'analytics', to: '/analytics', tone: 'warm' },
      { title: '管理端', desc: '自习室 · 座位 · 用户', icon: 'admin', to: '/admin', tone: 'primary' },
      {
        title: '消息中心',
        desc: unread.value > 0 ? `${unread.value} 条未读通知` : '通知公告 · 异常提醒',
        icon: unread.value > 0 ? 'notification' : 'notification-empty',
        to: '/notifications',
        tone: 'success'
      },
      { title: '个人中心', desc: '查看管理员账户信息', icon: 'profile', to: '/profile', tone: 'violet' }
    ]
  : [
      { title: '座位预约', desc: '手动选座 · 智能分配', icon: 'booking', to: '/booking', tone: 'primary' },
      { title: '我的预约', desc: '签到 · 临时离开 · 签退', icon: 'reservations', to: '/mine', tone: 'success' },
      { title: '我的候补', desc: '查看排队与递补状态', icon: 'waitlist', to: '/waitlist', tone: 'warm' },
      {
        title: '消息中心',
        desc: unread.value > 0 ? `${unread.value} 条未读消息` : '预约结果 · 违约警告 · 递补',
        icon: unread.value > 0 ? 'notification' : 'notification-empty',
        to: '/notifications',
        tone: 'violet'
      }
    ])
const cardToneClass = {
  primary: 'tone-primary',
  success: 'tone-success',
  warm: 'tone-warm',
  violet: 'tone-violet'
}
</script>

<template>
  <div v-reveal class="page-view">
    <header class="view-heading" data-page-title>
      <h1>{{ greeting }}，{{ who }}</h1>
      <p class="heading-sub">{{ todayText }} · {{ helloText }}</p>
    </header>
    <!-- 首页：页面级双栏 -->
    <div class="split home-split">
    <!-- 左栏：账户 KPI + 快速贴士 -->
    <div class="split-left">
      <section v-if="auth.isStudent" class="card overview-card">
        <div class="card-title-row">
          <h3>账户概览</h3>
          <span class="role-pill" :class="auth.isAdmin ? 'role-pill--admin' : 'role-pill--student'">{{ roleText }}</span>
        </div>
        <div class="kpi-grid">
          <div class="kpi">
            <div class="kpi-num"><SAnimatedNumber :value="currentCredit" /></div>
            <div class="kpi-label">现有信用分</div>
          </div>
          <div class="kpi">
            <div class="kpi-num"><SAnimatedNumber :value="roomCount" /></div>
            <div class="kpi-label">自习室可用</div>
          </div>
          <div class="kpi kpi-ok">
            <div class="kpi-num">
              <SAnimatedNumber :value="availableSeats" /><span class="kpi-slash">/</span><span class="kpi-total">{{ totalSeats }}</span>
            </div>
            <div class="kpi-label">可用座位</div>
          </div>
          <div class="kpi">
            <div class="kpi-num kpi-time">
              <span class="kpi-time-start">{{ openHours.open }}</span>
              <span class="kpi-time-end"><span class="kpi-tilde">~</span>{{ openHours.close }}</span>
            </div>
            <div class="kpi-label">今日开放</div>
          </div>
        </div>
      </section>

      <section v-else class="card overview-card">
        <div class="card-title-row">
          <h3>管理概览</h3>
          <span class="role-pill role-pill--admin">管理员</span>
        </div>
        <div class="kpi-grid">
          <div class="kpi">
            <div class="kpi-num"><SAnimatedNumber :value="roomCount" /></div>
            <div class="kpi-label">自习室</div>
          </div>
          <div class="kpi kpi-ok">
            <div class="kpi-num">
              <SAnimatedNumber :value="availableSeats" /><span class="kpi-slash">/</span><span class="kpi-total">{{ totalSeats }}</span>
            </div>
            <div class="kpi-label">可用 / 总座位</div>
          </div>
          <div class="kpi">
            <div class="kpi-num">2</div>
            <div class="kpi-label">管理模块</div>
          </div>
          <div class="kpi">
            <div class="kpi-num kpi-time">
              <span class="kpi-time-start">{{ openHours.open }}</span>
              <span class="kpi-time-end"><span class="kpi-tilde">~</span>{{ openHours.close }}</span>
            </div>
            <div class="kpi-label">今日开放</div>
          </div>
        </div>
      </section>


    </div>

    <!-- 右栏：功能入口卡 -->
    <div class="split-right">
      <section class="card shortcuts-card">
        <div class="card-title-row">
          <h3>快速入口</h3>
          <span class="muted">点击卡片直接进入对应功能</span>
        </div>
        <div class="shortcut-grid">
          <button
            v-for="s in shortcuts"
            :key="s.to"
            class="shortcut"
            :class="cardToneClass[s.tone]"
            @click="router.push(s.to)"
          >
            <div class="shortcut-top">
              <div class="shortcut-icon"><AppIcon :name="s.icon" :size="24" /></div>
              <div class="chev"><AppIcon name="chevron-right" :size="18" /></div>
            </div>
            <div class="shortcut-body">
              <div class="shortcut-title">{{ s.title }}</div>
              <div class="shortcut-desc">{{ s.desc }}</div>
            </div>
          </button>
        </div>
      </section>
      <StudyTips :title="auth.isStudent ? '使用小贴士' : '管理提示'">
        <ul v-if="auth.isStudent" class="tips tips-list">
          <li>距开始不足 30 分钟取消预约将扣 <b>2 分</b>信用分</li>
          <li>超时未签到会自动记为违约，扣 <b>8 分</b>，并释放座位</li>
          <li>满座时段可加入 <b>候补</b>，空位释放时按序自动递补</li>
          <li>信用分低于 60，<b>3 天内</b>无法发起新预约</li>
        </ul>
        <ul v-else class="tips tips-list">
          <li>定期检查自习室开放时间与座位规模是否准确</li>
          <li>维护中的座位不会开放给普通用户预约</li>
          <li>可在用户管理中启用或禁用普通用户账号</li>
          <li>通过热力图了解座位利用率和高峰时段</li>
        </ul>
            </StudyTips>
      <section class="card rooms-card">
        <div class="card-title-row"><h3>找到你的专注空间</h3><span class="muted">自习室</span></div>
        <div class="room-list">
          <button v-for="room in rooms" :key="room.id" class="room-link" @click="router.push(auth.isAdmin ? '/admin' : '/booking')">
            <span><b>{{ room.name }}</b><small>{{ room.location }} · {{ room.open_time?.slice(0,5) }}–{{ room.close_time?.slice(0,5) }}</small></span><span aria-hidden="true">↗</span>
          </button>
          <p v-if="!rooms.length" class="muted">暂无自习室信息</p>
        </div>
      </section>

      <section class="card intro-card">
        <div class="card-title-row">
          <h3>系统介绍</h3>
        </div>
        <div v-if="auth.isStudent" class="intro-grid">
          <div class="intro-cell">
            <div class="intro-label">在线预约</div>
            <div class="intro-text">平面图可视化选座，时段冲突自动检测，支持签到 / 临时离开 / 签退全生命周期。</div>
          </div>
          <div class="intro-cell">
            <div class="intro-label">智能分配</div>
            <div class="intro-text">按区域、电源、靠窗偏好加权评分，一键推荐最优座位或直接自动下单。</div>
          </div>
          <div class="intro-cell">
            <div class="intro-label">候补递补</div>
            <div class="intro-text">满座时加入候补队列，空位释放后按排队顺序自动递补并发送通知。</div>
          </div>
          <div class="intro-cell">
            <div class="intro-label">信用治理</div>
            <div class="intro-text">违约扣分、履约加分、低分限约，配合满座候补递补机制，公平利用座位资源。</div>
          </div>
        </div>
        <div v-else class="intro-grid">
          <div class="intro-cell">
            <div class="intro-label">资源管理</div>
            <div class="intro-text">维护自习室名称、位置、开放时间和座位规模，统一管理可预约资源。</div>
          </div>
          <div class="intro-cell">
            <div class="intro-label">座位维护</div>
            <div class="intro-text">批量生成座位并维护座位属性与状态，确保不可用座位及时下线。</div>
          </div>
          <div class="intro-cell">
            <div class="intro-label">用户管理</div>
            <div class="intro-text">查看普通用户信息与信用状态，并按需启用或禁用用户账号。</div>
          </div>
          <div class="intro-cell">
            <div class="intro-label">运营分析</div>
            <div class="intro-text">查看座位利用率和时段热力分布，为资源配置与开放安排提供参考。</div>
          </div>
        </div>
      </section>
    </div>
    </div>
  </div>
</template>

<style scoped>


.role-pill {
  font-size: 11px;
  font-weight: 500;
  line-height: 1;
  padding: 4px 9px;
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

/* KPI 中的可用/总数格式美化 */
.kpi-slash {
  font-size: 14px;
  margin: 0 1px;
  color: var(--text-4);
  font-weight: 500;
}
.kpi-total {
  font-size: 14px;
  color: var(--text-3);
  font-weight: 500;
}
.kpi-time {
  font-size: 19px;
  display: flex;
  align-items: baseline;
}
.kpi-time-start,
.kpi-time-end {
  display: inline-flex;
  align-items: baseline;
}
.kpi-tilde {
  font-size: 13px;
  color: var(--text-4);
  margin: 0 2px;
  font-weight: 500;
}

/* 贴士 */
.tips-list {
  margin-top: 2px;
}

/* 快速入口卡片 */
.shortcuts-card {
  display: flex;
  flex-direction: column;
}

.shortcut-grid {
  flex: 1;
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 12px;
  min-height: 0;
}

.shortcut {
  all: unset;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  height: 100%;
  min-height: 148px;
  padding: 18px 16px 16px;
  border-radius: var(--r-xl);
  cursor: pointer;
  border: 1px solid var(--border);
  background: var(--surface);
  transition: transform var(--dur-2) var(--ease), box-shadow var(--dur-2) var(--ease),
    border-color var(--dur-2) var(--ease);
  box-sizing: border-box;
}

.shortcut:hover {
  transform: translateY(-3px);
  box-shadow: var(--shadow-2);
  border-color: var(--border-strong);
}

.shortcut:focus-visible {
  outline: 2px solid var(--primary);
  outline-offset: 2px;
}

.shortcut-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 18px;
}

.shortcut-icon {
  width: 44px;
  height: 44px;
  border-radius: var(--r-lg);
  display: grid;
  place-items: center;
  flex-shrink: 0;
  transition: transform var(--dur-2) var(--ease-out);
}

.shortcut:hover .shortcut-icon {
  transform: scale(1.05);
}

.shortcut-body {
  min-width: 0;
}

.shortcut-title {
  font-size: 16px;
  font-weight: 650;
  color: var(--text-1);
  line-height: 1.3;
  margin-bottom: 5px;
  letter-spacing: -.01em;
  transition: color var(--dur-1) var(--ease);
}

.shortcut:hover .shortcut-title {
  color: var(--primary-active);
}

.shortcut-desc {
  font-size: var(--fs-caption);
  color: var(--text-3);
  line-height: 1.55;
  min-height: calc(1.55em * 2);
}

.shortcut .chev {
  color: var(--text-4);
  display: grid;
  place-items: center;
  width: 26px;
  height: 26px;
  border-radius: var(--r-sm);
  transition: transform var(--dur-2) var(--ease), color var(--dur-1) var(--ease), background var(--dur-1) var(--ease);
}

.shortcut:hover .chev {
  transform: translateX(3px);
  color: var(--primary);
  background: var(--primary-faint);
}






/* 系统介绍 */
.intro-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
}
.intro-cell {
  border-radius: var(--r-lg);
  padding: 14px 16px;
  background: var(--surface-2);
  border: 1px solid var(--hairline);
}
.intro-label {
  font-size: var(--fs-body-sm);
  font-weight: 600;
  color: var(--text-1);
  margin-bottom: 5px;
  letter-spacing: -.005em;
}
.intro-text {
  font-size: var(--fs-caption);
  color: var(--text-3);
  line-height: 1.7;
}

/* ---------- 响应式断点 ---------- */
@media (max-width: 1024px) {
  .home-split {
    display: flex !important;
    flex-direction: column !important;
    gap: 14px !important;
    width: 100% !important;
  }
  .home-split .split-left,
  .home-split .split-right {
    display: contents !important;
  }
  .overview-card { order: 1; width: 100%; }
  .shortcuts-card { order: 2; width: 100%; }
  .rooms-card { order: 3; width: 100%; }
  .tips-card { order: 4; width: 100%; }
  .intro-card { order: 5; width: 100%; }

  .shortcut-grid {
    grid-template-columns: 1fr;
    gap: 10px;
    width: 100%;
  }
  .shortcut {
    width: 100%;
    min-height: 84px;
    padding: 16px 18px;
    display: flex;
    flex-direction: row;
    align-items: center;
    gap: 14px;
  }
  .shortcut-top {
    display: contents;
  }
  .shortcut-icon {
    order: 1;
    width: 48px;
    height: 48px;
    flex-shrink: 0;
  }
  .shortcut-desc {
    min-height: 0;
  }
  .shortcut-body {
    order: 2;
    flex: 1;
    min-width: 0;
  }
  .shortcut .chev {
    order: 3;
    flex-shrink: 0;
    width: 30px;
    height: 30px;
  }

  .intro-grid {
    grid-template-columns: 1fr;
    gap: 10px;
    width: 100%;
  }

  .kpi-time {
    flex-direction: column !important;
    align-items: center !important;
    justify-content: center !important;
    line-height: 1.15 !important;
    font-size: clamp(12px, 2.7vw, 15px) !important;
    white-space: normal !important;
    text-align: center !important;
  }
  .kpi-time .kpi-time-start,
  .kpi-time .kpi-time-end {
    display: block !important;
    line-height: 1.15 !important;
    text-align: center !important;
  }
  .kpi-time .kpi-tilde {
    font-size: 0.85em !important;
    margin: 0 1px 0 0 !important;
  }
}

@media (max-width: 560px) {
  .shortcut {
    min-height: 74px;
    padding: 14px 14px;
    gap: 12px;
  }
  .shortcut-icon {
    width: 42px;
    height: 42px;
  }
  .shortcut-title {
    font-size: 15px;
  }
  .shortcut-desc {
    font-size: 11.5px;
  }

}
.tone-primary .shortcut-icon { background: var(--primary-weak); color: var(--primary-active); }
.tone-success .shortcut-icon { background: var(--green-weak); color: var(--green-strong); }
.tone-warm    .shortcut-icon { background: var(--amber-weak); color: var(--amber-strong); }
.tone-violet  .shortcut-icon { background: var(--violet-weak); color: var(--violet-strong); }
</style>
