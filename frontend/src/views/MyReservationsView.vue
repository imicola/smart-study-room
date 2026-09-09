<script setup>
import PageHelp from '../components/PageHelp.vue'
import SAnimatedNumber from '../components/ui/SAnimatedNumber.vue'
import { usePagination } from '../composables/usePagination'
import SPagination from '../components/ui/SPagination.vue'
import { ref, computed, onMounted } from 'vue'
import { message, confirmDialog } from '../components/ui/feedback'
import {
  listMyReservations, cancelReservation, checkinReservation,
  leaveReservation, returnReservation, checkoutReservation
} from '../api/reservation'
import AppIcon from '../components/AppIcon.vue'
import SButton from '../components/ui/SButton.vue'
import STag from '../components/ui/STag.vue'
import SEmpty from '../components/ui/SEmpty.vue'

const list = ref([])
const loading = ref(false)
const filterStatus = ref('all')

const statusMeta = {
  pending:     { text: '待签到',   type: 'warning' },
  checked_in:  { text: '使用中',   type: 'success' },
  temp_leave:  { text: '临时离开', type: 'info' },
  completed:   { text: '已完成',   type: '' },
  cancelled:   { text: '已取消',   type: 'info' },
  violation:   { text: '已违约',   type: 'danger' }
}
const sourceMeta = { manual: '手动选座', auto: '智能分配', waitlist: '候补递补' }

async function load() {
  loading.value = true
  try {
    const resp = await listMyReservations()
    list.value = resp.data || []
  } finally {
    loading.value = false
  }
}

const actionVariant = {
  primary: 'primary',
  danger: 'soft-danger',
  warning: 'soft-warn',
  success: 'soft-success',
  info: 'soft'
}

function actionsOf(r) {
  switch (r.status) {
    case 'pending':
      return [
        { key: 'checkin', label: '签到',     type: 'primary' },
        { key: 'cancel',  label: '取消预约', type: 'danger',  plain: true }
      ]
    case 'checked_in':
      return [
        { key: 'leave',    label: '临时离开', type: 'warning', plain: true },
        { key: 'checkout', label: '签退',     type: 'primary' }
      ]
    case 'temp_leave':
      return [
        { key: 'return',   label: '返回座位', type: 'success' },
        { key: 'checkout', label: '提前结束', type: 'info',    plain: true }
      ]
    default:
      return []
  }
}

const apiMap = {
  checkin: checkinReservation, cancel: cancelReservation, leave: leaveReservation,
  return: returnReservation, checkout: checkoutReservation
}
const actionText = {
  checkin: '签到', cancel: '取消', leave: '临时离开', return: '返回', checkout: '签退'
}

async function doAction(r, key) {
  if (key === 'cancel') {
    try {
      await confirmDialog(
        '距开始不足 30 分钟的取消将扣除 2 信用分，确认取消？',
        '取消预约', { confirmButtonText: '确认取消', type: 'warning' }
      )
    } catch { return }
  }
  await apiMap[key](r.id)
  message.success(actionText[key] + '成功')
  load()
}

// 左栏状态快筛
const statusBuckets = computed(() => {
  const b = { all: list.value.length, pending: 0, checked_in: 0, temp_leave: 0, completed: 0, violation: 0 }
  list.value.forEach((r) => { if (b[r.status] !== undefined) b[r.status]++ })
  return b
})
const filtered = computed(() => {
  if (filterStatus.value === 'all') return list.value
  return list.value.filter((r) => r.status === filterStatus.value)
})

const statusNav = [
  { key: 'all',        label: '全部',   icon: 'reservations' },
  { key: 'pending',    label: '待签到', icon: 'waitlist' },
  { key: 'checked_in', label: '使用中', icon: 'circle-success' },
  { key: 'temp_leave', label: '临离开', icon: 'walk' },
  { key: 'completed',  label: '已完成', icon: 'check' },
  { key: 'violation',  label: '已违约', icon: 'warning' }
]

onMounted(load)
const { page, pages, pageItems } = usePagination(filtered, filterStatus)
</script>

<template>
  <div v-reveal class="page-view">
    <header class="view-heading has-page-help"><div class="heading-copy" data-page-title>
      <h1>我的预约</h1>
      <p class="heading-sub">管理签到、临时离开与签退等预约全生命周期操作</p>
    </div><PageHelp title="操作说明">
        <ul class="tips">
          <li>开始前 <b>15 分钟</b> 内可签到</li>
          <li>临时离开时长超过 <b>20 分钟</b> 视为违约</li>
          <li>按期签退 <b>+1 分</b>；未签到违约 <b>-8 分</b></li>
        </ul>
      </PageHelp></header>
    <!-- 我的预约：页面级双栏 = 左状态筛选 | 右列表 -->
    <div class="split mine-split">
    <div class="split-left">
      <section class="card responsive-compact">
        <div class="card-title-row">
          <h3>预约概览</h3>
          <SButton size="sm" variant="secondary" @click="load"><AppIcon name="refresh" :size="14" />刷新</SButton>
        </div>
        <div class="kpi-grid kpi-lg">
          <div class="kpi"><div class="kpi-num"><SAnimatedNumber :value="statusBuckets.all" /></div><div class="kpi-label">累计预约</div></div>
          <div class="kpi kpi-warn"><div class="kpi-num"><SAnimatedNumber :value="statusBuckets.pending" /></div><div class="kpi-label">今日待签到</div></div>
          <div class="kpi kpi-ok"><div class="kpi-num">{{ statusBuckets.checked_in + statusBuckets.temp_leave }}</div><div class="kpi-label">当前进行中</div></div>
          <div class="kpi kpi-bad"><div class="kpi-num"><SAnimatedNumber :value="statusBuckets.violation" /></div><div class="kpi-label">违约记录</div></div>
        </div>
      </section>

      <section class="card responsive-compact">
        <div class="card-title-row">
          <h3>状态筛选</h3>
        </div>
        <nav v-active-track class="side-nav">
          <button
            v-for="s in statusNav"
            :key="s.key"
            class="side-nav-item"
            :class="{ active: filterStatus === s.key }"
            @click="filterStatus = s.key"
          >
            <span class="side-nav-icon"><AppIcon :name="s.icon" :size="16" /></span>
            <span class="side-nav-label">{{ s.label }}</span>
            <span class="side-nav-count">{{ statusBuckets[s.key] ?? 0 }}</span>
          </button>
        </nav>
      </section>

      
    </div>

    <div class="split-right">
      <section class="card">
        <div class="card-title-row">
          <h3>
            预约记录
            <span class="muted">共 {{ filtered.length }} 条</span>
          </h3>
        </div>

        <div v-list-motion="pageItems.map(row => row.id + row.status).join()" class="table-wrap">
          <div class="table-scroll" v-loading="loading" tabindex="0" aria-label="预约记录表格，可左右滑动">
            <table class="table mine-table">
              <thead>
                <tr>
                  <th style="width:106px">日期</th>
                  <th style="width:128px">时段</th>
                  <th style="min-width:118px">自习室</th>
                  <th style="width:64px">座位</th>
                  <th style="width:90px">来源</th>
                  <th style="width:96px">状态</th>
                  <th style="width:178px">操作</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="row in pageItems" :key="row.id">
                  <td class="num">{{ row.res_date }}</td>
                  <td class="num">{{ row.start_time.slice(0, 5) }} - {{ row.end_time.slice(0, 5) }}</td>
                  <td>{{ row.room_name }}</td>
                  <td class="cell-strong">{{ row.seat_no }}</td>
                  <td><STag>{{ sourceMeta[row.source] || row.source }}</STag></td>
                  <td>
                    <STag :type="statusMeta[row.status]?.type" dot :line="row.status === 'cancelled'">
                      {{ statusMeta[row.status]?.text || row.status }}
                    </STag>
                  </td>
                  <td>
                    <span class="row-actions">
                      <SButton
                        v-for="a in actionsOf(row)"
                        :key="a.key"
                        size="sm"
                        :variant="actionVariant[a.type]"
                        @click="doAction(row, a.key)"
                      >
                        {{ a.label }}
                      </SButton>
                      <span v-if="!actionsOf(row).length" class="cell-dim">—</span>
                    </span>
                  </td>
                </tr>
              </tbody>
            </table>
            <SEmpty v-if="!filtered.length && !loading" description="当前筛选条件下暂无预约记录" />
          </div>
        </div>
        <SPagination v-model="page" :pages="pages" :total="filtered.length" />
      </section>
    </div>
    </div>
  </div>
</template>

<style scoped>


.kpi-lg .kpi-num { font-size: 24px; }
.mine-table { min-width: 776px; }
.mine-table .row-actions {
  flex-wrap: nowrap;
  white-space: nowrap;
}
.mine-table td:nth-child(3) {
  max-width: 180px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
</style>
