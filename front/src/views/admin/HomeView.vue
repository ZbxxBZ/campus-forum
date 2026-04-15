<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { listAvailableBoardsApi, listPublishedPostsApi } from '../../services/modules/forumApi'

const route = useRoute()
const router = useRouter()
const publishedPosts = ref([])
const allBoards = ref([])
const loading = ref(false)
const errorMessage = ref('')
const showAdvancedFilter = ref(false)
const activeFeed = ref('recommend')
const pagination = reactive({
  page: 1,
  pageSize: 20,
  total: 0
})
const hasMore = ref(false)
const filters = reactive({
  keyword: '',
  author: '',
  tag: '',
  boardId: '',
  dateFrom: '',
  dateTo: ''
})

const feedTabs = [
  { key: 'all', label: '全部' },
  { key: 'recommend', label: '推荐' },
  { key: 'hot', label: '热门' },
  { key: 'latest', label: '最新' },
  { key: 'followed', label: '我的关注' }
]
const feedKeys = new Set(feedTabs.map((item) => item.key))
const pageSizeOptions = [10, 20, 50, 100]

const formatClassMap = {
  rich_text: 'format-rich-text',
  markdown: 'format-markdown',
  image_gallery: 'format-image-gallery',
  external_link: 'format-external-link'
}
const formatLabelMap = {
  rich_text: '富文本',
  markdown: 'Markdown',
  image_gallery: '图文相册',
  external_link: '外链'
}
const boardThemes = [
  { cardStart: '#ffffff', cardEnd: '#f8fafc', line: '#2563eb', pillBg: '#e8f0ff', pillBorder: '#93c5fd', pillText: '#1e3a8a' },
  { cardStart: '#ffffff', cardEnd: '#f8fafc', line: '#0f766e', pillBg: '#e6fffb', pillBorder: '#5eead4', pillText: '#134e4a' },
  { cardStart: '#ffffff', cardEnd: '#f8fafc', line: '#7c3aed', pillBg: '#f3edff', pillBorder: '#c4b5fd', pillText: '#4c1d95' },
  { cardStart: '#ffffff', cardEnd: '#f8fafc', line: '#ca8a04', pillBg: '#fff8e1', pillBorder: '#fcd34d', pillText: '#713f12' },
  { cardStart: '#ffffff', cardEnd: '#f8fafc', line: '#16a34a', pillBg: '#ecfdf3', pillBorder: '#86efac', pillText: '#14532d' },
  { cardStart: '#ffffff', cardEnd: '#f8fafc', line: '#ea580c', pillBg: '#fff1e9', pillBorder: '#fdba74', pillText: '#7c2d12' }
]

function formatClass(item) {
  return formatClassMap[item.format] || 'format-default'
}

function formatLabel(item) {
  return item.formatLabel || formatLabelMap[item.format] || item.format || '-'
}

function hashText(text) {
  let hash = 0
  const value = String(text || '')
  for (let i = 0; i < value.length; i += 1) {
    hash = (hash << 5) - hash + value.charCodeAt(i)
    hash |= 0
  }
  return Math.abs(hash)
}

function resolveBoardTheme(item) {
  const numericBoardId = Number(item.boardId)
  if (Number.isFinite(numericBoardId) && numericBoardId > 0) {
    return boardThemes[(numericBoardId - 1) % boardThemes.length]
  }
  const seed = `${item.boardName || ''}`
  const idx = hashText(seed) % boardThemes.length
  return boardThemes[idx]
}

function cardThemeStyle(item) {
  const theme = resolveBoardTheme(item)
  return {
    '--board-soft-1': theme.cardStart,
    '--board-soft-2': theme.cardEnd,
    '--board-line': theme.line
  }
}

function boardPillStyle(item) {
  const theme = resolveBoardTheme(item)
  return {
    backgroundColor: theme.pillBg,
    borderColor: theme.pillBorder,
    color: theme.pillText
  }
}

function jumpToDetail(item) {
  router.push(buildDetailRoute(item.id))
}

function onCardClick(item, event) {
  const target = event?.target
  if (target && target.closest && target.closest('a,button,input,select,textarea,label')) return
  jumpToDetail(item)
}

function onCardKeydown(item, event) {
  if (event.key === 'Enter' || event.key === ' ') {
    event.preventDefault()
    jumpToDetail(item)
  }
}

function extractSummary(item) {
  const raw = String(item.summary || item.content || '')
  const plain = raw.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim()
  if (!plain) return '暂无摘要'
  return plain.length > 88 ? `${plain.slice(0, 88)}...` : plain
}

function authorAvatarText(item) {
  const name = String(item.author || '').trim()
  if (!name) return '?'
  return name.slice(0, 1).toUpperCase()
}

function firstQueryValue(value) {
  if (Array.isArray(value)) return value[0] || ''
  return value || ''
}

function buildDetailRoute(postId) {
  return {
    path: `/admin/post-detail/${postId}`,
    query: {
      from: 'home',
      feed: activeFeed.value,
      page: pagination.page,
      pageSize: pagination.pageSize,
      keyword: filters.keyword || undefined,
      author: filters.author || undefined,
      tag: filters.tag || undefined,
      boardId: filters.boardId || undefined,
      dateFrom: filters.dateFrom || undefined,
      dateTo: filters.dateTo || undefined
    }
  }
}

const boardOptions = computed(() => {
  return (allBoards.value || []).map((item) => ({ id: item.id, name: item.name }))
})
const totalPages = computed(() => {
  const total = Number(pagination.total || 0)
  const size = Number(pagination.pageSize || 1)
  if (!size) return 1
  if (!total) return Math.max(1, pagination.page)
  return Math.max(1, Math.ceil(total / size))
})
const canGoPrev = computed(() => pagination.page > 1)
const canGoNext = computed(() => hasMore.value)
const pageText = computed(() => {
  if (Number(pagination.total) > 0) {
    return `${pagination.page}/${totalPages.value}`
  }
  return `${pagination.page}`
})
const totalText = computed(() => (Number(pagination.total) > 0 ? `${pagination.total}` : '未知'))
const paginationHint = computed(() => {
  if (Number(pagination.total) <= 0) return ''
  if (totalPages.value <= 1) {
    return `共 ${pagination.total} 条，当前每页 ${pagination.pageSize} 条，仅 1 页，无法翻页。`
  }
  return `共 ${pagination.total} 条，当前每页 ${pagination.pageSize} 条。`
})
const feedHintText = computed(() => {
  return ''
})

function buildSearchTerms(rawKeyword) {
  const keyword = String(rawKeyword || '').trim().toLowerCase()
  if (!keyword) return []

  const terms = new Set([keyword])

  if (keyword.includes('四六级')) {
    terms.add('四级')
    terms.add('六级')
    terms.add('四六')
    terms.add('四 六 级')
  }

  if (keyword.length >= 4) {
    for (let i = 0; i < keyword.length - 1; i += 1) {
      terms.add(keyword.slice(i, i + 2))
    }
  }

  return Array.from(terms).filter(Boolean)
}

function relevanceScore(item, terms, keyword) {
  if (!terms.length) return 0

  const title = String(item.title || '').toLowerCase()
  const content = String(item.content || '').toLowerCase()
  const summary = String(item.summary || '').toLowerCase()
  const authorText = String(item.author || '').toLowerCase()
  const tagText = Array.isArray(item.tags) ? item.tags.join(' ').toLowerCase() : ''

  let score = 0

  if (title === keyword) score += 120
  if (title.includes(keyword)) score += 100
  if (tagText.includes(keyword)) score += 60
  if (summary.includes(keyword)) score += 45
  if (content.includes(keyword)) score += 40
  if (authorText.includes(keyword)) score += 30

  for (const term of terms) {
    if (!term || term === keyword) continue
    if (title.includes(term)) score += 16
    if (tagText.includes(term)) score += 12
    if (summary.includes(term)) score += 8
    if (content.includes(term)) score += 6
    if (authorText.includes(term)) score += 4
  }

  return score
}

function hotScore(item) {
  const likeCount = Number(item.likeCount || 0)
  const favoriteCount = Number(item.favoriteCount || 0)
  const commentCount = Number(item.commentCount || 0)
  return likeCount * 3 + favoriteCount * 2 + commentCount
}

const filteredRows = computed(() => {
  const keyword = filters.keyword.trim().toLowerCase()
  const terms = buildSearchTerms(keyword)
  const author = filters.author.trim().toLowerCase()
  const tag = filters.tag.trim().toLowerCase()
  const fromTs = filters.dateFrom ? new Date(`${filters.dateFrom}T00:00:00`).getTime() : null
  const toTs = filters.dateTo ? new Date(`${filters.dateTo}T23:59:59`).getTime() : null

  return publishedPosts.value
    .map((item, index) => {
      const textPool = [
        item.title,
        item.summary,
        item.content,
        item.author,
        Array.isArray(item.tags) ? item.tags.join(' ') : ''
      ]
        .filter(Boolean)
        .join(' ')
        .toLowerCase()

      const matchedKeyword = !terms.length || terms.some((term) => textPool.includes(term))
      const matchedAuthor = !author || String(item.author || '').toLowerCase().includes(author)
      const matchedTag = !tag || (Array.isArray(item.tags) && item.tags.join(' ').toLowerCase().includes(tag))
      const matchedBoard = !filters.boardId || Number(item.boardId) === Number(filters.boardId)
      const createdAtTs = item.createdAt ? new Date(item.createdAt).getTime() : 0
      const matchedDateFrom = !fromTs || createdAtTs >= fromTs
      const matchedDateTo = !toTs || createdAtTs <= toTs

      return {
        item,
        index,
        createdAtTs,
        score: relevanceScore(item, terms, keyword),
        hot: hotScore(item),
        matched: matchedKeyword && matchedAuthor && matchedTag && matchedBoard && matchedDateFrom && matchedDateTo,
        hasKeyword: terms.length > 0
      }
    })
    .filter((row) => row.matched)
})

const displayPosts = computed(() => {
  const rows = [...filteredRows.value]

  if (!rows.length) return []

  // 搜索关键词优先时，按相关度排序（覆盖信息流板块排序）。
  if (rows[0].hasKeyword) {
    rows.sort((a, b) => {
      if (b.score !== a.score) return b.score - a.score
      return b.createdAtTs - a.createdAtTs
    })
    return rows.map((row) => row.item)
  }

  if (activeFeed.value === 'hot') {
    rows.sort((a, b) => {
      if (b.hot !== a.hot) return b.hot - a.hot
      return b.createdAtTs - a.createdAtTs
    })
  }

  if (activeFeed.value === 'latest') {
    rows.sort((a, b) => b.createdAtTs - a.createdAtTs)
  }

  if (activeFeed.value === 'recommend') {
    rows.sort((a, b) => a.index - b.index)
  }

  if (activeFeed.value === 'all' || activeFeed.value === 'followed') {
    rows.sort((a, b) => b.createdAtTs - a.createdAtTs)
  }

  return rows.map((row) => row.item)
})

async function loadPublishedPosts() {
  loading.value = true
  errorMessage.value = ''
  try {
    const data = await listPublishedPostsApi({
      feed: activeFeed.value,
      page: pagination.page,
      pageSize: pagination.pageSize,
      keyword: filters.keyword || undefined,
      author: filters.author || undefined,
      tag: filters.tag || undefined,
      boardId: filters.boardId || undefined,
      dateFrom: filters.dateFrom || undefined,
      dateTo: filters.dateTo || undefined
    })
    const nextList = Array.isArray(data.list) ? data.list : []
    publishedPosts.value = nextList

    const respPage = Number(data.page)
    const respPageSize = Number(data.pageSize)
    const respTotal = Number(data.total)

    if (Number.isFinite(respPage) && respPage > 0) {
      pagination.page = respPage
    }
    if (Number.isFinite(respPageSize) && respPageSize > 0) {
      pagination.pageSize = respPageSize
    }
    if (Number.isFinite(respTotal) && respTotal >= 0) {
      pagination.total = respTotal
      const currentPageSize = pagination.pageSize > 0 ? pagination.pageSize : 1
      const serverTotalPages = Math.max(1, Math.ceil(respTotal / currentPageSize))
      // 后端 total 偶发不准时，允许“满页数据”继续翻页尝试，直到下一页为空再停。
      hasMore.value = pagination.page < serverTotalPages || nextList.length === currentPageSize
    } else {
      pagination.total = 0
      // 无 total 场景：只要本页有数据，就允许尝试下一页，直到返回空列表为止。
      hasMore.value = nextList.length > 0
    }
  } catch (error) {
    errorMessage.value = error.message
    hasMore.value = false
  } finally {
    loading.value = false
  }
}

async function loadBoards() {
  try {
    const data = await listAvailableBoardsApi()
    allBoards.value = data.list || []
  } catch {
    // 板块下拉失败时保持当前选项，避免影响帖子检索主流程。
  }
}

function resetFilters() {
  filters.keyword = ''
  filters.author = ''
  filters.tag = ''
  filters.boardId = ''
  filters.dateFrom = ''
  filters.dateTo = ''
  pagination.page = 1
  loadPublishedPosts()
}

function applyRouteState() {
  const feed = firstQueryValue(route.query.feed)
  if (feedKeys.has(feed)) {
    activeFeed.value = feed
  }

  const page = Number(firstQueryValue(route.query.page))
  const pageSize = Number(firstQueryValue(route.query.pageSize))
  if (Number.isFinite(page) && page > 0) pagination.page = page
  if (Number.isFinite(pageSize) && pageSizeOptions.includes(pageSize)) pagination.pageSize = pageSize

  filters.keyword = firstQueryValue(route.query.keyword)
  filters.author = firstQueryValue(route.query.author)
  filters.tag = firstQueryValue(route.query.tag)
  filters.boardId = firstQueryValue(route.query.boardId)
  filters.dateFrom = firstQueryValue(route.query.dateFrom)
  filters.dateTo = firstQueryValue(route.query.dateTo)
}

function searchPosts() {
  pagination.page = 1
  loadPublishedPosts()
}

function changePageSize() {
  pagination.page = 1
  loadPublishedPosts()
}

function goPrevPage() {
  if (!canGoPrev.value) return
  pagination.page -= 1
  loadPublishedPosts()
}

function goNextPage() {
  if (!canGoNext.value) return
  pagination.page += 1
  loadPublishedPosts()
}

function changeFeed(feedKey) {
  if (activeFeed.value === feedKey) return
  activeFeed.value = feedKey
  pagination.page = 1
  loadPublishedPosts()
}

onMounted(async () => {
  applyRouteState()
  await loadBoards()
  await loadPublishedPosts()
})
</script>

<template>
  <section class="panel">
    <h2>论坛已发布帖子</h2>
    <p class="hint">登录后可查看已发布内容，便于学生和教师快速浏览最新信息。</p>

    <div class="filter-row">
      <input
        v-model.trim="filters.keyword"
        placeholder="全文检索：标题/内容/作者/标签"
        @keyup.enter="searchPosts"
      />
      <button class="primary-btn" type="button" @click="searchPosts">检索</button>
      <button type="button" @click="showAdvancedFilter = !showAdvancedFilter">
        {{ showAdvancedFilter ? '收起高级筛选' : '高级筛选' }}
      </button>
      <button type="button" @click="resetFilters">重置</button>
    </div>

    <div class="form-grid two-col" v-if="showAdvancedFilter">
      <label>
        作者
        <input v-model.trim="filters.author" placeholder="按作者账号检索" />
      </label>
      <label>
        话题标签
        <input v-model.trim="filters.tag" placeholder="按标签关键词检索" />
      </label>
      <label>
        所属板块
        <select v-model="filters.boardId">
          <option value="">全部板块</option>
          <option v-for="item in boardOptions" :key="item.id" :value="item.id">{{ item.name }}</option>
        </select>
      </label>
      <label>
        发布时间起
        <input v-model="filters.dateFrom" type="date" />
      </label>
      <label>
        发布时间止
        <input v-model="filters.dateTo" type="date" />
      </label>
    </div>

    <div class="action-row">
      <button type="button" @click="loadPublishedPosts">刷新</button>
      <label>
        每页
        <select v-model.number="pagination.pageSize" @change="changePageSize">
          <option v-for="size in pageSizeOptions" :key="size" :value="size">{{ size }}</option>
        </select>
        条
      </label>
      <span class="hint" v-if="loading">加载中...</span>
      <span class="hint" v-if="!loading">
        {{ filters.keyword ? '相关度优先结果' : '检索结果' }}：第 {{ pageText }} 页，共 {{ totalText }} 条
      </span>
    </div>

    <div class="feed-nav-row">
      <button
        v-for="tab in feedTabs"
        :key="tab.key"
        type="button"
        class="feed-nav-btn"
        :class="{ active: activeFeed === tab.key }"
        @click="changeFeed(tab.key)"
      >
        {{ tab.label }}
      </button>
    </div>
    <p v-if="feedHintText" class="hint">{{ feedHintText }}</p>

    <p v-if="errorMessage" class="error">{{ errorMessage }}</p>

    <div class="workbench-card-grid">
      <article
        class="workbench-post-card"
        :class="formatClass(item)"
        :style="cardThemeStyle(item)"
        v-for="item in displayPosts"
        :key="item.id"
        role="link"
        tabindex="0"
        @click="onCardClick(item, $event)"
        @keydown="onCardKeydown(item, $event)"
      >
        <div class="workbench-post-head">
          <span class="workbench-author-avatar">
            <img v-if="item.authorAvatar" :src="item.authorAvatar" :alt="item.author || 'author'" />
            <span v-else>{{ authorAvatarText(item) }}</span>
          </span>
          <span class="workbench-format-chip" :class="formatClass(item)">{{ formatLabel(item) }}</span>
          <span class="workbench-board-pill" :style="boardPillStyle(item)">{{ item.boardName || '-' }}</span>
        </div>

        <h3 class="workbench-post-title">
          <RouterLink :to="buildDetailRoute(item.id)">{{ item.title }}</RouterLink>
        </h3>

        <p class="workbench-post-summary">{{ extractSummary(item) }}</p>

        <div class="workbench-post-meta">
          <div>
            作者：
            <RouterLink v-if="item.authorId" :to="`/admin/profile/${item.authorId}`">{{ item.author }}</RouterLink>
            <template v-else>{{ item.author || '-' }}</template>
          </div>
          <div>发布时间：{{ item.createdAt?.slice(0, 16).replace('T', ' ') }}</div>
        </div>

      </article>
    </div>

    <p v-if="!displayPosts.length && !loading" class="hint">暂无已发布帖子</p>

    <div class="action-row" v-if="pagination.total > 0">
      <button type="button" :disabled="!canGoPrev || loading" @click="goPrevPage">上一页</button>
      <span class="page-indicator">第 {{ pagination.page }} / {{ totalPages }} 页</span>
      <button type="button" :disabled="!canGoNext || loading" @click="goNextPage">下一页</button>
      <span class="hint">{{ paginationHint }}</span>
    </div>
  </section>
</template>
