<script setup>
<<<<<<< HEAD
import { useAuthStore } from '../stores/auth'

const auth = useAuthStore()
</script>

<template>
  <div class="page-card">
    <h2>欢迎使用智能共享自习室预约系统</h2>
    <p v-if="auth.isLoggedIn">
      你好，{{ auth.user?.real_name || auth.user?.username }}！
      更多功能（座位预约、热力图等）正在开发中，敬请期待。
    </p>
  </div>
</template>
=======
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const router = useRouter()
const auth = useAuthStore()

const who = computed(() => auth.user?.real_name || auth.user?.username || '同学')
const roleText = computed(() => (auth.isAdmin ? '管理员' : '学生'))

const shortcuts = [
  { title: '座位预约', desc: '手动选座 · 智能分配', icon: '🪑', to: '/booking', tone: 'primary' },
  { title: '我的预约', desc: '签到 · 临时离开 · 签退', icon: '📑', to: '/mine', tone: 'success' },
  { title: '热力图统计', desc: '座位利用率 · 高峰时段', icon: '📊', to: '/analytics', tone: 'warm' },
  { title: '消息中心', desc: '预约结果 · 违约警告 · 递补', icon: '🔔', to: '/notifications', tone: 'violet' }
]
const cardToneClass = {
  primary: 'tone-primary',
  success: 'tone-success',
  warm: 'tone-warm',
  violet: 'tone-violet'
}
</script>

<template>
  <!-- 首页：页面级双栏 -->
  <div class="split home-split">
    <!-- 左栏：欢迎 + 账户 KPI + 快速贴士 -->
    <div class="split-left">
      <section class="card welcome-card">
        <div class="hello">
          <div class="hello-avatar">{{ who.slice(0, 1) }}</div>
          <div>
            <div class="hello-role">
              <el-tag size="small" effect="plain" :type="auth.isAdmin ? 'danger' : 'primary'">
                {{ roleText }}
              </el-tag>
            </div>
            <h2 class="hello-name">你好，{{ who }}</h2>
            <p class="hello-sub">今天也要高效学习呀 ✨</p>
          </div>
        </div>
      </section>

      <section class="card">
        <div class="card-title-row">
          <h3>账户概览</h3>
        </div>
        <div class="kpi-grid">
          <div class="kpi">
            <div class="kpi-num">100</div>
            <div class="kpi-label">初始信用分</div>
          </div>
          <div class="kpi">
            <div class="kpi-num">3</div>
            <div class="kpi-label">自习室可用</div>
          </div>
          <div class="kpi">
            <div class="kpi-num">158</div>
            <div class="kpi-label">座位总数</div>
          </div>
          <div class="kpi">
            <div class="kpi-num">08:00<br/><span style="font-size:11px;font-weight:500">~ 22:00</span></div>
            <div class="kpi-label">今日开放</div>
          </div>
        </div>
      </section>

      <section class="card tips-card">
        <h3>使用小贴士</h3>
        <ul class="tips">
          <li>距开始不足 30 分钟取消预约将扣 <b>2 分</b>信用分</li>
          <li>超时未签到会自动记为违约，扣 <b>8 分</b>，并释放座位</li>
          <li>满座时段可加入 <b>候补</b>，空位释放时按序自动递补</li>
          <li>信用分低于 60，<b>3 天内</b>无法发起新预约</li>
        </ul>
      </section>
    </div>

    <!-- 右栏：功能入口卡 -->
    <div class="split-right">
      <section class="card">
        <div class="card-title-row">
          <h3>快速入口</h3>
          <span class="muted">点击卡片直接进入对应功能</span>
        </div>
        <div class="shortcut-grid">
          <div
            v-for="s in shortcuts"
            :key="s.to"
            class="shortcut"
            :class="cardToneClass[s.tone]"
            @click="router.push(s.to)"
          >
            <div class="shortcut-icon">{{ s.icon }}</div>
            <div>
              <div class="shortcut-title">{{ s.title }}</div>
              <div class="shortcut-desc">{{ s.desc }}</div>
            </div>
            <div class="chev">→</div>
          </div>
        </div>
      </section>

      <section class="card">
        <div class="card-title-row">
          <h3>系统介绍</h3>
        </div>
        <div class="intro-grid">
          <div class="intro-cell">
            <div class="intro-label">在线预约</div>
            <div class="intro-text">平面图可视化选座，时段冲突自动检测，支持签到 / 临时离开 / 签退全生命周期。</div>
          </div>
          <div class="intro-cell">
            <div class="intro-label">智能分配</div>
            <div class="intro-text">按区域、电源、靠窗偏好加权评分，一键推荐最优座位或直接自动下单。</div>
          </div>
          <div class="intro-cell">
            <div class="intro-label">热力分析</div>
            <div class="intro-text">座位×小时占用热力图、近14天趋势、高峰时段、热门座位 Top10 可视化。</div>
          </div>
          <div class="intro-cell">
            <div class="intro-label">信用治理</div>
            <div class="intro-text">违约扣分、履约加分、低分限约，配合满座候补递补机制，公平利用座位资源。</div>
          </div>
        </div>
      </section>
    </div>
  </div>
</template>

<style scoped>
.home-split {
  grid-template-columns: 320px 1fr;
}

/* 欢迎卡 */
.welcome-card {
  background:
    linear-gradient(145deg, #eef3f9, #f7f9fc);
}
.hello {
  display: flex;
  gap: 14px;
  align-items: center;
}
.hello-avatar {
  width: 54px;
  height: 54px;
  border-radius: 14px;
  background: linear-gradient(145deg, #8ea6c4, #5f7ea3);
  color: #fff;
  display: grid;
  place-items: center;
  font-weight: 700;
  font-size: 22px;
  box-shadow: inset 0 1px 0 rgba(255,255,255,.25), 0 8px 18px rgba(95,126,163,.22);
}
.hello-role { margin-bottom: 2px; }
.hello-name {
  margin: 4px 0 2px;
  font-size: 20px;
}
.hello-sub {
  margin: 0;
  color: #828c9d;
  font-size: 13px;
}

/* 贴士 */
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
.tips b {
  color: #456388;
  font-weight: 600;
}

/* 快速入口 */
.shortcut-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
}
.shortcut {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 16px 18px;
  border-radius: 14px;
  cursor: pointer;
  border: 1px solid #eef1f6;
  background: #fbfcfe;
  transition: transform .2s ease, box-shadow .2s ease, border-color .2s ease;
}
.shortcut:hover {
  transform: translateY(-2px);
  box-shadow: 0 10px 24px rgba(108,128,160,.12);
  border-color: transparent;
}
.shortcut-icon {
  width: 42px;
  height: 42px;
  border-radius: 12px;
  display: grid;
  place-items: center;
  font-size: 20px;
  background: #fff;
  box-shadow: 0 1px 2px rgba(108,128,160,.06), 0 4px 10px rgba(108,128,160,.08);
  flex-shrink: 0;
}
.shortcut-title {
  font-size: 15px;
  font-weight: 600;
  color: #2b3240;
}
.shortcut-desc {
  margin-top: 2px;
  font-size: 12px;
  color: #828c9d;
}
.shortcut .chev {
  margin-left: auto;
  color: #a2abb9;
  font-size: 16px;
  transition: transform .2s ease, color .2s ease;
}
.shortcut:hover .chev {
  transform: translateX(3px);
  color: #456388;
}

.tone-primary .shortcut-icon { background: linear-gradient(145deg, #dce8f7, #eff4fb); }
.tone-success .shortcut-icon { background: linear-gradient(145deg, #dff1e0, #eff9f0); }
.tone-warm    .shortcut-icon { background: linear-gradient(145deg, #f6e7d0, #fbf2e3); }
.tone-violet  .shortcut-icon { background: linear-gradient(145deg, #e4ddf5, #f1ecfa); }

/* 系统介绍 */
.intro-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 14px;
}
.intro-cell {
  border-radius: 12px;
  padding: 14px 16px;
  background: linear-gradient(150deg, #f7f9fc, #eef2f8);
  border: 1px solid #eef1f6;
}
.intro-label {
  font-size: 13px;
  font-weight: 700;
  color: #456388;
  margin-bottom: 4px;
  letter-spacing: .3px;
}
.intro-text {
  font-size: 12.5px;
  color: #5b6576;
  line-height: 1.65;
}

@media (max-width: 1100px) {
  .shortcut-grid, .intro-grid {
    grid-template-columns: 1fr;
  }
}
</style>
>>>>>>> 958d510 (chore: init smart-study-room with ui redesign)
