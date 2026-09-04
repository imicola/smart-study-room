<script setup>
import { ref, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  listMyReservations, cancelReservation, checkinReservation,
  leaveReservation, returnReservation, checkoutReservation
} from '../api/reservation'
import AppIcon from '../components/AppIcon.vue'

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
      await ElMessageBox.confirm(
        '距开始不足 30 分钟的取消将扣除 2 信用分，确认取消？',
        '取消预约', { confirmButtonText: '确认取消', type: 'warning' }
      )
    } catch { return }
  }
  await apiMap[key](r.id)
  ElMessage.success(actionText[key] + '成功')
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
</script>

<template>
  <div class="page-view">
    <header class="view-heading" data-page-title><h1>我的预约</h1></header>
    <!-- 我的预约：页面级双栏 = 左状态筛选 | 右列表 -->
    <div class="split mine-split">
    <div class="split-left">
      <section class="card responsive-compact">
        <div class="card-title-row">
          <h3>预约概览</h3>
          <el-button size="small" @click="load"><AppIcon name="refresh" :size="15" />刷新</el-button>
        </div>
        <div class="kpi-grid kpi-lg">
          <div class="kpi"><div class="kpi-num">{{ statusBuckets.all }}</div><div class="kpi-label">累计预约</div></div>
          <div class="kpi kpi-warn"><div class="kpi-num">{{ statusBuckets.pending }}</div><div class="kpi-label">今日待签到</div></div>
          <div class="kpi kpi-ok"><div class="kpi-num">{{ statusBuckets.checked_in + statusBuckets.temp_leave }}</div><div class="kpi-label">当前进行中</div></div>
          <div class="kpi kpi-bad"><div class="kpi-num">{{ statusBuckets.violation }}</div><div class="kpi-label">违约记录</div></div>
        </div>
      </section>

      <section class="card responsive-compact">
        <div class="card-title-row">
          <h3>状态筛选</h3>
        </div>
        <div class="status-list">
          <button
            v-for="s in statusNav"
            :key="s.key"
            class="status-btn"
            :class="{ active: filterStatus === s.key }"
            @click="filterStatus = s.key"
          >
            <span class="status-icon"><AppIcon :name="s.icon" :size="17" /></span>
            <span class="status-label">{{ s.label }}</span>
            <span class="status-count">{{ statusBuckets[s.key] ?? 0 }}</span>
          </button>
        </div>
      </section>

      <section class="card tips-card responsive-compact">
        <h3>操作说明</h3>
        <ul class="tips">
          <li>开始前 <b>15 分钟</b> 内可签到</li>
          <li>临时离开时长超过 <b>20 分钟</b> 视为违约</li>
          <li>按期签退 <b>+1 分</b>；未签到违约 <b>-8 分</b></li>
        </ul>
      </section>
    </div>

    <div class="split-right">
      <section class="card">
        <div class="card-title-row">
          <h3>
            预约记录
            <span class="muted" style="font-weight:400; margin-left:8px">（共 {{ filtered.length }} 条）</span>
          </h3>
        </div>

        <div class="responsive-scroll" tabindex="0" aria-label="预约记录表格，可左右滑动">
        <el-table v-loading="loading" :data="filtered" stripe class="mine-table" max-height="560">
          <el-table-column label="日期" width="110">
            <template #default="{ row }">{{ row.res_date }}</template>
          </el-table-column>
          <el-table-column label="时段" width="130">
            <template #default="{ row }">{{ row.start_time.slice(0, 5) }} - {{ row.end_time.slice(0, 5) }}</template>
          </el-table-column>
          <el-table-column label="自习室" prop="room_name" min-width="130" />
          <el-table-column label="座位" width="80">
            <template #default="{ row }"><b>{{ row.seat_no }}</b></template>
          </el-table-column>
          <el-table-column label="来源" width="96">
            <template #default="{ row }">
              <el-tag size="small" effect="plain">{{ sourceMeta[row.source] || row.source }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column label="状态" width="98">
            <template #default="{ row }">
              <el-tag size="small" :type="statusMeta[row.status]?.type">
                {{ statusMeta[row.status]?.text || row.status }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column label="操作" min-width="230">
            <template #default="{ row }">
              <el-button
                v-for="a in actionsOf(row)"
                :key="a.key"
                size="small"
                :type="a.type"
                :plain="a.plain"
                @click="doAction(row, a.key)"
              >
                {{ a.label }}
              </el-button>
              <span v-if="!actionsOf(row).length" class="dim">—</span>
            </template>
          </el-table-column>
        </el-table>
        </div>

        <el-empty v-if="!filtered.length && !loading" description="当前筛选条件下暂无预约记录" />
      </section>
    </div>
    </div>
  </div>
</template>

<style scoped>
.mine-split { grid-template-columns: 300px 1fr; }

.kpi-lg .kpi-num { font-size: 24px; }
.kpi-warn .kpi-num { color: #d49a3a; }
.kpi-ok   .kpi-num { color: #5fa655; }
.kpi-bad  .kpi-num { color: #c86a6a; }

.status-list {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.status-btn {
  all: unset;
  cursor: pointer;
  display: grid;
  grid-template-columns: 24px 1fr auto;
  gap: 10px;
  align-items: center;
  padding: 9px 12px;
  border-radius: 10px;
  transition: background .15s ease;
}
.status-btn:hover { background: #eef2f8; }
.status-btn.active {
  background: linear-gradient(135deg, #cfdae8, #e3eaf4);
  color: #2f4462;
  font-weight: 600;
  box-shadow: inset 0 1px 0 #fff;
}
.status-icon { font-size: 15px; text-align: center; }
.status-label { font-size: 13.5px; color: #465065; }
.status-btn.active .status-label { color: #2f4462; }
.status-count {
  font-size: 12px;
  padding: 1px 8px;
  border-radius: 999px;
  background: #e5e9f0;
  color: #6b7280;
}
.status-btn.active .status-count {
  background: #fff;
  color: #456388;
}

.tips {
  margin: 0;
  padding-left: 18px;
  display: flex;
  flex-direction: column;
  gap: 6px;
  color: #4b5567;
  font-size: 13px;
  line-height: 1.6;
}
.tips b { color: #456388; font-weight: 600; }
.dim { color: #c0c4cc; }
.mine-table { min-width: 974px; }
</style>
