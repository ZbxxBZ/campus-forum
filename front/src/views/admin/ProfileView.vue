<script setup>
import { computed, onBeforeUnmount, onMounted, reactive, ref, watch } from 'vue'
import {
  getMyProfileApi,
  listMyProfileCommentsApi,
  listMyProfileFavoritesApi,
  listMyFollowingApi,
  listMyProfileLikesApi,
  listMyProfilePostsApi,
  uploadImagesApi,
  updateMyProfileApi
} from '../../services/modules/forumApi'

const activeTab = ref('posts')
const loading = ref(false)
const tabLoading = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
const isEditingProfile = ref(false)

const profile = ref({
  user: {
    id: null,
    username: '',
    displayName: '',
    avatar: '',
    role: '',
    bio: '',
    joinedAt: ''
  },
  stats: {
    postCount: 0,
    commentCount: 0,
    likeCount: 0,
    favoriteCount: 0,
    followerCount: 0,
    followingCount: 0
  }
})

const editForm = reactive({
  displayName: '',
  avatar: '',
  bio: ''
})
const avatarFile = ref(null)
const avatarPreviewUrl = ref('')

const postList = ref([])
const commentList = ref([])
const likeList = ref([])
const favoriteList = ref([])
const followingList = ref([])

const tabs = [
  { key: 'posts', label: '我的帖子' },
  { key: 'comments', label: '我的评论' },
  { key: 'likes', label: '我的点赞' },
  { key: 'favorites', label: '我的收藏' },
  { key: 'following', label: '我的关注' }
]

const roleLabel = computed(() => {
  const map = {
    student: '学生',
    teacher: '教师',
    admin: '管理员',
    super_admin: '超级管理员'
  }
  return map[profile.value.user.role] || profile.value.user.role || '-'
})

function normalizeList(data) {
  if (Array.isArray(data?.list)) return data.list
  if (Array.isArray(data)) return data
  return []
}

function clearAvatarSelection() {
  avatarFile.value = null
  if (avatarPreviewUrl.value) {
    URL.revokeObjectURL(avatarPreviewUrl.value)
    avatarPreviewUrl.value = ''
  }
}

function onAvatarFileChange(event) {
  const file = event.target.files?.[0]
  if (!file) return
  if (!file.type.startsWith('image/')) {
    errorMessage.value = '请选择图片文件作为头像。'
    event.target.value = ''
    return
  }

  if (avatarPreviewUrl.value) {
    URL.revokeObjectURL(avatarPreviewUrl.value)
  }
  avatarFile.value = file
  avatarPreviewUrl.value = URL.createObjectURL(file)
}

async function loadProfile() {
  loading.value = true
  errorMessage.value = ''
  try {
    const data = await getMyProfileApi()
    profile.value = {
      user: { ...profile.value.user, ...(data.user || {}) },
      stats: { ...profile.value.stats, ...(data.stats || {}) }
    }
    editForm.displayName = profile.value.user.displayName || ''
    editForm.avatar = profile.value.user.avatar || ''
    editForm.bio = profile.value.user.bio || ''
  } catch (error) {
    errorMessage.value = `个人主页加载失败：${error.message}`
  } finally {
    loading.value = false
  }
}

async function loadTabData() {
  tabLoading.value = true
  errorMessage.value = ''
  try {
    if (activeTab.value === 'posts') {
      const data = await listMyProfilePostsApi({ page: 1, pageSize: 20 })
      postList.value = normalizeList(data)
    }

    if (activeTab.value === 'comments') {
      const data = await listMyProfileCommentsApi({ page: 1, pageSize: 20 })
      commentList.value = normalizeList(data)
    }

    if (activeTab.value === 'likes') {
      const data = await listMyProfileLikesApi({ page: 1, pageSize: 20 })
      likeList.value = normalizeList(data)
    }

    if (activeTab.value === 'favorites') {
      const data = await listMyProfileFavoritesApi({ page: 1, pageSize: 20 })
      favoriteList.value = normalizeList(data)
    }

    if (activeTab.value === 'following') {
      const data = await listMyFollowingApi({ page: 1, pageSize: 20 })
      followingList.value = normalizeList(data)
    }
  } catch (error) {
    errorMessage.value = `数据加载失败：${error.message}`
  } finally {
    tabLoading.value = false
  }
}

async function saveProfile() {
  successMessage.value = ''
  errorMessage.value = ''
  try {
    let avatarValue = editForm.avatar
    if (avatarFile.value) {
      const uploadResult = await uploadImagesApi([avatarFile.value])
      const uploadedUrl = uploadResult?.files?.[0]?.url
      if (!uploadedUrl) {
        throw new Error('头像上传失败，请检查上传接口返回。')
      }
      avatarValue = uploadedUrl
      editForm.avatar = uploadedUrl
      clearAvatarSelection()
    }

    await updateMyProfileApi({
      displayName: editForm.displayName,
      avatar: avatarValue,
      bio: editForm.bio
    })
    successMessage.value = '个人资料已更新。'
    await loadProfile()
    isEditingProfile.value = false
  } catch (error) {
    errorMessage.value = `保存失败：${error.message}`
  }
}

function openProfileEditor() {
  successMessage.value = ''
  errorMessage.value = ''
  editForm.displayName = profile.value.user.displayName || ''
  editForm.avatar = profile.value.user.avatar || ''
  editForm.bio = profile.value.user.bio || ''
  clearAvatarSelection()
  isEditingProfile.value = true
}

function cancelProfileEditor() {
  clearAvatarSelection()
  isEditingProfile.value = false
}

watch(activeTab, loadTabData)

onMounted(async () => {
  await loadProfile()
  await loadTabData()
})

onBeforeUnmount(() => {
  clearAvatarSelection()
})
</script>

<template>
  <section class="panel">
    <h2>个人主页</h2>
    <p class="hint">按角色展示内容资产与互动沉淀（帖子/评论/点赞/收藏）。</p>
    <p v-if="loading" class="hint">资料加载中...</p>
    <p v-if="errorMessage" class="error">{{ errorMessage }}</p>
    <p v-if="successMessage" class="success">{{ successMessage }}</p>

    <div class="profile-grid profile-overview-grid" v-if="!loading">
      <section class="profile-card profile-info-card">
        <h3>基础信息</h3>
        <div class="profile-avatar">
          <img v-if="profile.user.avatar" :src="profile.user.avatar" alt="avatar" />
          <div v-else class="avatar-placeholder">{{ (profile.user.displayName || 'U').slice(0, 1) }}</div>
        </div>
        <p><strong>{{ profile.user.displayName || '-' }}</strong></p>
        <div class="profile-basic-lines">
          <p class="hint"><span>账号</span>{{ profile.user.username || '-' }}</p>
          <p class="hint"><span>角色</span>{{ roleLabel }}</p>
          <p class="hint"><span>加入时间</span>{{ profile.user.joinedAt?.slice(0, 10) || '-' }}</p>
          <p class="hint"><span>简介</span>{{ profile.user.bio || '暂无' }}</p>
        </div>
      </section>

      <section class="profile-card profile-edit-card">
        <h3>资料编辑</h3>
        <template v-if="!isEditingProfile">
          <p class="hint">头像、昵称、简介可按需修改，修改后立即生效。</p>
          <div class="action-row">
            <button class="primary-btn" type="button" @click="openProfileEditor">编辑资料</button>
          </div>
        </template>
        <template v-else>
          <div class="form-grid">
            <label>
              昵称
              <input v-model.trim="editForm.displayName" placeholder="请输入昵称" />
            </label>
            <label>
              本地上传头像
              <input type="file" accept="image/*" @change="onAvatarFileChange" />
            </label>
            <p class="hint" v-if="avatarFile">已选择：{{ avatarFile.name }}</p>
            <div class="profile-avatar" v-if="avatarPreviewUrl">
              <img :src="avatarPreviewUrl" alt="avatar preview" />
            </div>
            <label>
              个人简介
              <textarea v-model="editForm.bio" rows="4" placeholder="介绍一下你自己" />
            </label>
          </div>
          <div class="action-row">
            <button class="primary-btn" type="button" @click="saveProfile">保存资料</button>
            <button type="button" @click="cancelProfileEditor">取消</button>
          </div>
        </template>
      </section>

      <section class="profile-card profile-assets-card">
        <h3>内容资产</h3>
        <div class="kpi-grid">
          <div class="kpi-card">
            <p>粉丝</p>
            <strong>{{ profile.stats.followerCount || 0 }}</strong>
          </div>
          <div class="kpi-card">
            <p>关注</p>
            <strong>{{ profile.stats.followingCount || 0 }}</strong>
          </div>
          <div class="kpi-card">
            <p>帖子</p>
            <strong>{{ profile.stats.postCount || 0 }}</strong>
          </div>
          <div class="kpi-card">
            <p>评论</p>
            <strong>{{ profile.stats.commentCount || 0 }}</strong>
          </div>
          <div class="kpi-card">
            <p>点赞</p>
            <strong>{{ profile.stats.likeCount || 0 }}</strong>
          </div>
          <div class="kpi-card">
            <p>收藏</p>
            <strong>{{ profile.stats.favoriteCount || 0 }}</strong>
          </div>
        </div>
      </section>
    </div>

    <section class="panel sub-panel">
      <div class="profile-tabs">
        <button
          v-for="tab in tabs"
          :key="tab.key"
          type="button"
          class="tab-btn"
          :class="{ active: activeTab === tab.key }"
          @click="activeTab = tab.key"
        >
          {{ tab.label }}
        </button>
      </div>

      <p class="hint" v-if="tabLoading">列表加载中...</p>

      <table v-if="activeTab === 'posts'">
        <thead>
          <tr><th>ID</th><th>标题</th><th>点赞</th><th>收藏</th><th>评论</th><th>更新时间</th></tr>
        </thead>
        <tbody>
          <tr v-for="item in postList" :key="item.id">
            <td>{{ item.id }}</td>
            <td><RouterLink :to="`/admin/post-detail/${item.id}`">{{ item.title }}</RouterLink></td>
            <td>{{ item.likeCount ?? 0 }}</td>
            <td>{{ item.favoriteCount ?? 0 }}</td>
            <td>{{ item.commentCount ?? 0 }}</td>
            <td>{{ item.updatedAt?.slice(0, 16).replace('T', ' ') }}</td>
          </tr>
          <tr v-if="!postList.length && !tabLoading"><td colspan="6" class="hint">暂无帖子</td></tr>
        </tbody>
      </table>

      <table v-if="activeTab === 'comments'">
        <thead>
          <tr><th>ID</th><th>所属帖子</th><th>评论内容</th><th>时间</th></tr>
        </thead>
        <tbody>
          <tr v-for="item in commentList" :key="item.id">
            <td>{{ item.id }}</td>
            <td>
              <RouterLink v-if="item.postId" :to="`/admin/post-detail/${item.postId}`">
                {{ item.postTitle || `帖子 #${item.postId}` }}
              </RouterLink>
              <template v-else>{{ item.postTitle || '-' }}</template>
            </td>
            <td>{{ item.content }}</td>
            <td>{{ item.createdAt?.slice(0, 16).replace('T', ' ') }}</td>
          </tr>
          <tr v-if="!commentList.length && !tabLoading"><td colspan="4" class="hint">暂无评论</td></tr>
        </tbody>
      </table>

      <table v-if="activeTab === 'likes'">
        <thead>
          <tr><th>ID</th><th>帖子标题</th><th>作者</th></tr>
        </thead>
        <tbody>
          <tr v-for="item in likeList" :key="item.id">
            <td>{{ item.id }}</td>
            <td><RouterLink :to="`/admin/post-detail/${item.id}`">{{ item.title }}</RouterLink></td>
            <td>
              <RouterLink v-if="item.authorId" :to="`/admin/profile/${item.authorId}`">{{ item.author }}</RouterLink>
              <template v-else>{{ item.author || '-' }}</template>
            </td>
          </tr>
          <tr v-if="!likeList.length && !tabLoading"><td colspan="3" class="hint">暂无点赞记录</td></tr>
        </tbody>
      </table>

      <table v-if="activeTab === 'favorites'">
        <thead>
          <tr><th>ID</th><th>帖子标题</th><th>作者</th></tr>
        </thead>
        <tbody>
          <tr v-for="item in favoriteList" :key="item.id">
            <td>{{ item.id }}</td>
            <td><RouterLink :to="`/admin/post-detail/${item.id}`">{{ item.title }}</RouterLink></td>
            <td>
              <RouterLink v-if="item.authorId" :to="`/admin/profile/${item.authorId}`">{{ item.author }}</RouterLink>
              <template v-else>{{ item.author || '-' }}</template>
            </td>
          </tr>
          <tr v-if="!favoriteList.length && !tabLoading"><td colspan="3" class="hint">暂无收藏记录</td></tr>
        </tbody>
      </table>

      <table v-if="activeTab === 'following'">
        <thead>
          <tr><th>ID</th><th>头像</th><th>昵称</th><th>账号</th><th>角色</th></tr>
        </thead>
        <tbody>
          <tr v-for="item in followingList" :key="item.id">
            <td>{{ item.id }}</td>
            <td>
              <RouterLink :to="`/admin/profile/${item.id}`" class="mini-avatar-link">
                <img v-if="item.avatar" :src="item.avatar" alt="avatar" class="mini-avatar" />
                <div v-else class="avatar-placeholder mini-avatar">{{ (item.displayName || 'U').slice(0, 1) }}</div>
              </RouterLink>
            </td>
            <td><RouterLink :to="`/admin/profile/${item.id}`">{{ item.displayName || '-' }}</RouterLink></td>
            <td>{{ item.username || '-' }}</td>
            <td>{{ item.role || '-' }}</td>
          </tr>
          <tr v-if="!followingList.length && !tabLoading"><td colspan="5" class="hint">暂无关注账号</td></tr>
        </tbody>
      </table>
    </section>
  </section>
</template>
