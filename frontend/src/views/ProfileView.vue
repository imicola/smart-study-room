<script setup>
import { usePagination } from '../composables/usePagination'
import SPagination from '../components/ui/SPagination.vue'
import { ref, computed, onMounted } from 'vue'
import { useAuthStore } from '../stores/auth'
import { getCreditOverview } from '../api/credit'
import SEmpty from '../components/ui/SEmpty.vue'
import SGauge from '../components/ui/SGauge.vue'
import SBanner from '../components/ui/SBanner.vue'

const auth = useAuthStore()
const overview = ref(null)

const scoreColor = computed(() => {
  const s = overview.value?.score ?? 100
  if (s >= 80) return 'var(--green)'
  if (s >= 60) return 'var(--amber)'
  return 'var(--red)'
})

const banned = computed(() => {
  const until = overview.value?.banned_until
  return until && new Date(until) > new Date() ? new Date(until).toLocaleString('zh-CN', { hour12: false }) : null
})

onMounted(async () => {
  if (!auth.isStudent) return
  const resp = await getCreditOverview()
  overview.value = resp.data
})
const creditLogs = computed(() => overview.value?.logs || [])
const { page, pages, pageItems } = usePagination(creditLogs, null)
</script>

<template>
  <div v-reveal class="page-view">
    <header class="view-heading" data-page-title>
      <h1>个人中心</h1>
      <p class="heading-sub">账户信息与信用分记录</p>
    </header>
    <div class="split profile-split" :class="{ 'profile-admin': auth.isAdmin }">
    <div class="split-left">
      <!-- 用户卡片 -->
      <section class="card profile-card responsive-compact">
        <div class="avatar-lg">
          {{ (auth.user?.real_name || auth.user?.username || '?').slice(0, 1) }}
        </div>
        <div class="profile-name">{{ auth.user?.real_name || auth.user?.username }}</div>
        <div class="profile-sub">@{{ auth.user?.username }}</div>
        <div style="margin-top: 10px">
          <span class="role-pill" :class="auth.isAdmin ? 'role-pill--admin' : 'role-pill--student'">
            {{ auth.isAdmin ? '管理员' : '学生' }}
          </span>
        </div>
      </section>

      <!-- 基本信息 -->
      <section class="card responsive-compact">
        <div class="card-title-row"><h3>基本信息</h3></div>
        <div class="info-row"><span>姓名</span><b>{{ auth.user?.real_name || '—' }}</b></div>
        <div class="info-row"><span>用户名</span><b>{{ auth.user?.username || '—' }}</b></div>
        <div v-if="auth.isStudent" class="info-row"><span>学号</span><b>{{ auth.user?.student_no || '—' }}</b></div>
        <div class="info-row"><span>角色</span><b>{{ auth.isAdmin ? '管理员' : '学生' }}</b></div>
        <div class="info-row"><span>账号状态</span><b :class="{ 'status-off': auth.user?.status !== 'active' }">{{ auth.user?.status === 'active' ? '正常' : '已禁用' }}</b></div>
      </section>

      <!-- 信用卡 -->
      <section v-if="auth.isStudent" class="card responsive-compact">
        <div class="card-title-row"><h3>我的信用</h3></div>
        <div v-if="overview" class="credit-box">
          <SGauge :value="overview.score" :color="scoreColor" :size="152">
            <div class="score-num" :style="{ color: scoreColor }">{{ overview.score }}</div>
            <div class="score-label">信用分</div>
          </SGauge>
          <SBanner
            v-if="banned"
            type="error"
            style="margin-top: 14px; width: 100%"
            :title="`信用分低于 60，禁止预约至 ${banned}`"
          />
          <SBanner
            v-else type="success"
            style="margin-top: 14px; width: 100%"
            title="信用状态正常，可正常预约"
          />
          <div class="rule-tip">
            规则：违约 −8 · 迟到取消 −2 · 按期履约 +1 · 低于 60 分禁约 3 天
          </div>
        </div>
      </section>
    </div>

    <div v-if="auth.isStudent" class="split-right">
      <section class="card">
        <div class="card-title-row">
          <h3>信用分流水</h3>
          <span class="muted">最新 {{ overview?.logs?.length || 0 }} 条记录</span>
        </div>
        <div v-list-motion="pageItems.map(row => row.id + row.status).join()" class="table-wrap">
          <div class="table-scroll" tabindex="0" aria-label="信用分流水表格，可左右滑动">
            <table class="table credit-table">
              <thead>
                <tr>
                  <th style="width:180px">时间</th>
                  <th style="width:100px">变动</th>
                  <th style="min-width:240px">事由</th>
                  <th style="width:110px">关联预约</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="row in pageItems" :key="row.id">
                  <td class="num">{{ new Date(row.created_at).toLocaleString('zh-CN', { hour12: false }) }}</td>
                  <td>
                    <span :class="row.delta > 0 ? 'up' : 'down'">
                      {{ row.delta > 0 ? '+' + row.delta : row.delta }}
                    </span>
                  </td>
                  <td>{{ row.reason }}</td>
                  <td class="num">#{{ row.reservation_id ?? '—' }}</td>
                </tr>
              </tbody>
            </table>
            <SEmpty v-if="!overview?.logs?.length" description="暂无信用记录" />
          </div>
        </div>
        <SPagination v-model="page" :pages="pages" :total="creditLogs.length" />
      </section>
    </div>
    </div>
  </div>
</template>

<style scoped>

.credit-table { min-width: 640px; }


.profile-card {
  text-align: center;
  background: var(--surface-2);
}
.avatar-lg {
  width: 76px;
  height: 76px;
  border-radius: var(--r-2xl);
  background: var(--primary-weak);
  color: var(--primary-active);
  display: grid;
  place-items: center;
  font-size: 32px;
  font-weight: 700;
  margin: 6px auto 14px;
}
.profile-name {
  font-size: 18px;
  font-weight: 650;
  color: var(--text-1);
  letter-spacing: -.01em;
}
.profile-sub {
  font-size: var(--fs-caption);
  color: var(--text-3);
  margin-top: 3px;
}
.role-pill {
  display: inline-flex;
  font-size: 11px;
  font-weight: 500;
  line-height: 1;
  padding: 4px 10px;
  border-radius: var(--r-full);
}
.role-pill--student {
  background: var(--primary-weak);
  color: var(--primary-active);
}
.role-pill--admin {
  background: var(--red-weak);
  color: var(--red-strong);
}

.info-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px 0;
  border-bottom: 1px solid var(--hairline);
  font-size: var(--fs-body-sm);
}
.info-row:last-child { border-bottom: none; }
.info-row span { color: var(--text-3); }
.info-row b { color: var(--text-1); font-weight: 600; }
.info-row b.status-off { color: var(--red-strong); }

.credit-box {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 8px 0 4px;
}
.score-num {
  font-size: 30px;
  font-weight: 700;
  line-height: 1;
  font-variant-numeric: tabular-nums;
}
.score-label {
  font-size: var(--fs-caption);
  color: var(--text-3);
  margin-top: 3px;
}
.rule-tip {
  margin-top: 14px;
  padding: 10px 12px;
  background: var(--surface-3);
  border-radius: var(--r-lg);
  font-size: var(--fs-caption);
  color: var(--text-3);
  line-height: 1.6;
  width: 100%;
  box-sizing: border-box;
  text-align: center;
}

.up   { color: var(--green-strong); font-weight: 700; font-variant-numeric: tabular-nums; }
.down { color: var(--red-strong); font-weight: 700; font-variant-numeric: tabular-nums; }
</style>
