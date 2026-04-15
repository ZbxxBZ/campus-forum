import http from '../http'
import { mockListUsers, mockUpdateUserRole, mockUpdateUserStatus } from '../mockServer'

const useMock = import.meta.env.VITE_USE_MOCK !== 'false'

export async function listUsersApi(params) {
  if (useMock) return mockListUsers(params)
  const { data } = await http.get('/v1/users', { params })
  return data.data
}

export async function updateUserRoleApi(userId, role) {
  if (useMock) return mockUpdateUserRole(userId, role)
  const { data } = await http.patch(`/v1/users/${userId}/role`, { role })
  return data.data
}

export async function updateUserStatusApi(userId, status) {
  if (useMock) return mockUpdateUserStatus(userId, status)
  const { data } = await http.patch(`/v1/users/${userId}/status`, { status })
  return data.data
}
