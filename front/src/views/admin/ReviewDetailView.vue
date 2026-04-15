<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { getPostDetailApi, reviewPostApi } from '../../services/modules/forumApi'
import { normalizeExternalLink, renderMarkdownToHtml } from '../../utils/contentFormat'

const route = useRoute()
const router = useRouter()

const loading = ref(false)
const submitting = ref(false)
const errorMessage = ref('')
const post = ref(null)

const formatLabel = computed(() => {
  const map = {
    rich_text: '富文本',
    markdown: 'Markdown',
    image_gallery: '图文相册',
    external_link: '外链分享'
  }
  return map[post.value?.format] || post.value?.format || '-'
})

const statusLabel = computed(() => {
  const map = {
    draft: '草稿',
    pending: '待审核',
    pending_review: '待审核',
    to_review: '待审核',
    published: '已发布',
    rejected: '已驳回',
    hidden: '已下架'
  }
  return map[post.value?.status] || post.value?.status || '-'
})

const canReview = computed(() => ['pending', 'pending_review', 'to_review'].includes(String(post.value?.status || '')))
const normalizedLink = computed(() => normalizeExternalLink(post.value?.linkUrl || post.value?.content || ''))
const markdownHtml = computed(() => renderMarkdownToHtml(post.value?.content || ''))

function normalizePost(data) {
  if (data?.post) return data.post
  return data
}

async function loadDetail() {
  loading.value = true
  errorMessage.value = ''
  try {
    const data = await getPostDetailApi(route.params.postId)
    post.value = normalizePost(data)
  } catch (error) {
    errorMessage.value = `审核详情加载失败：${error.message}`
  } finally {
    loading.value = false
  }
}

async function review(action) {
  if (!post.value?.id) return
  submitting.value = true
  errorMessage.value = ''
  try {
    await reviewPostApi(post.value.id, action)
    await router.push('/admin/reviews')
  } catch (error) {
    errorMessage.value = `审核操作失败：${error.message}`
  } finally {
    submitting.value = false
  }
}

onMounted(loadDetail)
</script>

<template>
  <section class="panel">
    <div class="action-row">
      <button type="button" @click="router.push('/admin/reviews')">返回待审核列表</button>
    </div>

    <h2>审核详情</h2>
    <p v-if="loading" class="hint">加载中...</p>
    <p v-if="errorMessage" class="error">{{ errorMessage }}</p>

    <template v-if="post && !loading">
      <h3>{{ post.title }}</h3>
      <p class="hint" v-if="post.summary">摘要：{{ post.summary }}</p>

      <div class="meta-grid">
        <span>作者：{{ post.author || '-' }}</span>
        <span>板块：{{ post.boardName || '-' }}</span>
        <span>格式：{{ formatLabel }}</span>
        <span>状态：{{ statusLabel }}</span>
        <span>风险等级：{{ post.riskLevel || '-' }}</span>
      </div>

      <div class="tag-row" v-if="post.tags?.length">
        <span class="chip chip-on" v-for="tag in post.tags" :key="tag">{{ tag }}</span>
      </div>

      <article class="post-content" v-if="post.format === 'rich_text'" v-html="post.content || ''" />
      <article class="post-content" v-else-if="post.format === 'markdown'" v-html="markdownHtml" />

      <section v-else-if="post.format === 'image_gallery'" class="post-content">
        <p class="hint" v-if="post.content">{{ post.content }}</p>
        <div class="gallery-grid" v-if="post.attachments?.length">
          <div class="gallery-item" v-for="url in post.attachments" :key="url">
            <img :src="url" alt="gallery image" />
          </div>
        </div>
      </section>

      <section v-else-if="post.format === 'external_link'" class="post-content">
        <p>
          外链地址：
          <a :href="normalizedLink" target="_blank" rel="noreferrer">{{ normalizedLink }}</a>
        </p>
        <p class="hint" v-if="post.linkSummary">{{ post.linkSummary }}</p>
        <p v-if="post.content && post.content !== post.linkUrl">{{ post.content }}</p>
      </section>

      <pre class="post-content" v-else>{{ post.content || '' }}</pre>

      <div v-if="post.attachments?.length && post.format !== 'image_gallery'" class="attachments">
        <h4>附件</h4>
        <ul>
          <li v-for="url in post.attachments" :key="url">
            <a :href="url" target="_blank" rel="noreferrer">{{ url }}</a>
          </li>
        </ul>
      </div>

      <div class="action-row" v-if="canReview">
        <button class="primary-btn" type="button" :disabled="submitting" @click="review('approve')">通过</button>
        <button class="danger" type="button" :disabled="submitting" @click="review('reject')">驳回</button>
      </div>
      <p class="hint" v-else>当前状态不是待审核，已不可在此页面执行审核。</p>
    </template>
  </section>
</template>
