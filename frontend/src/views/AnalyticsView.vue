<script setup>
import { ref, onMounted, nextTick, watch, onUnmounted } from 'vue'
import * as echarts from 'echarts'
import { getRooms } from '../api/room'
import { getHeatmap, getOverview } from '../api/stats'

const rooms = ref([])
const roomId = ref(null)
const date = ref(new Date().toISOString().slice(0, 10))

const heatEl = ref(null)
const trendEl = ref(null)
const peakEl = ref(null)
const topEl = ref(null)

const overview = ref(null)

let heatChart, trendChart, peakChart, topChart

async function loadHeatmap() {
  if (!roomId.value) return
  const resp = await getHeatmap(roomId.value, date.value)
  const d = resp.data
  if (!heatChart) heatChart = echarts.init(heatEl.value)

  const data = []
  d.seats.forEach((s, i) => {
    d.cells[i].forEach((v, j) => data.push([j, i, v]))
  })
  heatChart.setOption({
    tooltip: {
      position: 'top',
      formatter: (p) => `${d.seats[p.value[1]].seat_no} ${d.hours[p.value[0]]}<br/>占用：${p.value[2] ? '是' : '否'}`
    },
    grid: { top: 30, left: 70, right: 20, bottom: 60 },
    xAxis: { type: 'category', data: d.hours, splitArea: { show: true }, axisLabel: { fontSize: 10 } },
    yAxis: {
      type: 'category', data: d.seats.map((s) => s.seat_no),
      splitArea: { show: true }, axisLabel: { fontSize: 9 }
    },
    visualMap: {
      min: 0, max: 1, calculable: false,
      orient: 'horizontal', left: 'center', bottom: 0,
      inRange: { color: ['#f6f8fb', '#456388'] },
      text: ['占用', '空闲'], textStyle: { fontSize: 11 }
    },
    series: [{
      type: 'heatmap', data,
      label: { show: false },
      itemStyle: { borderColor: '#fff', borderWidth: 1 }
    }]
  })
}

async function loadOverview() {
  const resp = await getOverview()
  overview.value = resp.data
  const d = resp.data
  await nextTick()

  if (!trendChart) trendChart = echarts.init(trendEl.value)
  trendChart.setOption({
    title: { text: '近 14 天使用率趋势', left: 'center', textStyle: { fontSize: 13, color: '#3d4656' } },
    grid: { top: 40, left: 50, right: 20, bottom: 30 },
    tooltip: {
      trigger: 'axis',
      formatter: (ps) => {
        const p = ps[0]
        return `${p.name}<br/>使用率 ${(p.value * 100).toFixed(1)}%`
      }
    },
    xAxis: { type: 'category', data: d.trend_14.map((t) => t.date.slice(5)), axisLine: { lineStyle: { color: '#cfd5df' } } },
    yAxis: { type: 'value', axisLabel: { formatter: '{value}%' }, splitLine: { lineStyle: { color: '#eef1f6' } } },
    series: [{
      type: 'line', smooth: true, data: d.trend_14.map((t) => (t.utilization * 100).toFixed(1) * 1),
      areaStyle: { color: 'rgba(108,128,160,0.18)' },
      lineStyle: { color: '#5f7ea3', width: 2 },
      itemStyle: { color: '#5f7ea3' },
      symbol: 'circle', symbolSize: 6
    }]
  })

  if (!peakChart) peakChart = echarts.init(peakEl.value)
  peakChart.setOption({
    title: { text: '高峰时段分布（近 14 天）', left: 'center', textStyle: { fontSize: 13, color: '#3d4656' } },
    grid: { top: 40, left: 50, right: 20, bottom: 30 },
    tooltip: { trigger: 'axis' },
    xAxis: { type: 'category', data: d.peak.map((p) => p.hour), axisLine: { lineStyle: { color: '#cfd5df' } } },
    yAxis: { type: 'value', name: '预约数', splitLine: { lineStyle: { color: '#eef1f6' } } },
    series: [{
      type: 'bar', data: d.peak.map((p) => p.count),
      itemStyle: {
        color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
          { offset: 0, color: '#8ea6c4' }, { offset: 1, color: '#5f7ea3' }
        ]),
        borderRadius: [6, 6, 0, 0]
      },
      barWidth: '50%'
    }]
  })

  if (!topChart) topChart = echarts.init(topEl.value)
  const tops = [...d.top_seats].reverse()
  topChart.setOption({
    title: { text: '热门座位 Top 10', left: 'center', textStyle: { fontSize: 13, color: '#3d4656' } },
    grid: { top: 40, left: 130, right: 30, bottom: 30 },
    tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } },
    xAxis: { type: 'value', name: '占用小时' },
    yAxis: { type: 'category', data: tops.map((t) => `${t.room_name.slice(0, 3)} ${t.seat_no}`) },
    series: [{
      type: 'bar', data: tops.map((t) => t.hours),
      itemStyle: {
        color: new echarts.graphic.LinearGradient(0, 0, 1, 0, [
          { offset: 0, color: '#cfdae8' }, { offset: 1, color: '#8ea6c4' }
        ]),
        borderRadius: [0, 6, 6, 0]
      },
      label: { show: true, position: 'right', color: '#456388', fontSize: 11 }
    }]
  })
}

async function init() {
  const resp = await getRooms()
  rooms.value = resp.data || []
  if (rooms.value.length) roomId.value = rooms.value[0].id
  await Promise.all([loadHeatmap(), loadOverview()])
}

watch([roomId, date], loadHeatmap)

function resizeAll() {
  heatChart?.resize(); trendChart?.resize(); peakChart?.resize(); topChart?.resize()
}

onMounted(() => {
  init()
  window.addEventListener('resize', resizeAll)
})
onUnmounted(() => window.removeEventListener('resize', resizeAll))
</script>

<template>
  <!-- 统计：页面级双栏 = 左 KPI/筛选 | 右热力图+图表 -->
  <div class="split analytics-split">
    <!-- 左栏：概览 KPI + 筛选器 -->
    <div class="split-left">
      <section class="card">
        <div class="card-title-row"><h3>运营总览</h3></div>
        <div class="kpi-grid">
          <div v-if="overview" class="kpi">
            <div class="kpi-num">{{ overview.total_seats }}</div>
            <div class="kpi-label">总座位数</div>
          </div>
          <div v-if="overview" class="kpi kpi-ok">
            <div class="kpi-num">{{ overview.active_today }}</div>
            <div class="kpi-label">今日预约</div>
          </div>
          <div v-if="overview" class="kpi kpi-primary">
            <div class="kpi-num">{{ overview.in_use_now }}</div>
            <div class="kpi-label">当前使用中</div>
          </div>
          <div v-if="overview" class="kpi kpi-warm">
            <div class="kpi-num">{{ (overview.today_utilization * 100).toFixed(1) }}%</div>
            <div class="kpi-label">今日利用率</div>
          </div>
        </div>
      </section>

      <section class="card">
        <div class="card-title-row"><h3>热力图参数</h3></div>
        <div class="filter-group">
          <div class="filter-row">
            <label>自习室</label>
            <el-select v-model="roomId">
              <el-option v-for="r in rooms" :key="r.id" :label="r.name" :value="r.id" />
            </el-select>
          </div>
          <div class="filter-row">
            <label>日期</label>
            <el-date-picker v-model="date" type="date" value-format="YYYY-MM-DD" />
          </div>
        </div>
        <div class="filter-hint" style="margin-top:12px">
          颜色越深表示该座位在该小时被预约/占用的概率越高，便于提前规划热门时段。
        </div>
      </section>

      <section class="card">
        <div class="card-title-row"><h3>指标说明</h3></div>
        <ul class="tips">
          <li><b>利用率</b>：实际占用小时数 ÷ 可开放小时数</li>
          <li><b>高峰时段</b>：近 14 天按时段聚合的预约数 Top</li>
          <li><b>热门座位</b>：近 14 天累计占用小时数 Top 10</li>
        </ul>
      </section>
    </div>

    <!-- 右栏：热力图 + 图表 -->
    <div class="split-right">
      <section class="card">
        <div class="card-title-row">
          <h3>座位 × 时段 热力图</h3>
          <span class="muted">颜色越深 = 占用概率越高</span>
        </div>
        <div ref="heatEl" class="chart chart-heat"></div>
      </section>

      <section class="card">
        <div class="card-title-row"><h3>近 14 天运营趋势</h3></div>
        <div class="charts-row">
          <div ref="trendEl" class="chart"></div>
          <div ref="peakEl" class="chart"></div>
        </div>
      </section>

      <section class="card">
        <div class="card-title-row"><h3>热门座位 Top 10</h3></div>
        <div ref="topEl" class="chart chart-bar"></div>
      </section>
    </div>
  </div>
</template>

<style scoped>
.analytics-split { grid-template-columns: 300px 1fr; }

.kpi-primary .kpi-num { color: #456388; }
.kpi-ok      .kpi-num { color: #5fa655; }
.kpi-warm    .kpi-num { color: #c78941; }

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
.tips b { color: #456388; font-weight: 600; }

.chart {
  width: 100%;
  height: 320px;
}
.chart-heat { height: 380px; }
.chart-bar  { height: 340px; }

.charts-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 18px;
}

@media (max-width: 1100px) {
  .charts-row { grid-template-columns: 1fr; }
}
</style>
