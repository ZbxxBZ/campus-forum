import http from '../http'
import { mockGetProfile, mockLogin, mockRegister } from '../mockServer'

const useMock = import.meta.env.VITE_USE_MOCK !== 'false'

export async function registerApi(payload) {
  if (useMock) return mockRegister(payload)
  const { data } = await http.post('/v1/auth/register', payload)
  return data.data
}

export async function loginApi(payload) {
  if (useMock) return mockLogin(payload)
  const { data } = await http.post('/v1/auth/login', payload)
  return data.data
}

export async function getProfileApi(token) {
  if (useMock) return mockGetProfile(token)
  const { data } = await http.get('/v1/auth/profile')
  return data.data
}
