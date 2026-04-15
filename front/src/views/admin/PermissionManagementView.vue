<script setup>
import { computed, onMounted, ref } from 'vue'
import { ALL_PERMISSIONS, getPermissionLabel } from '../../constants/permissions'
import { useAuthStore } from '../../stores/auth'
import { useUserStore } from '../../stores/user'

const authStore = useAuthStore()
const userStore = useUserStore()
const selectedRole = ref('teacher')

const allPermissions = ALL_PERMISSIONS
const canUpdateRolePermission = computed(() => authStore.hasPermission('role:update'))

const editablePermissions = computed(() => {
  const role = userStore.roles.find((item) => item.role === selectedRole.value)
  return role ? [...role.permissions] : []
})

const editablePermissionLabels = computed(() =>
  editablePermissions.value.map((permission) => getPermissionLabel(permission))
)

const draftPermissions = ref([])

onMounted(async () => {
  await userStore.fetchRoles()
  const role = userStore.roles.find((item) => item.role === selectedRole.value)
  draftPermissions.value = role ? [...role.permissions] : []
})

async function onRoleChange() {
  const role = userStore.roles.find((item) => item.role === selectedRole.value)
  draftPermissions.value = role ? [...role.permissions] : []
}

function togglePermission(permission) {
  if (!canUpdateRolePermission.value) return

  if (draftPermissions.value.includes(permission)) {
    draftPermissions.value = draftPermissions.value.filter((item) => item !== permission)
  } else {
    draftPermissions.value = [...draftPermissions.value, permission]
  }
}

async function save() {
  if (!canUpdateRolePermission.value) return
  await userStore.saveRolePermissions(selectedRole.value, draftPermissions.value)
  await userStore.fetchRoles()
}
</script>

<template>
  <section class="panel">
    <h2>权限管理</h2>

    <div class="filter-row">
      <select v-model="selectedRole" @change="onRoleChange">
        <option v-for="item in userStore.roles" :key="item.role" :value="item.role">
          {{ item.roleLabel }}
        </option>
      </select>
      <button type="button" :disabled="!canUpdateRolePermission" @click="save">保存权限配置</button>
    </div>

    <p class="hint">当前角色权限：{{ editablePermissionLabels.join('，') || '无' }}</p>
    <p v-if="!canUpdateRolePermission" class="hint">当前账号没有 role:update 权限，仅可查看。</p>

    <div class="permission-grid">
      <label v-for="permission in allPermissions" :key="permission" class="check-item">
        <input
          type="checkbox"
          :disabled="!canUpdateRolePermission"
          :checked="draftPermissions.includes(permission)"
          @change="togglePermission(permission)"
        />
        <span>{{ getPermissionLabel(permission) }}</span>
      </label>
    </div>
  </section>
</template>
