<script setup>
import { nextTick, onMounted, onUnmounted, reactive, ref, watch } from 'vue'
import { gsap } from 'gsap'
import { message, confirmDialog, feedbackState } from './ui/feedback'
import { createReservation } from '../api/reservation'
import { deleteAIConversation, listAIConversations, listAIMessages, streamAIChat } from '../api/ai'

const emit = defineEmits(['reservation-created'])
const open = ref(false)
const showHistory = ref(false)
const conversations = ref([])
const conversationId = ref(0)
const messages = ref([])
const input = ref('')
const sending = ref(false)
const sendPulse = ref(0)
const pulseActive = ref(false)
const messageList = ref(null)
const lastPrompt = ref('')
const textareaRef = ref(null)
let controller = null
const shellRef = ref(null)
const launcherRef = ref(null)
const ambientRef = ref(null)
const narrow = ref(window.matchMedia('(max-width: 1024px)').matches)
const media = window.matchMedia('(max-width: 1024px)')
let animationContext
let ambientTweens = []
let historyRequest = 0
const loadingHistory = ref(false)
const busy = () => sending.value || Boolean(bookingRecKey.value) || loadingHistory.value
const reducedMotion = () => window.matchMedia('(prefers-reduced-motion: reduce)').matches
function syncMedia() { narrow.value = media.matches }
function stopAmbientFlow() {
  ambientTweens.forEach(tween => tween.kill())
  ambientTweens = []
}
function syncAmbientFlow() {
  stopAmbientFlow()
}
function visibleRecommendations(msg) {
  return (msg.recommendations || []).filter(rec => rec.booked || (!msg.historical && !rec.dismissed))
}
async function settleRecommendations() {
  await nextTick()
  const list = messageList.value
  if (!list) return
  const outgoing = [...list.querySelectorAll('.seat-rec.is-disabled')]
  if (outgoing.length && !reducedMotion()) {
    await new Promise(resolve => animationContext.add(() => {
      gsap.to(outgoing, { x: 100, autoAlpha: 0, stagger: .06, duration: .3, ease: 'power2.in', onComplete: resolve, onInterrupt: resolve })
    }))
  }
  const before = new Map([...list.querySelectorAll('.message, .seat-rec:not(.is-disabled)')].map(el => [el, el.getBoundingClientRect().top]))
  for (const msg of messages.value) for (const rec of msg.recommendations || []) {
    if (rec.disabled && !rec.booked) rec.dismissed = true
  }
  await nextTick()
  // Keep the conversation anchored to its latest response as the cards leave.
  list.scrollTop = list.scrollHeight
  if (!reducedMotion()) animationContext.add(() => {
    const offsets = new Map([...before].filter(([el]) => el.isConnected).map(([el, top]) => [el, top - el.getBoundingClientRect().top]))
    for (const [el, delta] of offsets) {
      // Nested cards inherit their message's movement; animate only their remaining displacement.
      const parentDelta = el.classList.contains('seat-rec') ? (offsets.get(el.closest('.message')) || 0) : 0
      const offset = delta - parentDelta
      if (Math.abs(offset) > 1) gsap.fromTo(el, { y: offset }, { y: 0, duration: .48, ease: 'power3.out', clearProps: 'transform' })
    }
  })
}
function enterCard(el, done) {
  animationContext.add(() => gsap.fromTo(el, { autoAlpha: 0, y: 14 }, {
    autoAlpha: 1, y: 0, duration: reducedMotion() ? 0 : .4, ease: 'power3.out', clearProps: 'all', onComplete: done, onInterrupt: done
  }))
}

const quickPrompts = ['我的状态', '未读通知', '帮我选座']
const zoneNames = { quiet: '静音区', regular: '普通区', discussion: '研讨区', computer: '机房区' }

function adjustTextareaHeight() {
  const el = textareaRef.value
  if (!el) return
  const prevScrollTop = el.scrollTop
  el.style.height = 'auto'
  const minHeight = 34
  const maxHeight = 120
  const scrollHeight = el.scrollHeight

  if (scrollHeight <= minHeight) {
    el.style.height = `${minHeight}px`
    el.style.overflowY = 'hidden'
  } else if (scrollHeight >= maxHeight) {
    el.style.height = `${maxHeight}px`
    el.style.overflowY = 'auto'
    el.scrollTop = prevScrollTop
  } else {
    el.style.height = `${scrollHeight}px`
    el.style.overflowY = 'hidden'
  }
}

async function loadConversations() {
  try {
    const response = await listAIConversations()
    conversations.value = response.data || []
  } catch { message.info('暂时无法加载历史会话，请稍后重试。') }
}
async function selectConversation(item) {
  if (busy()) return
  const request = ++historyRequest
  loadingHistory.value = true
  try {
    const response = await listAIMessages(item.id)
    if (request !== historyRequest) return
    conversationId.value = item.id
    messages.value = (response.data || []).filter(m => m.role !== 'system' && m.role !== 'tool').map(m => ({ ...m, historical: true }))
    showHistory.value = false
    scrollBottom()
  } catch { message.info('会话加载失败，请重试。') }
  finally { loadingHistory.value = false }
}
function newConversation() {
  if (busy()) return
  pulseActive.value = false
  conversationId.value = 0
  messages.value = []
  showHistory.value = false
}
async function removeConversation(item) {
  try { await confirmDialog(`删除“${item.title}”及其消息？`, '删除会话', { type: 'warning' }) } catch { return }
  await deleteAIConversation(item.id)
  if (conversationId.value === item.id) newConversation()
  await loadConversations()
}
async function scrollBottom() {
  await nextTick()
  if (messageList.value) messageList.value.scrollTop = messageList.value.scrollHeight
}
async function send(text = input.value) {
  const prompt = String(text || '').trim()
  if (!prompt || busy()) return
  sendPulse.value += 1
  pulseActive.value = open.value && !reducedMotion()
  lastPrompt.value = prompt
  input.value = ''
  messages.value.push({ role: 'user', content: prompt, status: 'complete' })
  const assistant = reactive({ role: 'assistant', content: '', recommendations: [], status: 'streaming' })
  messages.value.push(assistant)
  sending.value = true
  controller = new AbortController()
  scrollBottom()
  try {
    await streamAIChat({ conversation_id: conversationId.value || undefined, message: prompt }, (event, data) => {
      if (event === 'meta') conversationId.value = data.conversation_id
      if (event === 'delta') assistant.content += data.content || ''
      if (event === 'card') assistant.recommendations = data.recommendations || []
      if (event === 'done') assistant.status = 'complete'
      if (event === 'error') throw new Error(data.message || 'AI 暂时不可用')
      scrollBottom()
    }, controller.signal)
    await loadConversations()
  } catch (error) {
    assistant.status = 'failed'
    assistant.error = error.name === 'AbortError' ? '回复已停止' : error.message
  } finally {
    sending.value = false
    controller = null
    scrollBottom()
  }
}
const bookingRecKey = ref('')

function stop() { controller?.abort() }
async function book(rec) {
  if (busy() || rec.disabled || rec.booked) return
  const recKey = `${rec.seat_id}-${rec.date}-${rec.start_time}`
  bookingRecKey.value = recKey
  try {
    await confirmDialog(
      `确认预约 ${rec.room_name} ${rec.seat_no}？\n${rec.date} ${rec.start_time}–${rec.end_time}`,
      '最终预约确认', { confirmButtonText: '确认预约', cancelButtonText: '再想想' }
    )
  } catch { bookingRecKey.value = ''; return }
  try {
    const response = await createReservation({ seat_id: rec.seat_id, date: rec.date, start_time: rec.start_time, end_time: rec.end_time })
    message.success(`预约成功：${response.data.room_name} ${response.data.seat_no}`)
    messages.value.push({ role: 'assistant', content: `已预约 ${response.data.room_name} ${response.data.seat_no}，请按时签到。`, status: 'local' })
    emit('reservation-created', response.data)

    // 预约成功后，自动禁用所有推荐卡片的选择按钮，避免重复与多余预约
    for (const msg of messages.value) {
      if (msg.recommendations?.length) {
        for (const r of msg.recommendations) {
          r.disabled = true
        }
      }
    }
    rec.booked = true
    await settleRecommendations()
  } catch {
    message.info('该推荐可能已失效，请让助手重新推荐。')
  } finally {
    bookingRecKey.value = ''
  }
}
function onComposerEnter(event) {
  if (event.isComposing || event.keyCode === 229) return
  event.preventDefault()
  send()
}
function onKeydown(event) {
  if (event.defaultPrevented || feedbackState.box) return
  if (event.key === 'Escape' && open.value) { open.value = false; nextTick(() => launcherRef.value?.focus()) }
  if (event.key === 'Tab' && open.value && narrow.value) {
    const items = [...shellRef.value.querySelectorAll('button:not(:disabled), textarea')].filter(el => el.getClientRects().length)
    const first = items[0], last = items.at(-1)
    if (!shellRef.value?.contains(document.activeElement)) { event.preventDefault(); first?.focus() }
    else if (event.shiftKey && document.activeElement === first) { event.preventDefault(); last?.focus() }
    else if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first?.focus() }
  }
}
watch(input, async () => {
  await nextTick()
  adjustTextareaHeight()
})
watch(showHistory, async (val) => {
  if (!val) {
    await nextTick()
    adjustTextareaHeight()
  }
})
watch(() => [open.value, messages.value.length, showHistory.value, conversationId.value], syncAmbientFlow)
watch(open, (value) => {
  if (value) {
    loadConversations()
    scrollBottom()
    nextTick(() => { adjustTextareaHeight(); (showHistory.value ? shellRef.value?.querySelector('.header-actions button') : textareaRef.value)?.focus({ preventScroll: true }) })
  } else {
    pulseActive.value = false
    nextTick(() => launcherRef.value?.focus({ preventScroll: true }))
  }
})
onMounted(() => {
  animationContext = gsap.context(() => {}, shellRef.value)
  media.addEventListener('change', syncMedia)
  window.addEventListener('keydown', onKeydown)
  nextTick(adjustTextareaHeight)
  syncAmbientFlow()
})
onUnmounted(() => { window.removeEventListener('keydown', onKeydown); controller?.abort(); stopAmbientFlow(); animationContext?.revert(); media.removeEventListener('change', syncMedia) })
</script>

<template>
  <Teleport to="body">
    <Transition name="backdrop">
      <button v-if="open && narrow" class="ai-backdrop" aria-label="关闭 AI 助手" @click="open = false" @wheel.prevent @touchmove.prevent />
    </Transition>
    <section ref="shellRef" class="ai-shell" :class="{ 'is-open': open }" :role="open ? 'dialog' : undefined" :aria-modal="open && narrow ? true : undefined" aria-label="AI 学习助手">
      <button v-show="!open" ref="launcherRef" class="ai-fab" type="button" aria-label="打开 AI 助手" :aria-expanded="open" aria-controls="ai-panel" @click="open = true">
        <span class="fab-icon" aria-hidden="true">✦</span><span class="fab-label">AI 助手</span>
      </button>
      <div id="ai-panel" class="ai-sheet" :inert="!open" :aria-hidden="!open">
        <div ref="ambientRef" class="ambient-gradient" :class="{ 'is-flowing': open && !messages.length && !showHistory && !conversationId }" aria-hidden="true">
          <span class="ambient-blob ambient-blob-a" />
          <span class="ambient-blob ambient-blob-b" />
          <span class="ambient-blob ambient-blob-c" />
        </div>
        <div v-if="open && pulseActive" :key="sendPulse" class="send-pulse" aria-hidden="true" @animationend.self="pulseActive = false">
          <span class="pulse-wave" />
        </div>
        <header class="ai-header">
          <div class="assistant-brand"><span class="brand-spark" aria-hidden="true">✦</span><b>AI 助手</b></div>
          <div class="header-actions">
            <button type="button" :disabled="busy()" @click="newConversation">＋ 新对话</button>
            <button class="history-button" type="button" :disabled="busy()" :aria-pressed="showHistory" aria-label="历史记录" title="历史记录" @click="showHistory = !showHistory">
              <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M3 12a9 9 0 1 0 3-6.7L3.5 7.8M3.5 3.8v4h4M12 7.5V12l3 1.8" /></svg>
            </button>
            <button type="button" aria-label="关闭" @click="open = false">×</button>
          </div>
        </header>
        <div v-if="showHistory" class="history-panel">
          <div v-if="!conversations.length" class="empty">还没有历史会话</div>
          <div v-for="item in conversations" :key="item.id" class="history-item" :class="{ active: item.id === conversationId }">
            <button type="button" :disabled="loadingHistory" @click="selectConversation(item)"><span>{{ item.title }}</span><small>{{ new Date(item.updated_at).toLocaleString() }}</small></button>
            <button class="delete" type="button" :disabled="busy()" aria-label="删除会话" @click="removeConversation(item)">×</button>
          </div>
        </div>
        <div v-else ref="messageList" class="message-list"><div class="conversation-stack">
          <div v-if="!messages.length" class="welcome">
            <span class="welcome-icon">✦</span><b>把找座位的时间，<br>留给专注。</b><p>告诉我你的学习计划，<br>一起找到适合你的那个位置。</p>
          </div>
          <div v-for="(message, index) in messages" :key="index" class="message" :class="message.role">
            <div v-if="message.content" class="bubble">{{ message.content }}</div>
            <TransitionGroup v-if="message.recommendations?.length" tag="div" class="recommendations" :css="false" @enter="enterCard">
              <article
                v-for="rec in visibleRecommendations(message)"
                :key="`${rec.seat_id}-${rec.date}-${rec.start_time}`"
                class="seat-rec"
                :class="{ 'is-booked': rec.booked, 'is-disabled': rec.disabled && !rec.booked }"
              >
                <div class="rec-top"><b>{{ rec.room_name }} · {{ rec.seat_no }}</b><span>{{ zoneNames[rec.zone] || rec.zone }}</span></div>
                <div class="rec-time">{{ rec.date }}　{{ rec.start_time }}–{{ rec.end_time }}</div>
                <div class="rec-tags"><span v-if="rec.has_power">有电源</span><span v-if="rec.near_window">靠窗</span></div>
                <p>{{ rec.reason }}</p>
                <button
                  type="button"
                  :disabled="Boolean(sending || bookingRecKey || rec.disabled || rec.booked)"
                  @click="book(rec)"
                >
                  <template v-if="bookingRecKey === `${rec.seat_id}-${rec.date}-${rec.start_time}`">预约中…</template>
                  <template v-else-if="rec.booked">✓ 已选择此座位</template>
                  <template v-else-if="rec.disabled">已选择其他座位</template>
                  <template v-else>选择此座位</template>
                </button>
              </article>
            </TransitionGroup>
            <div v-if="message.status === 'streaming' && !message.content && !message.recommendations?.length" class="typing"><i/><i/><i/></div>
            <div v-if="message.status === 'failed'" class="message-error">{{ message.error }} <button type="button" @click="send(lastPrompt)">重试</button></div>
          </div>
        </div>
        </div>
        <div v-if="!showHistory" class="composer">
          <div class="quick-prompts"><button v-for="q in quickPrompts" :key="q" type="button" :disabled="busy()" @click="send(q)">{{ q }}</button></div>
          <div class="input-row">
            <textarea
              ref="textareaRef"
              v-model="input"
              maxlength="1000"
              rows="1"
              aria-label="向 AI 学习助手提问"
              placeholder="例如：明天下午，想找一个靠窗的安静座位"
              @input="adjustTextareaHeight"
              @keydown.enter.exact="onComposerEnter"
            />
            <button v-if="sending" class="send stop" type="button" aria-label="停止生成" @click="stop"><svg viewBox="0 0 24 24" aria-hidden="true"><rect x="7" y="7" width="10" height="10" rx="2" fill="currentColor" stroke="none" /></svg></button>
            <button v-else class="send" type="button" :disabled="!input.trim() || busy()" aria-label="发送消息" @click="send()">
              <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M5 12h13M13 7l5 5-5 5" /></svg>
            </button>
          </div>
          <div class="composer-note">AI 提供选座建议 · 预约前由你确认</div>
        </div>
      </div>
    </section>
  </Teleport>
</template>

<style scoped>
.ai-header{padding:16px 16px 13px;border-bottom:1px solid var(--hairline);display:flex;justify-content:space-between;align-items:center}

.ai-header b{font-size:15px;font-weight:650;color:var(--text-1);letter-spacing:-.01em}
.header-actions{display:flex;gap:4px}
.header-actions button,.quick-prompts button{border:1px solid var(--border);background:var(--surface);color:var(--text-3);border-radius:var(--r-md);padding:6px 10px;font-size:12.5px;font-weight:500;cursor:pointer;transition:all .14s var(--ease)}
.header-actions button:hover,.quick-prompts button:hover{background:var(--surface-hover);color:var(--text-1);border-color:var(--border-strong)}
.header-actions button:last-child{font-size:18px;padding:1px 10px;line-height:1.4}
.message-list{flex:1;overflow:auto;padding:18px;background:var(--surface-2);scrollbar-width:thin;scrollbar-color:var(--scrollbar-thumb) transparent}
.message-list::-webkit-scrollbar{width:6px}
.message-list::-webkit-scrollbar-track{background:transparent}
.message-list::-webkit-scrollbar-thumb{background-color:var(--scrollbar-thumb);border-radius:999px}
.welcome{text-align:center;color:var(--text-3);padding:64px 24px}
.welcome-icon{display:block;font-size:26px;color:var(--primary)}
.welcome b{display:block;color:var(--text-1);margin:10px 0 4px;font-size:15px}
.welcome p{font-size:13px}
.message{display:flex;flex-direction:column;margin:10px 0;align-items:flex-start}
.message.user{align-items:flex-end}
.bubble{max-width:86%;white-space:pre-wrap;line-height:1.6;padding:10px 13px;border-radius:var(--r-lg);background:var(--surface);border:1px solid var(--border);color:var(--text-1);font-size:13.5px;box-shadow:var(--shadow-1)}
.user .bubble{background:var(--primary);color:#fff;border:0}
.typing{padding:12px;background:var(--surface);border:1px solid var(--border);border-radius:var(--r-lg)}
.typing i{display:inline-block;width:6px;height:6px;margin:0 2px;border-radius:50%;background:var(--text-4);animation:pulse 1s infinite}
.typing i:nth-child(2){animation-delay:.15s}
.typing i:nth-child(3){animation-delay:.3s}
@keyframes pulse{50%{opacity:.25;transform:translateY(-2px)}}
.recommendations{width:100%;display:grid;gap:10px;margin-top:8px}
.seat-rec{background:var(--surface);border:1px solid var(--border);border-radius:var(--r-lg);padding:13px;box-shadow:var(--shadow-1);transition:background .18s var(--ease),border-color .18s var(--ease),box-shadow .18s var(--ease)}
.seat-rec.is-booked{border-color:#b5dfc9;background:var(--green-faint)}
.seat-rec.is-disabled{opacity:.72}
.rec-top{display:flex;justify-content:space-between;gap:8px;align-items:center}
.rec-top b{color:var(--text-1);font-size:13.5px}
.rec-top span,.rec-tags span{font-size:11.5px;padding:2px 8px;background:var(--surface-3);color:var(--text-3);border-radius:var(--r-full)}
.rec-time{font-size:12.5px;color:var(--text-3);margin:6px 0;font-variant-numeric:tabular-nums}
.rec-tags{display:flex;gap:5px}
.seat-rec p{font-size:12.5px;color:var(--text-3);margin:7px 0 9px;line-height:1.6}
.seat-rec button{width:100%;border:0;border-radius:var(--r-md);padding:8px;background:var(--primary);color:#fff;font-size:13px;font-weight:600;cursor:pointer;transition:all .16s var(--ease)}
.seat-rec button:hover:not(:disabled){background:var(--primary-hover)}
.seat-rec button:disabled{background:var(--surface-3);color:var(--text-4);cursor:not-allowed}
.seat-rec.is-booked button:disabled{background:var(--green);color:#fff;opacity:1}
.message-error{font-size:12px;color:var(--red-strong)}
.message-error button{border:0;background:none;color:var(--primary);cursor:pointer;font-weight:500}
.composer{border-top:1px solid var(--hairline);padding:11px 14px 14px;background:var(--surface)}
.quick-prompts{display:flex;gap:7px;overflow-x:auto;margin-bottom:9px;scrollbar-width:none}
.quick-prompts::-webkit-scrollbar{display:none}
.quick-prompts button{white-space:nowrap;padding:5px 11px;font-size:12px;border-radius:var(--r-full)}
.input-row{display:flex;gap:8px;align-items:flex-end;background:var(--surface-2);border:1px solid var(--border);border-radius:var(--r-lg);padding:6px 7px;transition:border-color .18s var(--ease),background-color .18s var(--ease),box-shadow .18s var(--ease)}
.input-row:focus-within{border-color:var(--primary);background:var(--surface);box-shadow:var(--ring)}
.input-row textarea{flex:1;resize:none;border:0;outline:0;margin:0;background:transparent;font-family:inherit;font-size:14px;line-height:20px;height:34px;min-height:34px;max-height:120px;box-sizing:border-box;padding:7px 8px;overflow-y:hidden;color:var(--text-1);scrollbar-width:thin;scrollbar-color:var(--scrollbar-thumb) transparent}
.input-row textarea::placeholder{color:var(--text-4)}
.input-row textarea::-webkit-scrollbar{width:5px}
.input-row textarea::-webkit-scrollbar-track{background:transparent}
.input-row textarea::-webkit-scrollbar-thumb{background-color:var(--scrollbar-thumb);border-radius:999px}
.send{width:34px;height:34px;flex-shrink:0;display:inline-flex;align-items:center;justify-content:center;border:0;border-radius:var(--r-md);background:var(--primary);color:#fff;font-size:15px;font-weight:600;cursor:pointer;transition:background-color .18s var(--ease),opacity .18s var(--ease),transform .1s var(--ease)}
.send:hover:not(:disabled){background:var(--primary-hover)}
.send:active:not(:disabled){transform:scale(.96)}
.send:disabled{opacity:.35;cursor:not-allowed}
.send.stop{background:var(--text-3)}
.send.stop:hover{background:var(--text-2)}
.history-panel{flex:1;overflow:auto;padding:12px;scrollbar-width:thin;scrollbar-color:var(--scrollbar-thumb) transparent}
.history-panel::-webkit-scrollbar{width:6px}
.history-panel::-webkit-scrollbar-track{background:transparent}
.history-panel::-webkit-scrollbar-thumb{background-color:var(--scrollbar-thumb);border-radius:999px}
.history-item{display:grid;grid-template-columns:1fr auto;border-radius:var(--r-lg)}
.history-item.active{background:var(--primary-faint)}
.history-item>button:first-child{border:0;background:none;text-align:left;padding:11px;display:flex;flex-direction:column;gap:3px;min-width:0;cursor:pointer}
.history-item span{overflow:hidden;text-overflow:ellipsis;white-space:nowrap;font-size:13px;color:var(--text-1)}
.history-item small{color:var(--text-4)}
.history-item .delete{border:0;background:none;color:var(--text-4);padding:10px;font-size:16px;cursor:pointer}
.history-item .delete:hover{color:var(--red)}
.empty{text-align:center;color:var(--text-4);padding:40px;font-size:13px}
/* The same anchored surface changes from launcher to panel; its lower-right corner stays fixed. */
.ai-shell{position:fixed;right:24px;bottom:24px;z-index:80;width:132px;height:50px;overflow:hidden;border-radius:25px;background:var(--primary);box-shadow:0 8px 28px #24489430;transition:width .26s var(--ease-out),height .26s var(--ease-out),border-radius .26s,background .22s,box-shadow .22s;isolation:isolate}
.ai-shell.is-open{width:min(620px,calc(100vw - 48px));height:min(780px,calc(100dvh - 48px));border-radius:28px;background:var(--surface);box-shadow:0 24px 80px #15254330,0 0 0 1px var(--border)}
.ai-fab{position:absolute;inset:0;width:100%;height:100%;border:0;background:transparent;color:white;display:flex;align-items:center;justify-content:center;gap:10px;font-family:inherit;font-size:14px;font-weight:600;cursor:pointer}
.fab-icon{font-size:23px;transition:transform .4s}.ai-fab:hover .fab-icon{transform:rotate(90deg)}
.ai-sheet{position:absolute;right:0;bottom:0;width:min(620px,calc(100vw - 48px));height:min(780px,calc(100dvh - 48px));display:flex;flex-direction:column;background:linear-gradient(145deg,var(--surface) 0%,var(--surface-2) 52%,var(--primary-faint) 145%);opacity:0;visibility:hidden;transform:translate(8px,8px);transition:opacity .16s,transform .4s,visibility .16s}
.is-open .ai-sheet{opacity:1;visibility:visible;transform:none;transition:opacity .22s .04s,transform .26s,visibility 0s}
.ai-sheet{isolation:isolate;overflow:hidden}
.ai-sheet>.ai-header,.ai-sheet>.message-list,.ai-sheet>.history-panel,.ai-sheet>.composer{position:relative;z-index:1}
/* Pause at the current frame and fade into the static base when reading begins. */
.ambient-gradient{position:absolute;inset:-25%;z-index:0;pointer-events:none;overflow:hidden;opacity:0;transition:opacity .55s ease;contain:strict}
.ambient-gradient.is-flowing{opacity:.25}
.ambient-blob{position:absolute;display:block;width:105%;height:82%;border-radius:50%;transform:translateZ(0);background:radial-gradient(ellipse at center,color-mix(in srgb,var(--primary) 20%,transparent) 0%,color-mix(in srgb,var(--primary) 12%,transparent) 32%,color-mix(in srgb,var(--primary) 5%,transparent) 62%,transparent 88%)}
.ambient-blob-a{left:-18%;top:-14%}
.ambient-blob-b{right:-20%;top:24%;width:96%;height:88%;opacity:.72}
.ambient-blob-c{left:2%;bottom:-18%;width:112%;height:78%;opacity:.5}
/* Explicit radii fade to transparent before every edge, so moving the glow cannot expose a hard seam. */
.send-pulse{position:absolute;inset:0;z-index:0;pointer-events:none;animation:pulse-envelope .95s linear both}
.send-pulse>span{position:absolute;display:block;pointer-events:none}
.pulse-wave{inset:-35%;background:radial-gradient(ellipse 72% 68% at 50% 50%,color-mix(in srgb,var(--primary) 24%,transparent) 0%,color-mix(in srgb,var(--primary) 14%,transparent) 34%,color-mix(in srgb,var(--primary) 5%,transparent) 68%,transparent 100%);animation:pulse-rise 1.05s cubic-bezier(.2,.55,.35,1) both}
@keyframes pulse-envelope{0%,100%{opacity:0}18%,40%{opacity:1}72%{opacity:.45}}
@keyframes pulse-rise{from{transform:translate(38%,38%)}to{transform:translate(-38%,-38%)}}
.ai-backdrop{position:fixed;inset:0;z-index:79;border:0;background:#14213d66;backdrop-filter:blur(4px);touch-action:none}
.backdrop-enter-active,.backdrop-leave-active{transition:opacity .3s}.backdrop-enter-from,.backdrop-leave-to{opacity:0}
.ai-header{padding:22px 24px;gap:12px;background:transparent;border-bottom:0;flex-shrink:0}
.ai-header .assistant-brand{display:flex;flex-direction:row;align-items:center;gap:10px}
.brand-spark{display:grid;place-items:center;width:36px;height:36px;border-radius:10px;color:var(--primary);background:color-mix(in srgb,var(--surface) 72%,transparent);box-shadow:inset 0 0 0 1px var(--border);font-size:22px}.ai-header b{font-size:16px}
.header-actions button{padding:7px 9px;border-color:transparent;background:color-mix(in srgb,var(--surface) 62%,transparent)}
.header-actions .history-button{width:34px;height:34px;padding:0;display:grid;place-items:center}.history-button svg{width:17px;height:17px;fill:none;stroke:currentColor;stroke-width:1.8;stroke-linecap:round;stroke-linejoin:round}
.header-actions button[aria-pressed=true]{background:var(--primary-faint);color:var(--primary)}
.message-list{padding:24px;min-height:0;overscroll-behavior:contain;overflow-x:hidden;background:transparent;overflow-anchor:none}
.conversation-stack{min-height:100%;display:flex;flex-direction:column;justify-content:flex-end}.welcome{margin:auto 0;padding:30px 12px 48px}
.welcome-icon{display:grid;place-items:center;margin:0 auto 24px;width:72px;height:72px;border-radius:18px;background:color-mix(in srgb,var(--surface) 72%,transparent);box-shadow:0 10px 30px #2448940d,inset 0 0 0 1px var(--border);font-size:36px}.welcome b{font-size:29px;line-height:1.45;letter-spacing:-.04em}.welcome p{line-height:1.9;margin-top:14px}
.message{margin:9px 0;flex-shrink:0}.bubble{font-size:14px;line-height:1.8;padding:13px 16px;max-width:92%;border-radius:18px 18px 18px 5px}.user .bubble{border-radius:18px 18px 5px 18px;background:linear-gradient(135deg,var(--primary),var(--primary-active))}
.recommendations{gap:12px}.recommendations:empty{display:none}.seat-rec{padding:18px;border-radius:20px;position:relative;transition:border-color .25s,background .25s,box-shadow .25s}.seat-rec:hover{border-color:var(--border-strong);box-shadow:0 8px 24px #24489412}.rec-top b{font-size:15px}.rec-time{margin:10px 0;font-size:13px}.rec-tags span{background:var(--primary-faint);color:var(--primary)}.seat-rec p{margin:12px 0;color:var(--text-2);line-height:1.7}.seat-rec button{border-radius:12px;padding:11px;transition:transform .2s,background .2s}.seat-rec button:active:not(:disabled){transform:scale(.98)}.seat-rec.is-disabled{opacity:1}.seat-rec.is-booked{box-shadow:inset 3px 0 var(--green)}
.composer{padding:16px 22px 14px;flex-shrink:0;background:transparent;border-top:0}.quick-prompts{margin-bottom:12px}.quick-prompts button{padding:7px 12px;background:color-mix(in srgb,var(--surface) 58%,transparent)}.quick-prompts button:hover:not(:disabled){transform:translateY(-2px);border-color:var(--primary)}.input-row{padding:9px;border-radius:18px;background:color-mix(in srgb,var(--surface) 70%,transparent)}.input-row textarea{font-size:13px}.send{width:38px;height:38px;border-radius:12px;font-size:0;padding:0;display:grid;place-items:center}.send svg{display:block;width:20px;height:20px;fill:none;stroke:currentColor;stroke-width:2;stroke-linecap:round;stroke-linejoin:round}.composer-note{text-align:center;font-size:10px;color:var(--text-4);padding-top:10px;letter-spacing:.03em}
.history-panel{padding:20px;background:transparent;overscroll-behavior:contain}.history-item{border:1px solid var(--border);background:color-mix(in srgb,var(--surface) 64%,transparent);margin-bottom:10px;padding:5px;animation:arrive .3s ease-out}.history-item small{font-size:11px;margin-top:4px}
.ai-shell button:focus-visible{outline:2px solid var(--primary);outline-offset:-3px}.ai-shell button:disabled{cursor:not-allowed}.header-actions button:disabled,.quick-prompts button:disabled{opacity:.45}
@keyframes arrive{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:none}}
@media(max-width:1024px){
 .ai-shell{right:16px;bottom:max(20px,env(safe-area-inset-bottom));width:52px;height:52px;border-radius:26px}.fab-label{display:none}
 .ai-shell.is-open{width:min(620px,calc(100vw - 32px));height:min(780px,82dvh);border-radius:26px}
 .ai-sheet{width:min(620px,calc(100vw - 32px));height:min(780px,82dvh)}
 .ai-header{padding:17px 16px;gap:8px}.ai-header .assistant-brand{gap:8px}.brand-spark{width:34px;height:34px;font-size:21px}.ai-header b{font-size:14px}.header-actions{gap:3px}.header-actions button{font-size:11px;padding:7px}.header-actions .history-button{padding:0}.message-list{padding:16px}.composer{padding:12px 14px}.welcome{padding:20px 8px}.welcome b{font-size:25px}.welcome-icon{margin:0 auto 20px;width:60px;height:60px}.seat-rec{padding:15px}.rec-top{align-items:flex-start}.rec-top span{flex-shrink:0}
}
@media(max-width:370px){.brand-spark{display:none}.header-actions button{padding:6px}}
@media(prefers-reduced-motion:reduce){.ai-shell,.ai-sheet,.is-open .ai-sheet,.backdrop-enter-active,.backdrop-leave-active{transition:none}.ai-shell *{animation:none!important;transition:none!important}}
@media(prefers-reduced-motion:reduce){.ambient-gradient,.send-pulse{display:none}}

/* Desktop dock: the left icon stays visible while the label rests off-screen.
   Hover/focus expands toward the page without moving away from the pointer. */
@media (min-width: 1025px) {
  .ai-shell { right: 0; transform: translateX(84px); transition: transform .28s var(--ease-out), width .26s var(--ease-out), height .26s var(--ease-out), border-radius .26s, background .22s, box-shadow .22s; }
  .ai-shell:not(.is-open) { border-radius: 25px 0 0 25px; }
  .ai-shell:not(.is-open):hover, .ai-shell:not(.is-open):focus-within { transform: translateX(0); }
  .ai-shell.is-open { right: 24px; transform: none; }
  .ai-fab { justify-content: flex-start; gap: 0; }
  .ai-fab .fab-icon { width: 48px; flex: 0 0 48px; text-align: center; }
  .ai-fab .fab-label { white-space: nowrap; opacity: 0; transition: opacity .18s; }
  .ai-shell:hover .fab-label, .ai-shell:focus-within .fab-label { opacity: 1; }
}
@media (min-width: 1025px) and (prefers-reduced-motion: reduce) { .ai-shell { transition: none; } }
</style>
