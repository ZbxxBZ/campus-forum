<script setup>
import { onMounted, reactive, ref } from 'vue'
import { listAuditLogsApi } from '../../services/modules/forumApi'

const loading = ref(false)
const errorMessage = ref('')
const logs = ref([])
const total = ref(0)

const filters = reactive({
  keyword: '',
  action: '',
  role: '',
  operator: '',
  page: 1,
  pageSize: 20
})

const actionOptions = [
  { value: '', label: '全部操作' },
  { value: 'review_approve', label: '审核通过' },
  { value: 'review_reject', label: '审核驳回' },
  { value: 'post_hide', label: '帖子下架' },
  { value: 'post_publish', label: '帖子上架' },
  { value: 'post_status_change', label: '状态变更' }
]

const roleOptions = [
  { value: '', label: '全部角色' },
  { value: 'teacher', label: '教师' },
  { value: 'admin', label: '管理员' },
  { value: 'super_admin', label: '超级管理员' }
]

function actionMeta(action, actionLabel) {
  const map = {
    review_approve: { label: '审核通过', className: 'audit-tag-approve' },
    review_reject: { label: '审核驳回', className: 'audit-tag-reject' },
    post_hide: { label: '帖子下架', className: 'audit-tag-hide' },
    post_publish: { label: '帖子上架', className: 'audit-tag-publish' },
    post_status_change: { label: '状态变更', className: 'audit-tag-change' }
  }
  return map[action] || { label: actionLabel || action || '未知操作', className: 'audit-tag-change' }
}

async function loadData() {
  loading.value = true
  errorMessage.value = ''
  try {
    const data = await listAuditLogsApi(filters)
    logs.value = data.list || []
    total.value = data.total || 0
  } catch (error) {
    logs.value = []
    total.value = 0
    errorMessage.value = `审核日志加载失败：${error.message}`
  } finally {
    loading.value = false
  }
}

function query() {
  filters.page = 1
  loadData()
}

onMounted(loadData)
</script>

<template>
  <section class="panel">
    <h2>审核日志</h2>
    <p class="hint">仅超级管理员可见，用于追溯审核通过、驳回、下架、上架等关键操作。</p>

    <div class="filter-row">
      <input v-model.trim="filters.keyword" placeholder="按帖子标题/详情搜索" @keyup.enter="query" />
      <select v-model="filters.action">
        <option v-for="item in actionOptions" :key="item.value" :value="item.value">{{ item.label }}</option>
      </select>
      <select v-model="filters.role">
        <option v-for="item in roleOptions" :key="item.value" :value="item.value">{{ item.label }}</option>
      </select>
      <input v-model.trim="filters.operator" placeholder="按操作人账号搜索" @keyup.enter="query" />
      <button type="button" @click="query">查询</button>
    </div>

    <p class="hint">共 {{ total }} 条日志</p>
    <p v-if="loading" class="hint">日志加载中...</p>
    <p v-if="errorMessage" class="error">{{ errorMessage }}</p>

    <table>
      <thead>
        <tr>
          <th>ID</th>
          <th>时间</th>
          <th>操作</th>
          <th>帖子</th>
          <th>操作人</th>
          <th>角色</th>
          <th>详情</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="item in logs" :key="item.id">
          <td>{{ item.id }}</td>
          <td>{{ item.createdAt?.slice(0, 19).replace('T', ' ') }}</td>
          <td>
            <span class="audit-tag" :class="actionMeta(item.action, item.actionLabel).className">
              {{ actionMeta(item.action, item.actionLabel).label }}
            </span>
          </td>
          <td>
            <RouterLink v-if="item.postId" :to="`/admin/post-detail/${item.postId}`">
              {{ item.postTitle || `帖子 #${item.postId}` }}
            </RouterLink>
            <template v-else>{{ item.postTitle || '-' }}</template>
          </td>
          <td>{{ item.operator || '-' }}</td>
          <td>{{ item.operatorRole || '-' }}</td>
          <td>{{ item.detail || '-' }}</td>
        </tr>
        <tr v-if="!logs.length && !loading">
          <td colspan="7" class="hint">暂无审核日志</td>
        </tr>
      </tbody>
    </table>
  </section>
</template>
