<script setup>
import { reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../../stores/auth'

const router = useRouter()
const authStore = useAuthStore()

const submitting = ref(false)
const errorMessage = ref('')
const successMessage = ref('')

const form = reactive({
  username: '',
  displayName: '',
  email: '',
  password: '',
  confirmPassword: ''
})

function validateEmail(email) {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  return emailRegex.test(email)
}

function validateUsername(username) {
  // 用户名只能包含字母、数字、下划线，长度3-20位
  const usernameRegex = /^[a-zA-Z0-9_]{3,20}$/
  return usernameRegex.test(username)
}

async function onSubmit() {
  // 判空验证
  if (!form.username) {
    errorMessage.value = '请输入用户名。'
    return
  }
  if (!form.displayName) {
    errorMessage.value = '请输入姓名。'
    return
  }
  if (!form.email) {
    errorMessage.value = '请输入邮箱。'
    return
  }
  if (!form.password) {
    errorMessage.value = '请输入密码。'
    return
  }
  if (!form.confirmPassword) {
    errorMessage.value = '请确认密码。'
    return
  }

  // 格式验证
  if (!validateUsername(form.username)) {
    errorMessage.value = '用户名只能包含字母、数字、下划线，长度3-20位。'
    return
  }
  if (!validateEmail(form.email)) {
    errorMessage.value = '请输入有效的邮箱地址。'
    return
  }
  if (form.password.length < 8) {
    errorMessage.value = '密码至少需要8位。'
    return
  }
  if (form.password !== form.confirmPassword) {
    errorMessage.value = '两次输入的密码不一致。'
    return
  }

  submitting.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    await authStore.register(form)
    successMessage.value = '注册成功，正在跳转登录页。'
    setTimeout(() => router.push('/login'), 1000)
  } catch (error) {
    errorMessage.value = error.message
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <div class="auth-page">
    <div class="bubble-container">
      <div class="bubble bubble-1"></div>
      <div class="bubble bubble-2"></div>
      <div class="bubble bubble-3"></div>
      <div class="bubble bubble-4"></div>
      <div class="bubble bubble-5"></div>
      <div class="bubble bubble-6"></div>
      <div class="bubble bubble-7"></div>
      <div class="bubble bubble-8"></div>
    </div>
    <div class="wave-container">
      <svg class="wave" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1440 320">
        <path fill="rgba(255, 255, 255, 0.1)" d="M0,96L48,112C96,128,192,160,288,160C384,160,480,128,576,122.7C672,117,768,139,864,154.7C960,171,1056,181,1152,165.3C1248,149,1344,107,1392,85.3L1440,64L1440,320L1392,320C1344,320,1248,320,1152,320C1056,320,960,320,864,320C768,320,672,320,576,320C480,320,384,320,288,320C192,320,96,320,48,320L0,320Z"></path>
      </svg>
      <svg class="wave wave-2" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1440 320">
        <path fill="rgba(255, 255, 255, 0.05)" d="M0,224L48,213.3C96,203,192,181,288,181.3C384,181,480,203,576,213.3C672,224,768,224,864,208C960,192,1056,160,1152,154.7C1248,149,1344,171,1392,181.3L1440,192L1440,320L1392,320C1344,320,1248,320,1152,320C1056,320,960,320,864,320C768,320,672,320,576,320C480,320,384,320,288,320C192,320,96,320,48,320L0,320Z"></path>
      </svg>
    </div>
    <div class="auth-container">
      <form class="auth-card" @submit.prevent="onSubmit">
        <div class="auth-header">
          <div class="auth-icon">
            <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
              <circle cx="8.5" cy="7" r="4"></circle>
              <line x1="20" y1="8" x2="20" y2="14"></line>
              <line x1="23" y1="11" x2="17" y2="11"></line>
            </svg>
          </div>
          <h1>校园论坛管理系统</h1>
          <p class="auth-subtitle">创建您的账号，加入我们的社区</p>
        </div>

        <div class="form-group">
          <label>
            <span class="label-text">用户名</span>
            <div class="input-wrapper">
              <input v-model.trim="form.username" type="text" placeholder="3-20位字母、数字或下划线" />
            </div>
          </label>
        </div>

        <div class="form-group">
          <label>
            <span class="label-text">姓名</span>
            <div class="input-wrapper">
              <input v-model.trim="form.displayName" type="text" placeholder="请输入您的真实姓名" />
            </div>
          </label>
        </div>

        <div class="form-group">
          <label>
            <span class="label-text">邮箱</span>
            <div class="input-wrapper">
              <input v-model.trim="form.email" type="email" placeholder="例如：zhangsan@campus.edu" />
            </div>
          </label>
        </div>

        <div class="form-group">
          <label>
            <span class="label-text">密码</span>
            <div class="input-wrapper">
              <input v-model="form.password" type="password" placeholder="至少8位字符" />
            </div>
          </label>
        </div>

        <div class="form-group">
          <label>
            <span class="label-text">确认密码</span>
            <div class="input-wrapper">
              <input v-model="form.confirmPassword" type="password" placeholder="请再次输入密码" />
            </div>
          </label>
        </div>

        <p v-if="errorMessage" class="error">{{ errorMessage }}</p>
        <p v-if="successMessage" class="success">{{ successMessage }}</p>

        <button class="primary-btn" type="submit" :disabled="submitting">
          <span v-if="!submitting">注册账号</span>
          <span v-else class="loading-text">
            <svg class="spinner" xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <line x1="12" y1="2" x2="12" y2="6"></line>
              <line x1="12" y1="18" x2="12" y2="22"></line>
              <line x1="4.93" y1="4.93" x2="7.76" y2="7.76"></line>
              <line x1="16.24" y1="16.24" x2="19.07" y2="19.07"></line>
              <line x1="2" y1="12" x2="6" y2="12"></line>
              <line x1="18" y1="12" x2="22" y2="12"></line>
              <line x1="4.93" y1="19.07" x2="7.76" y2="16.24"></line>
              <line x1="16.24" y1="7.76" x2="19.07" y2="4.93"></line>
            </svg>
            提交中...
          </span>
        </button>

        <p class="hint auth-footnote">
          已有账号？
          <RouterLink to="/login">返回登录</RouterLink>
        </p>
      </form>
    </div>
  </div>
</template>

<style scoped>
.bubble-container {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  overflow: hidden;
  z-index: 0;
}

.bubble {
  position: absolute;
  border-radius: 50%;
  background: radial-gradient(circle at 30% 30%, rgba(255, 255, 255, 0.8), rgba(255, 255, 255, 0.2));
  box-shadow: inset 0 0 20px rgba(255, 255, 255, 0.5),
              0 0 30px rgba(255, 255, 255, 0.3);
  animation: float-up 15s ease-in-out infinite;
}

.bubble-1 {
  width: 80px;
  height: 80px;
  left: 10%;
  bottom: -100px;
  animation-delay: 0s;
  animation-duration: 12s;
}

.bubble-2 {
  width: 60px;
  height: 60px;
  left: 25%;
  bottom: -100px;
  animation-delay: 2s;
  animation-duration: 14s;
}

.bubble-3 {
  width: 100px;
  height: 100px;
  left: 40%;
  bottom: -100px;
  animation-delay: 4s;
  animation-duration: 16s;
}

.bubble-4 {
  width: 70px;
  height: 70px;
  left: 55%;
  bottom: -100px;
  animation-delay: 1s;
  animation-duration: 13s;
}

.bubble-5 {
  width: 90px;
  height: 90px;
  left: 70%;
  bottom: -100px;
  animation-delay: 3s;
  animation-duration: 15s;
}

.bubble-6 {
  width: 50px;
  height: 50px;
  left: 85%;
  bottom: -100px;
  animation-delay: 5s;
  animation-duration: 11s;
}

.bubble-7 {
  width: 65px;
  height: 65px;
  left: 15%;
  bottom: -100px;
  animation-delay: 6s;
  animation-duration: 17s;
}

.bubble-8 {
  width: 75px;
  height: 75px;
  left: 60%;
  bottom: -100px;
  animation-delay: 7s;
  animation-duration: 14s;
}

@keyframes float-up {
  0% {
    transform: translateY(0) translateX(0) scale(1);
    opacity: 0;
  }
  10% {
    opacity: 0.6;
  }
  50% {
    transform: translateY(-50vh) translateX(20px) scale(1.1);
    opacity: 0.4;
  }
  100% {
    transform: translateY(-100vh) translateX(-20px) scale(0.8);
    opacity: 0;
  }
}

.wave-container {
  position: absolute;
  bottom: 0;
  left: 0;
  width: 100%;
  z-index: 0;
}

.wave {
  position: absolute;
  bottom: 0;
  left: 0;
  width: 100%;
  height: auto;
  animation: wave-move 10s ease-in-out infinite;
}

.wave-2 {
  animation: wave-move 15s ease-in-out infinite reverse;
}

@keyframes wave-move {
  0%, 100% {
    transform: translateX(0);
  }
  50% {
    transform: translateX(-50px);
  }
}

.auth-icon {
  width: 80px;
  height: 80px;
  margin: 0 auto 20px;
  background: linear-gradient(135deg, #38bdf8 0%, #0ea5e9 100%);
  border-radius: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  box-shadow: 0 10px 30px rgba(56, 189, 248, 0.4);
}

.auth-header h1 {
  margin-bottom: 8px;
  text-align: center;
}

.auth-subtitle {
  color: #64748b;
  font-size: 14px;
  text-align: center;
}

.form-group {
  margin-bottom: 6px;
}

.form-group label {
  display: flex;
  align-items: center;
  gap: 16px;
}

.label-text {
  min-width: 80px;
  font-weight: 500;
  color: #334155;
  text-align: right;
}

.input-wrapper {
  position: relative;
  display: flex;
  align-items: center;
  flex: 1;
}

.input-wrapper input {
  width: 100%;
  padding: 12px 14px;
  border: 2px solid #e2e8f0;
  border-radius: 12px;
  font-size: 15px;
  transition: all 0.3s ease;
  background: white;
}

.input-wrapper input:focus {
  outline: none;
  border-color: #38bdf8;
  box-shadow: 0 0 0 3px rgba(56, 189, 248, 0.1);
}

.input-wrapper input::placeholder {
  color: #cbd5e1;
}

.primary-btn {
  width: 100%;
  padding: 14px;
  background: linear-gradient(135deg, #38bdf8 0%, #0ea5e9 100%);
  color: white;
  border: none;
  border-radius: 12px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  margin-top: 8px;
}

.primary-btn:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 10px 25px rgba(56, 189, 248, 0.4);
}

.primary-btn:active:not(:disabled) {
  transform: translateY(0);
}

.primary-btn:disabled {
  opacity: 0.7;
  cursor: not-allowed;
}

.loading-text {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

.spinner {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}

.error {
  color: #ef4444;
  font-size: 14px;
  margin: 12px 0;
  padding: 10px;
  background: #fee2e2;
  border-radius: 8px;
  border-left: 3px solid #ef4444;
}

.success {
  color: #10b981;
  font-size: 14px;
  margin: 12px 0;
  padding: 10px;
  background: #d1fae5;
  border-radius: 8px;
  border-left: 3px solid #10b981;
}

.auth-footnote {
  text-align: center;
  margin-top: 24px;
  color: #64748b;
  font-size: 14px;
}

.auth-footnote a {
  color: #0ea5e9;
  font-weight: 600;
  transition: color 0.2s ease;
}

.auth-footnote a:hover {
  color: #0284c7;
}
</style>
