import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    { path: '/', redirect: '/admin/home' },
    {
      path: '/login',
      name: 'login',
      component: () => import('../views/auth/LoginView.vue'),
      meta: { guestOnly: true }
    },
    {
      path: '/register',
      name: 'register',
      component: () => import('../views/auth/RegisterView.vue'),
      meta: { guestOnly: true }
    },
    {
      path: '/admin',
      component: () => import('../components/layout/AdminLayout.vue'),
      meta: { requiresAuth: true },
      children: [
        {
          path: 'home',
          name: 'home',
          component: () => import('../views/admin/HomeView.vue')
        },
        {
          path: 'profile',
          name: 'profile',
          component: () => import('../views/admin/ProfileView.vue')
        },
        {
          path: 'profile/:userId',
          name: 'public-profile',
          component: () => import('../views/admin/PublicProfileView.vue')
        },
        {
          path: 'dashboard',
          name: 'dashboard',
          component: () => import('../views/admin/DashboardView.vue'),
          meta: { permission: 'dashboard:read' }
        },
        {
          path: 'post-detail/:postId',
          name: 'post-detail',
          component: () => import('../views/admin/PostDetailView.vue')
        },
        {
          path: 'users',
          name: 'user-management',
          component: () => import('../views/admin/UserManagementView.vue'),
          meta: { permission: 'user:read' }
        },
        {
          path: 'posts',
          name: 'post-management',
          component: () => import('../views/admin/PostManagementView.vue'),
          meta: { permission: 'post:read', blockedRoles: ['student'] }
        },
        {
          path: 'my-posts',
          name: 'my-posts',
          component: () => import('../views/admin/MyPostView.vue'),
          meta: { permission: 'post:read' }
        },
        {
          path: 'post-create',
          name: 'post-create',
          component: () => import('../views/admin/PostCreateView.vue'),
          meta: { permission: 'post:create' }
        },
        {
          path: 'boards',
          name: 'board-management',
          component: () => import('../views/admin/BoardManagementView.vue'),
          meta: { permission: 'board:read' }
        },
        {
          path: 'reviews',
          name: 'review-management',
          component: () => import('../views/admin/ContentReviewView.vue'),
          meta: { permission: 'review:read' }
        },
        {
          path: 'reviews/:postId',
          name: 'review-detail',
          component: () => import('../views/admin/ReviewDetailView.vue'),
          meta: { permission: 'review:read' }
        },
        {
          path: 'topics',
          name: 'topic-vote',
          component: () => import('../views/admin/TopicVoteView.vue')
        },
        {
          path: 'permissions',
          name: 'permission-management',
          component: () => import('../views/admin/PermissionManagementView.vue'),
          meta: { permission: 'role:read' }
        },
        {
          path: 'audit-logs',
          name: 'audit-logs',
          component: () => import('../views/admin/AuditLogView.vue'),
          meta: { blockedRoles: ['teacher', 'student'] }
        }
      ]
    },
    {
      path: '/403',
      name: 'forbidden',
      component: () => import('../views/admin/ForbiddenView.vue')
    }
  ]
})

router.beforeEach(async (to) => {
  const authStore = useAuthStore()

  if (authStore.token && !authStore.user) {
    try {
      await authStore.fetchProfile()
    } catch {
      authStore.logout()
    }
  }

  if (to.meta.requiresAuth && !authStore.isLoggedIn) {
    return { name: 'login', query: { redirect: to.fullPath } }
  }

  if (to.meta.guestOnly && authStore.isLoggedIn) {
    return { path: authStore.getDefaultRoute() }
  }

  if (to.meta.permission && !authStore.hasPermission(to.meta.permission)) {
    return { path: authStore.getDefaultRoute() }
  }

  if (to.meta.blockedRoles?.includes(authStore.user?.role)) {
    return { path: authStore.getDefaultRoute() }
  }

  return true
})

export default router

