<script setup>
import { reactive, ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { message } from '../components/ui/feedback'
import { login, register } from '../api/auth'
import { useAuthStore } from '../stores/auth'
import AppIcon from '../components/AppIcon.vue'
import SButton from '../components/ui/SButton.vue'
import SInput from '../components/ui/SInput.vue'

const router = useRouter()
const route = useRoute()
const auth = useAuthStore()

const mode = ref('login') // login | register
const loading = ref(false)

const loginForm = reactive({ username: 'stu01', password: '123456' })
const regForm = reactive({ username: '', password: '', confirm: '', real_name: '', student_no: '' })

async function onLogin() {
  if (!loginForm.username || !loginForm.password) {
    message.warning('请输入用户名与口令')
    return
  }
  loading.value = true
  try {
    const resp = await login(loginForm)
    auth.setLogin(resp.data)
    message.success('登录成功')
    router.push(route.query.redirect || '/')
  } finally {
    loading.value = false
  }
}

async function onRegister() {
  const f = regForm
  if (!f.username || !f.password || !f.real_name) {
    message.warning('请完整填写必填项')
    return
  }
  if (f.password.length < 6) {
    message.warning('口令至少 6 位')
    return
  }
  if (f.password !== f.confirm) {
    message.warning('两次输入的口令不一致')
    return
  }
  loading.value = true
  try {
    await register({
      username: f.username,
      password: f.password,
      real_name: f.real_name,
      student_no: f.student_no
    })
    message.success('注册成功，请登录')
    loginForm.username = f.username
    mode.value = 'login'
  } finally {
    loading.value = false
  }
}

const features = [
  { icon: 'booking', title: '可视化选座', desc: '平面图实时选座，冲突自动检测' },
  { icon: 'sparkles', title: '智能分配', desc: '按区域与偏好加权推荐最优座位' },
  { icon: 'waitlist', title: '候补递补', desc: '满座自动排队，空位按序递补' },
  { icon: 'credit', title: '信用治理', desc: '履约加分，违约扣分，公平利用' }
]
</script>

<template>
  <div v-reveal class="auth-shell">
    <!-- ============ 左侧：品牌叙事 ============ -->
    <aside class="auth-hero">
      <div class="hero-brand">
        <div class="hero-mark"><AppIcon name="book" :size="20" /></div>
        <div>
          <div class="hero-name">智能共享自习室</div>
          <div class="hero-sub">Smart Study Room</div>
        </div>
      </div>

      <div class="hero-body"><div class="study-art" aria-hidden="true"><span/><span/><span/></div>
        <h1 class="hero-title">让每一次自习<br />都有理想的位置</h1>
        <p class="hero-desc">座位预约 · 智能分配 · 信用治理 —— 面向校园的一站式自习室数字化系统。</p>

        <ul class="hero-features">
          <li v-for="f in features" :key="f.title">
            <span class="feature-icon"><AppIcon :name="f.icon" :size="18" /></span>
            <div>
              <div class="feature-title">{{ f.title }}</div>
              <div class="feature-desc">{{ f.desc }}</div>
            </div>
          </li>
        </ul>
      </div>

      <div class="hero-foot">智能共享自习室预约系统 · 课程设计演示环境</div>
    </aside>

    <!-- ============ 右侧：登录 / 注册 ============ -->
    <main class="auth-panel">
      <div class="auth-card"><header class="auth-heading"><h2>{{ mode === 'login' ? '欢迎回来' : '开启专注时光' }}</h2><p>为今天的学习，留一个好位置。</p></header>
        <div v-active-track class="seg seg-block" role="tablist" aria-label="登录或注册">
          <button
            class="seg-btn"
            role="tab"
            :class="{ active: mode === 'login' }"
            :aria-selected="mode === 'login'"
            @click="mode = 'login'"
          >
            登录
          </button>
          <button
            class="seg-btn"
            role="tab"
            :class="{ active: mode === 'register' }"
            :aria-selected="mode === 'register'"
            @click="mode = 'register'"
          >
            注册
          </button>
        </div>

        <form v-if="mode === 'login'" class="auth-form" @submit.prevent="onLogin">
          <div class="form-field">
            <label class="form-label" for="login-username">用户名</label>
            <SInput id="login-username" v-model="loginForm.username" size="lg" placeholder="用户名" autocomplete="username" />
          </div>
          <div class="form-field">
            <label class="form-label" for="login-password">口令</label>
            <SInput
              id="login-password"
              v-model="loginForm.password"
              type="password"
              size="lg"
              placeholder="口令"
              show-password
              autocomplete="current-password"
              @keyup.enter="onLogin"
            />
          </div>
          <SButton type="submit" variant="primary" size="lg" block :loading="loading">
            登录
          </SButton>
        </form>

        <form v-else class="auth-form" @submit.prevent="onRegister">
          <div class="form-field">
            <label class="form-label" for="reg-username">用户名</label>
            <SInput id="reg-username" v-model="regForm.username" size="lg" placeholder="用户名（≥3 位）" autocomplete="username" />
          </div>
          <div class="form-field">
            <label class="form-label" for="reg-realname">真实姓名</label>
            <SInput id="reg-realname" v-model="regForm.real_name" size="lg" placeholder="真实姓名" />
          </div>
          <div class="form-field">
            <label class="form-label" for="reg-studentno">学号（选填）</label>
            <SInput id="reg-studentno" v-model="regForm.student_no" size="lg" placeholder="学号（选填）" />
          </div>
          <div class="form-field">
            <label class="form-label" for="reg-password">口令</label>
            <SInput id="reg-password" v-model="regForm.password" type="password" size="lg" placeholder="口令（≥6 位）" show-password autocomplete="new-password" />
          </div>
          <div class="form-field">
            <label class="form-label" for="reg-confirm">确认口令</label>
            <SInput id="reg-confirm" v-model="regForm.confirm" type="password" size="lg" placeholder="再次输入口令" show-password autocomplete="new-password" />
          </div>
          <SButton type="submit" variant="primary" size="lg" block :loading="loading">
            注册
          </SButton>
        </form>

        <p class="auth-tip">
          演示账号：stu01 / 123456 · 管理员：admin / admin123
        </p>
      </div>
    </main>
  </div>
</template>

<style scoped>
.auth-shell {
  height: 100%;
  display: grid;
  grid-template-columns: minmax(420px, 46%) 1fr;
  background: var(--canvas);
}

/* ============ 左侧品牌区 ============ */
.auth-hero {
  position: relative;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  padding: 44px 52px 28px;
  background:
    radial-gradient(circle at 88% 6%, rgba(59, 102, 218, .07), transparent 42%),
    radial-gradient(circle at 4% 92%, rgba(31, 145, 96, .05), transparent 40%),
    var(--surface);
  border-right: 1px solid var(--border);
  overflow: hidden;
}

.auth-hero::before {
  content: '';
  position: absolute;
  inset: 0;
  background-image: radial-gradient(rgba(28, 37, 52, .05) 1px, transparent 1px);
  background-size: 26px 26px;
  mask-image: linear-gradient(to bottom, transparent 12%, #000 42%, #000 78%, transparent);
  pointer-events: none;
}

.hero-brand {
  position: relative;
  display: flex;
  align-items: center;
  gap: 12px;
}

.hero-mark {
  width: 40px;
  height: 40px;
  border-radius: var(--r-lg);
  background: var(--primary);
  color: #fff;
  display: grid;
  place-items: center;
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, .18), 0 4px 12px rgba(59, 102, 218, .32);
}

.hero-name {
  font-size: 16px;
  font-weight: 650;
  color: var(--text-1);
  letter-spacing: -.01em;
}

.hero-sub {
  font-size: 10.5px;
  color: var(--text-4);
  letter-spacing: .08em;
  text-transform: uppercase;
  margin-top: 1px;
}

.hero-body {
  position: relative;
  padding: 24px 0;
}

.hero-title {
  font-size: clamp(28px, 3.2vw, 38px);
  line-height: 1.28;
  font-weight: 700;
  letter-spacing: -.02em;
  color: var(--text-1);
}

.hero-desc {
  margin-top: 14px;
  font-size: var(--fs-body);
  line-height: 1.75;
  color: var(--text-3);
  max-width: 40ch;
}

.hero-features {
  list-style: none;
  margin: 34px 0 0;
  padding: 0;
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px 20px;
}

.hero-features li {
  display: flex;
  gap: 11px;
  align-items: flex-start;
}

.feature-icon {
  width: 34px;
  height: 34px;
  flex: 0 0 34px;
  border-radius: var(--r-md);
  background: var(--surface-3);
  color: var(--primary);
  display: grid;
  place-items: center;
}

.feature-title {
  font-size: var(--fs-body-sm);
  font-weight: 600;
  color: var(--text-1);
}

.feature-desc {
  font-size: var(--fs-caption);
  color: var(--text-3);
  margin-top: 2px;
  line-height: 1.5;
}

.hero-foot {
  position: relative;
  font-size: var(--fs-caption);
  color: var(--text-4);
}

/* ============ 右侧表单区 ============ */
.auth-panel {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 32px 24px;
  overflow-y: auto;
}

.auth-card {
  width: 400px;
  max-width: 100%;
}

.auth-form {
  display: flex;
  flex-direction: column;
  gap: 16px;
  margin-top: 22px;
}

.form-field {
  display: flex;
  flex-direction: column;
  gap: 7px;
}

.form-label {
  font-size: var(--fs-caption);
  font-weight: 600;
  color: var(--text-2);
  letter-spacing: .02em;
}

.auth-form .s-btn {
  margin-top: 6px;
}

.auth-tip {
  margin-top: 18px;
  font-size: var(--fs-caption);
  color: var(--text-4);
  text-align: center;
  line-height: 1.7;
  padding-top: 16px;
  border-top: 1px solid var(--hairline);
}

/* ============ 响应式 ============ */
@media (max-width: 920px) {
  .auth-shell {
    grid-template-columns: 1fr;
  }
  .auth-hero {
    display: none;
  }
  .auth-panel {
    background:
      radial-gradient(circle at 85% 4%, rgba(59, 102, 218, .06), transparent 44%),
      var(--canvas);
  }
  .auth-card {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--r-xl);
    box-shadow: var(--shadow-2);
    padding: 26px 24px 20px;
  }
}

@media (max-width: 480px) {
  .auth-panel {
    padding: 20px 14px;
    align-items: flex-start;
    padding-top: max(20px, 8vh);
  }
  .auth-card {
    padding: 20px 16px 16px;
  }
}
</style>
