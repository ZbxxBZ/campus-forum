import axios from 'axios'

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || '/api'

const http = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000
})

http.interceptors.request.use((config) => {
  const token = localStorage.getItem('campus_forum_token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

http.interceptors.response.use(
  (response) => response,
  (error) => {
    const responseData = error?.response?.data || {}
    const normalizedError = new Error(responseData?.message || '请求失败')
    normalizedError.status = error?.response?.status || 0
    normalizedError.code = responseData?.code
    normalizedError.data = responseData?.data
    return Promise.reject(normalizedError)
  }
)

export default http
