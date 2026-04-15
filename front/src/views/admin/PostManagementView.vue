<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { listBoardsApi, listPostsApi, updatePostApi } from '../../services/modules/forumApi'

const posts = ref([])
const boards = ref([])
const errorMessage = ref('')
const saving = ref(false)
const editingPostId = ref(null)
const loading = ref(false)
const viewMode = ref('table')
const pageSizeOptions = [10, 20, 50, 100]
const pagination = reactive({
  page: 1,
  pageSize: 20,
  total: 0
})

const filters = reactive({
  keyword: '',
  status: 'published,hidden',
  boardId: '',
  format: ''
})

const editForm = reactive({
  title: '',
  summary: '',
  content: '',
  boardId: '',
  format: 'rich_text',
  status: 'pending',
  tagsText: ''
})

const formatMap = {
  rich_text: '富文本',
  markdown: 'Markdown',
  image_gallery: '图文相册',
  external_link: '外链分享'
}

const statusMap = {
  draft: '草稿',
  pending: '待审核',
  published: '已发布',
  rejected: '已驳回',
  hidden: '已下架'
}

function statusText(status) {
  return statusMap[status] || status
}

function getStatusClass(status) {
  const classMap = {
    draft: 'chip-draft',
    pending: 'chip-pending',
    published: 'chip-published',
    rejected: 'chip-rejected',
    hidden: 'chip-hidden'
  }
  return classMap[status] || ''
}

function formatText(format) {
  return formatMap[format] || format
}

function extractPreview(post) {
  const raw = String(post.summary || post.content || '')
  const plain = raw.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim()
  if (!plain) return '暂无摘要'
  return plain.length > 88 ? `${plain.slice(0, 88)}...` : plain
}

const totalPages = computed(() => {
  const total = Number(pagination.total || 0)
  const size = Number(pagination.pageSize || 1)
  if (!size) return 1
  if (!total) return Math.max(1, pagination.page)
  return Math.max(1, Math.ceil(total / size))
})
const canGoPrev = computed(() => pagination.page > 1)
const canGoNext = computed(() => pagination.page < totalPages.value)
const pageIndicator = computed(() => `第 ${pagination.page} / ${totalPages.value} 页`)
const totalHint = computed(() => `共 ${pagination.total} 条帖子`)

async function loadBoards() {
  try {
    const data = await listBoardsApi({ status: 'enabled' })
    boards.value = data.list
  } catch (error) {
    errorMessage.value = `板块加载失败：${error.message}`
  }
}

async function loadData() {
  errorMessage.value = ''
  loading.value = true
  try {
    const data = await listPostsApi({
      ...filters,
      page: pagination.page,
      pageSize: pagination.pageSize
    })
    posts.value = data.list || []
    pagination.total = Number(data.total || 0)
    pagination.page = Number(data.page || pagination.page)
    pagination.pageSize = Number(data.pageSize || pagination.pageSize)
  } catch (error) {
    posts.value = []
    pagination.total = 0
    errorMessage.value = `帖子加载失败：${error.message}`
  } finally {
    loading.value = false
  }
}

function runSearch() {
  pagination.page = 1
  loadData()
}

function goPrevPage() {
  if (!canGoPrev.value || loading.value) return
  pagination.page -= 1
  loadData()
}

function goNextPage() {
  if (!canGoNext.value || loading.value) return
  pagination.page += 1
  loadData()
}

function changePageSize(event) {
  const value = Number(event.target.value)
  if (!value || value === pagination.pageSize) return
  pagination.pageSize = value
  pagination.page = 1
  loadData()
}

function startEdit(post) {
  editingPostId.value = post.id
  editForm.title = post.title
  editForm.summary = post.summary || ''
  editForm.content = post.content || ''
  editForm.boardId = post.boardId
  editForm.format = post.format
  editForm.status = post.status
  editForm.tagsText = (post.tags || []).join(', ')
}

function cancelEdit() {
  editingPostId.value = null
}

async function saveEdit() {
  if (!editingPostId.value) return
  saving.value = true
  errorMessage.value = ''
  try {
    await updatePostApi(editingPostId.value, {
      title: editForm.title,
      summary: editForm.summary,
      content: editForm.content,
      boardId: Number(editForm.boardId),
      format: editForm.format,
      status: editForm.status,
      tags: editForm.tagsText
    })
    editingPostId.value = null
    await loadData()
  } catch (error) {
    errorMessage.value = error.message
  } finally {
    saving.value = false
  }
}

async function toggleTop(post) {
  await updatePostApi(post.id, { isTop: !post.isTop })
  await loadData()
}

async function toggleFeatured(post) {
  await updatePostApi(post.id, { isFeatured: !post.isFeatured })
  await loadData()
}

async function togglePublish(post) {
  if (post.status === 'published') {
    const confirmed = window.confirm('确认下架该帖子？\n下架后帖子不会被删除，可在后台重新上架。')
    if (!confirmed) return
  }

  const status = post.status === 'published' ? 'hidden' : 'published'
  await updatePostApi(post.id, { status })
  await loadData()
}

onMounted(async () => {
  await loadBoards()
  await loadData()
})
</script>

<template>
  <section class="panel">
    <h2>帖子精细化管理</h2>

    <div class="filter-row">
      <input v-model.trim="filters.keyword" placeholder="按标题/摘要搜索" @keyup.enter="runSearch" />
      <select v-model="filters.boardId">
        <option value="">全部板块</option>
        <option v-for="item in boards" :key="item.id" :value="item.id">{{ item.name }}</option>
      </select>
      <select v-model="filters.format">
        <option value="">全部格式</option>
        <option value="rich_text">富文本</option>
        <option value="markdown">Markdown</option>
        <option value="image_gallery">图文相册</option>
        <option value="external_link">外链分享</option>
      </select>
      <select v-model="filters.status">
        <option value="published,hidden">已发布 + 已下架</option>
        <option value="published">已发布</option>
        <option value="hidden">已下架</option>
      </select>
      <button type="button" :disabled="loading" @click="runSearch">查询</button>
    </div>

    <div class="view-toggle-row">
      <span class="hint">视图：</span>
      <button type="button" class="feed-nav-btn" :class="{ active: viewMode === 'table' }" @click="viewMode = 'table'">
        表格
      </button>
      <button type="button" class="feed-nav-btn" :class="{ active: viewMode === 'card' }" @click="viewMode = 'card'">
        卡片
      </button>
    </div>

    <div class="action-row">
      <button type="button" :disabled="!canGoPrev || loading" @click="goPrevPage">上一页</button>
      <span class="page-indicator">{{ pageIndicator }}</span>
      <button type="button" :disabled="!canGoNext || loading" @click="goNextPage">下一页</button>
      <label class="hint">
        每页
        <select :value="pagination.pageSize" @change="changePageSize">
          <option v-for="size in pageSizeOptions" :key="size" :value="size">{{ size }}</option>
        </select>
        条
      </label>
      <span class="hint">{{ totalHint }}</span>
      <span class="hint" v-if="loading">加载中...</span>
    </div>

    <p v-if="errorMessage" class="error">{{ errorMessage }}</p>

    <table v-if="viewMode === 'table'">
      <thead>
        <tr>
          <th>ID</th>
          <th>标题</th>
          <th>作者</th>
          <th>板块</th>
          <th>格式</th>
          <th>状态</th>
          <th>标签</th>
          <th>策略</th>
          <th>更新时间</th>
          <th>操作</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="item in posts" :key="item.id">
          <td>{{ item.id }}</td>
          <td><RouterLink :to="`/admin/post-detail/${item.id}`">{{ item.title }}</RouterLink></td>
          <td>
            <RouterLink v-if="item.authorId" :to="`/admin/profile/${item.authorId}`">{{ item.author }}</RouterLink>
            <template v-else>{{ item.author || '-' }}</template>
          </td>
          <td>{{ item.boardName }}</td>
          <td>{{ formatText(item.format) }}</td>
          <td>{{ statusText(item.status) }}</td>
          <td>{{ (item.tags || []).join('，') || '-' }}</td>
          <td>
            <span class="chip" :class="item.isTop ? 'chip-on' : ''">置顶</span>
            <span class="chip" :class="item.isFeatured ? 'chip-on' : ''">加精</span>
          </td>
          <td>{{ item.updatedAt?.slice(0, 16).replace('T', ' ') }}</td>
          <td>
            <div class="table-actions">
              <button type="button" @click="startEdit(item)">编辑</button>
              <button type="button" @click="toggleTop(item)">{{ item.isTop ? '取消置顶' : '置顶' }}</button>
              <button type="button" @click="toggleFeatured(item)">{{ item.isFeatured ? '取消加精' : '加精' }}</button>
              <button type="button" :class="item.status === 'published' ? 'danger' : ''" @click="togglePublish(item)">
                {{ item.status === 'published' ? '下架' : '发布' }}
              </button>
            </div>
          </td>
        </tr>
      </tbody>
    </table>

    <div v-else class="management-card-grid">
      <article class="management-post-card" v-for="item in posts" :key="item.id">
        <div class="management-post-head">
          <span class="workbench-post-id">#{{ item.id }}</span>
          <span class="chip" :class="getStatusClass(item.status)">{{ statusText(item.status) }}</span>
        </div>

        <h3 class="workbench-post-title">
          <RouterLink :to="`/admin/post-detail/${item.id}`">{{ item.title }}</RouterLink>
        </h3>

        <p class="workbench-post-summary">{{ extractPreview(item) }}</p>

        <div class="management-meta-grid">
          <div class="meta-item">
            <span class="meta-label">作者</span>
            <RouterLink v-if="item.authorId" :to="`/admin/profile/${item.authorId}`" class="meta-value">{{ item.author }}</RouterLink>
            <span v-else class="meta-value">{{ item.author || '-' }}</span>
          </div>
          <div class="meta-item">
            <span class="meta-label">板块</span>
            <span class="meta-value">{{ item.boardName || '-' }}</span>
          </div>
          <div class="meta-item">
            <span class="meta-label">格式</span>
            <span class="meta-value">{{ formatText(item.format) }}</span>
          </div>
          <div class="meta-item">
            <span class="meta-label">更新时间</span>
            <span class="meta-value">{{ item.updatedAt?.slice(0, 16).replace('T', ' ') }}</span>
          </div>
          <div class="meta-item" v-if="item.tags && item.tags.length">
            <span class="meta-label">标签</span>
            <span class="meta-value meta-tags">
              <span v-for="tag in item.tags" :key="tag" class="tag-badge">{{ tag }}</span>
            </span>
          </div>
        </div>

        <div class="management-actions">
          <div class="chip-group">
            <span class="chip" :class="item.isTop ? 'chip-on' : 'chip-off'">{{ item.isTop ? '已置顶' : '置顶' }}</span>
            <span class="chip" :class="item.isFeatured ? 'chip-on' : 'chip-off'">{{ item.isFeatured ? '已加精' : '加精' }}</span>
          </div>
          <div class="action-buttons">
            <button type="button" @click="startEdit(item)">编辑</button>
            <button type="button" @click="toggleTop(item)">{{ item.isTop ? '取消置顶' : '置顶' }}</button>
            <button type="button" @click="toggleFeatured(item)">{{ item.isFeatured ? '取消加精' : '加精' }}</button>
            <button type="button" :class="item.status === 'published' ? 'danger' : ''" @click="togglePublish(item)">
              {{ item.status === 'published' ? '下架' : '发布' }}
            </button>
          </div>
        </div>
      </article>
    </div>

    <p v-if="!posts.length && !loading" class="hint">当前筛选条件下暂无帖子</p>

    <div class="action-row" v-if="pagination.total > 0">
      <button type="button" :disabled="!canGoPrev || loading" @click="goPrevPage">上一页</button>
      <span class="page-indicator">{{ pageIndicator }}</span>
      <button type="button" :disabled="!canGoNext || loading" @click="goNextPage">下一页</button>
      <label class="hint">
        每页
        <select :value="pagination.pageSize" @change="changePageSize">
          <option v-for="size in pageSizeOptions" :key="size" :value="size">{{ size }}</option>
        </select>
        条
      </label>
      <span class="hint">{{ totalHint }}</span>
    </div>

    <div v-if="editingPostId" class="edit-modal-mask" @click.self="cancelEdit">
      <div class="edit-modal-panel">
        <div class="edit-modal-header">
          <h3>编辑帖子 #{{ editingPostId }}</h3>
          <button type="button" class="edit-modal-close" @click="cancelEdit">关闭</button>
        </div>

        <div class="form-grid two-col">
          <label>
            标题
            <input v-model.trim="editForm.title" />
          </label>
          <label>
            板块
            <select v-model="editForm.boardId">
              <option v-for="item in boards" :key="item.id" :value="item.id">{{ item.name }}</option>
            </select>
          </label>
          <label>
            摘要
            <input v-model.trim="editForm.summary" />
          </label>
          <label>
            格式
            <select v-model="editForm.format">
              <option value="rich_text">富文本</option>
              <option value="markdown">Markdown</option>
              <option value="image_gallery">图文相册</option>
              <option value="external_link">外链分享</option>
            </select>
          </label>
          <label>
            状态
            <select v-model="editForm.status">
              <option value="draft">草稿</option>
              <option value="pending">待审核</option>
              <option value="published">已发布</option>
              <option value="rejected">已驳回</option>
              <option value="hidden">已下架</option>
            </select>
          </label>
          <label class="full-width">
            标签
            <input v-model.trim="editForm.tagsText" placeholder="逗号分隔" />
          </label>
          <label class="full-width">
            正文
            <textarea v-model="editForm.content" rows="8" />
          </label>
        </div>

        <div class="action-row">
          <button class="primary-btn" type="button" :disabled="saving" @click="saveEdit">
            {{ saving ? '保存中...' : '保存修改' }}
          </button>
          <button type="button" @click="cancelEdit">取消</button>
        </div>
      </div>
    </div>
  </section>
</template>
