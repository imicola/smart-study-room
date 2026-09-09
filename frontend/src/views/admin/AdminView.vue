<script setup>
import PageHelp from '../../components/PageHelp.vue'
import { ref, onMounted, computed } from 'vue'
import { message, confirmDialog, promptDialog } from '../../components/ui/feedback'
import { getRooms, getSeatMap } from '../../api/room'
import {
  createRoom, updateRoom, deleteRoom, batchGenSeats, updateSeat, listUsers, setUserStatus
} from '../../api/admin'
import AppIcon from '../../components/AppIcon.vue'
import SButton from '../../components/ui/SButton.vue'
import SInput from '../../components/ui/SInput.vue'
import SSelect from '../../components/ui/SSelect.vue'
import SInputNumber from '../../components/ui/SInputNumber.vue'
import SDialog from '../../components/ui/SDialog.vue'
import STag from '../../components/ui/STag.vue'
import SEmpty from '../../components/ui/SEmpty.vue'

const activeTab = ref('rooms')

// 时间下拉选项（30 分钟粒度）
function buildTimeOptions(startHour, endHour) {
  const opts = []
  for (let h = startHour; h <= endHour; h++) {
    opts.push({ label: `${String(h).padStart(2, '0')}:00`, value: `${String(h).padStart(2, '0')}:00` })
    if (h < endHour) opts.push({ label: `${String(h).padStart(2, '0')}:30`, value: `${String(h).padStart(2, '0')}:30` })
  }
  return opts
}
const openTimeOptions = buildTimeOptions(5, 12)
const closeTimeOptions = buildTimeOptions(12, 23)

// ---------- 房间管理 ----------
const rooms = ref([])
const roomDialog = ref(false)
const editingId = ref(null)
const roomForm = ref({
  name: '', location: '', open_time: '08:00', close_time: '22:00',
  seat_rows: 6, seat_cols: 8, description: ''
})

async function loadRooms() {
  const resp = await getRooms()
  rooms.value = resp.data || []
}

function openCreate() {
  editingId.value = null
  roomForm.value = { name: '', location: '', open_time: '08:00', close_time: '22:00', seat_rows: 6, seat_cols: 8, description: '' }
  roomDialog.value = true
}
function openEdit(r) {
  editingId.value = r.id
  roomForm.value = {
    name: r.name, location: r.location,
    open_time: r.open_time.slice(0, 5), close_time: r.close_time.slice(0, 5),
    seat_rows: r.seat_rows, seat_cols: r.seat_cols, description: r.description
  }
  roomDialog.value = true
}
async function saveRoom() {
  const f = roomForm.value
  if (!f.name?.trim()) { message.warning('请输入自习室名称'); return }
  if (editingId.value) { await updateRoom(editingId.value, f); message.success('房间已更新') }
  else {
    const resp = await createRoom(f)
    message.success(`房间已创建（ID=${resp.data.id}），可批量生成座位`)
  }
  roomDialog.value = false
  loadRooms()
}
async function onBatchGen(r) {
  try {
    await promptDialog(
      `按行列批量生成 ${r.name} 的座位（追加新座位，不覆盖现有）`,
      '批量生成座位',
      {
        inputValue: `${r.seat_rows} ${r.seat_cols}`,
        inputPattern: /^\s*\d{1,2}\s+\d{1,2}\s*$/,
        inputErrorMessage: '格式: 行 列（如 6 8）',
        confirmButtonText: '生成'
      }
    ).then(async ({ value }) => {
      const [rows, cols] = value.trim().split(/\s+/).map(Number)
      const resp = await batchGenSeats(r.id, { seat_rows: rows, seat_cols: cols })
      message.success(`已生成 ${resp.data.created} 个座位`)
      loadRooms()
    })
  } catch { /* 取消 */ }
}
async function onDeleteRoom(r) {
  try {
    await confirmDialog(
      `删除房间「${r.name}」将级联删除其全部座位与预约记录，确认？`,
      '危险操作', { type: 'warning', confirmButtonText: '确认删除' }
    )
  } catch { return }
  await deleteRoom(r.id)
  message.success('已删除')
  loadRooms()
}

// ---------- 座位维护 ----------
const seatDialog = ref(false)
const seatRoom = ref(null)
const seatList = ref([])
const seatLoading = ref(false)

const zoneName = { quiet: '静音区', regular: '普通区', discussion: '研讨区', computer: '机房区' }

async function openSeats(r) {
  seatRoom.value = r
  seatDialog.value = true
  seatLoading.value = true
  const today = new Date().toISOString().slice(0, 10)
  try {
    const resp = await getSeatMap(r.id, today, '08:00', '22:00')
    seatList.value = resp.data.seats || []
  } finally {
    seatLoading.value = false
  }
}
async function toggleSeatStatus(s) {
  const next = s.status === 'available' ? 'maintenance' : 'available'
  await updateSeat(s.id, { zone: s.zone, has_power: s.has_power, near_window: s.near_window, status: next })
  s.status = next
  message.success(`${s.seat_no} 已${next === 'available' ? '恢复可用' : '进入维护'}`)
}

// ---------- 用户管理 ----------
const users = ref([])
async function loadUsers() {
  const resp = await listUsers()
  users.value = resp.data || []
}
async function toggleUser(u) {
  const next = u.status === 'active' ? 'disabled' : 'active'
  await setUserStatus(u.id, next)
  u.status = next
  message.success(`${u.username} 已${next === 'active' ? '启用' : '禁用'}`)
}

// ---------- 左栏统计 ----------
const userStats = ref({ total: 0, active: 0, disabled: 0, admin: 0, student: 0 })
function refreshStats() {
  const total = users.value.length || 0
  const active = users.value.filter((u) => u.status === 'active').length
  const disabled = total - active
  const admin = users.value.filter((u) => u.role === 'admin').length
  userStats.value = { total, active, disabled, admin, student: total - admin }
}
const roomStats = computed(() => ({
  total: rooms.value.length,
  seats: rooms.value.reduce((s, r) => s + (r.seat_rows * r.seat_cols || 0), 0)
}))
onMounted(async () => {
  await loadRooms(); await loadUsers()
  refreshStats()
})

const tabs = [
  { key: 'rooms', label: '自习室管理', icon: 'building' },
  { key: 'users', label: '用户管理',   icon: 'users' }
]

function creditColor(s) {
  if (s < 60) return 'var(--red-strong)'
  if (s < 80) return 'var(--amber-strong)'
  return 'var(--green-strong)'
}
</script>

<template>
  <div v-reveal class="page-view">
    <header class="view-heading has-page-help"><div class="heading-copy" data-page-title>
      <h1>管理端</h1>
      <p class="heading-sub">自习室、座位与用户的全局管理</p>
    </div><PageHelp title="管理须知"><ul class="tips">
          <li>批量生成座位会<b>追加</b>而非覆盖现有座位</li>
          <li>维护中座位学生端不可预约，不计入统计</li>
          <li>管理员账号<b>无法禁用</b>，防止误操作锁死</li>
        </ul></PageHelp></header>
    <div class="split admin-split">
    <!-- 左栏：导航 + 统计 + 快速操作 -->
    <div class="split-left">
      <section class="card responsive-compact">
        <div class="card-title-row">
          <h3>管理面板</h3>
          <STag type="danger">管理员</STag>
        </div>
        <nav v-active-track class="side-nav">
          <button
            v-for="t in tabs"
            :key="t.key"
            class="side-nav-item"
            :class="{ active: activeTab === t.key }"
            @click="activeTab = t.key"
          >
            <span class="side-nav-icon"><AppIcon :name="t.icon" :size="17" /></span>
            <span class="side-nav-label">{{ t.label }}</span>
          </button>
        </nav>
      </section>

      <section class="card responsive-compact">
        <div class="card-title-row"><h3>运营统计</h3></div>
        <div class="kpi-grid">
          <div class="kpi">
            <div class="kpi-num">{{ roomStats.total }}</div>
            <div class="kpi-label">自习室数量</div>
          </div>
          <div class="kpi">
            <div class="kpi-num">{{ roomStats.seats }}</div>
            <div class="kpi-label">座位规模</div>
          </div>
          <div class="kpi">
            <div class="kpi-num">{{ userStats.total }}</div>
            <div class="kpi-label">注册用户</div>
          </div>
          <div class="kpi kpi-bad">
            <div class="kpi-num">{{ userStats.disabled }}</div>
            <div class="kpi-label">已禁用</div>
          </div>
        </div>
      </section>

      <section class="card responsive-compact">
        <h3>快速操作</h3>
        <div class="quick-actions">
          <SButton v-if="activeTab === 'rooms'" variant="primary" block @click="openCreate">
            <AppIcon name="add" :size="16" />新建自习室
          </SButton>
          <SButton variant="secondary" block @click="loadRooms(); loadUsers(); refreshStats()">
            <AppIcon name="refresh" :size="16" />刷新数据
          </SButton>
        </div>
        
      </section>
    </div>

    <!-- 右栏：自习室 / 用户 表格 -->
    <div class="split-right">
      <!-- 自习室管理 -->
      <section v-if="activeTab === 'rooms'" class="card">
        <div class="card-title-row">
          <h3>自习室管理</h3>
          <SButton variant="primary" size="sm" @click="openCreate">新建自习室</SButton>
        </div>
        <div class="table-wrap">
          <div class="table-scroll" tabindex="0" aria-label="自习室管理表格，可左右滑动">
            <table class="table rooms-table">
              <thead>
                <tr>
                  <th style="width:46px" class="num-col">ID</th>
                  <th style="width:132px">名称</th>
                  <th style="width:124px">位置</th>
                  <th style="width:108px">开放时间</th>
                  <th style="width:64px">规模</th>
                  <th style="width:286px">操作</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="row in rooms" :key="row.id">
                  <td class="num cell-dim num-col">{{ row.id }}</td>
                  <td class="cell-strong ellip">{{ row.name }}</td>
                  <td class="ellip">{{ row.location }}</td>
                  <td class="num">{{ row.open_time.slice(0, 5) }} – {{ row.close_time.slice(0, 5) }}</td>
                  <td class="num">{{ row.seat_rows }} × {{ row.seat_cols }}</td>
                  <td>
                    <span class="row-actions">
                      <SButton size="sm" variant="soft" @click="openEdit(row)">编辑</SButton>
                      <SButton size="sm" variant="soft" @click="onBatchGen(row)">生成座位</SButton>
                      <SButton size="sm" variant="soft" @click="openSeats(row)">座位维护</SButton>
                      <SButton size="sm" variant="soft-danger" @click="onDeleteRoom(row)">删除</SButton>
                    </span>
                  </td>
                </tr>
              </tbody>
            </table>
            <SEmpty v-if="!rooms.length" description="暂无自习室，点击右上角新建" />
          </div>
        </div>
      </section>

      <!-- 用户管理 -->
      <section v-if="activeTab === 'users'" class="card">
        <div class="card-title-row">
          <h3>用户管理</h3>
          <SButton variant="secondary" size="sm" @click="loadUsers(); refreshStats()">
            <AppIcon name="refresh" :size="14" />刷新
          </SButton>
        </div>
        <div class="table-wrap">
          <div class="table-scroll" tabindex="0" aria-label="用户管理表格，可左右滑动">
            <table class="table users-table">
              <thead>
                <tr>
                  <th style="width:44px" class="num-col">ID</th>
                  <th style="width:108px">用户名</th>
                  <th style="width:96px">姓名</th>
                  <th style="width:112px">学号</th>
                  <th style="width:88px">角色</th>
                  <th style="width:88px">信用分</th>
                  <th style="width:90px">状态</th>
                  <th style="width:96px">操作</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="row in users" :key="row.id">
                  <td class="num cell-dim num-col">{{ row.id }}</td>
                  <td class="cell-strong">{{ row.username }}</td>
                  <td>{{ row.real_name }}</td>
                  <td class="num">{{ row.student_no }}</td>
                  <td>
                    <STag :type="row.role === 'admin' ? 'danger' : 'primary'">
                      {{ row.role === 'admin' ? '管理员' : '学生' }}
                    </STag>
                  </td>
                  <td class="num-col">
                    <span class="credit-num" :style="{ color: creditColor(row.credit_score) }">
                      {{ row.credit_score }}
                    </span>
                  </td>
                  <td>
                    <STag :type="row.status === 'active' ? 'success' : 'neutral'" dot>
                      {{ row.status === 'active' ? '正常' : '禁用' }}
                    </STag>
                  </td>
                  <td>
                    <SButton
                      v-if="row.role !== 'admin'"
                      size="sm"
                      :variant="row.status === 'active' ? 'soft-danger' : 'soft-success'"
                      @click="toggleUser(row)"
                    >
                      {{ row.status === 'active' ? '禁用' : '启用' }}
                    </SButton>
                    <span v-else class="cell-dim">—</span>
                  </td>
                </tr>
              </tbody>
            </table>
            <SEmpty v-if="!users.length" description="暂无用户" />
          </div>
        </div>
      </section>
    </div>
  </div>

  <!-- =============== 房间编辑弹框 =============== -->
  <SDialog v-model="roomDialog" :title="editingId ? '编辑自习室' : '新建自习室'" width="540px">
    <div class="dialog-form">
      <div class="dialog-field">
        <label class="dialog-label">名称 <span class="req">*</span></label>
        <SInput v-model="roomForm.name" placeholder="如 1F-静音自习室" />
      </div>
      <div class="dialog-field">
        <label class="dialog-label">位置</label>
        <SInput v-model="roomForm.location" placeholder="如 图书馆一层东侧" />
      </div>
      <div class="dialog-field">
        <label class="dialog-label">开放时间</label>
        <div class="time-range">
          <SSelect v-model="roomForm.open_time" :options="openTimeOptions" />
          <span class="time-arrow">至</span>
          <SSelect v-model="roomForm.close_time" :options="closeTimeOptions" />
        </div>
      </div>
      <div class="dialog-field">
        <label class="dialog-label">默认规模</label>
        <div class="scale-range">
          <SInputNumber v-model="roomForm.seat_rows" :min="1" :max="30" />
          <span class="scale-x">行</span>
          <SInputNumber v-model="roomForm.seat_cols" :min="1" :max="30" />
          <span class="scale-x">列</span>
        </div>
      </div>
      <div class="dialog-field">
        <label class="dialog-label">说明</label>
        <SInput v-model="roomForm.description" type="textarea" :rows="2" placeholder="静音 / 研讨 / 机房 / 靠窗描述等（选填）" />
      </div>
    </div>
    <template #footer>
      <SButton variant="secondary" @click="roomDialog = false">取消</SButton>
      <SButton variant="primary" @click="saveRoom">保存</SButton>
    </template>
  </SDialog>

  <!-- =============== 座位维护弹框 =============== -->
  <SDialog v-model="seatDialog" :title="`座位维护 - ${seatRoom?.name || ''}`" width="820px">
    <div class="seat-tip">
      <span class="seat-tip-icon"><AppIcon name="info" :size="17" /></span>
      <span>点击右侧按钮切换座位状态，<b>维护中</b>的座位在学生端不可预约。</span>
    </div>
    <div class="table-wrap">
      <div class="table-scroll" v-loading="seatLoading" tabindex="0" aria-label="座位维护表格，可左右滑动">
        <table class="table seats-table">
          <thead>
            <tr>
              <th style="width:90px">座位号</th>
              <th style="width:90px">坐标</th>
              <th style="width:110px">区域</th>
              <th style="width:72px">电源</th>
              <th style="width:72px">靠窗</th>
              <th style="width:104px">状态</th>
              <th style="width:120px">操作</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="row in seatList" :key="row.id">
              <td class="cell-strong num num-col">{{ row.seat_no }}</td>
              <td class="num num-col">{{ row.row_no }}, {{ row.col_no }}</td>
              <td><span class="zone-chip">{{ zoneName[row.zone] || row.zone }}</span></td>
              <td>
                <span v-if="row.has_power" class="chip-ok"><AppIcon name="check" :size="15" /></span>
                <span v-else class="cell-dim">—</span>
              </td>
              <td>
                <span v-if="row.near_window" class="chip-ok"><AppIcon name="check" :size="15" /></span>
                <span v-else class="cell-dim">—</span>
              </td>
              <td>
                <STag :type="row.status === 'available' ? 'success' : 'warning'" dot>
                  {{ row.status === 'available' ? '可用' : '维护' }}
                </STag>
              </td>
              <td>
                <SButton
                  size="sm"
                  :variant="row.status === 'available' ? 'soft-warn' : 'soft-success'"
                  @click="toggleSeatStatus(row)"
                >
                  {{ row.status === 'available' ? '设为维护' : '恢复可用' }}
                </SButton>
              </td>
            </tr>
          </tbody>
        </table>
        <SEmpty v-if="!seatList.length && !seatLoading" description="该自习室暂无座位" />
      </div>
    </div>
    <template #footer>
      <SButton variant="secondary" @click="seatDialog = false">关闭</SButton>
    </template>
  </SDialog>
  </div>
</template>

<style scoped>

.rooms-table { min-width: 760px; }
.users-table { min-width: 770px; }
.seats-table { min-width: 620px; }

.quick-actions {
  display: flex;
  flex-direction: column;
  gap: 10px;
  margin-bottom: 14px;
  margin-top: 2px;
}

.num-col {
  text-align: center;
}

.credit-num {
  font-weight: 700;
  font-size: var(--fs-body);
  font-variant-numeric: tabular-nums;
}

.zone-chip {
  display: inline-block;
  padding: 2px 9px;
  background: var(--surface-3);
  color: var(--text-3);
  border-radius: var(--r-sm);
  font-size: 11.5px;
  font-weight: 500;
  white-space: nowrap;
}

.rooms-table .row-actions {
  flex-wrap: nowrap;
  white-space: nowrap;
}
.chip-ok {
  color: var(--green);
  display: inline-grid;
  place-items: center;
}

/* 弹窗表单 */
.dialog-form {
  display: flex;
  flex-direction: column;
  gap: 16px;
}
.dialog-field {
  display: flex;
  flex-direction: column;
  gap: 6px;
  min-width: 0;
}
.dialog-label {
  font-size: var(--fs-caption);
  color: var(--text-3);
  font-weight: 600;
  letter-spacing: .03em;
}
.dialog-label .req {
  color: var(--red);
}
.time-range {
  display: flex;
  align-items: center;
  gap: 10px;
}
.time-arrow {
  color: var(--text-4);
  font-size: var(--fs-body-sm);
  flex: 0 0 auto;
}
.scale-range {
  display: flex;
  align-items: center;
  gap: 8px;
}
.scale-x {
  color: var(--text-4);
  font-size: var(--fs-body-sm);
  margin-right: 8px;
}

/* 座位提示条 */
.seat-tip {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  background: var(--primary-faint);
  border: 1px solid #dfe8fb;
  color: var(--text-2);
  padding: 10px 14px;
  border-radius: var(--r-lg);
  margin-bottom: 14px;
  font-size: var(--fs-body-sm);
  line-height: 1.6;
}
.seat-tip-icon {
  color: var(--primary);
  flex: 0 0 auto;
  margin-top: 2px;
}
.seat-tip b {
  color: var(--primary-active);
  font-weight: 600;
}

@media (max-width: 720px) {
  .time-range,
  .scale-range {
    align-items: stretch;
    flex-direction: column;
  }
  .time-arrow,
  .scale-x {
    margin: 0;
    text-align: center;
  }
  .seat-tip {
    padding: 10px 12px;
  }
}
</style>
