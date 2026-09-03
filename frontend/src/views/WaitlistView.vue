<script setup>
<<<<<<< HEAD
import { ref, onMounted } from 'vue'
=======
import { ref, computed, onMounted } from 'vue'
>>>>>>> 958d510 (chore: init smart-study-room with ui redesign)
import { ElMessage, ElMessageBox } from 'element-plus'
import { listMyWaitlist, cancelWaitlist } from '../api/waitlist'

const list = ref([])
const loading = ref(false)
<<<<<<< HEAD

const statusMeta = {
  waiting: { text: '排队中', type: 'warning' },
  promoted: { text: '已递补', type: 'success' },
  cancelled: { text: '已取消', type: 'info' },
  expired: { text: '已过期', type: 'info' }
=======
const filterStatus = ref('all')

const statusMeta = {
  waiting:   { text: '排队中', type: 'warning' },
  promoted:  { text: '已递补', type: 'success' },
  cancelled: { text: '已取消', type: 'info' },
  expired:   { text: '已过期', type: 'info' }
>>>>>>> 958d510 (chore: init smart-study-room with ui redesign)
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
    await ElMessageBox.confirm('确认退出该场次候补队列？', '取消候补', { type: 'warning' })
  } catch { return }
  await cancelWaitlist(row.id)
  ElMessage.success('已退出候补')
  load()
}

function prefText(row) {
  const ps = []
  if (row.zone) ps.push(zoneName[row.zone] || row.zone)
  if (row.has_power) ps.push('电源')
  if (row.near_window) ps.push('靠窗')
  return ps.length ? ps.join(' / ') : '不限'
}

<<<<<<< HEAD
=======
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
  { key: 'all',       label: '全部候补', icon: '⏳' },
  { key: 'waiting',   label: '排队中',   icon: '🟡' },
  { key: 'promoted',  label: '已递补',   icon: '🟢' },
  { key: 'expired',   label: '已过期',   icon: '⛔' },
  { key: 'cancelled', label: '已取消',   icon: '↩️' }
]

>>>>>>> 958d510 (chore: init smart-study-room with ui redesign)
onMounted(load)
</script>

<template>
<<<<<<< HEAD
  <div class="page-card">
    <div class="head">
      <h2 style="margin: 0">我的候补</h2>
      <el-button @click="load">刷新</el-button>
    </div>
    <el-alert type="info" :closable="false" style="margin-bottom: 12px"
      title="满座时段提交候补后，系统会在空位释放时自动按排队顺序递补，并通过站内消息通知您。" />

    <el-table v-loading="loading" :data="list" stripe>
      <el-table-column label="日期" width="110">
        <template #default="{ row }">{{ row.res_date }}</template>
      </el-table-column>
      <el-table-column label="时段" width="130">
        <template #default="{ row }">{{ row.start_time.slice(0, 5) }} - {{ row.end_time.slice(0, 5) }}</template>
      </el-table-column>
      <el-table-column label="自习室" prop="room_name" min-width="130" />
      <el-table-column label="偏好" min-width="120">
        <template #default="{ row }">{{ prefText(row) }}</template>
      </el-table-column>
      <el-table-column label="排队位次" width="90">
        <template #default="{ row }">
          <b v-if="row.status === 'waiting'">第 {{ row.position }} 位</b>
          <span v-else>—</span>
        </template>
      </el-table-column>
      <el-table-column label="状态" width="90">
        <template #default="{ row }">
          <el-tag size="small" :type="statusMeta[row.status]?.type">
            {{ statusMeta[row.status]?.text || row.status }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="100">
        <template #default="{ row }">
          <el-button v-if="row.status === 'waiting'" size="small" type="danger" plain @click="doCancel(row)">
            退出
          </el-button>
          <span v-else class="dim">—</span>
        </template>
      </el-table-column>
    </el-table>
=======
  <div class="split wl-split">
    <div class="split-left">
      <section class="card">
        <div class="card-title-row"><h3>候补概览</h3><el-button size="small" @click="load">🔄 刷新</el-button></div>
        <div class="kpi-grid">
          <div class="kpi"><div class="kpi-num">{{ buckets.all }}</div><div class="kpi-label">历史候补</div></div>
          <div class="kpi kpi-warn"><div class="kpi-num">{{ buckets.waiting }}</div><div class="kpi-label">正在排队</div></div>
          <div class="kpi kpi-ok"><div class="kpi-num">{{ buckets.promoted }}</div><div class="kpi-label">成功递补</div></div>
          <div class="kpi"><div class="kpi-num">{{ buckets.expired }}</div><div class="kpi-label">已过期</div></div>
        </div>
      </section>

      <section class="card">
        <div class="card-title-row"><h3>状态分类</h3></div>
        <div class="nav-list">
          <button
            v-for="n in nav"
            :key="n.key"
            class="nav-btn"
            :class="{ active: filterStatus === n.key }"
            @click="filterStatus = n.key"
          >
            <span class="nav-icon">{{ n.icon }}</span>
            <span class="nav-label">{{ n.label }}</span>
            <span class="nav-count">{{ buckets[n.key] ?? 0 }}</span>
          </button>
        </div>
      </section>

      <section class="card">
        <h3>候补机制</h3>
        <ul class="tips">
          <li>提交候补时，系统会按<b>时间优先</b>记录位次</li>
          <li>空位产生后，按位次自动递补并发送<b>站内消息</b>通知</li>
          <li>若递补成功后 5 分钟内未确认，顺位自动取消</li>
          <li>排队过程中可随时退出候补，无信用分影响</li>
        </ul>
      </section>
    </div>

    <div class="split-right">
      <section class="card">
        <div class="card-title-row">
          <h3>候补记录 <span class="muted" style="font-weight:400;margin-left:8px">（共 {{ filtered.length }} 条）</span></h3>
        </div>
        <el-alert type="info" :closable="false" style="margin-bottom: 14px"
          title="满座时段提交候补后，系统会在空位释放时自动按排队顺序递补，并通过站内消息通知您。" />

        <el-table v-loading="loading" :data="filtered" stripe>
          <el-table-column label="日期" width="110">
            <template #default="{ row }">{{ row.res_date }}</template>
          </el-table-column>
          <el-table-column label="时段" width="130">
            <template #default="{ row }">{{ row.start_time.slice(0, 5) }} - {{ row.end_time.slice(0, 5) }}</template>
          </el-table-column>
          <el-table-column label="自习室" prop="room_name" min-width="130" />
          <el-table-column label="偏好" min-width="120">
            <template #default="{ row }">{{ prefText(row) }}</template>
          </el-table-column>
          <el-table-column label="排队位次" width="100">
            <template #default="{ row }">
              <b v-if="row.status === 'waiting'">第 {{ row.position }} 位</b>
              <span v-else class="dim">—</span>
            </template>
          </el-table-column>
          <el-table-column label="状态" width="98">
            <template #default="{ row }">
              <el-tag size="small" :type="statusMeta[row.status]?.type">
                {{ statusMeta[row.status]?.text || row.status }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="100">
            <template #default="{ row }">
              <el-button v-if="row.status === 'waiting'" size="small" type="danger" plain @click="doCancel(row)">
                退出
              </el-button>
              <span v-else class="dim">—</span>
            </template>
          </el-table-column>
        </el-table>
        <el-empty v-if="!filtered.length && !loading" description="当前分类下暂无候补记录" />
      </section>
    </div>
>>>>>>> 958d510 (chore: init smart-study-room with ui redesign)
  </div>
</template>

<style scoped>
<<<<<<< HEAD
.head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 14px;
}
.dim {
  color: #c0c4cc;
}
=======
.wl-split { grid-template-columns: 300px 1fr; }
.kpi-warn .kpi-num { color: #d49a3a; }
.kpi-ok   .kpi-num { color: #5fa655; }

.nav-list {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.nav-btn {
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

.tips {
  margin: 0; padding-left: 18px;
  display: flex; flex-direction: column; gap: 6px;
  color: #4b5567; font-size: 13px; line-height: 1.6;
}
.tips b { color: #456388; font-weight: 600; }
.dim { color: #c0c4cc; }
>>>>>>> 958d510 (chore: init smart-study-room with ui redesign)
</style>
