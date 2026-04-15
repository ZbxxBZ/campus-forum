import { defineStore } from 'pinia'
import { ref } from 'vue'
import { listRolesApi, updateRolePermissionsApi } from '../services/modules/permissionApi'
import { listUsersApi, updateUserRoleApi, updateUserStatusApi } from '../services/modules/userApi'

export const useUserStore = defineStore('user', () => {
  const users = ref([])
  const total = ref(0)
  const roles = ref([])
  const loading = ref(false)

  async function fetchUsers(filters = {}) {
    loading.value = true
    try {
      const result = await listUsersApi(filters)
      users.value = result.list
      total.value = result.total
    } finally {
      loading.value = false
    }
  }

  async function changeUserRole(userId, role) {
    await updateUserRoleApi(userId, role)
  }

  async function changeUserStatus(userId, status) {
    await updateUserStatusApi(userId, status)
  }

  async function fetchRoles() {
    const result = await listRolesApi()
    roles.value = result.list
  }

  async function saveRolePermissions(role, permissions) {
    await updateRolePermissionsApi(role, permissions)
  }

  return {
    users,
    total,
    roles,
    loading,
    fetchUsers,
    changeUserRole,
    changeUserStatus,
    fetchRoles,
    saveRolePermissions
  }
})
