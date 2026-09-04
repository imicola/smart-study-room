<script setup>
import { ref, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { getRooms, getSeatMap } from '../api/room'
import { createReservation, autoAllocate } from '../api/reservation'
import { joinWaitlist } from '../api/waitlist'

// ---- 条件区状态 ----
const rooms = ref([])
const roomId = ref(null)
const date = ref(new Date().toISOString().slice(0, 10))
const start = ref('09:00')
const end = ref('12:00')

// 时间选项(30 分钟粒度)
const timeOptions = []
for (let h = 7; h <= 22; h++) {
  timeOptions.push(`${String(h).padStart(2, '0')}:00`)
  timeOptions.push(`${String(h).padStart(2, '0')}:30`)
}

// ---- 平面图 ----
const room = ref(null)
const seats = ref([])
const loading = ref(false)
const selected = ref(null)

const zoneName = { quiet: '静音区', regular: '普通区', discussion: '研讨区', computer: '机房区' }

async function loadRooms() {
  const resp = await getRooms()
  rooms.value = resp.data || []
  if (rooms.value.length && !roomId.value) {
    roomId.value = rooms.value[0].id
    loadSeatMap()
  }
}

async function loadSeatMap() {
  if (!roomId.value || !date.value || !start.value || !end.value) return
  if (start.value >= end.value) {
    ElMessage.warning('开始时间需早于结束时间')
    return
  }
  loading.value = true
  selected.value = null
  try {
    const resp = await getSeatMap(roomId.value, date.value, start.value, end.value)
    room.value = resp.data.room
    seats.value = resp.data.seats || []
  } finally {
    loading.value = false
  }
}

// 行列网格
const gridStyle = computed(() => ({
  display: 'grid',
  gridTemplateColumns: `repeat(${room.value?.seat_cols || 8}, 1fr)`,
  gap: '8px'
}))

function seatClass(s) {
  if (s.status !== 'available') return 'seat seat-disabled'
  if (s.occupied) return 'seat seat-occupied'
  if (selected.value?.id === s.id) return 'seat seat-selected'
  return 'seat seat-free'
}

function seatTip(s) {
  return `${s.seat_no} · ${zoneName[s.zone] || s.zone}${s.has_power ? ' · 电源' : ''}${s.near_window ? ' · 靠窗' : ''}${s.status !== 'available' ? ' · ' + (s.status === 'maintenance' ? '维护中' : '停用') : ''}`
}

function onSeatClick(s) {
  if (s.status !== 'available') {
    ElMessage.info(s.status === 'maintenance' ? '该座位维护中' : '该座位已停用')
    return
  }
  if (s.occupied) {
    ElMessage.info('该座位在所选时段已被占用')
    return
  }
  selected.value = s
}

async function confirmBooking() {
  const s = selected.value
  if (!s) return
  try {
    await ElMessageBox.confirm(
      `确认预约 ${room.value.name} ${s.seat_no} 座位？\n日期：${date.value}　时段：${start.value} - ${end.value}`,
      '预约确认',
      { confirmButtonText: '确认预约', cancelButtonText: '再想想' }
    )
  } catch {
    return
  }
  const resp = await createReservation({
    seat_id: s.id, date: date.value, start_time: start.value, end_time: end.value
  })
  ElMessage.success(`预约成功：${resp.data.room_name} ${resp.data.seat_no}`)
  selected.value = null
  loadSeatMap()
}

// ---- 智能分配 ----
const allocVisible = ref(false)
const allocForm = ref({ zone: '', need_power: false, need_window: false })
const recommendations = ref([])
const allocLoading = ref(false)

function openAlloc() {
  recommendations.value = []
  allocVisible.value = true
}

async function runAllocate(autoBook = false) {
  allocLoading.value = true
  try {
    const resp = await autoAllocate({
      room_id: roomId.value, date: date.value, start_time: start.value, end_time: end.value,
      zone: allocForm.value.zone || undefined,
      has_power: allocForm.value.need_power || undefined,
      near_window: allocForm.value.need_window || undefined,
      auto_book: autoBook
    })
    if (autoBook) {
      const r = resp.data.reservation
      ElMessage.success(`已为您分配：${r.room_name} ${r.seat_no}，请按时签到`)
      allocVisible.value = false
      loadSeatMap()
    } else {
      recommendations.value = resp.data.recommendations || []
      if (!recommendations.value.length) ElMessage.info('没有满足条件的推荐')
    }
  } catch (e) {
    if (String(e.message).includes('没有满足条件')) {
      try {
        await ElMessageBox.confirm('当前时段已满座，是否加入候补队列？', '满座提示', { type: 'info' })
        await joinWaitlist({
          room_id: roomId.value, date: date.value, start_time: start.value, end_time: end.value,
          zone: allocForm.value.zone || undefined
        })
        ElMessage.success('已加入候补队列，空出座位将自动递补并通知您')
        allocVisible.value = false
      } catch { /* 取消 */ }
    }
  } finally {
    allocLoading.value = false
  }
}

async function pickRecommended(rec) {
  const resp = await createReservation({
    seat_id: rec.seat.id, date: date.value, start_time: start.value, end_time: end.value
  })
  ElMessage.success(`预约成功：${resp.data.room_name} ${resp.data.seat_no}`)
  allocVisible.value = false
  loadSeatMap()
}

// 统计右栏实时数据
const seatStats = computed(() => {
  const total = seats.value.length
  if (!total) return { total: 0, free: 0, occ: 0, down: 0 }
  let occ = 0, down = 0
  seats.value.forEach((s) => {
    if (s.status !== 'available') down++
    else if (s.occupied) occ++
  })
  return { total, free: total - occ - down, occ, down }
})

onMounted(loadRooms)
</script>

<template>
  <!-- 座位预约：页面级双栏 = 左筛选 | 右座位图 -->
  <div class="split booking-split">
    <!-- 左栏：筛选 + 智能分配 + 统计 + 图例 -->
    <div class="split-left">
      <section class="card">
        <div class="card-title-row">
          <h3>预约条件</h3>
        </div>
        <div class="filter-group">
          <div class="filter-row">
            <label>自习室</label>
            <el-select v-model="roomId" @change="loadSeatMap">
              <el-option v-for="r in rooms" :key="r.id" :label="r.name" :value="r.id" />
            </el-select>
          </div>
          <div class="filter-row">
            <label>日期</label>
            <el-date-picker
              v-model="date" type="date" value-format="YYYY-MM-DD"
              :disabled-date="(d) => d.getTime() < Date.now() - 86400000"
              @change="loadSeatMap"
            />
          </div>
          <div class="filter-row">
            <label>时段</label>
            <div class="time-pair">
              <el-select v-model="start" @change="loadSeatMap">
                <el-option v-for="t in timeOptions" :key="t" :label="t" :value="t" />
              </el-select>
              <span class="arrow">→</span>
              <el-select v-model="end" @change="loadSeatMap">
                <el-option v-for="t in timeOptions" :key="t" :label="t" :value="t" />
              </el-select>
            </div>
            <div class="filter-hint">默认 30 分钟粒度；开始时间必须早于结束时间。</div>
          </div>
        </div>
      </section>

      <section class="card">
        <div class="card-title-row">
          <h3>实时数据</h3>
        </div>
        <div class="kpi-grid">
          <div class="kpi">
            <div class="kpi-num">{{ seatStats.total }}</div>
            <div class="kpi-label">座位总数</div>
          </div>
          <div class="kpi kpi-free">
            <div class="kpi-num">{{ seatStats.free }}</div>
            <div class="kpi-label">当前空闲</div>
          </div>
          <div class="kpi kpi-occ">
            <div class="kpi-num">{{ seatStats.occ }}</div>
            <div class="kpi-label">时段内占用</div>
          </div>
          <div class="kpi kpi-down">
            <div class="kpi-num">{{ seatStats.down }}</div>
            <div class="kpi-label">维护/停用</div>
          </div>
        </div>
      </section>

      <section class="card">
        <div class="card-title-row">
          <h3>快捷操作</h3>
        </div>
        <div class="actions">
          <el-button type="primary" class="action-btn" @click="openAlloc">
            ✨ 智能分配
          </el-button>
          <el-button class="action-btn" @click="loadSeatMap">🔄 刷新座位图</el-button>
        </div>
        <div class="legend">
          <div class="legend-item"><span class="dot dot-free" /><span>空闲（可预约）</span></div>
          <div class="legend-item"><span class="dot dot-selected" /><span>已选中</span></div>
          <div class="legend-item"><span class="dot dot-occupied" /><span>占用</span></div>
          <div class="legend-item"><span class="dot dot-disabled" /><span>维护/停用</span></div>
        </div>
      </section>
    </div>

    <!-- 右栏：座位平面图 + 已选条 -->
    <div class="split-right">
      <section class="card seat-card">
        <div class="card-title-row">
          <div>
            <h3 style="margin:0">座位平面图</h3>
            <div v-if="room" class="room-meta muted">
              {{ room.name }} · {{ room.location }} · 开放 {{ room.open_time?.slice(0, 5) }}–{{ room.close_time?.slice(0, 5) }} · {{ room.seat_rows }}×{{ room.seat_cols }}
            </div>
          </div>
        </div>

        <div v-loading="loading" class="seat-grid-wrap">
          <div v-if="!room" class="empty-tip muted">请先在左侧选择自习室并设置预约条件</div>
          <div v-else :style="gridStyle" class="seat-grid">
            <el-tooltip v-for="s in seats" :key="s.id" :content="seatTip(s)" placement="top">
              <div :class="seatClass(s)" @click="onSeatClick(s)">
                {{ s.seat_no }}
              </div>
            </el-tooltip>
          </div>
        </div>
      </section>

      <!-- 已选座位操作条 -->
      <section v-if="selected" class="card selected-card">
        <div class="sel-info">
          <div class="sel-icon">🪑</div>
          <div>
            <div class="sel-title">
              已选择 <b>{{ selected.seat_no }}</b>
              <el-tag size="small" effect="plain">{{ zoneName[selected.zone] || selected.zone }}</el-tag>
              <el-tag v-if="selected.has_power" size="small" type="success" effect="plain">电源</el-tag>
              <el-tag v-if="selected.near_window" size="small" type="warning" effect="plain">靠窗</el-tag>
            </div>
            <div class="muted">{{ date.value }} · {{ start }} – {{ end }} · {{ room?.name }}</div>
          </div>
        </div>
        <el-button type="primary" size="large" @click="confirmBooking">提交预约</el-button>
      </section>
    </div>
  </div>

  <!-- 智能分配对话框（沿用） -->
  <el-dialog v-model="allocVisible" title="智能分配座位" width="520px">
    <div class="alloc-form">
      <div class="filter-row">
        <label>偏好区域</label>
        <el-select v-model="allocForm.zone" placeholder="不限（推荐）" clearable>
          <el-option label="静音区" value="quiet" />
          <el-option label="普通区" value="regular" />
          <el-option label="研讨区" value="discussion" />
          <el-option label="机房区" value="computer" />
        </el-select>
      </div>
      <div class="pref-checks">
        <el-checkbox v-model="allocForm.need_power">需要电源插座</el-checkbox>
        <el-checkbox v-model="allocForm.need_window">偏好靠窗</el-checkbox>
      </div>
    </div>

    <div v-if="recommendations.length" class="rec-title">推荐座位（评分从高到低）</div>
    <div v-if="recommendations.length" class="rec-list">
      <div v-for="(r, i) in recommendations" :key="r.seat.id" class="rec-item">
        <div class="rec-rank">{{ i + 1 }}</div>
        <div>
          <div class="rec-seat">
            <b>{{ r.seat.seat_no }}</b>
            <el-tag size="small" effect="plain">{{ zoneName[r.seat.zone] || r.seat.zone }}</el-tag>
            <span v-if="r.seat.has_power" class="muted">· 电源</span>
            <span v-if="r.seat.near_window" class="muted">· 靠窗</span>
          </div>
          <div class="muted rec-score">匹配得分 {{ r.score.toFixed(1) }}</div>
        </div>
        <el-button size="small" type="primary" @click="pickRecommended(r)">选这个预约</el-button>
      </div>
    </div>

    <template #footer>
      <div style="display:flex; justify-content:space-between; align-items:center">
        <el-button :loading="allocLoading" @click="runAllocate(false)">👀 仅推荐</el-button>
        <el-button type="primary" :loading="allocLoading" @click="runAllocate(true)">
          ✨ 立即分配并下单
        </el-button>
      </div>
    </template>
  </el-dialog>
</template>

<style scoped>
.booking-split {
  grid-template-columns: 320px 1fr;
  align-items: start;
}

/* 时段选择并排 */
.time-pair {
  display: grid;
  grid-template-columns: 1fr 20px 1fr;
  gap: 6px;
  align-items: center;
}
.time-pair .arrow {
  text-align: center;
  color: #a2abb9;
}

.actions {
  display: flex;
  flex-direction: column;
  gap: 10px;
  margin-bottom: 14px;
}
.action-btn { width: 100%; }

.legend {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 8px 12px;
  padding-top: 10px;
  border-top: 1px dashed #e5e9f0;
}
.legend-item {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12.5px;
  color: #5b6576;
}
.dot {
  width: 16px; height: 16px; border-radius: 5px; display: inline-block;
}
.dot-free { background: #a7d7a0; }
.dot-selected { background: #456388; box-shadow: 0 0 0 3px #cfdae8; }
.dot-occupied { background: #e5a1a1; }
.dot-disabled { background: #cfd5df; }

/* KPI 色偏 */
.kpi-free .kpi-num { color: #5fa655; }
.kpi-occ  .kpi-num { color: #c86a6a; }
.kpi-down .kpi-num { color: #828c9d; }

/* 座位图 */
.seat-card {
  min-height: 0;
}
.room-meta {
  margin-top: 2px;
}
.seat-grid-wrap {
  margin-top: 8px;
  padding: 18px;
  background: linear-gradient(150deg, #f6f8fb, #eef2f8);
  border: 1px solid #eef1f6;
  border-radius: 12px;
  min-height: 280px;
  display: grid;
  place-items: start center;
}
.empty-tip {
  padding: 60px 0;
  font-size: 14px;
}
.seat-grid {
  width: 100%;
  max-width: 640px;
  padding: 14px;
  background: #ffffffcc;
  border-radius: 10px;
}
.seat {
  aspect-ratio: 1 / 1;
  border-radius: 8px;
  display: grid;
  place-items: center;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  transition: transform .12s ease, box-shadow .12s ease;
  user-select: none;
  border: 1px solid transparent;
}
.seat:hover {
  transform: translateY(-1px);
}
.seat-free {
  background: #cae7c3;
  color: #355d31;
  border-color: #b4dba9;
}
.seat-free:hover { background: #b9dfb0; }
.seat-selected {
  background: #456388;
  color: #fff;
  border-color: #355074;
  box-shadow: 0 0 0 3px #cfdae8, 0 6px 14px rgba(69,99,136,.28);
}
.seat-occupied {
  background: #f1c4c4;
  color: #7a3636;
  border-color: #e3aaaa;
  cursor: not-allowed;
}
.seat-disabled {
  background: #e2e6ec;
  color: #8d97a8;
  border-color: #d4dae3;
  cursor: not-allowed;
  text-decoration: line-through;
}

/* 已选条 */
.selected-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  background: linear-gradient(135deg, #eef3f9, #dde7f4);
}
.sel-info {
  display: flex;
  align-items: center;
  gap: 14px;
}
.sel-icon {
  width: 48px; height: 48px; border-radius: 14px;
  background: #fff;
  display: grid; place-items: center;
  font-size: 22px;
  box-shadow: 0 2px 6px rgba(108,128,160,.08);
}
.sel-title {
  font-size: 15px;
  font-weight: 600;
  color: #2b3240;
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 2px;
}

/* 智能分配弹窗内 */
.alloc-form {
  display: flex;
  flex-direction: column;
  gap: 14px;
}
.pref-checks {
  display: flex;
  gap: 16px;
}
.rec-title {
  margin: 18px 0 8px;
  font-weight: 600;
  color: #456388;
  font-size: 13px;
}
.rec-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
  max-height: 260px;
  overflow: auto;
}
.rec-item {
  display: grid;
  grid-template-columns: 36px 1fr auto;
  gap: 12px;
  align-items: center;
  padding: 10px 12px;
  border-radius: 10px;
  background: #f6f8fb;
  border: 1px solid #eef1f6;
}
.rec-rank {
  width: 30px; height: 30px; border-radius: 8px;
  background: linear-gradient(145deg, #8ea6c4, #5f7ea3);
  color: #fff;
  display: grid; place-items: center;
  font-weight: 700;
}
.rec-seat {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 14px;
}
.rec-score {
  margin-top: 2px;
  font-size: 12px;
}
</style>
