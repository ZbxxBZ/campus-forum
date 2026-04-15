import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import { getProfileApi, loginApi, registerApi } from '../services/modules/authApi'

const TOKEN_KEY = 'campus_forum_token'

export const useAuthStore = defineStore('auth', () => {
  const token = ref(localStorage.getItem(TOKEN_KEY) || '')
  const user = ref(null)
  const permissions = ref([])

  const isLoggedIn = computed(() => Boolean(token.value))

  function hasPermission(permission) {
    return permissions.value.includes(permission)
  }

  function getDefaultRoute() {
    if (user.value?.role === 'student' && hasPermission('post:read')) return '/admin/my-posts'
    if (hasPermission('dashboard:read')) return '/admin/dashboard'
    if (hasPermission('post:create')) return '/admin/post-create'
    if (hasPermission('post:read')) return '/admin/posts'
    if (hasPermission('board:read')) return '/admin/boards'
    if (hasPermission('review:read')) return '/admin/reviews'
    if (hasPermission('user:read')) return '/admin/users'
    if (hasPermission('topic:read')) return '/admin/topics'
    if (hasPermission('role:read')) return '/admin/permissions'
    return '/admin/home'
  }

  async function login(payload) {
    const result = await loginApi(payload)
    token.value = result.token
    user.value = result.user
    permissions.value = result.permissions
    localStorage.setItem(TOKEN_KEY, result.token)
  }

  async function register(payload) {
    await registerApi(payload)
  }

  async function fetchProfile() {
    if (!token.value) return
    const result = await getProfileApi(token.value)
    user.value = result.user
    permissions.value = result.permissions
  }

  function logout() {
    token.value = ''
    user.value = null
    permissions.value = []
    localStorage.removeItem(TOKEN_KEY)
  }

  return {
    token,
    user,
    permissions,
    isLoggedIn,
    hasPermission,
    getDefaultRoute,
    login,
    register,
    fetchProfile,
    logout
  }
})
