<script setup>
import PageHelp from '../components/PageHelp.vue'
import SAnimatedNumber from '../components/ui/SAnimatedNumber.vue'
import { usePagination } from '../composables/usePagination'
import SPagination from '../components/ui/SPagination.vue'
import { ref, computed, onMounted } from 'vue'
import { message, confirmDialog } from '../components/ui/feedback'
import { listMyWaitlist, cancelWaitlist } from '../api/waitlist'
import AppIcon from '../components/AppIcon.vue'
import SButton from '../components/ui/SButton.vue'
import STag from '../components/ui/STag.vue'
import SEmpty from '../components/ui/SEmpty.vue'
import SBanner from '../components/ui/SBanner.vue'

const list = ref([])
const loading = ref(false)
const filterStatus = ref('all')

const statusMeta = {
  waiting:   { text: '排队中', type: 'warning' },
  promoted:  { text: '已递补', type: 'success' },
  cancelled: { text: '已取消', type: 'info' },
  expired:   { text: '已过期', type: 'info' }
}
const zoneName = { quiet: '静音区', regular: '普通区', discussion: '研讨区', computer: '机房区' }

async function load() {
  loading.value = true
  try {
    const resp = await listMyWaitlist()
    list.value = resp.data || []
  } finally {
    loading.value = false
  }
}

async function doCancel(row) {
  try {
    await confirmDialog('确认退出该场次候补队列？', '取消候补', { type: 'warning' })
  } catch { return }
  await cancelWaitlist(row.id)
  message.success('已退出候补')
  load()
}

function prefText(row) {
  const ps = []
  if (row.zone) ps.push(zoneName[row.zone] || row.zone)
  if (row.has_power) ps.push('电源')
  if (row.near_window) ps.push('靠窗')
  return ps.length ? ps.join(' / ') : '不限'
}

const buckets = computed(() => {
  const b = { all: list.value.length, waiting: 0, promoted: 0, cancelled: 0, expired: 0 }
  list.value.forEach((r) => { if (b[r.status] !== undefined) b[r.status]++ })
  return b
})
const filtered = computed(() => {
  if (filterStatus.value === 'all') return list.value
  return list.value.filter((r) => r.status === filterStatus.value)
})
const nav = [
  { key: 'all',       label: '全部候补', icon: 'waitlist' },
  { key: 'waiting',   label: '排队中',   icon: 'circle-wait' },
  { key: 'promoted',  label: '已递补',   icon: 'circle-success' },
  { key: 'expired',   label: '已过期',   icon: 'circle-muted' },
  { key: 'cancelled', label: '已取消',   icon: 'circle-muted' }
]

onMounted(load)
const { page, pages, pageItems } = usePagination(filtered, filterStatus)
</script>

<template>
  <div v-reveal class="page-view">
    <header class="view-heading has-page-help"><div class="heading-copy" data-page-title>
      <h1>我的候补</h1>
      <p class="heading-sub">满座时段自动排队，空位释放后按序递补</p>
    </div><PageHelp title="候补机制">
        <ul class="tips">
          <li>提交候补时，系统会按<b>时间优先</b>记录位次</li>
          <li>空位产生后，按位次自动递补并发送<b>站内消息</b>通知</li>
          <li>若递补成功后 5 分钟内未确认，顺位自动取消</li>
          <li>排队过程中可随时退出候补，无信用分影响</li>
        </ul>
      </PageHelp></header>
    <div class="split wl-split">
    <div class="split-left">
      <section class="card responsive-compact">
        <div class="card-title-row">
          <h3>候补概览</h3>
          <SButton size="sm" variant="secondary" @click="load"><AppIcon name="refresh" :size="14" />刷新</SButton>
        </div>
        <div class="kpi-grid">
          <div class="kpi"><div class="kpi-num"><SAnimatedNumber :value="buckets.all" /></div><div class="kpi-label">历史候补</div></div>
          <div class="kpi kpi-warn"><div class="kpi-num"><SAnimatedNumber :value="buckets.waiting" /></div><div class="kpi-label">正在排队</div></div>
          <div class="kpi kpi-ok"><div class="kpi-num"><SAnimatedNumber :value="buckets.promoted" /></div><div class="kpi-label">成功递补</div></div>
          <div class="kpi"><div class="kpi-num"><SAnimatedNumber :value="buckets.expired" /></div><div class="kpi-label">已过期</div></div>
        </div>
      </section>

      <section class="card responsive-compact">
        <div class="card-title-row"><h3>状态分类</h3></div>
        <nav v-active-track class="side-nav">
          <button
            v-for="n in nav"
            :key="n.key"
            class="side-nav-item"
            :class="{ active: filterStatus === n.key }"
            @click="filterStatus = n.key"
          >
            <span class="side-nav-icon"><AppIcon :name="n.icon" :size="16" /></span>
            <span class="side-nav-label">{{ n.label }}</span>
            <span class="side-nav-count">{{ buckets[n.key] ?? 0 }}</span>
          </button>
        </nav>
      </section>

      
    </div>

    <div class="split-right">
      <section class="card">
        <div class="card-title-row">
          <h3>候补记录 <span class="muted">共 {{ filtered.length }} 条</span></h3>
        </div>
        <SBanner type="info" style="margin-bottom: 14px">
          满座时段提交候补后，系统会在空位释放时自动按排队顺序递补，并通过站内消息通知您。
        </SBanner>

        <div v-list-motion="pageItems.map(row => row.id + row.status).join()" class="table-wrap">
          <div class="table-scroll" v-loading="loading" tabindex="0" aria-label="候补记录表格，可左右滑动">
            <table class="table waitlist-table">
              <thead>
                <tr>
                  <th style="width:110px">日期</th>
                  <th style="width:130px">时段</th>
                  <th style="min-width:130px">自习室</th>
                  <th style="min-width:120px">偏好</th>
                  <th style="width:100px">排队位次</th>
                  <th style="width:98px">状态</th>
                  <th style="width:90px">操作</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="row in pageItems" :key="row.id">
                  <td class="num">{{ row.res_date }}</td>
                  <td class="num">{{ row.start_time.slice(0, 5) }} - {{ row.end_time.slice(0, 5) }}</td>
                  <td class="ellip">{{ row.room_name }}</td>
                  <td class="ellip">{{ prefText(row) }}</td>
                  <td>
                    <b v-if="row.status === 'waiting'" class="position-num">第 {{ row.position }} 位</b>
                    <span v-else class="cell-dim">—</span>
                  </td>
                  <td>
                    <STag :type="statusMeta[row.status]?.type" dot :line="row.status === 'cancelled' || row.status === 'expired'">
                      {{ statusMeta[row.status]?.text || row.status }}
                    </STag>
                  </td>
                  <td>
                    <SButton v-if="row.status === 'waiting'" size="sm" variant="soft-danger" @click="doCancel(row)">
                      退出
                    </SButton>
                    <span v-else class="cell-dim">—</span>
                  </td>
                </tr>
              </tbody>
            </table>
            <SEmpty v-if="!filtered.length && !loading" description="当前分类下暂无候补记录" />
          </div>
        </div>
        <SPagination v-model="page" :pages="pages" :total="filtered.length" />
      </section>
    </div>
    </div>
  </div>
</template>

<style scoped>

.waitlist-table { min-width: 790px; }
.position-num {
  color: var(--amber-strong);
  font-variant-numeric: tabular-nums;
}
</style>
