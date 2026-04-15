<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { useAuthStore } from '../../stores/auth'
import { listMyPostsApi, updatePostApi } from '../../services/modules/forumApi'

const authStore = useAuthStore()
const posts = ref([])
const total = ref(0)
const saving = ref(false)
const editingPostId = ref(null)
const errorMessage = ref('')

const filters = reactive({
  keyword: '',
  status: ''
})

const editForm = reactive({
  title: '',
  summary: '',
  content: ''
})

const myPosts = computed(() => {
  return posts.value
})

const statusMap = {
  draft: '草稿',
  pending: '待审核',
  published: '已发布',
  rejected: '已驳回',
  hidden: '已下架'
}
const editableStatuses = new Set(['draft', 'pending', 'rejected'])

function statusText(status) {
  return statusMap[status] || status
}

async function loadData() {
  errorMessage.value = ''
  try {
    const data = await listMyPostsApi(filters)
    posts.value = data.list || []
    total.value = myPosts.value.length
  } catch (error) {
    posts.value = []
    total.value = 0
    errorMessage.value = `帖子加载失败：${error.message}`
  }
}

function startEdit(post) {
  if (!editableStatuses.has(post.status)) return
  editingPostId.value = post.id
  editForm.title = post.title
  editForm.summary = post.summary || ''
  editForm.content = post.content || ''
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
      content: editForm.content
    })
    editingPostId.value = null
    await loadData()
  } catch (error) {
    errorMessage.value = error.message
  } finally {
    saving.value = false
  }
}

async function softDeletePost(post) {
  const confirmed = window.confirm('确认删除该帖子？\n帖子不会被物理删除，将改为下架并从我的帖子列表移除。')
  if (!confirmed) return
  saving.value = true
  errorMessage.value = ''
  try {
    await updatePostApi(post.id, { status: 'hidden' })
    if (editingPostId.value === post.id) {
      cancelEdit()
    }
    await loadData()
  } catch (error) {
    errorMessage.value = error.message
  } finally {
    saving.value = false
  }
}

async function withdrawPost(post) {
  saving.value = true
  errorMessage.value = ''
  try {
    await updatePostApi(post.id, { status: 'draft' })
    await loadData()
  } catch (error) {
    errorMessage.value = error.message
  } finally {
    saving.value = false
  }
}

async function republishPost(post) {
  saving.value = true
  errorMessage.value = ''
  try {
    await updatePostApi(post.id, { status: 'pending' })
    await loadData()
  } catch (error) {
    errorMessage.value = error.message
  } finally {
    saving.value = false
  }
}

function canEdit(post) {
  return editableStatuses.has(post.status)
}

function canDelete(post) {
  return post.status === 'published'
}

function canWithdraw(post) {
  return post.status === 'pending'
}

function canRepublish(post) {
  return post.status === 'draft' || post.status === 'rejected'
}

onMounted(loadData)
</script>

<template>
  <section class="panel">
    <h2>我的帖子</h2>
    <p class="hint">仅展示你本人发布的帖子</p>

    <div class="filter-row">
      <input v-model.trim="filters.keyword" placeholder="按标题搜索" @keyup.enter="loadData" />
      <select v-model="filters.status">
        <option value="">全部状态</option>
        <option value="draft">草稿</option>
        <option value="pending">待审核</option>
        <option value="published">已发布</option>
        <option value="rejected">已驳回</option>
        <option value="hidden">已下架</option>
      </select>
      <button type="button" @click="loadData">查询</button>
    </div>

    <p class="hint">共 {{ total }} 条</p>
    <p v-if="errorMessage" class="error">{{ errorMessage }}</p>

    <table>
      <thead>
        <tr>
          <th>ID</th>
          <th>标题</th>
          <th>板块</th>
          <th>状态</th>
          <th>更新时间</th>
          <th>操作</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="item in myPosts" :key="item.id">
          <td>{{ item.id }}</td>
          <td>{{ item.title }}</td>
          <td>{{ item.boardName }}</td>
          <td>{{ statusText(item.status) }}</td>
          <td>{{ item.updatedAt?.slice(0, 16).replace('T', ' ') }}</td>
          <td>
            <div class="table-actions">
              <button v-if="canEdit(item)" type="button" @click="startEdit(item)">编辑</button>
              <button v-if="canWithdraw(item)" type="button" @click="withdrawPost(item)">撤回</button>
              <button v-if="canRepublish(item)" type="button" @click="republishPost(item)">重新发布</button>
              <button v-if="canDelete(item)" type="button" class="danger" @click="softDeletePost(item)">删除</button>
            </div>
          </td>
        </tr>
        <tr v-if="!myPosts.length">
          <td colspan="6" class="hint">暂无帖子</td>
        </tr>
      </tbody>
    </table>

    <div v-if="editingPostId" class="edit-modal-mask" @click.self="cancelEdit">
      <div class="edit-modal-panel">
        <div class="edit-modal-header">
          <h3>编辑我的帖子 #{{ editingPostId }}</h3>
          <button type="button" class="edit-modal-close" @click="cancelEdit">关闭</button>
        </div>
        <div class="form-grid">
          <label>
            标题
            <input v-model.trim="editForm.title" />
          </label>
          <label>
            摘要
            <input v-model.trim="editForm.summary" />
          </label>
          <label>
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
