<script setup>
import PageHelp from '../components/PageHelp.vue'
import SAnimatedNumber from '../components/ui/SAnimatedNumber.vue'
import { usePagination } from '../composables/usePagination'
import SPagination from '../components/ui/SPagination.vue'
import { ref, computed, onMounted } from 'vue'
import { message } from '../components/ui/feedback'
import { listNotifications, markRead, markAllRead } from '../api/notification'
import { useNotificationStore } from '../stores/notification'
import AppIcon from '../components/AppIcon.vue'
import SButton from '../components/ui/SButton.vue'
import SEmpty from '../components/ui/SEmpty.vue'

const notifStore = useNotificationStore()
const list = ref([])
const loading = ref(false)
const filterType = ref('all')

const typeMeta = {
  reservation_success: { text: '预约成功', color: 'var(--green-strong)', bg: 'var(--green-weak)' },
  checkin_reminder:   { text: '签到提醒', color: 'var(--primary-active)', bg: 'var(--primary-weak)' },
  violation:          { text: '违约警告', color: 'var(--red-strong)', bg: 'var(--red-weak)' },
  credit_change:      { text: '信用变动', color: 'var(--amber-strong)', bg: 'var(--amber-weak)' },
  waitlist_promoted:  { text: '候补递补', color: 'var(--violet-strong)', bg: 'var(--violet-weak)' },
  system:             { text: '系统',     color: 'var(--text-2)', bg: 'var(--surface-3)' }
}

async function load() {
  loading.value = true
  try {
    const resp = await listNotifications()
    list.value = resp.data || []
    notifStore.refresh()
  } finally {
    loading.value = false
  }
}

async function onMarkRead(n) {
  if (n.is_read) return
  await markRead(n.id)
  n.is_read = true
  notifStore.decrement(1)
  notifStore.refresh()
}

async function onMarkAll() {
  const resp = await markAllRead()
  message.success(`已标记 ${resp.data.marked} 条为已读`)
  notifStore.clear()
  load()
}

function fmtTime(t) {
  return new Date(t).toLocaleString('zh-CN', { hour12: false })
}

const buckets = computed(() => {
  const b = { all: list.value.length, unread: 0 }
  Object.keys(typeMeta).forEach((k) => (b[k] = 0))
  list.value.forEach((n) => {
    if (b[n.type] !== undefined) b[n.type]++
    if (!n.is_read) b.unread++
  })
  return b
})
const filtered = computed(() => {
  if (filterType.value === 'all') return list.value
  if (filterType.value === 'unread') return list.value.filter((n) => !n.is_read)
  return list.value.filter((n) => n.type === filterType.value)
})

const typeNav = computed(() => ([
  { key: 'all',    label: '全部消息', icon: 'inbox' },
  { key: 'unread', label: '未读消息', icon: 'notification' },
  ...Object.keys(typeMeta).map((k) => ({ key: k, label: typeMeta[k].text, icon: typeIcon(k) }))
]))
function typeIcon(k) {
  return {
    reservation_success: 'circle-success',
    checkin_reminder: 'waitlist',
    violation: 'warning',
    credit_change: 'credit',
    waitlist_promoted: 'ticket',
    system: 'announcement'
  }[k] || 'circle-muted'
}

onMounted(load)
const { page, pages, pageItems } = usePagination(filtered, filterType)
</script>

<template>
  <div v-reveal class="page-view">
    <header class="view-heading has-page-help"><div class="heading-copy" data-page-title>
      <h1>消息中心</h1>
      <p class="heading-sub">预约结果、违约警告与候补递补通知</p>
    </div><PageHelp title="使用提示">
        <ul class="tips">
          <li>点击消息条目将其标记为<b>已读</b></li>
          <li>候补递补、违约警告等<b>关键事件</b>建议及时查看</li>
          <li>每 60 秒自动刷新未读数量（顶部铃铛）</li>
        </ul>
      </PageHelp></header>
    <div class="split notif-split">
    <div class="split-left">
      <section class="card responsive-compact">
        <div class="card-title-row">
          <h3>消息总览</h3>
          <SButton size="sm" variant="secondary" :disabled="buckets.unread === 0" @click="onMarkAll">全部已读</SButton>
        </div>
        <div class="kpi-grid">
          <div class="kpi"><div class="kpi-num"><SAnimatedNumber :value="buckets.all" /></div><div class="kpi-label">消息总数</div></div>
          <div class="kpi" :class="buckets.unread > 0 ? 'kpi-bad' : ''"><div class="kpi-num"><SAnimatedNumber :value="buckets.unread" /></div><div class="kpi-label">未读</div></div>
        </div>
      </section>

      <section class="card responsive-compact">
        <div class="card-title-row"><h3>消息分类</h3></div>
        <nav v-active-track class="side-nav">
          <button
            v-for="n in typeNav"
            :key="n.key"
            class="side-nav-item"
            :class="{ active: filterType === n.key }"
            @click="filterType = n.key"
          >
            <span class="side-nav-icon"><AppIcon :name="n.icon" :size="16" /></span>
            <span class="side-nav-label">{{ n.label }}</span>
            <span v-if="(n.key === 'unread' ? buckets.unread : buckets[n.key] ?? 0) > 0" class="side-nav-count">
              {{ n.key === 'unread' ? buckets.unread : buckets[n.key] ?? 0 }}
            </span>
          </button>
        </nav>
      </section>

      
    </div>

    <div class="split-right">
      <section class="card">
        <div class="card-title-row">
          <h3>消息列表 <span class="muted">共 {{ filtered.length }} 条</span></h3>
        </div>

        <div v-list-motion="pageItems.map(row => row.id).join()" v-loading="loading" class="list">
          <SEmpty v-if="!filtered.length && !loading" icon="inbox" description="暂无消息" />
          <button
            v-for="n in pageItems"
            :key="n.id"
            class="msg-item"
            :class="{ unread: !n.is_read }"
            @click="onMarkRead(n)"
          >
            <span
              class="msg-type"
              :style="{ color: typeMeta[n.type]?.color, background: typeMeta[n.type]?.bg }"
            >
              {{ typeMeta[n.type]?.text || n.type }}
            </span>
            <div class="msg-body">
              <div class="msg-title">
                <span class="msg-title-text">{{ n.title }}</span>
                <span v-if="!n.is_read" class="msg-dot" aria-label="未读" />
              </div>
              <div class="msg-content">{{ n.content }}</div>
            </div>
            <span class="msg-time">{{ fmtTime(n.created_at) }}</span>
          </button>
        </div>
        <SPagination v-model="page" :pages="pages" :total="filtered.length" />
      </section>
    </div>
    </div>
  </div>
</template>

<style scoped>


.list {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
/* PC 宽屏：消息列表在右栏卡内纵向滚动，右栏高度可控 */

.msg-item {
  all: unset;
  display: grid;
  grid-template-columns: 76px 1fr auto;
  gap: 14px;
  align-items: flex-start;
  padding: 14px 16px;
  border-radius: var(--r-lg);
  cursor: pointer;
  transition: background var(--dur-1) var(--ease);
  border: 1px solid transparent;
  box-sizing: border-box;
  width: 100%;
}
.msg-item:hover {
  background: var(--surface-hover);
}
.msg-item:focus-visible {
  outline: 2px solid var(--primary);
  outline-offset: -2px;
}
.msg-item.unread {
  background: var(--primary-faint);
  border-color: var(--border-strong);
}
.msg-body { min-width: 0; }
.msg-type {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  height: 22px;
  padding: 0 9px;
  border-radius: var(--r-sm);
  font-size: 11.5px;
  font-weight: 500;
  white-space: nowrap;
}
.msg-title {
  font-weight: 600;
  color: var(--text-1);
  display: flex;
  align-items: center;
  gap: 6px;
}
.msg-title-text {
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.msg-dot {
  width: 7px;
  height: 7px;
  flex: 0 0 7px;
  border-radius: 50%;
  background: var(--primary);
}
.msg-content {
  color: var(--text-2);
  font-size: var(--fs-body-sm);
  margin-top: 4px;
  line-height: 1.6;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
.msg-time {
  color: var(--text-4);
  font-size: var(--fs-caption);
  white-space: nowrap;
  font-variant-numeric: tabular-nums;
  padding-top: 2px;
}

@media (max-width: 720px) {
  .msg-item {
    grid-template-columns: minmax(0, 1fr);
    gap: 8px 10px;
    padding: 12px;
  }
  .msg-time {
    grid-column: 1;
    white-space: normal;
  }
}
</style>
