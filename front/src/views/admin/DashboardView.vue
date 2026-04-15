<script setup>
import { computed, onMounted, ref } from 'vue'
import { getDashboardStatsApi } from '../../services/modules/forumApi'

const stats = ref({
  totalUsers: 0,
  totalPosts: 0,
  pendingReviews: 0,
  rejectedToday: 0,
  onlineUsers: 0
})

const piePaletteRole = ['#2563eb', '#16a34a', '#9333ea', '#ea580c', '#0ea5e9']
const piePaletteBoard = ['#16a34a', '#2563eb', '#eab308', '#9333ea', '#ea580c', '#0ea5e9']

function num(value, fallback = 0) {
  const n = Number(value)
  return Number.isFinite(n) ? n : fallback
}

function safePercent(value, total) {
  if (!total) return 0
  return Math.max(0, Math.round((value / total) * 100))
}

function fallbackTrend(total, days = 30) {
  const base = Math.max(1, Math.floor(num(total, 0) / days))
  return Array.from({ length: days }).map((_, idx) => ({
    label: `D${idx + 1}`,
    value: Math.max(1, base + ((idx % 5) - 2) * Math.max(1, Math.floor(base * 0.22)))
  }))
}

function normalizeDistribution(list = []) {
  return list
    .map((item) => ({
      label: String(item.label ?? item.name ?? '-'),
      value: Math.max(0, num(item.value ?? item.count ?? 0))
    }))
    .filter((item) => item.value > 0)
}

function buildPieData(rawList, palette, fallbackTotal = 0) {
  const list = normalizeDistribution(rawList)
  const total = list.reduce((sum, item) => sum + item.value, 0)

  if (!list.length || !total) {
    return {
      total: num(fallbackTotal, 0),
      style: { background: '#e2e8f0' },
      items: [{ label: '暂无数据', value: 0, percent: 0, color: '#cbd5e1' }]
    }
  }

  let cursor = 0
  const chartParts = []
  const items = list.map((item, index) => {
    const color = palette[index % palette.length]
    const degree = (item.value / total) * 360
    const from = cursor
    const to = cursor + degree
    cursor = to
    chartParts.push(`${color} ${from}deg ${to}deg`)
    return {
      ...item,
      color,
      percent: safePercent(item.value, total)
    }
  })

  return {
    total,
    style: { background: `conic-gradient(${chartParts.join(', ')})` },
    items
  }
}

const dashboard = computed(() => {
  const source = stats.value || {}
  const totalUsers = num(source.totalUsers)
  const totalPosts = num(source.totalPosts)
  const pendingReviews = num(source.pendingReviews)
  const rejectedToday = num(source.rejectedToday)
  const onlineUsers = num(source.onlineUsers)
  const totalComments = num(source.totalComments)
  const totalLikes = num(source.totalLikes)
  const totalFavorites = num(source.totalFavorites)
  const publishedPosts = num(source.publishedPosts, Math.max(0, totalPosts - pendingReviews))
  const hiddenPosts = num(source.hiddenPosts)
  const rejectedPosts = num(source.rejectedPosts, rejectedToday)
  const reviewPassedToday = num(source.reviewPassedToday)
  const reviewSubmittedToday = num(source.reviewSubmittedToday, reviewPassedToday + rejectedToday + pendingReviews)

  const postTrend = Array.isArray(source.postTrend) && source.postTrend.length
    ? source.postTrend.map((item, idx) => ({
        label: item.label || item.date || `D${idx + 1}`,
        value: num(item.value ?? item.count)
      }))
    : fallbackTrend(totalPosts || 90, 30)

  const activeTrend = Array.isArray(source.activeTrend) && source.activeTrend.length
    ? source.activeTrend.map((item, idx) => ({
        label: item.label || item.date || `D${idx + 1}`,
        value: num(item.value ?? item.count)
      }))
    : fallbackTrend(totalUsers || 70, 30)

  const roleDistribution = Array.isArray(source.roleDistribution) && source.roleDistribution.length
    ? source.roleDistribution
    : [
        { label: '学生', value: Math.max(0, Math.round(totalUsers * 0.72)) },
        { label: '教师', value: Math.max(0, Math.round(totalUsers * 0.22)) },
        { label: '管理员', value: Math.max(0, totalUsers - Math.round(totalUsers * 0.94)) }
      ]

  const statusDistribution = Array.isArray(source.statusDistribution) && source.statusDistribution.length
    ? source.statusDistribution
    : [
        { label: '已发布', value: publishedPosts },
        { label: '待审核', value: pendingReviews },
        { label: '已下架', value: hiddenPosts },
        { label: '已驳回', value: rejectedPosts }
      ]

  const boardDistribution = Array.isArray(source.boardDistribution) && source.boardDistribution.length
    ? source.boardDistribution
    : [
        { label: '学习交流', value: Math.max(1, Math.round(totalPosts * 0.4)) },
        { label: '校园生活', value: Math.max(1, Math.round(totalPosts * 0.35)) },
        { label: '通知公告', value: Math.max(1, totalPosts - Math.round(totalPosts * 0.75)) }
      ]

  return {
    totalUsers,
    totalPosts,
    pendingReviews,
    rejectedToday,
    onlineUsers,
    totalComments,
    totalLikes,
    totalFavorites,
    reviewPassedToday,
    reviewSubmittedToday,
    postTrend,
    activeTrend,
    roleDistribution,
    statusDistribution,
    boardDistribution
  }
})

const reviewPassRate = computed(() => {
  const total = dashboard.value.reviewSubmittedToday
  if (!total) return 0
  return safePercent(dashboard.value.reviewPassedToday, total)
})

const rolePie = computed(() => buildPieData(dashboard.value.roleDistribution, piePaletteRole, dashboard.value.totalUsers))
const boardPie = computed(() => buildPieData(dashboard.value.boardDistribution, piePaletteBoard, dashboard.value.totalPosts))

function chartMax(list) {
  return Math.max(...list.map((item) => num(item.value, 0)), 1)
}

onMounted(async () => {
  stats.value = await getDashboardStatsApi()
})
</script>

<template>
  <section class="panel">
    <h2>系统总览</h2>
    <p class="hint">面向校园活动高峰与考试季的运行监控看板</p>

    <div class="kpi-grid">
      <div class="kpi-card">
        <p>注册用户</p>
        <strong>{{ dashboard.totalUsers }}</strong>
      </div>
      <div class="kpi-card">
        <p>帖子总量</p>
        <strong>{{ dashboard.totalPosts }}</strong>
      </div>
      <div class="kpi-card">
        <p>待审核内容</p>
        <strong>{{ dashboard.pendingReviews }}</strong>
      </div>
      <div class="kpi-card">
        <p>今日驳回</p>
        <strong>{{ dashboard.rejectedToday }}</strong>
      </div>
      <div class="kpi-card">
        <p>在线用户</p>
        <strong>{{ dashboard.onlineUsers }}</strong>
      </div>
      <div class="kpi-card">
        <p>评论总量</p>
        <strong>{{ dashboard.totalComments }}</strong>
      </div>
      <div class="kpi-card">
        <p>点赞总量</p>
        <strong>{{ dashboard.totalLikes }}</strong>
      </div>
      <div class="kpi-card">
        <p>收藏总量</p>
        <strong>{{ dashboard.totalFavorites }}</strong>
      </div>
      <div class="kpi-card">
        <p>今日审核通过率</p>
        <strong>{{ reviewPassRate }}%</strong>
      </div>
    </div>

    <div class="dashboard-grid dashboard-grid-trend">
      <article class="dashboard-card">
        <h3>近一个月发帖趋势</h3>
        <div class="trend-scroll">
          <div class="trend-chart">
            <div class="trend-bar" v-for="item in dashboard.postTrend" :key="`post-${item.label}`">
              <div class="trend-fill" :style="{ height: `${Math.round((item.value / chartMax(dashboard.postTrend)) * 100)}%` }" />
              <span>{{ item.label }}</span>
            </div>
          </div>
        </div>
      </article>

      <article class="dashboard-card">
        <h3>近一个月活跃趋势</h3>
        <div class="trend-scroll">
          <div class="trend-chart">
            <div class="trend-bar" v-for="item in dashboard.activeTrend" :key="`active-${item.label}`">
              <div class="trend-fill trend-fill-alt" :style="{ height: `${Math.round((item.value / chartMax(dashboard.activeTrend)) * 100)}%` }" />
              <span>{{ item.label }}</span>
            </div>
          </div>
        </div>
      </article>
    </div>

    <div class="dashboard-grid dashboard-grid-analytics">
      <article class="dashboard-card">
        <h3>角色占比（饼图）</h3>
        <div class="pie-layout">
          <div class="pie-chart" :style="rolePie.style">
            <span>{{ rolePie.total }}</span>
          </div>
          <div class="pie-legend">
            <div class="pie-legend-item" v-for="item in rolePie.items" :key="`role-${item.label}`">
              <i :style="{ backgroundColor: item.color }" />
              <span>{{ item.label }}</span>
              <strong>{{ item.value }}（{{ item.percent }}%）</strong>
            </div>
          </div>
        </div>
      </article>

      <article class="dashboard-card">
        <h3>板块发帖 Top（饼图）</h3>
        <div class="pie-layout">
          <div class="pie-chart" :style="boardPie.style">
            <span>{{ boardPie.total }}</span>
          </div>
          <div class="pie-legend">
            <div class="pie-legend-item" v-for="item in boardPie.items" :key="`board-${item.label}`">
              <i :style="{ backgroundColor: item.color }" />
              <span>{{ item.label }}</span>
              <strong>{{ item.value }}（{{ item.percent }}%）</strong>
            </div>
          </div>
        </div>
      </article>

      <article class="dashboard-card dashboard-card-wide">
        <h3>帖子状态分布</h3>
        <div class="distribution-list">
          <div class="distribution-row" v-for="item in dashboard.statusDistribution" :key="item.label">
            <span>{{ item.label }}</span>
            <div class="distribution-track">
              <div class="distribution-fill distribution-fill-alt" :style="{ width: `${safePercent(item.value, dashboard.totalPosts || 1)}%` }" />
            </div>
            <strong>{{ item.value }}</strong>
          </div>
        </div>
      </article>
    </div>
  </section>
</template>
