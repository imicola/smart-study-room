<script setup>
import SAnimatedNumber from '../components/ui/SAnimatedNumber.vue'
import { ref, computed, onMounted } from 'vue'
import SeatExplorer from '../components/seat3d/SeatExplorer.vue'
import SeatPlanDesk from '../components/SeatPlanDesk.vue'
import { seatType, zoneName, getWindowSides } from '../components/seat3d/seatPresentation'
import { message, confirmDialog } from '../components/ui/feedback'
import { getRooms, getSeatMap } from '../api/room'
import { createReservation, autoAllocate } from '../api/reservation'
import { joinWaitlist } from '../api/waitlist'
import AppIcon from '../components/AppIcon.vue'
import SButton from '../components/ui/SButton.vue'
import SSelect from '../components/ui/SSelect.vue'
import SDatePicker from '../components/ui/SDatePicker.vue'
import SCheckbox from '../components/ui/SCheckbox.vue'
import SDialog from '../components/ui/SDialog.vue'
import STag from '../components/ui/STag.vue'

// ---- 条件区状态 ----
const rooms = ref([])
const roomId = ref(null)
const date = ref(new Date().toISOString().slice(0, 10))
const start = ref('09:00')
const end = ref('12:00')

// 时间选项(30 分钟粒度)
const timeOptions = []
for (let h = 7; h <= 22; h++) {
  timeOptions.push({ label: `${String(h).padStart(2, '0')}:00`, value: `${String(h).padStart(2, '0')}:00` })
  timeOptions.push({ label: `${String(h).padStart(2, '0')}:30`, value: `${String(h).padStart(2, '0')}:30` })
}

// ---- 平面图 ----
const room = ref(null)
const seats = ref([])
const loading = ref(false)
const selected = ref(null)

const seatCard = ref(null)
const explorer = ref(null)
const show3D = ref(false)
const submitting = ref(false)
const mapError = ref(false)
let mapRequest = 0
function open3D() {
  if (!room.value || loading.value || mapError.value || !seats.value.length) return
  hoverTip.value = null
  show3D.value = true
}

async function loadRooms() {
  const resp = await getRooms()
  rooms.value = resp.data || []
  if (rooms.value.length && !roomId.value) {
    roomId.value = rooms.value[0].id
    loadSeatMap()
  }
}

async function loadSeatMap(preserveSelection = false) {
  const requestId = ++mapRequest
  if (!roomId.value || !date.value || !start.value || !end.value) return
  if (start.value >= end.value) {
    mapError.value = true
    selected.value = null
    loading.value = false
    message.warning('开始时间需早于结束时间')
    return
  }
  loading.value = true
  mapError.value = false
  const previousId = preserveSelection === true ? selected.value?.id : null
  selected.value = null
  try {
    const resp = await getSeatMap(roomId.value, date.value, start.value, end.value)
    if (requestId !== mapRequest) return
    room.value = resp.data.room
    seats.value = resp.data.seats || []
    if (previousId) {
      selected.value = seats.value.find(s => s.id === previousId && s.status === 'available' && !s.occupied) || null
      if (!selected.value) message.info('该座位状态已变化，请重新选择')
    }
  } catch {
    if (requestId === mapRequest) { mapError.value = true; selected.value = null; seats.value = [] }
  } finally {
    if (requestId === mapRequest) loading.value = false
  }
}

// 行列网格（座位区）
const gridStyle = computed(() => ({
  gridTemplateColumns: `repeat(${room.value?.seat_cols || 8}, minmax(76px, 1fr))`,
  gap: '10px'
}))

// 房间框架（墙/窗包裹座位区），最小宽度保证小容器可横向滚动
const frameStyle = computed(() => {
  const cols = room.value?.seat_cols || 8
  const contentMin = cols * 76 + (cols - 1) * 10 + 24 + 36
  return { minWidth: `${Math.max(480, contentMin)}px` }
})

// 靠窗方位：某条边只有当其全部座位连续靠窗时才判定为窗（避免角落座位误判两条边）
const windowSides = computed(() => getWindowSides(room.value, seats.value))

// 靠窗座位旁的窗条方向：仅在该侧边确认为窗时渲染
function nearWindowSide(s) {
  const sides = windowSides.value
  const rows = room.value?.seat_rows || 0
  const cols = room.value?.seat_cols || 0
  if (sides.right && s.col_no === cols) return 'seat-near-window-right'
  if (sides.left && s.col_no === 1) return 'seat-near-window-left'
  if (sides.top && s.row_no === 1) return 'seat-near-window-top'
  if (sides.bottom && s.row_no === rows) return 'seat-near-window-bottom'
  return ''
}

function seatClass(s) {
  let cls
  if (s.status !== 'available') cls = 'seat seat-disabled'
  else if (s.occupied) cls = 'seat seat-occupied'
  else if (selected.value?.id === s.id) cls = 'seat seat-selected'
  else cls = 'seat seat-free'
  if (s.near_window) {
    const side = nearWindowSide(s)
    if (side) cls += ' ' + side
  }
  return cls
}

function seatTip(s) {
  return `${s.seat_no} · ${seatType(s)} · ${zoneName[s.zone] || s.zone}${s.near_window ? ' · 靠窗' : ''}${s.status !== 'available' ? ' · ' + (s.status === 'maintenance' ? '维护中' : '停用') : ''}`
}

// 座位悬浮提示（共享单例，fixed 定位避免被滚动容器裁剪）
const hoverTip = ref(null)
function onGridOver(e) {
  const seatEl = e.target.closest('.seat')
  if (!seatEl) return
  const s = seats.value.find((x) => String(x.id) === seatEl.dataset.id)
  if (!s) return
  const rect = seatEl.getBoundingClientRect()
  hoverTip.value = {
    text: seatTip(s),
    x: Math.min(Math.max(rect.left + rect.width / 2, 90), window.innerWidth - 90),
    y: rect.top
  }
}
function onGridLeave() {
  hoverTip.value = null
}

function onSeatClick(s) {
  if (loading.value || mapError.value || submitting.value) return
  if (s.status !== 'available') {
    message.info(s.status === 'maintenance' ? '该座位维护中' : '该座位已停用')
    return
  }
  if (s.occupied) {
    message.info('该座位在所选时段已被占用')
    return
  }
  selected.value = s
}

async function confirmBooking() {
  const s = selected.value
  if (!s || submitting.value || loading.value || mapError.value || s.status !== 'available' || s.occupied) return
  const payload = { seat_id: s.id, date: date.value, start_time: start.value, end_time: end.value }
  submitting.value = true
  try {
    try {
    await confirmDialog(
      `确认预约 ${room.value.name} ${s.seat_no} 座位？\n日期：${payload.date}　时段：${payload.start_time} - ${payload.end_time}`,
      '预约确认',
      { confirmButtonText: '确认预约', cancelButtonText: '再想想' }
    )
    } catch { return }
    try {
      const resp = await createReservation(payload)
      message.success(`预约成功：${resp.data.room_name} ${resp.data.seat_no}`)
    } catch {
      await loadSeatMap(true)
      return
    }
    selected.value = null
    await loadSeatMap()
    explorer.value?.close()
  } finally { submitting.value = false }
}

// ---- 智能分配 ----
const allocVisible = ref(false)
const allocForm = ref({ zone: '', need_power: false, need_window: false })
const recommendations = ref([])
const allocLoading = ref(false)

const zoneOptions = [
  { label: '静音区', value: 'quiet' },
  { label: '普通区', value: 'regular' },
  { label: '研讨区', value: 'discussion' },
  { label: '机房区', value: 'computer' }
]

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
      message.success(`已为您分配：${r.room_name} ${r.seat_no}，请按时签到`)
      allocVisible.value = false
      loadSeatMap()
    } else {
      recommendations.value = resp.data.recommendations || []
      if (!recommendations.value.length) message.info('没有满足条件的推荐')
    }
  } catch (e) {
    if (String(e.message).includes('没有满足条件')) {
      try {
        await confirmDialog('当前时段已满座，是否加入候补队列？', '满座提示', { type: 'info' })
        await joinWaitlist({
          room_id: roomId.value, date: date.value, start_time: start.value, end_time: end.value,
          zone: allocForm.value.zone || undefined
        })
        message.success('已加入候补队列，空出座位将自动递补并通知您')
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
  message.success(`预约成功：${resp.data.room_name} ${resp.data.seat_no}`)
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
  <div v-reveal class="page-view">
    <header class="view-heading" data-page-title>
      <h1>座位预约</h1>
      <p class="heading-sub">选择自习室与时段，点击平面图中的座位提交预约</p>
    </header>
    <!-- 预约条件、紧凑信息条、座位图 -->
    <div class="split booking-split">
    <!-- 筛选与统计操作区 -->
    <div class="split-left">
      <section class="card responsive-compact">
        <div class="card-title-row">
          <h3>预约条件</h3>
        </div>
        <div class="filter-group">
          <div class="filter-row">
            <label>自习室</label>
            <SSelect v-model="roomId" :options="rooms" label-key="name" value-key="id" @change="loadSeatMap" />
          </div>
          <div class="filter-row">
            <label>日期</label>
            <SDatePicker
              v-model="date"
              :disabled-date="(d) => d.getTime() < Date.now() - 86400000"
              @change="loadSeatMap"
            />
          </div>
          <div class="filter-row">
            <label>时段</label>
            <div class="time-pair">
              <SSelect v-model="start" :options="timeOptions" @change="loadSeatMap" />
              <span class="arrow">→</span>
              <SSelect v-model="end" :options="timeOptions" @change="loadSeatMap" />
            </div>
            <div class="filter-hint">默认 30 分钟粒度，开始需早于结束</div>
          </div>
        </div>
      </section>

      <section class="card booking-summary" aria-label="座位统计、图例与快捷操作">
        <div class="booking-counts" aria-label="座位数量统计">
        <div class="kpi-grid">
          <div class="kpi">
            <div class="kpi-num"><SAnimatedNumber :value="seatStats.total" /></div>
            <div class="kpi-label">座位总数</div>
          </div>
          <div class="kpi kpi-ok">
            <div class="kpi-num"><SAnimatedNumber :value="seatStats.free" /></div>
            <div class="kpi-label">当前空闲</div>
          </div>
          <div class="kpi kpi-bad">
            <div class="kpi-num"><SAnimatedNumber :value="seatStats.occ" /></div>
            <div class="kpi-label">时段内占用</div>
          </div>
          <div class="kpi">
            <div class="kpi-num"><SAnimatedNumber :value="seatStats.down" /></div>
            <div class="kpi-label">维护/停用</div>
          </div>
        </div>
        </div>
        <div class="booking-legends" aria-label="座位类型与状态图例">
<div class="legend">
          <div class="legend-item"><span class="type-ico"><AppIcon name="desk-book" :size="16" /></span><span>普通桌</span></div>
          <div class="legend-item"><span class="type-ico"><AppIcon name="desk-power" :size="16" /></span><span>插座桌</span></div>
          <div class="legend-item"><span class="type-ico"><AppIcon name="desk-pc" :size="16" /></span><span>电脑桌</span></div>
          <div class="legend-item"><span class="type-ico type-ico--window" /><span>窗户</span></div>
        </div>
        <div class="legend legend--status">
          <div class="legend-item"><span class="dot dot-free" /><span>可预约</span></div>
          <div class="legend-item"><span class="dot dot-selected" /><span>已选中</span></div>
          <div class="legend-item"><span class="dot dot-occupied" /><span>占用</span></div>
          <div class="legend-item"><span class="dot dot-disabled" /><span>维护/停用</span></div>
        </div>
        </div>
<div class="booking-actions">
          <SButton variant="primary" block @click="openAlloc">
            <AppIcon name="sparkles" :size="16" />智能分配
          </SButton>
          <SButton variant="secondary" block @click="loadSeatMap">
            <AppIcon name="refresh" :size="16" />刷新座位图
          </SButton>
        </div>
      </section>
    </div>

    <!-- 右栏：座位平面图 + 已选条 -->
    <div class="split-right">
      <section ref="seatCard" class="card seat-card">
        <div class="card-title-row">
          <div class="seat-heading">
            <h3 style="margin:0">座位平面图</h3>
            <div class="seat-head-tools">
              <SSelect v-if="room" v-model="roomId" class="room-select" :options="rooms" label-key="name" value-key="id" aria-label="选择自习室" @change="loadSeatMap" />
              <div v-if="room" class="room-chip">
                <span class="room-chip__meta">{{ room.location }} · 开放 {{ room.open_time?.slice(0, 5) }}–{{ room.close_time?.slice(0, 5) }} · {{ room.seat_rows }}×{{ room.seat_cols }}</span>
              </div>
            </div>
            <SButton :disabled="!room || loading || mapError || !seats.length" aria-label="打开 3D 选座" @click="open3D">3D</SButton>
          </div>
        </div>

        <div class="responsive-scroll" tabindex="0" aria-label="座位平面图，可左右滑动">
        <div v-loading="loading" class="seat-grid-wrap" @mouseover="onGridOver" @mouseleave="onGridLeave">
          <div v-if="!room" class="empty-tip muted">请先选择自习室并设置预约条件</div>
          <div v-else :style="frameStyle" class="room-frame">
            <!-- 顶部：窗或墙 -->
            <div class="wall wall-top" :class="{ window: windowSides.top }" aria-hidden="true"></div>
            <!-- 左：窗或墙 -->
            <div class="wall wall-left" :class="{ window: windowSides.left }" aria-hidden="true"></div>
            <!-- 座位网格 -->
            <div :style="gridStyle" class="seat-grid">
              <button
                v-for="s in seats"
                :key="s.id"
                :class="seatClass(s)"
                :data-id="s.id"
                type="button"
                :style="{ gridRow: s.row_no, gridColumn: s.col_no }"
                :aria-label="seatTip(s)"
                :aria-pressed="selected?.id === s.id"
                :aria-disabled="s.status !== 'available' || s.occupied || loading || submitting"
                @click="onSeatClick(s)"
              >
                <SeatPlanDesk :computer="s.zone === 'computer'" :power="s.has_power" />
                <span class="seat-no">{{ s.seat_no }}</span>
              </button>
            </div>
            <!-- 右：窗或墙 -->
            <div class="wall wall-right" :class="{ window: windowSides.right }" aria-hidden="true"></div>
            <!-- 底部：窗或墙（有门时底部为墙） -->
            <div class="wall wall-bottom" :class="{ window: windowSides.bottom }">
              <template v-if="!windowSides.bottom">
                <span class="wall-seg" aria-hidden="true"></span>
                <span class="door" aria-hidden="true"></span>
                <span class="wall-seg" aria-hidden="true"></span>
              </template>
            </div>
          </div>
        </div>
        </div>
      </section>

      <!-- 已选座位操作条（常驻可见：未选座位时为提示态，提交按钮禁用） -->
      <section class="card selected-card" :class="{ 'selected-card--empty': !selected }">
        <div class="sel-info">
          <div class="sel-icon"><AppIcon name="seat" :size="25" /></div>
          <div class="sel-detail" :key="selected?.id || 'empty'">
            <template v-if="selected">
              <div class="sel-title">
                已选择 <b>{{ selected.seat_no }}</b>
                <STag>{{ zoneName[selected.zone] || selected.zone }}</STag>
                <STag v-if="selected.has_power" type="success">电源</STag>
                <STag v-if="selected.near_window" type="warning">靠窗</STag>
              </div>
              <div class="muted">{{ date }} · {{ start }} – {{ end }} · {{ room?.name }}</div>
            </template>
            <template v-else>
              <div class="sel-placeholder">请选择座位</div>
              <div class="muted">点击座位平面图中可预约的座位后，再提交预约</div>
            </template>
          </div>
        </div>
        <SButton variant="primary" size="lg" :disabled="!selected || loading || mapError" :loading="submitting" @click="confirmBooking">提交预约</SButton>
      </section>
    </div>
  </div>

  <SeatExplorer v-if="show3D" ref="explorer" :origin="seatCard" :room="room" :seats="seats" :selected-id="selected?.id" :date="date" :start="start" :end="end" :loading="loading" :submitting="submitting" @select="onSeatClick" @submit="confirmBooking" @closed="show3D = false" />

  <!-- 座位悬浮提示 -->
  <Teleport to="body">
    <div
      v-if="hoverTip"
      class="seat-hover-tip"
      :style="{ left: `${hoverTip.x}px`, top: `${hoverTip.y}px` }"
      aria-hidden="true"
    >
      {{ hoverTip.text }}
    </div>
  </Teleport>

  <!-- 智能分配对话框 -->
  <SDialog v-model="allocVisible" title="智能分配座位" width="520px">
    <div class="alloc-form">
      <div class="filter-row">
        <label>偏好区域</label>
        <SSelect v-model="allocForm.zone" :options="zoneOptions" placeholder="不限（推荐）" clearable />
      </div>
      <div class="pref-checks">
        <SCheckbox v-model="allocForm.need_power">需要电源插座</SCheckbox>
        <SCheckbox v-model="allocForm.need_window">偏好靠窗</SCheckbox>
      </div>
    </div>

    <div v-if="recommendations.length" class="rec-title">推荐座位（评分从高到低）</div>
    <div v-if="recommendations.length" class="rec-list">
      <div v-for="(r, i) in recommendations" :key="r.seat.id" class="rec-item">
        <div class="rec-rank">{{ i + 1 }}</div>
        <div class="rec-main">
          <div class="rec-seat">
            <b>{{ r.seat.seat_no }}</b>
            <STag>{{ zoneName[r.seat.zone] || r.seat.zone }}</STag>
            <span v-if="r.seat.has_power" class="muted">· 电源</span>
            <span v-if="r.seat.near_window" class="muted">· 靠窗</span>
          </div>
          <div class="muted rec-score">匹配得分 {{ r.score.toFixed(1) }}</div>
        </div>
        <SButton size="sm" variant="primary" @click="pickRecommended(r)">选这个预约</SButton>
      </div>
    </div>

    <template #footer>
      <div class="alloc-footer">
        <SButton :loading="allocLoading" variant="secondary" @click="runAllocate(false)">
          <AppIcon name="eye" :size="16" />仅推荐
        </SButton>
        <SButton :loading="allocLoading" variant="primary" @click="runAllocate(true)">
          <AppIcon name="sparkles" :size="16" />立即分配并下单
        </SButton>
      </div>
    </template>
  </SDialog>
  </div>
</template>

<style scoped>
.seat-card .seat-heading { width: 100%; display: flex; align-items: center; gap: 10px 16px; flex-wrap: wrap; }
.seat-heading h3 { flex: 0 0 auto; }
/* 自习室选择器 + 示意卡片：与标题相邻、整体靠左 */
.seat-head-tools {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
  min-width: 0;
  margin-inline-end: auto; /* 把右侧空间推给 3D 按钮，本组自身靠左 */
}
/* 示意卡片：单行概要 */
.room-chip {
  min-width: 0;
  max-width: min(360px, 46vw);
  padding: 5px 12px;
  background: var(--surface-2);
  border: 1px solid var(--hairline);
  border-radius: 999px;
  box-shadow: inset 0 1px 0 #ffffff0a;
}
.room-chip__meta {
  display: block;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: var(--fs-caption);
  color: var(--text-4);
  line-height: 1.5;
}
.room-select { flex: 0 0 150px; width: 150px; }
@media (max-width: 720px) {
  .seat-head-tools { margin-inline-end: 0; }
  .room-chip { flex: 1 1 auto; max-width: 100%; }
  .room-select { flex: 0 0 150px; }
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
  color: var(--text-4);
}

.booking-summary {
  display: grid;
  grid-template-columns: minmax(260px, 1fr) minmax(320px, 1.15fr) max-content;
  align-items: center;
  gap: 16px;
  padding: 14px 18px;
}
.booking-counts { min-width: 0; }
.booking-counts .kpi-grid { grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 0; }
.booking-counts .kpi { padding: 6px 10px; }
.booking-counts .kpi-num { font-size: 24px; }
.booking-counts .kpi-label { font-size: 12px; white-space: nowrap; }
.booking-legends { display: grid; gap: 12px; min-width: 0; padding-inline: 16px; border-inline: 1px solid var(--border); }
.booking-legends .legend { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 8px; padding: 0; border: 0; margin: 0; }
.booking-legends .legend-item { gap: 5px; white-space: nowrap; font-size: 12px; }
.booking-actions { display: flex; flex-direction: column; align-items: stretch; justify-content: center; align-self: stretch; gap: 8px; margin: 0; padding: 0; }
.booking-actions :deep(.s-btn) { margin: 0; }
@media (max-width: 1024px) {
  .booking-summary { grid-template-columns: minmax(0, 1fr); gap: 14px; }
  .booking-legends { width: 100%; padding: 14px 0; border-inline: 0; border-block: 1px solid var(--border); }
  .booking-actions { width: 100%; flex-direction: row; align-items: center; }
  .booking-actions :deep(.s-btn) { flex: 1; min-width: 0; }
}
@media (max-width: 420px) {
  .booking-counts .kpi { padding-inline: 4px; }
  .booking-counts .kpi-num { font-size: 22px; }
  .booking-counts .kpi-label, .booking-legends .legend-item { font-size: 11px; }
  .booking-legends .legend { gap: 6px; }
  .booking-legends .dot { width: 11px; height: 11px; flex-shrink: 0; }
}


.legend {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 8px 12px;
  padding-top: 12px;
  border-top: 1px solid var(--hairline);
}
.legend-item {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: var(--fs-caption);
  color: var(--text-3);
}
.dot {
  width: 15px;
  height: 15px;
  border-radius: 5px;
  display: inline-block;
  border: 1px solid transparent;
}
.dot-free     { background: var(--seat-free-bg); border-color: var(--seat-free-border); }
.dot-selected { background: var(--primary); }
.dot-occupied { background: var(--seat-occupied-bg); border-color: var(--seat-occupied-border); }
.dot-disabled { background: var(--surface-3); border-color: var(--border); }

/* 桌型 / 窗户 图例 */
.type-ico {
  width: 16px;
  height: 16px;
  display: inline-grid;
  place-items: center;
  color: var(--text-3);
  flex: 0 0 auto;
}
.type-ico--window {
  background:
    linear-gradient(180deg, var(--window-glass-hi), transparent 60%),
    repeating-linear-gradient(90deg, var(--window-frame) 0 2px, var(--window-glass) 2px 8px);
  border: 1px solid var(--window-frame);
  border-radius: 3px;
}
.legend--status {
  margin-top: 10px;
  padding-top: 10px;
  border-top: 1px solid var(--hairline);
}

/* 座位图 */
.seat-card {
  min-height: 0;
}
.booking-split > .split-right { align-self: start; }
.booking-split > .split-right > .seat-card:first-child { flex: 0 0 auto; }
.seat-grid-wrap {
  margin-top: 8px;
  padding: 12px;
  background: var(--surface-2);
  border: 1px solid var(--hairline);
  border-radius: var(--r-lg);
  min-height: 0;
  display: grid;
  place-items: start stretch;
}
.empty-tip {
  padding: 60px 0;
  font-size: var(--fs-body);
}
/* 房间框架：墙 + 窗 + 门 包裹座位区 */
.room-frame {
  width: 100%;
  display: grid;
  grid-template-columns: 18px minmax(0, 1fr) 18px;
  grid-template-rows: 18px auto 18px;
  border-radius: var(--r-lg);
  overflow: hidden;
}
.wall { background: linear-gradient(135deg, #ffffff12, #00000010), var(--wall-solid); box-shadow: inset 0 1px 0 #ffffff12, inset 0 -2px 3px #0002; }
.wall-top { grid-column: 1 / -1; grid-row: 1; }
.wall-left { grid-column: 1; grid-row: 2; }
.wall-right { grid-column: 3; grid-row: 2; }
.wall-bottom {
  grid-column: 1 / -1;
  grid-row: 3;
  display: flex;
  align-items: stretch;
}
.wall-seg { flex: 1 1 auto; }

/* 窗户：水平墙（顶/底）竖窗棂，竖直墙（左/右）横窗棂 */
.wall-top.window,
.wall-bottom.window {
  background:
    linear-gradient(180deg, var(--window-glass-hi), transparent 60%),
    repeating-linear-gradient(90deg, var(--window-frame) 0 3px, var(--window-glass) 3px 22px);
}
.wall-left.window,
.wall-right.window {
  background:
    linear-gradient(90deg, var(--window-glass-hi), transparent 60%),
    repeating-linear-gradient(180deg, var(--window-frame) 0 3px, var(--window-glass) 3px 22px);
}
.wall.window { box-shadow: inset 0 0 0 1px var(--window-frame), inset 3px 0 8px #d0f3ff22, 0 0 12px #95d5ff15; }

/* 门：底墙中间开口 */
.door {
  flex: 0 0 46px;
  position: relative;
  background: var(--door);
  border: 2px solid var(--door-frame);
  border-bottom: none;
  border-radius: 6px 6px 0 0;
}
.door::after {
  content: '';
  position: absolute;
  right: 7px;
  top: 6px;
  width: 4px;
  height: 4px;
  border-radius: 50%;
  background: var(--door-frame);
}

/* 座位区 */
.seat-grid {
  grid-column: 2;
  grid-row: 2;
  min-width: 0;
  display: grid;
  padding: 12px;
  background: linear-gradient(125deg, #d5e6ef0c, transparent 65%), repeating-linear-gradient(0deg, transparent 0 43px, #87999d12 43px 44px), repeating-linear-gradient(90deg, transparent 0 87px, #87999d12 87px 88px), var(--room-floor);
  box-shadow: inset 0 2px 8px #00000012;
}
.seat {
  min-height: 62px;
  min-width: 0;
  padding: 6px 3px;
  appearance: none;
  font-family: inherit;
  border-radius: var(--r-md);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 5px;
  font-variant-numeric: tabular-nums;
  letter-spacing: .02em;
  cursor: pointer;
  position: relative;
  transition: transform var(--dur-1) var(--ease), box-shadow var(--dur-1) var(--ease),
    background var(--dur-1) var(--ease), border-color var(--dur-1) var(--ease);
  user-select: none;
  border: 1px solid transparent;
}
.seat:hover {
  transform: translateY(-1px);
}
.seat:focus-visible { outline: 2px solid var(--primary); outline-offset: 2px; z-index: 1; }
.seat[aria-disabled='true']:hover { transform: none; }
.seat-no {
  font-size: 10px;
  font-weight: 700;
  line-height: 1;
  display: inline-flex;
  align-items: center;
  gap: 5px;
  opacity: 1;
}
.seat-no::before { content: ''; width: 5px; height: 5px; border-radius: 50%; background: currentColor; box-shadow: 0 0 5px currentColor; }
/* 靠窗座位：桌面靠窗一侧淡蓝窗条（方向随数据） */
.seat-near-window-right::after,
.seat-near-window-left::after {
  content: '';
  position: absolute;
  top: 7px;
  bottom: 7px;
  width: 3px;
  border-radius: 2px;
  background: var(--window-frame);
}
.seat-near-window-right::after { right: 3px; }
.seat-near-window-left::after { left: 3px; }
.seat-near-window-top::after,
.seat-near-window-bottom::after {
  content: '';
  position: absolute;
  left: 7px;
  right: 7px;
  height: 3px;
  border-radius: 2px;
  background: var(--window-frame);
}
.seat-near-window-top::after { top: 3px; }
.seat-near-window-bottom::after { bottom: 3px; }
.seat-free {
  background: linear-gradient(145deg, #ffffff09, transparent), color-mix(in srgb, var(--seat-free-bg) 55%, transparent);
  color: var(--seat-free-color);
  border-color: var(--seat-free-border);
  box-shadow: inset 0 1px 0 #ffffff0c, 0 2px 3px #0000000a;
}
.seat-free:hover {
  background: var(--seat-free-hover-bg);
  border-color: var(--seat-free-hover-border);
}
.seat-selected {
  background: linear-gradient(135deg, #ffffff22, transparent), var(--primary);
  color: #fff;
  border-color: var(--primary-active);
  box-shadow: 0 0 0 3px var(--primary-ring), 0 4px 12px rgba(59, 102, 218, .32);
}
.seat-occupied {
  background: var(--seat-occupied-bg);
  color: var(--seat-occupied-color);
  border-color: var(--seat-occupied-border);
  cursor: not-allowed;
}
.seat-disabled {
  background:
    repeating-linear-gradient(135deg, var(--surface-3) 0 5px, var(--seat-disabled-stripe) 5px 9px);
  color: var(--text-4);
  border-color: var(--border);
  cursor: not-allowed;
  text-decoration: line-through;
  text-decoration-color: var(--text-4);
}
.seat-disabled :deep(.plan-desk), .seat-occupied :deep(.plan-desk) { filter: saturate(.4) brightness(.85); }
@media (prefers-reduced-motion: reduce) { .seat { transition: none; }.seat:hover { transform: none; } }

/* 座位悬浮提示 */
.seat-hover-tip {
  position: fixed;
  z-index: var(--z-popover);
  transform: translate(-50%, calc(-100% - 10px));
  background: var(--seat-tip-bg);
  color: var(--seat-tip-text);
  font-size: var(--fs-caption);
  padding: 5px 10px;
  border-radius: var(--r-sm);
  pointer-events: none;
  white-space: nowrap;
  box-shadow: var(--shadow-2);
}

.seat-hover-tip::after {
  content: '';
  position: absolute;
  left: 50%;
  bottom: -4px;
  width: 8px;
  height: 8px;
  transform: translateX(-50%) rotate(45deg);
  background: var(--seat-tip-bg);
}

/* 已选条 */
.selected-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  background: var(--primary-faint);
  border-color: var(--border-strong);
}
.sel-info {
  display: flex;
  align-items: center;
  gap: 14px;
  min-width: 0;
}
.sel-detail {
  min-width: 0;
}
.sel-icon {
  width: 46px;
  height: 46px;
  border-radius: var(--r-lg);
  background: var(--surface);
  display: grid;
  place-items: center;
  color: var(--primary);
  box-shadow: var(--shadow-1);
  flex: 0 0 auto;
}
.sel-title {
  font-size: var(--fs-title);
  font-weight: 600;
  color: var(--text-1);
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 2px;
}
/* 未选择座位：常驻提示态 */
.selected-card--empty {
  background: var(--surface);
  border-color: var(--border);
}
.selected-card--empty .sel-icon {
  background: var(--surface-3);
  color: var(--text-4);
  box-shadow: none;
}
.selected-card--empty .sel-detail .muted {
  color: var(--text-4);
}
.sel-placeholder {
  font-size: var(--fs-title);
  font-weight: 600;
  color: var(--text-3);
  margin-bottom: 2px;
}

/* 智能分配弹窗内 */
.alloc-form {
  display: flex;
  flex-direction: column;
  gap: 16px;
}
.pref-checks {
  display: flex;
  gap: 18px;
}
.rec-title {
  margin: 20px 0 10px;
  font-weight: 600;
  color: var(--text-2);
  font-size: var(--fs-body-sm);
}
.rec-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
  max-height: 264px;
  overflow: auto;
  scrollbar-width: thin;
}
.rec-item {
  display: grid;
  grid-template-columns: 34px 1fr auto;
  gap: 12px;
  align-items: center;
  padding: 10px 12px;
  border-radius: var(--r-lg);
  background: var(--surface-2);
  border: 1px solid var(--hairline);
}
.rec-rank {
  width: 28px;
  height: 28px;
  border-radius: var(--r-sm);
  background: var(--primary-weak);
  color: var(--primary-active);
  display: grid;
  place-items: center;
  font-weight: 700;
  font-size: var(--fs-caption);
  font-variant-numeric: tabular-nums;
}
.rec-main {
  min-width: 0;
}
.rec-seat {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: var(--fs-body);
}
.rec-score {
  margin-top: 2px;
  font-size: var(--fs-caption);
  font-variant-numeric: tabular-nums;
}
.alloc-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  width: 100%;
}

@media (max-width: 720px) {
  .seat-grid-wrap { padding: 10px; min-width: max-content; }
  .seat-grid { padding: 8px; }
  .seat { border-radius: var(--r-sm); font-size: 10px; }
  .selected-card { align-items: stretch; flex-direction: column; }
  .selected-card :deep(.s-btn) { width: 100%; }
  .pref-checks { align-items: flex-start; flex-direction: column; gap: 10px; }
  .rec-item { grid-template-columns: 32px minmax(0, 1fr); }
  .rec-item :deep(.s-btn) { grid-column: 1 / -1; width: 100%; }
  .seat-card { overflow: hidden; }
  .sel-info { min-width: 0; align-items: flex-start; }
  .sel-title { flex-wrap: wrap; }
  .alloc-footer { align-items: stretch; flex-direction: column; }
  .alloc-footer :deep(.s-btn) { width: 100%; }
}
</style>
