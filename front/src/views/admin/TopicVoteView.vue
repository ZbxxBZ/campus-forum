<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { useAuthStore } from '../../stores/auth'
import { createTopicApi, listTopicsApi, voteTopicApi } from '../../services/modules/forumApi'

const authStore = useAuthStore()
const topics = ref([])
const total = ref(0)
const errorMessage = ref('')
const votedOptionByTopic = reactive({})
const canReadTopic = computed(
  () =>
    authStore.hasPermission('topic:read') ||
    authStore.hasPermission('topic:create') ||
    authStore.hasPermission('topic:vote')
)
const canCreateTopic = computed(() => authStore.hasPermission('topic:create'))
const canVoteTopic = computed(() => authStore.hasPermission('topic:vote'))

const createForm = reactive({
  title: '',
  description: '',
  optionsText: '选项A\n选项B'
})

function normalizeList(data) {
  if (Array.isArray(data?.list)) return data.list
  if (Array.isArray(data)) return data
  return []
}

function isSelected(topicId, optionId) {
  return Number(votedOptionByTopic[topicId]) === Number(optionId)
}

function optionBtnClass(topicId, option) {
  const classes = []
  if (isSelected(topicId, option.id)) classes.push('vote-option-active')
  const text = String(option.text || '')
  if (text.includes('支持')) classes.push('vote-option-support')
  if (text.includes('反对')) classes.push('vote-option-against')
  return classes
}

async function loadTopics() {
  if (!canReadTopic.value) {
    topics.value = []
    total.value = 0
    errorMessage.value = '你没有查看话题权限，请联系管理员分配 topic:read 权限。'
    return
  }

  errorMessage.value = ''
  try {
    const data = await listTopicsApi({ page: 1, pageSize: 50 })
    topics.value = normalizeList(data)
    total.value = data?.total ?? topics.value.length
    for (const topic of topics.value) {
      const votedOptionId = topic?.votedOptionId ?? topic?.myVoteOptionId
      if (votedOptionId) {
        votedOptionByTopic[topic.id] = Number(votedOptionId)
      }
    }
  } catch (error) {
    topics.value = []
    total.value = 0
    errorMessage.value = `话题加载失败：${error.message}`
  }
}

async function createTopic() {
  if (!canCreateTopic.value) {
    errorMessage.value = '你没有发布话题权限，请联系管理员分配 topic:create 权限。'
    return
  }

  const options = createForm.optionsText
    .split(/\r?\n/)
    .map((item) => item.trim())
    .filter(Boolean)

  if (!createForm.title || options.length < 2) {
    errorMessage.value = '请填写话题标题，并至少提供 2 个投票选项。'
    return
  }

  errorMessage.value = ''
  try {
    await createTopicApi({
      title: createForm.title,
      description: createForm.description,
      options,
      createdBy: authStore.user?.username || 'unknown'
    })
    createForm.title = ''
    createForm.description = ''
    createForm.optionsText = '选项A\n选项B'
    await loadTopics()
  } catch (error) {
    errorMessage.value = `话题创建失败：${error.message}`
  }
}

async function vote(topicId, optionId) {
  if (!canVoteTopic.value) {
    errorMessage.value = '你没有投票权限，请联系管理员分配 topic:vote 权限。'
    return
  }

  try {
    await voteTopicApi(topicId, optionId)
    votedOptionByTopic[topicId] = Number(optionId)
    await loadTopics()
  } catch (error) {
    errorMessage.value = `投票失败：${error.message}`
  }
}

onMounted(loadTopics)
</script>

<template>
  <section class="panel">
    <h2>话题与投票</h2>
    <p class="hint">
      权限状态：发布话题（{{ canCreateTopic ? '已开通' : '未开通' }}）/ 投票（{{ canVoteTopic ? '已开通' : '未开通' }})
    </p>

    <div class="form-grid">
      <label>
        话题标题
        <input v-model.trim="createForm.title" placeholder="例如：是否支持周末自习室延长开放？" />
      </label>
      <label>
        话题说明
        <textarea v-model="createForm.description" rows="3" placeholder="可选" />
      </label>
      <label>
        投票选项（每行一个）
        <textarea v-model="createForm.optionsText" rows="4" />
      </label>
    </div>

    <div class="action-row">
      <button class="primary-btn" type="button" :disabled="!canCreateTopic" @click="createTopic">发布话题</button>
      <span class="hint">共 {{ total }} 个话题</span>
    </div>

    <p v-if="errorMessage" class="error">{{ errorMessage }}</p>

    <div class="topic-list">
      <div class="topic-card" v-for="topic in topics" :key="topic.id">
        <h3>{{ topic.title }}</h3>
        <p class="hint" v-if="topic.description">{{ topic.description }}</p>
        <p class="hint">发起人：{{ topic.createdBy }} · {{ topic.createdAt?.slice(0, 16).replace('T', ' ') }}</p>

        <div class="topic-options">
          <button
            type="button"
            v-for="option in topic.options"
            :key="option.id"
            :disabled="!canVoteTopic"
            :class="optionBtnClass(topic.id, option)"
            @click="vote(topic.id, option.id)"
          >
            {{ option.text }}（{{ option.voteCount }}票）
          </button>
        </div>
      </div>
      <p class="hint" v-if="!topics.length">暂无话题，欢迎创建第一个投票。</p>
    </div>
  </section>
</template>
