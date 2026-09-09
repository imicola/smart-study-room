<script setup>
import PageHelp from '../components/PageHelp.vue'
import SAnimatedNumber from '../components/ui/SAnimatedNumber.vue'
import { ref, computed, onMounted, nextTick, watch, onUnmounted } from 'vue'
import * as echarts from 'echarts'
import { getRooms } from '../api/room'
import { getHeatmap, getOverview } from '../api/stats'
import { useThemeStore } from '../stores/theme'
import SSelect from '../components/ui/SSelect.vue'
import SDatePicker from '../components/ui/SDatePicker.vue'

const themeStore = useThemeStore()
const chartTab = ref('heat')
const chartRoot = ref(null)
const chartTabs = [{ key: 'heat', label: '座位热力图' }, { key: 'trend', label: '运营趋势' }, { key: 'top', label: '热门座位' }]
let resizeObserver
let disposed = false
let heatRequest = 0
let overviewRequest = 0
const motionMedia = window.matchMedia('(prefers-reduced-motion: reduce)')
const animateCharts = () => !motionMedia.matches

const rooms = ref([])
const roomId = ref(null)
const date = ref(new Date().toISOString().slice(0, 10))

const heatEl = ref(null)
const trendEl = ref(null)
const peakEl = ref(null)
const topEl = ref(null)

const overview = ref(null)

let heatChart, trendChart, peakChart, topChart

// 图表主题（与深浅色模式联动）
const CHART = computed(() => {
  const isDark = themeStore.isDark
  return {
    axisLine: isDark ? '#283547' : '#d4dbe6',
    splitLine: isDark ? '#1c2635' : '#eef1f6',
    label: isDark ? '#8393a7' : '#75819a',
    title: isDark ? '#f1f5fa' : '#46536a',
    tooltipBg: isDark ? '#151b24' : '#1c2534',
    primary: isDark ? '#4f7cf6' : '#3b66da',
    primarySoft: isDark ? 'rgba(79, 124, 246, .24)' : 'rgba(59, 102, 218, .14)',
    splitArea: isDark ? ['#151b24', '#1b232f'] : ['#ffffff', '#f8fafc'],
    heatRange: isDark ? ['#1b232f', '#2e5199', '#4f7cf6'] : ['#f4f6f9', '#93b1ea', '#3b66da'],
    heatBorder: isDark ? '#151b24' : '#ffffff'
  }
})

async function loadHeatmap() {
  if (!roomId.value) return
  const request = ++heatRequest
  const resp = await getHeatmap(roomId.value, date.value)
  if (disposed || request !== heatRequest) return
  const d = resp.data
  if (!heatChart) heatChart = echarts.init(heatEl.value, null, { width: heatEl.value.clientWidth || 720, height: heatEl.value.clientHeight || 380 })
  const c = CHART.value

  const data = []
  d.seats.forEach((s, i) => {
    d.cells[i].forEach((v, j) => data.push([j, i, v]))
  })
  heatChart.setOption({
    animation: animateCharts(), animationDuration: 450, animationDurationUpdate: 250,
    tooltip: {
      position: 'top',
      backgroundColor: c.tooltipBg,
      borderColor: c.axisLine,
      borderWidth: 1,
      textStyle: { color: '#fff', fontSize: 12 },
      formatter: (p) => `${d.seats[p.value[1]].seat_no} ${d.hours[p.value[0]]}<br/>占用：${p.value[2] ? '是' : '否'}`
    },
    grid: { top: 30, left: 70, right: 20, bottom: 60 },
    xAxis: { type: 'category', data: d.hours, splitArea: { show: true, areaStyle: { color: c.splitArea } }, axisLabel: { fontSize: 10, color: c.label }, axisLine: { lineStyle: { color: c.axisLine } } },
    yAxis: {
      type: 'category', data: d.seats.map((s) => s.seat_no),
      splitArea: { show: true, areaStyle: { color: c.splitArea } }, axisLabel: { fontSize: 9, color: c.label }, axisLine: { lineStyle: { color: c.axisLine } }
    },
    visualMap: {
      min: 0, max: 1, calculable: false,
      orient: 'horizontal', left: 'center', bottom: 0,
      inRange: { color: c.heatRange },
      text: ['占用', '空闲'], textStyle: { fontSize: 11, color: c.label }
    },
    series: [{
      type: 'heatmap', data,
      label: { show: false },
      itemStyle: { borderColor: c.heatBorder, borderWidth: 1, borderRadius: 2 }
    }]
  })
}

async function loadOverview() {
  const request = ++overviewRequest
  const resp = await getOverview()
  if (disposed || request !== overviewRequest) return
  overview.value = resp.data
  const d = resp.data
  await nextTick()
  if (disposed) return
  const c = CHART.value

  if (!trendChart) trendChart = echarts.init(trendEl.value, null, { width: trendEl.value.clientWidth || 500, height: 320 })
  trendChart.setOption({
    animation: animateCharts(), animationDuration: 450, animationDurationUpdate: 250,
    title: { text: '近 14 天使用率趋势', left: 'center', textStyle: { fontSize: 13, color: c.title, fontWeight: 600 } },
    grid: { top: 40, left: 50, right: 20, bottom: 30 },
    tooltip: {
      trigger: 'axis',
      backgroundColor: c.tooltipBg,
      borderColor: c.axisLine,
      borderWidth: 1,
      textStyle: { color: '#fff', fontSize: 12 },
      formatter: (ps) => {
        const p = ps[0]
        return `${p.name}<br/>使用率 ${(p.value * 100).toFixed(1)}%`
      }
    },
    xAxis: { type: 'category', data: d.trend_14.map((t) => t.date.slice(5)), axisLine: { lineStyle: { color: c.axisLine } }, axisLabel: { color: c.label } },
    yAxis: { type: 'value', axisLabel: { formatter: '{value}%', color: c.label }, splitLine: { lineStyle: { color: c.splitLine } } },
    series: [{
      type: 'line', smooth: true, data: d.trend_14.map((t) => (t.utilization * 100).toFixed(1) * 1),
      areaStyle: { color: c.primarySoft },
      lineStyle: { color: c.primary, width: 2 },
      itemStyle: { color: c.primary, borderColor: c.heatBorder, borderWidth: 1 },
      symbol: 'circle', symbolSize: 6
    }]
  })

  if (!peakChart) peakChart = echarts.init(peakEl.value, null, { width: peakEl.value.clientWidth || 500, height: 320 })
  peakChart.setOption({
    animation: animateCharts(), animationDuration: 450, animationDurationUpdate: 250,
    title: { text: '高峰时段分布（近 14 天）', left: 'center', textStyle: { fontSize: 13, color: c.title, fontWeight: 600 } },
    grid: { top: 40, left: 50, right: 20, bottom: 30 },
    tooltip: { trigger: 'axis', backgroundColor: c.tooltipBg, borderColor: c.axisLine, borderWidth: 1, textStyle: { color: '#fff', fontSize: 12 } },
    xAxis: { type: 'category', data: d.peak.map((p) => p.hour), axisLine: { lineStyle: { color: c.axisLine } }, axisLabel: { color: c.label } },
    yAxis: { type: 'value', name: '预约数', nameTextStyle: { color: c.label }, splitLine: { lineStyle: { color: c.splitLine } }, axisLabel: { color: c.label } },
    series: [{
      type: 'bar', data: d.peak.map((p) => p.count),
      itemStyle: {
        color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
          { offset: 0, color: '#6b8fdd' }, { offset: 1, color: c.primary }
        ]),
        borderRadius: [5, 5, 0, 0]
      },
      barWidth: '50%'
    }]
  })

  if (!topChart) topChart = echarts.init(topEl.value, null, { width: topEl.value.clientWidth || 720, height: 340 })
  const tops = [...d.top_seats].reverse()
  topChart.setOption({
    animation: animateCharts(), animationDuration: 450, animationDurationUpdate: 250,
    title: { text: '热门座位 Top 10', left: 'center', textStyle: { fontSize: 13, color: c.title, fontWeight: 600 } },
    grid: { top: 40, left: 130, right: 40, bottom: 30 },
    tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' }, backgroundColor: c.tooltipBg, borderColor: c.axisLine, borderWidth: 1, textStyle: { color: '#fff', fontSize: 12 } },
    xAxis: { type: 'value', name: '占用小时', nameTextStyle: { color: c.label }, splitLine: { lineStyle: { color: c.splitLine } }, axisLabel: { color: c.label } },
    yAxis: { type: 'category', data: tops.map((t) => `${t.room_name.slice(0, 3)} ${t.seat_no}`), axisLine: { lineStyle: { color: c.axisLine } }, axisLabel: { color: c.label } },
    series: [{
      type: 'bar', data: tops.map((t) => t.hours),
      itemStyle: {
        color: new echarts.graphic.LinearGradient(0, 0, 1, 0, [
          { offset: 0, color: '#c6d6f4' }, { offset: 1, color: '#5b83d6' }
        ]),
        borderRadius: [0, 5, 5, 0]
      },
      label: { show: true, position: 'right', color: c.title, fontSize: 11 }
    }]
  })
}

watch(() => themeStore.resolvedTheme, () => {
  loadHeatmap()
  if (overview.value) {
    loadOverview()
  }
})

async function init() {
  const resp = await getRooms()
  if (disposed) return
  rooms.value = resp.data || []
  if (rooms.value.length) roomId.value = rooms.value[0].id
  await Promise.all([loadHeatmap(), loadOverview()])
}

watch([roomId, date], loadHeatmap)

function resizeAll() {
  for (const chart of [heatChart, trendChart, peakChart, topChart]) {
    if (chart && chart.getDom().clientWidth) chart.resize()
  }
}

watch(chartTab, async () => { await nextTick(); resizeAll() })
function syncMotion() {
  for (const chart of [heatChart, trendChart, peakChart, topChart]) chart?.setOption({ animation: animateCharts() })
}
onMounted(() => {
  resizeObserver = new ResizeObserver(resizeAll)
  resizeObserver.observe(chartRoot.value)
  motionMedia.addEventListener('change', syncMotion)
  init()
  window.addEventListener('resize', resizeAll)
})
onUnmounted(() => {
  disposed = true
  resizeObserver?.disconnect()
  motionMedia.removeEventListener('change', syncMotion)
  window.removeEventListener('resize', resizeAll)
  for (const chart of [heatChart, trendChart, peakChart, topChart]) chart?.dispose()
})
</script>

<template>
  <div v-reveal class="page-view">
    <header class="view-heading has-page-help"><div class="heading-copy" data-page-title>
      <h1>热力图与统计</h1>
      <p class="heading-sub">座位利用率、高峰时段与热门座位分析</p>
    </div><PageHelp title="指标说明">
        <ul class="tips">
          <li><b>利用率</b>：实际占用小时数 ÷ 可开放小时数</li>
          <li><b>高峰时段</b>：近 14 天按时段聚合的预约数 Top</li>
          <li><b>热门座位</b>：近 14 天累计占用小时数 Top 10</li>
        </ul>
      </PageHelp></header>
    <!-- 统计：页面级双栏 = 左 KPI/筛选 | 右热力图+图表 -->
    <div class="split analytics-split">
    <!-- 左栏：概览 KPI + 筛选器 -->
    <div class="split-left">
      <section class="card responsive-compact">
        <div class="card-title-row"><h3>运营总览</h3></div>
        <div class="kpi-grid">
          <div v-if="overview" class="kpi">
            <div class="kpi-num"><SAnimatedNumber :value="overview.total_seats" /></div>
            <div class="kpi-label">总座位数</div>
          </div>
          <div v-if="overview" class="kpi kpi-ok">
            <div class="kpi-num"><SAnimatedNumber :value="overview.active_today" /></div>
            <div class="kpi-label">今日预约</div>
          </div>
          <div v-if="overview" class="kpi kpi-primary">
            <div class="kpi-num"><SAnimatedNumber :value="overview.in_use_now" /></div>
            <div class="kpi-label">当前使用中</div>
          </div>
          <div v-if="overview" class="kpi kpi-warm">
            <div class="kpi-num">{{ (overview.today_utilization * 100).toFixed(1) }}%</div>
            <div class="kpi-label">今日利用率</div>
          </div>
        </div>
      </section>

      <section class="card responsive-compact">
        <div class="card-title-row"><h3>热力图参数</h3></div>
        <div class="filter-group">
          <div class="filter-row">
            <label>自习室</label>
            <SSelect v-model="roomId" :options="rooms" label-key="name" value-key="id" />
          </div>
          <div class="filter-row">
            <label>日期</label>
            <SDatePicker v-model="date" />
          </div>
        </div>
        <div class="filter-hint" style="margin-top:12px">
          颜色越深表示该座位在该小时被预约/占用的概率越高，便于提前规划热门时段。
        </div>
      </section>

      
    </div>

    <!-- 右栏：热力图 + 图表 -->
    <div ref="chartRoot" class="split-right">
      <nav class="chart-tabs" aria-label="统计视图">
        <button v-for="tab in chartTabs" :key="tab.key" type="button" :class="{ active: chartTab === tab.key }" :aria-pressed="chartTab === tab.key" @click="chartTab = tab.key">{{ tab.label }}</button>
      </nav>
      <section v-show="chartTab === 'heat'" class="card chart-panel">
        <div class="card-title-row">
          <h3>座位 × 时段 热力图</h3>
          <span class="muted">颜色越深 = 占用概率越高</span>
        </div>
        <div class="responsive-scroll" tabindex="0" aria-label="座位时段热力图，可左右滑动">
          <div ref="heatEl" class="chart chart-heat chart-wide"></div>
        </div>
      </section>

      <section v-show="chartTab === 'trend'" class="card chart-panel">
        <div class="card-title-row"><h3>近 14 天运营趋势</h3></div>
        <div class="charts-row">
          <div ref="trendEl" class="chart"></div>
          <div ref="peakEl" class="chart"></div>
        </div>
      </section>

      <section v-show="chartTab === 'top'" class="card chart-panel">
        <div class="card-title-row"><h3>热门座位 Top 10</h3></div>
        <div class="responsive-scroll" tabindex="0" aria-label="热门座位图，可左右滑动">
          <div ref="topEl" class="chart chart-bar"></div>
        </div>
      </section>
    </div>
    </div>
  </div>
</template>

<style scoped>


.chart {
  width: 100%;
  height: 320px;
}
.chart-heat { height: 380px; }
.chart-wide { min-width: 720px; }
.chart-bar  { min-width: 620px; height: 340px; }

.charts-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 18px;
}

@media (max-width: 1100px) {
  .charts-row { grid-template-columns: 1fr; }
}

@media (max-width: 720px) {
  .chart { height: 280px; }
  .chart-heat { height: 360px; }
  .chart-bar { height: 340px; }
}
</style>
