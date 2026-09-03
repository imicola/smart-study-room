<script setup>
import { ref, computed, onMounted } from 'vue'
import { useAuthStore } from '../stores/auth'
import { getCreditOverview } from '../api/credit'

const auth = useAuthStore()
const overview = ref(null)

const scoreColor = computed(() => {
  const s = overview.value?.score ?? 100
<<<<<<< HEAD
  if (s >= 80) return '#67c23a'
  if (s >= 60) return '#e6a23c'
  return '#f56c6c'
=======
  if (s >= 80) return '#5fa655'
  if (s >= 60) return '#c78941'
  return '#c86a6a'
>>>>>>> 958d510 (chore: init smart-study-room with ui redesign)
})

const banned = computed(() => {
  const until = overview.value?.banned_until
  return until && new Date(until) > new Date() ? new Date(until).toLocaleString('zh-CN', { hour12: false }) : null
})

onMounted(async () => {
  const resp = await getCreditOverview()
  overview.value = resp.data
})
</script>

<template>
<<<<<<< HEAD
  <div class="page-card">
    <h2 style="margin-top: 0">个人中心</h2>

    <div class="grid2">
      <!-- 基本信息卡片 -->
      <div class="card">
        <h3>基本信息</h3>
        <el-descriptions :column="1" border>
          <el-descriptions-item label="用户名">{{ auth.user?.username }}</el-descriptions-item>
          <el-descriptions-item label="姓名">{{ auth.user?.real_name }}</el-descriptions-item>
          <el-descriptions-item label="学号">{{ auth.user?.student_no || '—' }}</el-descriptions-item>
          <el-descriptions-item label="角色">
            <el-tag size="small" :type="auth.isAdmin ? 'danger' : 'primary'">
              {{ auth.isAdmin ? '管理员' : '学生' }}
            </el-tag>
          </el-descriptions-item>
        </el-descriptions>
      </div>

      <!-- 信用卡片 -->
      <div class="card">
        <h3>我的信用</h3>
        <div v-if="overview" class="credit-box">
          <el-progress type="dashboard" :percentage="overview.score" :color="scoreColor" :width="140">
=======
  <div class="split profile-split">
    <div class="split-left">
      <!-- 用户卡片 -->
      <section class="card profile-card">
        <div class="avatar-lg">
          {{ (auth.user?.real_name || auth.user?.username || '?').slice(0, 1) }}
        </div>
        <div class="profile-name">{{ auth.user?.real_name || auth.user?.username }}</div>
        <div class="profile-sub">@{{ auth.user?.username }}</div>
        <div style="margin-top: 8px">
          <el-tag size="small" effect="plain" :type="auth.isAdmin ? 'danger' : 'primary'">
            {{ auth.isAdmin ? '管理员' : '学生' }}
          </el-tag>
        </div>
      </section>

      <!-- 基本信息 -->
      <section class="card">
        <div class="card-title-row"><h3>基本信息</h3></div>
        <div class="info-row"><span>姓名</span><b>{{ auth.user?.real_name || '—' }}</b></div>
        <div class="info-row"><span>用户名</span><b>{{ auth.user?.username || '—' }}</b></div>
        <div class="info-row"><span>学号</span><b>{{ auth.user?.student_no || '—' }}</b></div>
        <div class="info-row"><span>角色</span><b>{{ auth.isAdmin ? '管理员' : '学生' }}</b></div>
      </section>

      <!-- 信用卡 -->
      <section class="card">
        <div class="card-title-row"><h3>我的信用</h3></div>
        <div v-if="overview" class="credit-box">
          <el-progress type="dashboard" :percentage="overview.score" :color="scoreColor" :width="152">
>>>>>>> 958d510 (chore: init smart-study-room with ui redesign)
            <template #default>
              <div class="score-num" :style="{ color: scoreColor }">{{ overview.score }}</div>
              <div class="score-label">信用分</div>
            </template>
          </el-progress>
          <el-alert
            v-if="banned"
            type="error" :closable="false" style="margin-top: 12px"
            :title="`信用分低于 60，禁止预约至 ${banned}`"
          />
          <el-alert
            v-else type="success" :closable="false" style="margin-top: 12px"
            title="信用状态正常，可正常预约"
          />
          <div class="rule-tip">
            规则：违约 −8 · 迟到取消 −2 · 按期履约 +1 · 低于 60 分禁约 3 天
          </div>
        </div>
<<<<<<< HEAD
      </div>
    </div>

    <!-- 信用流水 -->
    <h3>信用流水</h3>
    <el-table :data="overview?.logs || []" stripe max-height="400">
      <el-table-column label="时间" width="170">
        <template #default="{ row }">{{ new Date(row.created_at).toLocaleString('zh-CN', { hour12: false }) }}</template>
      </el-table-column>
      <el-table-column label="变动" width="90">
        <template #default="{ row }">
          <span :class="row.delta > 0 ? 'up' : 'down'">
            {{ row.delta > 0 ? '+' + row.delta : row.delta }}
          </span>
        </template>
      </el-table-column>
      <el-table-column label="事由" prop="reason" min-width="260" />
      <el-table-column label="关联预约" width="100">
        <template #default="{ row }">#{{ row.reservation_id ?? '—' }}</template>
      </el-table-column>
    </el-table>
=======
      </section>
    </div>

    <div class="split-right">
      <section class="card">
        <div class="card-title-row">
          <h3>信用分流水</h3>
          <span class="muted">最新 {{ overview?.logs?.length || 0 }} 条记录</span>
        </div>
        <el-table :data="overview?.logs || []" stripe max-height="600">
          <el-table-column label="时间" width="180">
            <template #default="{ row }">{{ new Date(row.created_at).toLocaleString('zh-CN', { hour12: false }) }}</template>
          </el-table-column>
          <el-table-column label="变动" width="100">
            <template #default="{ row }">
              <span :class="row.delta > 0 ? 'up' : 'down'">
                {{ row.delta > 0 ? '+' + row.delta : row.delta }}
              </span>
            </template>
          </el-table-column>
          <el-table-column label="事由" prop="reason" min-width="260" />
          <el-table-column label="关联预约" width="110">
            <template #default="{ row }">#{{ row.reservation_id ?? '—' }}</template>
          </el-table-column>
        </el-table>
        <el-empty v-if="!overview?.logs?.length" description="暂无信用记录" />
      </section>
    </div>
>>>>>>> 958d510 (chore: init smart-study-room with ui redesign)
  </div>
</template>

<style scoped>
<<<<<<< HEAD
.grid2 {
  display: flex;
  gap: 16px;
  margin-bottom: 18px;
  flex-wrap: wrap;
}
.card {
  flex: 1;
  min-width: 320px;
  border: 1px solid #ebeef5;
  border-radius: 8px;
  padding: 14px;
}
.credit-box {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 8px 0;
}
.score-num {
  font-size: 30px;
  font-weight: 700;
}
.score-label {
  font-size: 12px;
  color: #909399;
}
.rule-tip {
  font-size: 12px;
  color: #909399;
  margin-top: 10px;
}
.up {
  color: #67c23a;
  font-weight: 600;
}
.down {
  color: #f56c6c;
  font-weight: 600;
}
=======
.profile-split { grid-template-columns: 320px 1fr; }

.profile-card {
  text-align: center;
  background: linear-gradient(150deg, #eef3f9, #fbfcfe);
}
.avatar-lg {
  width: 76px; height: 76px; border-radius: 22px;
  background: linear-gradient(145deg, #8ea6c4, #5f7ea3);
  color: #fff;
  display: grid; place-items: center;
  font-size: 32px; font-weight: 700;
  margin: 4px auto 12px;
  box-shadow: inset 0 1px 0 rgba(255,255,255,.2), 0 10px 22px rgba(95,126,163,.22);
}
.profile-name {
  font-size: 18px; font-weight: 700; color: #2b3240;
}
.profile-sub {
  font-size: 12.5px; color: #828c9d; margin-top: 2px;
}

.info-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 9px 0;
  border-bottom: 1px dashed #eef1f6;
  font-size: 13.5px;
}
.info-row:last-child { border-bottom: none; }
.info-row span { color: #828c9d; }
.info-row b { color: #2b3240; font-weight: 600; }

.credit-box {
  display: flex; flex-direction: column;
  align-items: center; padding: 8px 0 4px;
}
.score-num { font-size: 30px; font-weight: 700; line-height: 1; }
.score-label {
  font-size: 12px; color: #828c9d; margin-top: 2px;
}
.rule-tip {
  margin-top: 12px; padding: 10px 12px;
  background: #f6f8fb; border-radius: 10px;
  font-size: 12px; color: #6b7280; line-height: 1.6;
}

.up   { color: #5fa655; font-weight: 700; }
.down { color: #c86a6a; font-weight: 700; }
>>>>>>> 958d510 (chore: init smart-study-room with ui redesign)
</style>
