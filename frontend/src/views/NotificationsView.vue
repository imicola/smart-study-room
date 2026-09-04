<script setup>
import { ref, computed, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { listNotifications, markRead, markAllRead } from '../api/notification'
import AppIcon from '../components/AppIcon.vue'

const list = ref([])
const loading = ref(false)
const filterType = ref('all')

const typeMeta = {
  reservation_success: { text: '预约成功', color: '#5fa655' },
  checkin_reminder:   { text: '签到提醒', color: '#5f7ea3' },
  violation:          { text: '违约警告', color: '#c86a6a' },
  credit_change:      { text: '信用变动', color: '#c78941' },
  waitlist_promoted:  { text: '候补递补', color: '#8a72c0' },
  system:             { text: '系统',     color: '#828c9d' }
}

async function load() {
  loading.value = true
  try {
    const resp = await listNotifications()
    list.value = resp.data || []
  } finally {
    loading.value = false
  }
}

async function onMarkRead(n) {
  if (n.is_read) return
  await markRead(n.id)
  n.is_read = true
}

async function onMarkAll() {
  const resp = await markAllRead()
  ElMessage.success(`已标记 ${resp.data.marked} 条为已读`)
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
</script>

<template>
  <div class="page-view">
    <header class="view-heading" data-page-title><h1>消息中心</h1></header>
    <div class="split notif-split">
    <div class="split-left">
      <section class="card responsive-compact">
        <div class="card-title-row">
          <h3>消息总览</h3>
          <el-badge :value="buckets.unread" :hidden="buckets.unread === 0" :max="99">
            <el-button size="small" @click="onMarkAll">全部已读</el-button>
          </el-badge>
        </div>
        <div class="kpi-grid">
          <div class="kpi"><div class="kpi-num">{{ buckets.all }}</div><div class="kpi-label">消息总数</div></div>
          <div class="kpi kpi-warn"><div class="kpi-num">{{ buckets.unread }}</div><div class="kpi-label">未读</div></div>
        </div>
      </section>

      <section class="card responsive-compact">
        <div class="card-title-row"><h3>消息分类</h3></div>
        <div class="nav-list">
          <button
            v-for="n in typeNav"
            :key="n.key"
            class="nav-btn"
            :class="{ active: filterType === n.key }"
            @click="filterType = n.key"
          >
            <span class="nav-icon"><AppIcon :name="n.icon" :size="17" /></span>
            <span class="nav-label">{{ n.label }}</span>
            <span class="nav-count">{{ buckets[n.key] ?? 0 }}</span>
          </button>
        </div>
      </section>

      <section class="card responsive-compact">
        <h3>使用提示</h3>
        <ul class="tips">
          <li>点击消息条目将其标记为<b>已读</b></li>
          <li>候补递补、违约警告等<b>关键事件</b>建议及时查看</li>
          <li>每 60 秒自动刷新未读数量（顶部铃铛）</li>
        </ul>
      </section>
    </div>

    <div class="split-right">
      <section class="card">
        <div class="card-title-row">
          <h3>消息列表 <span class="muted" style="font-weight:400;margin-left:8px">（共 {{ filtered.length }} 条）</span></h3>
        </div>

        <div v-loading="loading" class="list">
          <el-empty v-if="!filtered.length && !loading" description="暂无消息" />
          <div
            v-for="n in filtered"
            :key="n.id"
            class="msg-item"
            :class="{ unread: !n.is_read }"
            @click="onMarkRead(n)"
          >
            <el-tag
              size="small"
              effect="dark"
              :style="{ background: typeMeta[n.type]?.color, border: 'none' }"
            >
              {{ typeMeta[n.type]?.text || n.type }}
            </el-tag>
            <div class="msg-body">
              <div class="msg-title">
                {{ n.title }}
                <el-badge v-if="!n.is_read" is-dot class="dot" />
              </div>
              <div class="msg-content">{{ n.content }}</div>
            </div>
            <span class="msg-time">{{ fmtTime(n.created_at) }}</span>
          </div>
        </div>
      </section>
    </div>
    </div>
  </div>
</template>

<style scoped>
.notif-split { grid-template-columns: 280px 1fr; }
.kpi-warn .kpi-num { color: #c86a6a; }

.nav-list { display: flex; flex-direction: column; gap: 6px; }
.nav-btn {
  all: unset; cursor: pointer;
  display: grid;
  grid-template-columns: 24px 1fr auto;
  gap: 10px; align-items: center;
  padding: 9px 12px; border-radius: 10px;
  transition: background .15s ease;
}
.nav-btn:hover { background: #eef2f8; }
.nav-btn.active {
  background: linear-gradient(135deg, #cfdae8, #e3eaf4);
  color: #2f4462; font-weight: 600;
  box-shadow: inset 0 1px 0 #fff;
}
.nav-icon { text-align: center; }
.nav-label { font-size: 13.5px; color: #465065; }
.nav-count {
  font-size: 12px; padding: 1px 8px; border-radius: 999px;
  background: #e5e9f0; color: #6b7280;
}
.nav-btn.active .nav-count { background: #fff; color: #456388; }

.list {
  display: flex; flex-direction: column; gap: 4px;
}
.msg-item {
  display: grid;
  grid-template-columns: 88px 1fr auto;
  gap: 14px;
  align-items: flex-start;
  padding: 14px 16px;
  border-radius: 12px;
  cursor: pointer;
  transition: background .15s ease;
  border: 1px solid transparent;
}
.msg-item:hover { background: #f6f8fb; }
.msg-item.unread {
  background: linear-gradient(135deg, #f4f7fb, #eef3f9);
  border-color: #e1e8f2;
}
.msg-body { min-width: 0; }
.msg-title {
  font-weight: 600; color: #2b3240;
  display: flex; align-items: center; gap: 6px;
}
.dot { margin-left: 2px; }
.msg-content {
  color: #4b5567; font-size: 13.5px;
  margin-top: 4px; line-height: 1.6;
}
.msg-time {
  color: #94a0b2; font-size: 12px;
  white-space: nowrap;
}
.tips {
  margin: 0; padding-left: 18px;
  display: flex; flex-direction: column; gap: 6px;
  color: #4b5567; font-size: 13px; line-height: 1.6;
}
.tips b { color: #456388; font-weight: 600; }

@media (max-width: 720px) {
  .msg-item {
    grid-template-columns: minmax(0, 1fr);
    gap: 8px 10px;
    padding: 12px;
  }
  .msg-item :deep(.el-tag) { width: fit-content; }
  .msg-time {
    grid-column: 1;
    white-space: normal;
  }
}
</style>
