<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { getFollowRelationApi, getUserPublicProfileApi, toggleFollowUserApi } from '../../services/modules/forumApi'
import { useAuthStore } from '../../stores/auth'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const loading = ref(false)
const errorMessage = ref('')
const followLoading = ref(false)
const followed = ref(false)
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
    followerCount: 0,
    followingCount: 0
  }
})

const roleLabel = computed(() => {
  const map = {
    student: '学生',
    teacher: '教师',
    admin: '管理员',
    super_admin: '超级管理员'
  }
  return map[profile.value.user.role] || profile.value.user.role || '-'
})

const isSelfProfile = computed(() => Number(route.params.userId) === Number(authStore.user?.id))

async function loadProfile() {
  loading.value = true
  errorMessage.value = ''
  try {
    const data = await getUserPublicProfileApi(route.params.userId)
    profile.value = {
      user: { ...profile.value.user, ...(data.user || {}) },
      stats: { ...profile.value.stats, ...(data.stats || {}) }
    }
  } catch (error) {
    errorMessage.value = `公开主页加载失败：${error.message}`
  } finally {
    loading.value = false
  }
}

async function loadFollowRelation() {
  if (isSelfProfile.value) return
  try {
    const data = await getFollowRelationApi(route.params.userId)
    followed.value = Boolean(data.followed)
  } catch {
    // ignore follow relation loading error to avoid blocking profile page
  }
}

async function toggleFollow() {
  followLoading.value = true
  errorMessage.value = ''
  try {
    const data = await toggleFollowUserApi(route.params.userId)
    followed.value = Boolean(data.followed)
  } catch (error) {
    errorMessage.value = `关注操作失败：${error.message}`
  } finally {
    followLoading.value = false
  }
}

onMounted(async () => {
  if (isSelfProfile.value) {
    router.replace('/admin/profile')
    return
  }
  await loadProfile()
  await loadFollowRelation()
})
</script>

<template>
  <section class="panel">
    <h2>用户公开主页</h2>
    <p v-if="loading" class="hint">加载中...</p>
    <p v-if="errorMessage" class="error">{{ errorMessage }}</p>

    <div class="profile-grid" v-if="!loading">
      <section class="profile-card">
        <h3>用户信息</h3>
        <div class="profile-avatar">
          <img v-if="profile.user.avatar" :src="profile.user.avatar" alt="avatar" />
          <div v-else class="avatar-placeholder">{{ (profile.user.displayName || 'U').slice(0, 1) }}</div>
        </div>
        <div class="action-row">
          <button
            type="button"
            :class="{ 'action-btn-active': followed }"
            :disabled="followLoading"
            @click="toggleFollow"
          >
            {{ followed ? '已关注' : '关注' }}
          </button>
        </div>
        <p><strong>{{ profile.user.displayName || '-' }}</strong></p>
        <p class="hint">账号：{{ profile.user.username || '-' }}</p>
        <p class="hint">角色：{{ roleLabel }}</p>
        <p class="hint">简介：{{ profile.user.bio || '暂无' }}</p>
        <p class="hint">加入时间：{{ profile.user.joinedAt?.slice(0, 10) || '-' }}</p>
      </section>

      <section class="profile-card">
        <h3>公开数据</h3>
        <div class="kpi-grid">
          <div class="kpi-card">
            <p>已发布帖子</p>
            <strong>{{ profile.stats.postCount || 0 }}</strong>
          </div>
          <div class="kpi-card">
            <p>评论总数</p>
            <strong>{{ profile.stats.commentCount || 0 }}</strong>
          </div>
          <div class="kpi-card">
            <p>粉丝</p>
            <strong>{{ profile.stats.followerCount || 0 }}</strong>
          </div>
          <div class="kpi-card">
            <p>关注</p>
            <strong>{{ profile.stats.followingCount || 0 }}</strong>
          </div>
        </div>
      </section>
    </div>
  </section>
</template>
