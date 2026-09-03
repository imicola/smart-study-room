<script setup>
<<<<<<< HEAD
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { getRooms, getSeatMap } from '../../api/room'
import { createRoom, updateRoom, deleteRoom, batchGenSeats, updateSeat, listUsers, setUserStatus } from '../../api/admin'
=======
import { ref, onMounted, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { getRooms, getSeatMap } from '../../api/room'
import {
  createRoom, updateRoom, deleteRoom, batchGenSeats, updateSeat, listUsers, setUserStatus
} from '../../api/admin'
>>>>>>> 958d510 (chore: init smart-study-room with ui redesign)

const activeTab = ref('rooms')

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
<<<<<<< HEAD

=======
>>>>>>> 958d510 (chore: init smart-study-room with ui redesign)
function openEdit(r) {
  editingId.value = r.id
  roomForm.value = {
    name: r.name, location: r.location,
    open_time: r.open_time.slice(0, 5), close_time: r.close_time.slice(0, 5),
    seat_rows: r.seat_rows, seat_cols: r.seat_cols, description: r.description
  }
  roomDialog.value = true
}
<<<<<<< HEAD

async function saveRoom() {
  const f = roomForm.value
  if (editingId.value) {
    await updateRoom(editingId.value, f)
    ElMessage.success('房间已更新')
  } else {
=======
async function saveRoom() {
  const f = roomForm.value
  if (!f.name?.trim()) { ElMessage.warning('请输入自习室名称'); return }
  if (editingId.value) { await updateRoom(editingId.value, f); ElMessage.success('房间已更新') }
  else {
>>>>>>> 958d510 (chore: init smart-study-room with ui redesign)
    const resp = await createRoom(f)
    ElMessage.success(`房间已创建（ID=${resp.data.id}），可批量生成座位`)
  }
  roomDialog.value = false
  loadRooms()
}
<<<<<<< HEAD

async function onBatchGen(r) {
  try {
    await ElMessageBox.prompt(
      `按行列批量生成 ${r.name} 的座位（将覆盖房间默认规模）`,
=======
async function onBatchGen(r) {
  try {
    await ElMessageBox.prompt(
      `按行列批量生成 ${r.name} 的座位（追加新座位，不覆盖现有）`,
>>>>>>> 958d510 (chore: init smart-study-room with ui redesign)
      '批量生成座位',
      {
        inputValue: `${r.seat_rows} ${r.seat_cols}`,
        inputPattern: /^\s*\d{1,2}\s+\d{1,2}\s*$/,
        inputErrorMessage: '格式: 行 列（如 6 8）'
      }
    ).then(async ({ value }) => {
      const [rows, cols] = value.trim().split(/\s+/).map(Number)
      const resp = await batchGenSeats(r.id, { seat_rows: rows, seat_cols: cols })
      ElMessage.success(`已生成 ${resp.data.created} 个座位`)
      loadRooms()
    })
  } catch { /* 取消 */ }
}
<<<<<<< HEAD

=======
>>>>>>> 958d510 (chore: init smart-study-room with ui redesign)
async function onDeleteRoom(r) {
  try {
    await ElMessageBox.confirm(
      `删除房间「${r.name}」将级联删除其全部座位与预约记录，确认？`,
<<<<<<< HEAD
      '危险操作', { type: 'error', confirmButtonText: '确认删除' }
=======
      '危险操作', { type: 'warning', confirmButtonText: '确认删除' }
>>>>>>> 958d510 (chore: init smart-study-room with ui redesign)
    )
  } catch { return }
  await deleteRoom(r.id)
  ElMessage.success('已删除')
  loadRooms()
}

// ---------- 座位维护 ----------
const seatDialog = ref(false)
const seatRoom = ref(null)
const seatList = ref([])
<<<<<<< HEAD
const seatDate = ref(new Date().toISOString().slice(0, 10))
=======
>>>>>>> 958d510 (chore: init smart-study-room with ui redesign)

async function openSeats(r) {
  seatRoom.value = r
  seatDialog.value = true
<<<<<<< HEAD
  const resp = await getSeatMap(r.id, seatDate.value, '08:00', '22:00')
  seatList.value = resp.data.seats || []
}

=======
  const today = new Date().toISOString().slice(0, 10)
  const resp = await getSeatMap(r.id, today, '08:00', '22:00')
  seatList.value = resp.data.seats || []
}
>>>>>>> 958d510 (chore: init smart-study-room with ui redesign)
async function toggleSeatStatus(s) {
  const next = s.status === 'available' ? 'maintenance' : 'available'
  await updateSeat(s.id, { zone: s.zone, has_power: s.has_power, near_window: s.near_window, status: next })
  s.status = next
  ElMessage.success(`${s.seat_no} 已${next === 'available' ? '恢复可用' : '进入维护'}`)
}

// ---------- 用户管理 ----------
const users = ref([])
<<<<<<< HEAD

=======
>>>>>>> 958d510 (chore: init smart-study-room with ui redesign)
async function loadUsers() {
  const resp = await listUsers()
  users.value = resp.data || []
}
<<<<<<< HEAD

=======
>>>>>>> 958d510 (chore: init smart-study-room with ui redesign)
async function toggleUser(u) {
  const next = u.status === 'active' ? 'disabled' : 'active'
  await setUserStatus(u.id, next)
  u.status = next
  ElMessage.success(`${u.username} 已${next === 'active' ? '启用' : '禁用'}`)
}

<<<<<<< HEAD
onMounted(() => {
  loadRooms()
  loadUsers()
})
</script>

<template>
  <div class="page-card">
    <h2 style="margin-top: 0">管理端</h2>

    <el-tabs v-model="activeTab">
      <!-- 房间管理 -->
      <el-tab-pane label="自习室管理" name="rooms">
        <div style="margin-bottom: 12px">
          <el-button type="primary" @click="openCreate">新建自习室</el-button>
        </div>
        <el-table :data="rooms" stripe>
          <el-table-column prop="id" label="ID" width="60" />
          <el-table-column prop="name" label="名称" min-width="130" />
          <el-table-column prop="location" label="位置" min-width="120" />
          <el-table-column label="开放时间" width="130">
            <template #default="{ row }">
              {{ row.open_time.slice(0, 5) }} - {{ row.close_time.slice(0, 5) }}
            </template>
          </el-table-column>
          <el-table-column label="规模" width="90">
            <template #default="{ row }">{{ row.seat_rows }} × {{ row.seat_cols }}</template>
          </el-table-column>
          <el-table-column label="操作" min-width="300">
            <template #default="{ row }">
              <el-button size="small" @click="openEdit(row)">编辑</el-button>
              <el-button size="small" type="success" plain @click="onBatchGen(row)">批量生成座位</el-button>
              <el-button size="small" @click="openSeats(row)">座位维护</el-button>
              <el-button size="small" type="danger" plain @click="onDeleteRoom(row)">删除</el-button>
            </template>
          </el-table-column>
        </el-table>
      </el-tab-pane>

      <!-- 用户管理 -->
      <el-tab-pane label="用户管理" name="users">
        <el-table :data="users" stripe>
          <el-table-column prop="id" label="ID" width="60" />
          <el-table-column prop="username" label="用户名" width="110" />
          <el-table-column prop="real_name" label="姓名" width="100" />
          <el-table-column prop="student_no" label="学号" width="110" />
          <el-table-column label="角色" width="90">
            <template #default="{ row }">
              <el-tag size="small" :type="row.role === 'admin' ? 'danger' : 'primary'">
                {{ row.role === 'admin' ? '管理员' : '学生' }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column label="信用分" width="90">
            <template #default="{ row }">
              <span :style="{ color: row.credit_score < 60 ? '#f56c6c' : row.credit_score < 80 ? '#e6a23c' : '#67c23a', fontWeight: 600 }">
=======
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
  { key: 'rooms', label: '自习室管理', icon: '🏢' },
  { key: 'users', label: '用户管理',   icon: '👥' }
]

// 低饱和 tag 颜色（与 NotificationsView 同色系规范）
const roleTagCls  = { admin: 'tag-role-admin',  student: 'tag-role-student' }
const statusCls   = { active: 'tag-st-active', disabled: 'tag-st-disabled' }
const seatStatusCls = { available: 'tag-seat-ok', maintenance: 'tag-seat-maint' }
function creditColor(s) {
  if (s < 60) return '#c07474'
  if (s < 80) return '#c79255'
  return '#6f9d66'
}
</script>

<template>
  <div class="split admin-split">
    <!-- 左栏：导航 + 统计 + 快速操作 -->
    <div class="split-left">
      <section class="card">
        <div class="card-title-row">
          <h3>管理面板</h3>
          <span class="tag-role-admin tag-pill">管理员</span>
        </div>
        <div class="tabs-v">
          <button
            v-for="t in tabs"
            :key="t.key"
            class="tab-btn"
            :class="{ active: activeTab === t.key }"
            @click="activeTab = t.key"
          >
            <span class="tab-icon">{{ t.icon }}</span>
            <span class="tab-label">{{ t.label }}</span>
          </button>
        </div>
      </section>

      <section class="card">
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
          <div class="kpi kpi-ok">
            <div class="kpi-num">{{ userStats.total }}</div>
            <div class="kpi-label">注册用户</div>
          </div>
          <div class="kpi kpi-bad">
            <div class="kpi-num">{{ userStats.disabled }}</div>
            <div class="kpi-label">已禁用</div>
          </div>
        </div>
      </section>

      <section class="card">
        <h3>快速操作</h3>
        <div class="quick-actions">
          <el-button v-if="activeTab === 'rooms'" type="primary" class="qa-btn btn-grad-primary" @click="openCreate">
            ➕ 新建自习室
          </el-button>
          <el-button class="qa-btn" @click="loadRooms(); loadUsers(); refreshStats()">
            🔄 刷新数据
          </el-button>
        </div>
        <ul class="tips">
          <li>批量生成座位会<b>追加</b>而非覆盖现有座位</li>
          <li>维护中座位学生端不可预约，不计入统计</li>
          <li>管理员账号<b>无法禁用</b>，防止误操作锁死</li>
        </ul>
      </section>
    </div>

    <!-- 右栏：自习室 / 用户 表格 -->
    <div class="split-right">
      <!-- 自习室管理 -->
      <section v-if="activeTab === 'rooms'" class="card">
        <div class="card-title-row">
          <h3>自习室管理</h3>
          <el-button type="primary" class="btn-grad-primary" @click="openCreate">新建自习室</el-button>
        </div>
        <el-table :data="rooms" stripe class="soft-table">
          <el-table-column prop="id" label="ID" width="64" align="center" />
          <el-table-column prop="name" label="名称" min-width="140" />
          <el-table-column prop="location" label="位置" min-width="130" />
          <el-table-column label="开放时间" width="140" align="center">
            <template #default="{ row }">
              <span class="time-chip">
                {{ row.open_time.slice(0, 5) }} – {{ row.close_time.slice(0, 5) }}
              </span>
            </template>
          </el-table-column>
          <el-table-column label="规模" width="96" align="center">
            <template #default="{ row }">
              <span class="scale-chip">{{ row.seat_rows }} × {{ row.seat_cols }}</span>
            </template>
          </el-table-column>
          <el-table-column label="操作" min-width="340" align="center">
            <template #default="{ row }">
              <div class="btn-row">
                <el-button size="small" class="btn-soft" @click="openEdit(row)">编辑</el-button>
                <el-button size="small" class="btn-soft btn-soft-success" @click="onBatchGen(row)">批量生成座位</el-button>
                <el-button size="small" class="btn-soft" @click="openSeats(row)">座位维护</el-button>
                <el-button size="small" class="btn-soft btn-soft-danger" @click="onDeleteRoom(row)">删除</el-button>
              </div>
            </template>
          </el-table-column>
        </el-table>
      </section>

      <!-- 用户管理 -->
      <section v-if="activeTab === 'users'" class="card">
        <div class="card-title-row">
          <h3>用户管理</h3>
          <el-button class="btn-soft" @click="loadUsers(); refreshStats()">🔄 刷新</el-button>
        </div>
        <el-table :data="users" stripe class="soft-table">
          <el-table-column prop="id" label="ID" width="64" align="center" />
          <el-table-column prop="username" label="用户名" width="116" />
          <el-table-column prop="real_name" label="姓名"   width="104" />
          <el-table-column prop="student_no" label="学号"  width="120" />
          <el-table-column label="角色" width="96" align="center">
            <template #default="{ row }">
              <span class="tag-pill" :class="roleTagCls[row.role]">
                {{ row.role === 'admin' ? '管理员' : '学生' }}
              </span>
            </template>
          </el-table-column>
          <el-table-column label="信用分" width="96" align="center">
            <template #default="{ row }">
              <span class="credit-chip" :style="{ color: creditColor(row.credit_score) }">
>>>>>>> 958d510 (chore: init smart-study-room with ui redesign)
                {{ row.credit_score }}
              </span>
            </template>
          </el-table-column>
<<<<<<< HEAD
          <el-table-column label="状态" width="80">
            <template #default="{ row }">
              <el-tag size="small" :type="row.status === 'active' ? 'success' : 'info'">
                {{ row.status === 'active' ? '正常' : '禁用' }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="100">
            <template #default="{ row }">
              <el-button
                size="small"
                :type="row.status === 'active' ? 'danger' : 'success'"
                plain
                :disabled="row.role === 'admin'"
=======
          <el-table-column label="状态" width="96" align="center">
            <template #default="{ row }">
              <span class="tag-pill" :class="statusCls[row.status]">
                {{ row.status === 'active' ? '正常' : '禁用' }}
              </span>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="120" align="center">
            <template #default="{ row }">
              <el-button
                v-if="row.role !== 'admin'"
                size="small"
                :class="row.status === 'active' ? 'btn-soft btn-soft-danger' : 'btn-soft btn-soft-success'"
>>>>>>> 958d510 (chore: init smart-study-room with ui redesign)
                @click="toggleUser(row)"
              >
                {{ row.status === 'active' ? '禁用' : '启用' }}
              </el-button>
<<<<<<< HEAD
            </template>
          </el-table-column>
        </el-table>
      </el-tab-pane>
    </el-tabs>
  </div>

  <!-- 房间编辑对话框 -->
  <el-dialog v-model="roomDialog" :title="editingId ? '编辑自习室' : '新建自习室'" width="480px">
    <el-form :model="roomForm" label-width="90px">
      <el-form-item label="名称" required>
        <el-input v-model="roomForm.name" placeholder="如 1F-静音自习室" />
      </el-form-item>
      <el-form-item label="位置">
        <el-input v-model="roomForm.location" />
      </el-form-item>
      <el-form-item label="开放时间">
        <el-time-select v-model="roomForm.open_time" start="05:00" step="00:30" end="12:00" style="width: 120px" />
        <span style="margin: 0 6px">至</span>
        <el-time-select v-model="roomForm.close_time" start="12:00" step="00:30" end="23:30" style="width: 120px" />
      </el-form-item>
      <el-form-item label="默认规模">
        <el-input-number v-model="roomForm.seat_rows" :min="1" :max="30" /> 行
        <el-input-number v-model="roomForm.seat_cols" :min="1" :max="30" style="margin-left: 8px" /> 列
      </el-form-item>
      <el-form-item label="说明">
        <el-input v-model="roomForm.description" type="textarea" :rows="2" />
      </el-form-item>
    </el-form>
    <template #footer>
      <el-button @click="roomDialog = false">取消</el-button>
      <el-button type="primary" @click="saveRoom">保存</el-button>
    </template>
  </el-dialog>

  <!-- 座位维护对话框 -->
  <el-dialog v-model="seatDialog" :title="`座位维护 - ${seatRoom?.name || ''}`" width="720px">
    <el-alert type="info" :closable="false" style="margin-bottom: 10px"
      title="点击「维护/恢复」切换座位状态；维护中的座位不可被预约。" />
    <el-table :data="seatList" stripe max-height="480">
      <el-table-column prop="seat_no" label="座位号" width="80" />
      <el-table-column label="坐标" width="80">
        <template #default="{ row }">{{ row.row_no }},{{ row.col_no }}</template>
      </el-table-column>
      <el-table-column prop="zone" label="区域" width="90" />
      <el-table-column label="电源" width="60">
        <template #default="{ row }">{{ row.has_power ? '✔' : '—' }}</template>
      </el-table-column>
      <el-table-column label="靠窗" width="60">
        <template #default="{ row }">{{ row.near_window ? '✔' : '—' }}</template>
      </el-table-column>
      <el-table-column label="状态" width="80">
        <template #default="{ row }">
          <el-tag size="small" :type="row.status === 'available' ? 'success' : 'warning'">
            {{ row.status === 'available' ? '可用' : '维护' }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="100">
        <template #default="{ row }">
          <el-button size="small" @click="toggleSeatStatus(row)">
            {{ row.status === 'available' ? '设为维护' : '恢复' }}
=======
              <span v-else class="muted">—</span>
            </template>
          </el-table-column>
        </el-table>
      </section>
    </div>
  </div>

  <!-- =============== 房间编辑弹框 =============== -->
  <el-dialog v-model="roomDialog" :title="editingId ? '编辑自习室' : '新建自习室'" width="540px" class="soft-dialog">
    <div class="dialog-body">
      <el-form :model="roomForm" label-width="90px" class="dialog-form">
        <el-form-item label="名称" required>
          <el-input v-model="roomForm.name" placeholder="如 1F-静音自习室" />
        </el-form-item>
        <el-form-item label="位置">
          <el-input v-model="roomForm.location" placeholder="如 图书馆一层东侧" />
        </el-form-item>
        <el-form-item label="开放时间">
          <div class="time-range">
            <el-time-select v-model="roomForm.open_time" start="05:00" step="00:30" end="12:00" style="flex:1" />
            <span class="time-arrow">至</span>
            <el-time-select v-model="roomForm.close_time" start="12:00" step="00:30" end="23:30" style="flex:1" />
          </div>
        </el-form-item>
        <el-form-item label="默认规模">
          <div class="scale-range">
            <el-input-number v-model="roomForm.seat_rows" :min="1" :max="30" controls-position="right" />
            <span class="scale-x">行</span>
            <el-input-number v-model="roomForm.seat_cols" :min="1" :max="30" controls-position="right" />
            <span class="scale-x">列</span>
          </div>
        </el-form-item>
        <el-form-item label="说明">
          <el-input v-model="roomForm.description" type="textarea" :rows="2" placeholder="静音 / 研讨 / 机房 / 靠窗描述等（选填）" />
        </el-form-item>
      </el-form>
    </div>
    <template #footer>
      <div class="dialog-footer">
        <el-button class="btn-soft" @click="roomDialog = false">取消</el-button>
        <el-button type="primary" class="btn-grad-primary" @click="saveRoom">保存</el-button>
      </div>
    </template>
  </el-dialog>

  <!-- =============== 座位维护弹框 =============== -->
  <el-dialog v-model="seatDialog" :title="`座位维护 - ${seatRoom?.name || ''}`" width="820px" class="soft-dialog">
    <div class="seat-tip">
      <span class="seat-tip-icon">ℹ️</span>
      <span>点击右侧按钮切换座位状态，<b>维护中</b>的座位在学生端不可预约。</span>
    </div>
    <el-table :data="seatList" stripe max-height="480" class="soft-table">
      <el-table-column prop="seat_no" label="座位号" width="90" align="center" />
      <el-table-column label="坐标" width="90" align="center">
        <template #default="{ row }">
          <span class="scale-chip">{{ row.row_no }}, {{ row.col_no }}</span>
        </template>
      </el-table-column>
      <el-table-column label="区域" width="110" align="center">
        <template #default="{ row }">
          <span class="zone-chip">{{ row.zone }}</span>
        </template>
      </el-table-column>
      <el-table-column label="电源" width="72" align="center">
        <template #default="{ row }">
          <span v-if="row.has_power" class="chip-ok">✔</span>
          <span v-else class="chip-no">—</span>
        </template>
      </el-table-column>
      <el-table-column label="靠窗" width="72" align="center">
        <template #default="{ row }">
          <span v-if="row.near_window" class="chip-ok">✔</span>
          <span v-else class="chip-no">—</span>
        </template>
      </el-table-column>
      <el-table-column label="状态" width="104" align="center">
        <template #default="{ row }">
          <span class="tag-pill" :class="seatStatusCls[row.status]">
            {{ row.status === 'available' ? '可用' : '维护' }}
          </span>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="140" align="center">
        <template #default="{ row }">
          <el-button
            size="small"
            :class="row.status === 'available' ? 'btn-soft btn-soft-warn' : 'btn-soft btn-soft-success'"
            @click="toggleSeatStatus(row)"
          >
            {{ row.status === 'available' ? '设为维护' : '恢复可用' }}
>>>>>>> 958d510 (chore: init smart-study-room with ui redesign)
          </el-button>
        </template>
      </el-table-column>
    </el-table>
  </el-dialog>
</template>
<<<<<<< HEAD
=======

<style scoped>
.admin-split { grid-template-columns: 280px 1fr; }
.kpi-ok  .kpi-num { color: #6f9d66; }
.kpi-bad .kpi-num { color: #c07474; }

/* ===== 左栏按钮导航 ===== */
.tabs-v { display: flex; flex-direction: column; gap: 6px; }
.tab-btn {
  all: unset; cursor: pointer;
  display: flex; align-items: center; gap: 10px;
  padding: 11px 14px; border-radius: 10px;
  transition: background .15s ease, transform .1s ease;
  font-size: 13.5px;
}
.tab-btn:hover { background: #eef2f8; transform: translateX(1px); }
.tab-btn.active {
  background: linear-gradient(135deg, #cfdae8, #e3eaf4);
  color: #2f4462; font-weight: 700;
  box-shadow: inset 0 1px 0 #fff, 0 1px 2px rgba(108,128,160,.08);
}
.tab-icon { width: 22px; text-align: center; font-size: 16px; }
.tab-label { font-size: 14px; }

/* ===== 低饱和 tag/状态色（与 Notifications 同色系） ===== */
.tag-pill {
  display: inline-block;
  padding: 2px 10px;
  border-radius: 999px;
  font-size: 12px;
  font-weight: 600;
  letter-spacing: .2px;
  border: 1px solid transparent;
}
.tag-role-admin   { background: #f4dedf; color: #a8535a; border-color: #ecd3d5; }
.tag-role-student { background: #dfe7f2; color: #4a678a; border-color: #cfd9e8; }
.tag-st-active    { background: #dbe7d6; color: #577f4e; border-color: #c9dcc3; }
.tag-st-disabled  { background: #e6e9ee; color: #6d7686; border-color: #d5dae2; }
.tag-seat-ok      { background: #dbe7d6; color: #577f4e; border-color: #c9dcc3; }
.tag-seat-maint   { background: #f3e4cd; color: #a07338; border-color: #ebd3b0; }

.credit-chip {
  font-weight: 700;
  font-size: 14px;
  padding: 2px 8px;
  border-radius: 8px;
  background: currentColor;
  background-color: transparent;
}
.credit-chip::before {
  content: '';
  display: inline-block;
  width: 0;
}
.time-chip {
  background: #eef2f8;
  color: #4a678a;
  border-radius: 6px;
  padding: 2px 8px;
  font-size: 12.5px;
  font-weight: 500;
}
.scale-chip {
  background: #eef2f8;
  color: #506078;
  border-radius: 6px;
  padding: 2px 8px;
  font-size: 12.5px;
  font-weight: 500;
  font-variant-numeric: tabular-nums;
}
.zone-chip {
  display: inline-block;
  padding: 2px 10px;
  background: #f2eeef;
  color: #6c6066;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: .5px;
}
.chip-ok  { color: #6f9d66; font-weight: 700; font-size: 14px; }
.chip-no  { color: #b6bcc8; font-size: 14px; }

/* ===== 按钮：柔和 & 主按钮渐变（统一与 Booking 智能分配同质感） ===== */
.quick-actions { display: flex; flex-direction: column; gap: 10px; margin-bottom: 14px; }
.qa-btn { width: 100%; }
.btn-grad-primary {
  background: linear-gradient(135deg, #7e99ba 0%, #5f7ea3 100%) !important;
  border: none !important;
  color: #fff !important;
  box-shadow: 0 2px 6px rgba(95,126,163,.28);
  transition: transform .1s ease, box-shadow .15s ease;
}
.btn-grad-primary:hover {
  transform: translateY(-1px);
  box-shadow: 0 6px 14px rgba(95,126,163,.34);
}
.btn-row { display: inline-flex; gap: 6px; flex-wrap: wrap; justify-content: center; }
.btn-soft {
  background: #f5f7fb !important;
  border: 1px solid #e3e7ef !important;
  color: #4b5567 !important;
  transition: all .12s ease;
}
.btn-soft:hover {
  background: #eef2f8 !important;
  border-color: #cfd6e3 !important;
  color: #2f3848 !important;
}
.btn-soft-success {
  background: #eef5ec !important;
  border-color: #d2e3cc !important;
  color: #4e7846 !important;
}
.btn-soft-success:hover {
  background: #e2efdd !important;
  border-color: #b7d3ae !important;
  color: #3b5f36 !important;
}
.btn-soft-danger {
  background: #f7eaea !important;
  border-color: #ecd2d3 !important;
  color: #a45359 !important;
}
.btn-soft-danger:hover {
  background: #f0d9da !important;
  border-color: #dcbdc0 !important;
  color: #8d3f45 !important;
}
.btn-soft-warn {
  background: #faf1e2 !important;
  border-color: #ecdcb8 !important;
  color: #9a6e30 !important;
}
.btn-soft-warn:hover {
  background: #f5e7cb !important;
  border-color: #e0ca9e !important;
  color: #825826 !important;
}

/* ===== 统一表格视觉：header 浅雾霾蓝、斑马纹淡、行 hover ===== */
.soft-table :deep(.el-table__header-wrapper thead th) {
  background: linear-gradient(180deg, #eef2f8 0%, #e8edf5 100%) !important;
  color: #4b5567 !important;
  font-weight: 600;
  border-bottom: 1px solid #dce2ec !important;
}
.soft-table :deep(.el-table__body-wrapper .el-table__row) {
  transition: background .12s ease;
}
.soft-table :deep(.el-table__body-wrapper .el-table__row--striped td.el-table__cell) {
  background: #fafbfd !important;
}
.soft-table :deep(.el-table__body-wrapper .el-table__row:hover td.el-table__cell) {
  background: #f0f4fa !important;
}
.soft-table :deep(.el-table td.el-table__cell),
.soft-table :deep(.el-table th.el-table__cell) {
  border-bottom: 1px solid #eef1f6 !important;
}
.soft-table :deep(.el-table .cell) {
  padding: 10px 0;
}

/* ===== tips 文字 ===== */
.tips {
  margin: 0; padding-left: 18px;
  display: flex; flex-direction: column; gap: 6px;
  color: #4b5567; font-size: 13px; line-height: 1.65;
}
.tips b { color: #456388; font-weight: 600; }

/* ===== 弹窗统一质感（与 Booking 智能分配弹框同） ===== */
.soft-dialog :deep(.el-dialog) {
  border-radius: 16px !important;
  overflow: hidden;
}
.soft-dialog :deep(.el-dialog__header) {
  background: linear-gradient(135deg, #eef3f9 0%, #e3eaf4 100%) !important;
  margin: 0 !important;
  padding: 18px 22px !important;
  border-bottom: 1px solid #dde4ef;
}
.soft-dialog :deep(.el-dialog__title) {
  color: #2f4462 !important;
  font-weight: 700;
}
.soft-dialog :deep(.el-dialog__body) {
  padding: 20px 22px 8px;
}
.soft-dialog :deep(.el-dialog__footer) {
  padding: 14px 22px 20px;
  border-top: 1px solid #eef1f6;
  background: #fbfcfe;
}

.dialog-body {}
.dialog-form .el-form-item { margin-bottom: 18px; }

.time-range {
  display: flex; align-items: center; gap: 10px;
}
.time-arrow {
  color: #828c9d; font-size: 13px;
}
.scale-range {
  display: flex; align-items: center; gap: 8px;
}
.scale-x { color: #828c9d; font-size: 13px; margin-right: 8px; }

.dialog-footer {
  display: flex; justify-content: flex-end; gap: 10px;
}

/* 座位提示条 */
.seat-tip {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  background: linear-gradient(135deg, #eef3f9 0%, #e3eaf4 100%);
  border: 1px solid #dde4ef;
  color: #40546e;
  padding: 10px 14px;
  border-radius: 12px;
  margin-bottom: 14px;
  font-size: 13px;
  line-height: 1.6;
}
.seat-tip-icon { font-size: 16px; line-height: 1; margin-top: 1px; }
.seat-tip b { color: #2f4462; font-weight: 600; }
</style>
>>>>>>> 958d510 (chore: init smart-study-room with ui redesign)
