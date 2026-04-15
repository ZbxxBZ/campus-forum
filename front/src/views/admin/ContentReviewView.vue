<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { listPendingReviewPostsApi, reviewPostApi } from '../../services/modules/forumApi'

const list = ref([])
const loading = ref(false)
const errorMessage = ref('')
const pageSizeOptions = [10, 20, 50, 100]
const pagination = reactive({
  page: 1,
  pageSize: 20,
  total: 0
})

const pendingPosts = computed(() =>
  list.value.filter((item) => {
    const status = String(item.status || item.reviewStatus || item.auditStatus || '').toLowerCase()
    return status === 'pending' || status === 'pending_review' || status === 'to_review'
  })
)

function normalizeList(result) {
  if (Array.isArray(result?.list)) return result.list
  if (Array.isArray(result?.records)) return result.records
  if (Array.isArray(result)) return result
  return []
}

async function tryLoad(params) {
  const data = await listPendingReviewPostsApi(params)
  return {
    list: normalizeList(data),
    total: Number(data?.total ?? 0),
    page: Number(data?.page ?? pagination.page),
    pageSize: Number(data?.pageSize ?? pagination.pageSize)
  }
}

async function loadData() {
  loading.value = true
  errorMessage.value = ''

  try {
    const result = await tryLoad({
      status: 'pending',
      reviewStatus: 'pending',
      auditStatus: 'pending',
      page: pagination.page,
      pageSize: pagination.pageSize
    })

    list.value = result.list
    pagination.total = result.total || result.list.length
    if (Number.isFinite(result.page) && result.page > 0) pagination.page = result.page
    if (Number.isFinite(result.pageSize) && result.pageSize > 0) pagination.pageSize = result.pageSize
  } catch (error) {
    list.value = []
    errorMessage.value = `待审核列表加载失败：${error.message}`
  } finally {
    loading.value = false
  }
}

async function review(postId, action) {
  await reviewPostApi(postId, action)
  await loadData()
}

const totalPages = computed(() => {
  if (!pagination.pageSize) return 1
  return Math.max(1, Math.ceil((pagination.total || 0) / pagination.pageSize))
})

const canGoPrev = computed(() => pagination.page > 1)
const canGoNext = computed(() => pagination.page < totalPages.value)

function changePageSize() {
  pagination.page = 1
  loadData()
}

function goPrevPage() {
  if (!canGoPrev.value) return
  pagination.page -= 1
  loadData()
}

function goNextPage() {
  if (!canGoNext.value) return
  pagination.page += 1
  loadData()
}

onMounted(loadData)
</script>

<template>
  <section class="panel">
    <h2>内容审核</h2>
    <p class="hint">待审核：共 {{ pagination.total }} 条，当前第 {{ pagination.page }}/{{ totalPages }} 页</p>
    <p class="hint" v-if="loading">正在刷新审核队列...</p>
    <p class="error" v-if="errorMessage">{{ errorMessage }}</p>

    <div class="action-row">
      <label>
        每页
        <select v-model.number="pagination.pageSize" @change="changePageSize">
          <option v-for="size in pageSizeOptions" :key="size" :value="size">{{ size }}</option>
        </select>
        条
      </label>
      <button type="button" :disabled="!canGoPrev || loading" @click="goPrevPage">上一页</button>
      <button type="button" :disabled="!canGoNext || loading" @click="goNextPage">下一页</button>
    </div>

    <table>
      <thead>
        <tr>
          <th>ID</th>
          <th>标题</th>
          <th>作者</th>
          <th>板块</th>
          <th>风险等级</th>
          <th>操作</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="item in pendingPosts" :key="item.id">
          <td>{{ item.id }}</td>
          <td>
            <RouterLink :to="`/admin/reviews/${item.id}`">{{ item.title }}</RouterLink>
          </td>
          <td>{{ item.author }}</td>
          <td>{{ item.boardName || item.category || '-' }}</td>
          <td>{{ item.riskLevel || '-' }}</td>
          <td>
            <button type="button" @click="review(item.id, 'approve')">通过</button>
            <button type="button" class="danger" @click="review(item.id, 'reject')">驳回</button>
          </td>
        </tr>
        <tr v-if="!pendingPosts.length && !loading">
          <td colspan="6" class="hint">暂无待审核帖子</td>
        </tr>
      </tbody>
    </table>
  </section>
</template>
