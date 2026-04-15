<script setup>
import { onMounted, reactive } from 'vue'
import { ROLE_LABELS } from '../../constants/permissions'
import { useUserStore } from '../../stores/user'

const userStore = useUserStore()

const filters = reactive({
  keyword: '',
  role: '',
  status: ''
})

async function loadUsers() {
  await userStore.fetchUsers(filters)
}

async function updateRole(userId, role) {
  await userStore.changeUserRole(userId, role)
  await loadUsers()
}

async function updateStatus(userId, status) {
  await userStore.changeUserStatus(userId, status)
  await loadUsers()
}

onMounted(loadUsers)
</script>

<template>
  <section class="panel">
    <h2>用户管理</h2>

    <div class="filter-row">
      <input v-model.trim="filters.keyword" placeholder="搜索用户名/姓名/邮箱" @keyup.enter="loadUsers" />
      <select v-model="filters.role">
        <option value="">全部角色</option>
        <option v-for="(label, role) in ROLE_LABELS" :key="role" :value="role">{{ label }}</option>
      </select>
      <select v-model="filters.status">
        <option value="">全部状态</option>
        <option value="active">启用</option>
        <option value="disabled">禁用</option>
      </select>
      <button type="button" @click="loadUsers">查询</button>
    </div>

    <p class="hint">共 {{ userStore.total }} 个用户</p>

    <table>
      <thead>
        <tr>
          <th>ID</th>
          <th>用户名</th>
          <th>姓名</th>
          <th>邮箱</th>
          <th>角色</th>
          <th>状态</th>
          <th>操作</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="user in userStore.users" :key="user.id">
          <td>{{ user.id }}</td>
          <td>{{ user.username }}</td>
          <td>{{ user.displayName }}</td>
          <td>{{ user.email }}</td>
          <td>
            <select :value="user.role" @change="updateRole(user.id, $event.target.value)">
              <option v-for="(label, role) in ROLE_LABELS" :key="role" :value="role">{{ label }}</option>
            </select>
          </td>
          <td>
            <span :class="['badge', user.status === 'active' ? 'ok' : 'off']">
              {{ user.status === 'active' ? '启用' : '禁用' }}
            </span>
          </td>
          <td>
            <button
              type="button"
              :class="user.status === 'active' ? 'danger' : ''"
              @click="updateStatus(user.id, user.status === 'active' ? 'disabled' : 'active')"
            >
              {{ user.status === 'active' ? '禁用' : '启用' }}
            </button>
          </td>
        </tr>
      </tbody>
    </table>
  </section>
</template>
