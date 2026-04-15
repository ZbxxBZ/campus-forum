<script setup>
import { computed, onBeforeUnmount, onMounted, reactive, ref, watch } from 'vue'
import { useAuthStore } from '../../stores/auth'
import {
  createPostApi,
  listAvailableBoardsApi,
  listPublishedPostsApi,
  uploadImagesApi
} from '../../services/modules/forumApi'
import { normalizeExternalLink, renderMarkdownToHtml } from '../../utils/contentFormat'

const authStore = useAuthStore()
const submitting = ref(false)
const savingDraft = ref(false)
const successMessage = ref('')
const errorMessage = ref('')
const preAuditResult = ref(null)
const boards = ref([])
const richTextRef = ref(null)
const isSuperAdmin = computed(() => authStore.user?.role === 'super_admin')

const formatOptions = [
  { value: 'rich_text', label: '富文本编辑器' },
  { value: 'markdown', label: 'Markdown' },
  { value: 'image_gallery', label: '图文相册' },
  { value: 'external_link', label: '外链分享' }
]

const markdownTips = [
  '# 一级标题',
  '## 二级标题',
  '**加粗**',
  '*斜体*',
  '> 引用',
  '[链接文字](https://example.com)'
]

const form = reactive({
  title: '',
  summary: '',
  boardId: '',
  format: 'rich_text',
  content: '',
  markdownContent: '',
  galleryDesc: '',
  tagsText: '',
  status: 'pending',
  isTop: false,
  isFeatured: false,
  linkUrl: '',
  linkTitle: '',
  linkSummary: ''
})

const localImages = ref([])

const markdownPreviewHtml = computed(() => renderMarkdownToHtml(form.markdownContent))

const contentPlaceholder = computed(() => {
  if (form.format === 'rich_text') return '请输入富文本 HTML 内容，或使用上方快捷排版按钮'
  if (form.format === 'markdown') return '请输入 Markdown 内容'
  if (form.format === 'external_link') return '请输入分享说明（可选）'
  return '请输入正文内容'
})

const canUsePublishDirectly = computed(() => isSuperAdmin.value)

watch(
  () => form.format,
  (value) => {
    if (value !== 'image_gallery') {
      clearLocalImages()
    }
  }
)

function resetForm() {
  form.title = ''
  form.summary = ''
  form.boardId = boards.value[0]?.id || ''
  form.format = 'rich_text'
  form.content = ''
  form.markdownContent = ''
  form.galleryDesc = ''
  form.tagsText = ''
  form.status = canUsePublishDirectly.value ? 'published' : 'pending'
  form.isTop = false
  form.isFeatured = false
  form.linkUrl = ''
  form.linkTitle = ''
  form.linkSummary = ''
  preAuditResult.value = null
  clearLocalImages()
}

function clearLocalImages() {
  localImages.value.forEach((item) => URL.revokeObjectURL(item.previewUrl))
  localImages.value = []
}

function addPollOption() {
  form.pollOptions.push('')
}

function removePollOption(index) {
  if (form.pollOptions.length > 2) {
    form.pollOptions.splice(index, 1)
  }
}

function insertRichText(templateText) {
  const el = richTextRef.value
  if (!el) {
    form.content += templateText
    return
  }

  const start = el.selectionStart ?? form.content.length
  const end = el.selectionEnd ?? start
  const before = form.content.slice(0, start)
  const selected = form.content.slice(start, end)
  const after = form.content.slice(end)

  const text = templateText.replace('{text}', selected || '内容')
  form.content = `${before}${text}${after}`

  requestAnimationFrame(() => {
    el.focus()
    const cursor = before.length + text.length
    el.setSelectionRange(cursor, cursor)
  })
}

async function onLocalImageChange(event) {
  const files = Array.from(event.target.files || [])
  if (!files.length) return

  const records = await Promise.all(
    files.map(
      (file) =>
        new Promise((resolve) => {
          resolve({
            name: file.name,
            caption: '',
            previewUrl: URL.createObjectURL(file),
            file
          })
        })
    )
  )

  localImages.value = [...localImages.value, ...records]
  event.target.value = ''
}

function removeLocalImage(index) {
  const target = localImages.value[index]
  if (!target) return
  URL.revokeObjectURL(target.previewUrl)
  localImages.value.splice(index, 1)
}

function moveImage(index, direction) {
  const next = index + direction
  if (next < 0 || next >= localImages.value.length) return
  const temp = localImages.value[index]
  localImages.value[index] = localImages.value[next]
  localImages.value[next] = temp
}

async function loadBoards() {
  errorMessage.value = ''
  try {
    const data = await listAvailableBoardsApi()
    boards.value = data.list
    if (!form.boardId) form.boardId = boards.value[0]?.id || ''
  } catch (error) {
    try {
      const published = await listPublishedPostsApi()
      const merged = []
      for (const post of published.list || []) {
        if (!post.boardId || !post.boardName) continue
        if (merged.some((item) => item.id === post.boardId)) continue
        merged.push({ id: post.boardId, name: post.boardName })
      }
      boards.value = merged
      if (!form.boardId) form.boardId = boards.value[0]?.id || ''
      if (!boards.value.length) {
        errorMessage.value = '暂无可选板块，请联系管理员检查板块配置。'
      }
    } catch (fallbackError) {
      errorMessage.value = `板块加载失败：${fallbackError.message}`
    }
  }
}

function buildPayload(overrideStatus) {
  const resolvedStatus =
    overrideStatus || (canUsePublishDirectly.value ? form.status : 'pending')
  const payload = {
    title: form.title,
    summary: form.summary,
    boardId: Number(form.boardId),
    format: form.format,
    tags: form.tagsText,
    status: resolvedStatus,
    isTop: form.isTop,
    isFeatured: form.isFeatured,
    author: authStore.user?.username || 'unknown'
  }

  if (form.format === 'rich_text') {
    payload.content = form.content
    payload.attachments = []
  }

  if (form.format === 'markdown') {
    payload.content = form.markdownContent
    payload.attachments = []
  }

  if (form.format === 'image_gallery') {
    payload.content = form.galleryDesc
    payload.attachments = []
    payload.galleryCaptions = localImages.value.map((item) => item.caption)
  }

  if (form.format === 'external_link') {
    payload.content = normalizeExternalLink(form.linkUrl)
    payload.linkUrl = normalizeExternalLink(form.linkUrl)
    payload.linkTitle = form.linkTitle || form.title
    payload.linkSummary = form.linkSummary
    payload.attachments = []
  }

  return payload
}

function validateForm(mode = 'publish') {
  if (!form.title || !form.boardId) {
    return '请至少填写标题和板块。'
  }

  if (mode === 'draft') {
    return ''
  }

  if (form.format === 'rich_text' && !form.content.trim()) {
    return '请填写富文本正文。'
  }

  if (form.format === 'markdown' && !form.markdownContent.trim()) {
    return '请填写 Markdown 正文。'
  }

  if (form.format === 'image_gallery' && !localImages.value.length) {
    return '请至少上传一张本地图片。'
  }

  if (form.format === 'external_link' && !form.linkUrl.trim()) {
    return '请输入要分享的外链地址。'
  }

  return ''
}

async function submitPost() {
  const validateMessage = validateForm()
  if (validateMessage) {
    errorMessage.value = validateMessage
    return
  }

  submitting.value = true
  errorMessage.value = ''
  successMessage.value = ''
  preAuditResult.value = null

  try {
    let uploadedUrls = []
    if (form.format === 'image_gallery') {
      const uploadResult = await uploadImagesApi(localImages.value.map((item) => item.file))
      uploadedUrls = (uploadResult.files || [])
        .map((item) => item.url)
        .filter(Boolean)
      if (!uploadedUrls.length) {
        throw new Error('图片上传失败，请检查 /api/v1/uploads/images 接口。')
      }
    }

    const payload = buildPayload()
    if (form.format === 'image_gallery') {
      payload.attachments = uploadedUrls
    }

    await createPostApi(payload)
    successMessage.value = isSuperAdmin.value ? '帖子发布成功。' : '帖子已提交审核，请等待管理员审核。'
    resetForm()
  } catch (error) {
    if (error?.status === 422 || error?.code === 42201) {
      const hitWords = Array.isArray(error?.data?.hitWords) ? error.data.hitWords : []
      preAuditResult.value = {
        message: error?.data?.message || error.message || '内容命中前置审核规则，请修改后重试。',
        riskLevel: error?.data?.riskLevel || 'high',
        hitWords
      }
      errorMessage.value = '前置审核未通过，请根据提示修改后再提交。'
      return
    }
    errorMessage.value = error.message
  } finally {
    submitting.value = false
  }
}

async function saveAsDraft() {
  const validateMessage = validateForm('draft')
  if (validateMessage) {
    errorMessage.value = validateMessage
    return
  }

  savingDraft.value = true
  errorMessage.value = ''
  successMessage.value = ''
  preAuditResult.value = null

  try {
    let uploadedUrls = []
    if (form.format === 'image_gallery' && localImages.value.length) {
      const uploadResult = await uploadImagesApi(localImages.value.map((item) => item.file))
      uploadedUrls = (uploadResult.files || []).map((item) => item.url).filter(Boolean)
    }

    const payload = buildPayload('draft')
    if (form.format === 'image_gallery' && uploadedUrls.length) {
      payload.attachments = uploadedUrls
    }

    await createPostApi(payload)
    successMessage.value = '已存为草稿，可在”我的帖子”中继续编辑或重新发布。'
    resetForm()
  } catch (error) {
    errorMessage.value = error.message
  } finally {
    savingDraft.value = false
  }
}

onMounted(loadBoards)
onBeforeUnmount(clearLocalImages)
</script>

<template>
  <section class="panel">
    <h2>内容发布</h2>
    <p class="hint">请先选择内容格式，系统会展示对应发布界面。</p>

    <div class="form-grid two-col">
      <label>
        帖子标题
        <input v-model.trim="form.title" placeholder="请输入帖子标题" />
      </label>

      <label>
        所属板块
        <select v-model="form.boardId">
          <option v-for="item in boards" :key="item.id" :value="item.id">{{ item.name }}</option>
        </select>
      </label>

      <label>
        内容格式
        <select v-model="form.format">
          <option v-for="item in formatOptions" :key="item.value" :value="item.value">{{ item.label }}</option>
        </select>
      </label>

      <label>
        内容摘要
        <input v-model.trim="form.summary" placeholder="可选，用于列表摘要展示" />
      </label>

      <label>
        发布状态
        <template v-if="canUsePublishDirectly">
          <select v-model="form.status">
            <option value="pending">提交审核</option>
            <option value="published">直接发布</option>
            <option value="draft">保存草稿</option>
          </select>
        </template>
        <template v-else>
          <input value="提交审核（默认）" disabled />
        </template>
      </label>

      <label class="full-width">
        标签（逗号分隔）
        <input v-model="form.tagsText" placeholder="例如：考试周, 经验分享" />
      </label>
    </div>

    <div class="format-card" v-if="form.format === 'rich_text'">
      <h3>富文本发布</h3>
      <div class="rich-toolbar">
        <button type="button" @click="insertRichText('<strong>{text}</strong>')">加粗</button>
        <button type="button" @click="insertRichText('<h2>{text}</h2>')">二级标题</button>
        <button type="button" @click="insertRichText('<blockquote>{text}</blockquote>')">引用</button>
        <button type="button" @click="insertRichText('<ul><li>{text}</li></ul>')">列表</button>
        <button type="button" @click="insertRichText(`<a href='https://example.com' target='_blank'>{text}</a>`)">超链接</button>
        <button type="button" @click="insertRichText(`<img src='https://image.example.com/demo.png' alt='{text}' />`)">插图模板</button>
      </div>
      <textarea
        ref="richTextRef"
        v-model="form.content"
        :placeholder="contentPlaceholder"
        rows="10"
      />
    </div>

    <div class="format-card" v-if="form.format === 'markdown'">
      <h3>Markdown 发布</h3>
      <p class="hint">左侧编辑，右侧实时预览。不会写 Markdown 可直接参考下方语法示例。</p>
      <div class="markdown-help">
        <span v-for="tip in markdownTips" :key="tip" class="chip">{{ tip }}</span>
      </div>
      <div class="markdown-split">
        <textarea
          v-model="form.markdownContent"
          :placeholder="contentPlaceholder"
          rows="12"
        />
        <article class="post-content markdown-preview" v-html="markdownPreviewHtml" />
      </div>
    </div>

    <div class="format-card" v-if="form.format === 'image_gallery'">
      <h3>图文相册发布</h3>
      <p class="hint">支持本地选择图片，发布时将先上传图片并提交 URL 到帖子接口。</p>
      <label>
        本地上传图片
        <input type="file" accept="image/*" multiple @change="onLocalImageChange" />
      </label>
      <label>
        相册说明
        <textarea v-model="form.galleryDesc" rows="4" placeholder="请输入图文说明" />
      </label>

      <div class="gallery-grid" v-if="localImages.length">
        <div class="gallery-item" v-for="(img, index) in localImages" :key="img.previewUrl">
          <img :src="img.previewUrl" :alt="img.name" />
          <input v-model.trim="img.caption" placeholder="图片说明（可选）" />
          <div class="table-actions">
            <button type="button" @click="moveImage(index, -1)">上移</button>
            <button type="button" @click="moveImage(index, 1)">下移</button>
            <button type="button" class="danger" @click="removeLocalImage(index)">删除</button>
          </div>
        </div>
      </div>
    </div>

    <div class="format-card" v-if="form.format === 'external_link'">
      <h3>外链分享发布</h3>
      <label>
        外链地址
        <input v-model.trim="form.linkUrl" placeholder="例如：https://example.com/news/123" />
      </label>
      <label>
        外链标题（可选）
        <input v-model.trim="form.linkTitle" placeholder="默认使用帖子标题" />
      </label>
      <label>
        外链摘要（可选）
        <textarea v-model="form.linkSummary" rows="3" placeholder="可填写链接摘要" />
      </label>
      <label>
        补充说明（可选）
        <textarea v-model="form.content" :placeholder="contentPlaceholder" rows="4" />
      </label>
    </div>

    <p v-if="errorMessage" class="error">{{ errorMessage }}</p>
    <div v-if="preAuditResult" class="panel sub-panel">
      <h3>前置审核提示</h3>
      <p class="error">{{ preAuditResult.message }}</p>
      <p class="hint">风险等级：{{ preAuditResult.riskLevel }}</p>
      <p class="hint" v-if="preAuditResult.hitWords.length">
        命中词：{{ preAuditResult.hitWords.join('，') }}
      </p>
    </div>
    <p v-if="successMessage" class="success">{{ successMessage }}</p>

    <div class="action-row">
      <button class="primary-btn" type="button" :disabled="submitting || savingDraft" @click="submitPost">
        {{ submitting ? '提交中...' : '发布内容' }}
      </button>
      <button type="button" :disabled="savingDraft || submitting" @click="saveAsDraft">
        {{ savingDraft ? '保存中...' : '存为草稿' }}
      </button>
      <button type="button" @click="resetForm">重置</button>
    </div>
  </section>
</template>
