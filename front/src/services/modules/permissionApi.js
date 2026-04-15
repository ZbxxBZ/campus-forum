import http from '../http'
import { mockListRoles, mockUpdateRolePermissions } from '../mockServer'

const useMock = import.meta.env.VITE_USE_MOCK !== 'false'

export async function listRolesApi() {
  if (useMock) return mockListRoles()
  const { data } = await http.get('/v1/roles')
  return data.data
}

export async function updateRolePermissionsApi(role, permissions) {
  if (useMock) return mockUpdateRolePermissions(role, permissions)
  const { data } = await http.put(`/v1/roles/${role}/permissions`, { permissions })
  return data.data
}
