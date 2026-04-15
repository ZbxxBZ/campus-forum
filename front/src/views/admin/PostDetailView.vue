<script setup>
import { computed, nextTick, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import {
  createCommentApi,
  getFollowRelationApi,
  getPostDetailApi,
  getPostInteractionApi,
  listCommentsApi,
  toggleFollowUserApi,
  togglePostFavoriteApi,
  togglePostLikeApi
} from '../../services/modules/forumApi'
import { normalizeExternalLink, renderMarkdownToHtml } from '../../utils/contentFormat'
import { useAuthStore } from '../../stores/auth'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const loading = ref(false)
const errorMessage = ref('')
const post = ref(null)

const interaction = ref({ likeCount: 0, favoriteCount: 0, liked: false, favorited: false })
const comments = ref([])
const commentText = ref('')
const replyParentId = ref(null)
const commentBoxVisible = ref(false)
const commentInputRef = ref(null)
const followLoading = ref(false)
const followedAuthor = ref(false)

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
    published: '已发布',
    rejected: '已驳回',
    hidden: '已下架'
  }
  return map[post.value?.status] || post.value?.status || '-'
})

const normalizedLink = computed(() => normalizeExternalLink(post.value?.linkUrl || post.value?.content || ''))
const markdownHtml = computed(() => renderMarkdownToHtml(post.value?.content || ''))
const canOpenAuthorProfile = computed(() => Boolean(post.value?.authorId))
const isOwnAuthor = computed(() => Number(post.value?.authorId) === Number(authStore.user?.id))
const hasListContext = computed(() => route.query.from === 'home')

const homeQuery = computed(() => {
  const keys = ['feed', 'keyword', 'author', 'tag', 'boardId', 'dateFrom', 'dateTo']
  const query = {}
  for (const key of keys) {
    const value = route.query[key]
    if (Array.isArray(value)) {
      if (value[0]) query[key] = value[0]
    } else if (value) {
      query[key] = value
    }
  }
  return query
})

const commentRows = computed(() => {
  const map = new Map(comments.value.map((item) => [item.id, item]))
  return comments.value
    .slice()
    .sort((a, b) => new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime())
    .map((item) => {
      let depth = 0
      let parent = item.parentId ? map.get(item.parentId) : null
      while (parent) {
        depth += 1
        if (!parent.parentId) break
        parent = map.get(parent.parentId)
      }
      return {
        ...item,
        depth,
        parentAuthor: item.parentId ? map.get(item.parentId)?.author : null
      }
    })
})

function normalizePost(data) {
  if (data?.post) return data.post
  return data
}

function normalizeList(data) {
  if (Array.isArray(data?.list)) return data.list
  if (Array.isArray(data)) return data
  return []
}

async function loadDetail() {
  loading.value = true
  errorMessage.value = ''
  try {
    const data = await getPostDetailApi(route.params.postId)
    post.value = normalizePost(data)
  } catch (error) {
    errorMessage.value = `帖子详情加载失败：${error.message}`
  } finally {
    loading.value = false
  }
}

async function loadInteraction() {
  try {
    const data = await getPostInteractionApi(route.params.postId)
    interaction.value = { ...interaction.value, ...data }
  } catch {
    // Ignore interaction loading failure to avoid blocking detail page.
  }
}

async function loadFollowRelation() {
  if (!post.value?.authorId || isOwnAuthor.value) return
  try {
    const data = await getFollowRelationApi(post.value.authorId)
    followedAuthor.value = Boolean(data.followed)
  } catch {
    // ignore follow relation loading error to avoid blocking detail page
  }
}

async function loadComments() {
  try {
    const data = await listCommentsApi(route.params.postId)
    comments.value = normalizeList(data)
  } catch {
    comments.value = []
  }
}

async function toggleLike() {
  const data = await togglePostLikeApi(route.params.postId)
  interaction.value = { ...interaction.value, ...data }
}

async function toggleFavorite() {
  const data = await togglePostFavoriteApi(route.params.postId)
  interaction.value = { ...interaction.value, ...data }
}

async function toggleFollowAuthor() {
  if (!post.value?.authorId || isOwnAuthor.value) return
  followLoading.value = true
  try {
    const data = await toggleFollowUserApi(post.value.authorId)
    followedAuthor.value = Boolean(data.followed)
  } finally {
    followLoading.value = false
  }
}

function setReply(parentId) {
  commentBoxVisible.value = true
  replyParentId.value = parentId
  focusCommentInput()
}

function cancelReply() {
  replyParentId.value = null
}

function openCommentBox() {
  commentBoxVisible.value = true
  focusCommentInput()
}

function closeCommentBox() {
  commentBoxVisible.value = false
  replyParentId.value = null
  commentText.value = ''
}

function focusCommentInput() {
  nextTick(() => {
    commentInputRef.value?.focus()
  })
}

async function submitComment() {
  if (!commentText.value.trim()) return

  await createCommentApi(route.params.postId, {
    parentId: replyParentId.value,
    content: commentText.value,
    author: authStore.user?.displayName || authStore.user?.username || '匿名用户'
  })

  commentText.value = ''
  replyParentId.value = null
  commentBoxVisible.value = false
  await loadComments()
}

function backToList() {
  router.push({
    path: '/admin/home',
    query: homeQuery.value
  })
}

onMounted(async () => {
  await loadDetail()
  await loadFollowRelation()
  await loadInteraction()
  await loadComments()
})
</script>

<template>
  <section class="panel">
    <h2>帖子详情</h2>
    <div class="action-row">
      <button type="button" @click="backToList">
        {{ hasListContext ? '返回帖子列表' : '返回工作台' }}
      </button>
    </div>
    <p v-if="loading" class="hint">加载中...</p>
    <p v-if="errorMessage" class="error">{{ errorMessage }}</p>

    <template v-if="post && !loading">
      <h3>{{ post.title }}</h3>
      <p class="hint" v-if="post.summary">摘要：{{ post.summary }}</p>

      <section class="detail-top-split">
        <section class="author-brief">
          <RouterLink v-if="canOpenAuthorProfile" :to="`/admin/profile/${post.authorId}`" class="author-avatar-link">
            <img v-if="post.authorAvatar" :src="post.authorAvatar" alt="author avatar" class="author-avatar" />
            <div v-else class="avatar-placeholder author-avatar">
              {{ (post.author || 'U').slice(0, 1) }}
            </div>
          </RouterLink>
          <div v-else class="avatar-placeholder author-avatar">{{ (post.author || 'U').slice(0, 1) }}</div>
          <div class="author-brief-name">
            <strong>{{ post.author || '-' }}</strong>
          </div>
          <button
            v-if="canOpenAuthorProfile && !isOwnAuthor"
            type="button"
            class="follow-author-btn"
            :class="{ 'action-btn-active': followedAuthor }"
            :disabled="followLoading"
            @click="toggleFollowAuthor"
          >
            {{ followedAuthor ? '已关注作者' : '关注作者' }}
          </button>
        </section>

        <div class="meta-grid detail-meta-grid">
          <span>
            作者：
            <RouterLink v-if="canOpenAuthorProfile" :to="`/admin/profile/${post.authorId}`">
              {{ post.author || '-' }}
            </RouterLink>
            <template v-else>{{ post.author || '-' }}</template>
          </span>
          <span>板块：{{ post.boardName || '-' }}</span>
          <span>格式：{{ formatLabel }}</span>
          <span>状态：{{ statusLabel }}</span>
          <span>发布时间：{{ post.createdAt?.slice(0, 19).replace('T', ' ') }}</span>
        </div>
      </section>

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

      <section class="panel sub-panel">
        <h3>互动交流</h3>

        <div class="action-row">
          <button
            type="button"
            :class="{ 'action-btn-active': interaction.liked }"
            @click="toggleLike"
          >
            点赞（{{ interaction.likeCount || 0 }}）
          </button>
          <button
            type="button"
            :class="{ 'action-btn-active': interaction.favorited }"
            @click="toggleFavorite"
          >
            收藏（{{ interaction.favoriteCount || 0 }}）
          </button>
        </div>

        <div class="comment-box" v-if="commentBoxVisible">
          <p class="hint" v-if="replyParentId">正在回复评论 #{{ replyParentId }}</p>
          <textarea ref="commentInputRef" v-model="commentText" rows="4" placeholder="写下你的评论..." />
          <div class="action-row">
            <button class="primary-btn" type="button" @click="submitComment">发表评论</button>
            <button type="button" v-if="replyParentId" @click="cancelReply">取消回复</button>
            <button type="button" v-if="!replyParentId" @click="closeCommentBox">收起</button>
          </div>
        </div>

        <div class="comment-list">
          <div
            class="comment-item"
            v-for="item in commentRows"
            :key="item.id"
            :style="{ marginLeft: `${item.depth * 18}px` }"
          >
            <p class="comment-meta">
              <strong>{{ item.author }}</strong>
              <span class="hint" v-if="item.parentAuthor"> 回复 {{ item.parentAuthor }}</span>
              <span class="hint"> · {{ item.createdAt?.slice(0, 16).replace('T', ' ') }}</span>
            </p>
            <p>{{ item.content }}</p>
            <button type="button" class="link-btn" @click="setReply(item.id)">回复</button>
          </div>
          <p class="hint" v-if="!commentRows.length">暂无评论，快来抢沙发。</p>
        </div>

        <button
          v-if="!commentBoxVisible"
          type="button"
          class="floating-comment-btn"
          @click="openCommentBox"
        >
          发表评论
        </button>
      </section>
    </template>
  </section>
</template>
