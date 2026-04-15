<script setup>
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '../../stores/auth'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()

const menus = computed(() => {
  const items = [
    { label: '工作台', to: '/admin/home' },
    { label: '个人主页', to: '/admin/profile' }
  ]

  if (authStore.hasPermission('dashboard:read')) {
    items.push({ label: '系统总览', to: '/admin/dashboard' })
  }
  if (authStore.hasPermission('user:read')) {
    items.push({ label: '用户管理', to: '/admin/users' })
  }
  if (authStore.hasPermission('post:read')) {
    if (authStore.user?.role === 'student') {
      items.push({ label: '我的帖子', to: '/admin/my-posts' })
    } else {
      items.push({ label: '帖子管理', to: '/admin/posts' })
    }
  }
  if (authStore.hasPermission('post:create')) {
    items.push({ label: '内容发布', to: '/admin/post-create' })
  }
  if (authStore.hasPermission('board:read')) {
    items.push({ label: '板块配置', to: '/admin/boards' })
  }
  if (authStore.hasPermission('review:read')) {
    items.push({ label: '内容审核', to: '/admin/reviews' })
  }
  if (
    authStore.hasPermission('topic:read') ||
    authStore.hasPermission('topic:create') ||
    authStore.hasPermission('topic:vote')
  ) {
    items.push({ label: '互动交流', to: '/admin/topics' })
  }
  if (authStore.hasPermission('role:read')) {
    items.push({ label: '权限管理', to: '/admin/permissions' })
  }
  if (authStore.user?.role === 'super_admin') {
    items.push({ label: '审核日志', to: '/admin/audit-logs' })
  }

  return items
})

function logout() {
  authStore.logout()
  router.push('/login')
}
</script>

<template>
  <div class="admin-shell">
    <aside class="sidebar">
      <h1>校园论坛管理系统</h1>
      <p class="slogan">高性能 · 安全可控 · 高并发</p>
      <nav>
        <RouterLink
          v-for="item in menus"
          :key="item.to"
          :to="item.to"
          class="menu-link"
          :class="{ active: route.path === item.to }"
        >
          {{ item.label }}
        </RouterLink>
      </nav>
    </aside>

    <section class="content">
      <header class="topbar">
        <div>
          <strong>{{ authStore.user?.displayName || '-' }}</strong>
          <span class="meta">账号：{{ authStore.user?.username || '-' }}</span>
        </div>
        <button class="danger" type="button" @click="logout">退出登录</button>
      </header>

      <main>
        <RouterView />
      </main>
    </section>
  </div>
</template>

