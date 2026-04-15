<script setup>
import { onMounted, reactive, ref } from 'vue'
import { createBoardApi, listBoardsApi, updateBoardApi } from '../../services/modules/forumApi'

const boards = ref([])
const total = ref(0)
const errorMessage = ref('')

const filters = reactive({
  keyword: '',
  status: ''
})

const createForm = reactive({
  name: '',
  code: '',
  description: '',
  sortOrder: 99,
  status: 'enabled'
})

async function loadBoards() {
  const data = await listBoardsApi(filters)
  boards.value = data.list.map((item) => ({ ...item, editing: false }))
  total.value = data.total
}

async function createBoard() {
  if (!createForm.name || !createForm.code) {
    errorMessage.value = '请填写板块名称和编码。'
    return
  }

  try {
    errorMessage.value = ''
    await createBoardApi(createForm)
    createForm.name = ''
    createForm.code = ''
    createForm.description = ''
    createForm.sortOrder = 99
    createForm.status = 'enabled'
    await loadBoards()
  } catch (error) {
    errorMessage.value = error.message
  }
}

function enableEdit(row) {
  row.editing = true
  row._draft = {
    name: row.name,
    code: row.code,
    description: row.description,
    sortOrder: row.sortOrder,
    status: row.status
  }
}

function cancelEdit(row) {
  row.editing = false
  row._draft = null
}

async function saveEdit(row) {
  try {
    await updateBoardApi(row.id, row._draft)
    row.editing = false
    row._draft = null
    await loadBoards()
  } catch (error) {
    errorMessage.value = error.message
  }
}

async function quickToggleStatus(row) {
  const target = row.status === 'enabled' ? 'disabled' : 'enabled'
  await updateBoardApi(row.id, { status: target })
  await loadBoards()
}

onMounted(loadBoards)
</script>

<template>
  <section class="panel">
    <h2>板块配置管理</h2>

    <div class="filter-row">
      <input v-model.trim="filters.keyword" placeholder="搜索板块名称/编码" @keyup.enter="loadBoards" />
      <select v-model="filters.status">
        <option value="">全部状态</option>
        <option value="enabled">启用</option>
        <option value="disabled">禁用</option>
      </select>
      <button type="button" @click="loadBoards">查询</button>
    </div>

    <div class="form-grid board-create-grid">
      <label>
        板块名称
        <input v-model.trim="createForm.name" placeholder="例如：技术问答" />
      </label>
      <label>
        板块编码
        <input v-model.trim="createForm.code" placeholder="例如：tech-qna" />
      </label>
      <label>
        排序
        <input v-model.number="createForm.sortOrder" type="number" min="0" />
      </label>
      <label>
        状态
        <select v-model="createForm.status">
          <option value="enabled">启用</option>
          <option value="disabled">禁用</option>
        </select>
      </label>
      <label class="full-width">
        描述
        <input v-model.trim="createForm.description" placeholder="板块说明" />
      </label>
    </div>

    <div class="action-row">
      <button class="primary-btn" type="button" @click="createBoard">新增板块</button>
      <p class="hint">共 {{ total }} 个板块</p>
    </div>

    <p v-if="errorMessage" class="error">{{ errorMessage }}</p>

    <table>
      <thead>
        <tr>
          <th>ID</th>
          <th>名称</th>
          <th>编码</th>
          <th>描述</th>
          <th>排序</th>
          <th>状态</th>
          <th>帖子数</th>
          <th>操作</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="row in boards" :key="row.id">
          <td>{{ row.id }}</td>
          <td>
            <template v-if="row.editing">
              <input v-model.trim="row._draft.name" />
            </template>
            <template v-else>{{ row.name }}</template>
          </td>
          <td>
            <template v-if="row.editing">
              <input v-model.trim="row._draft.code" />
            </template>
            <template v-else>{{ row.code }}</template>
          </td>
          <td>
            <template v-if="row.editing">
              <input v-model.trim="row._draft.description" />
            </template>
            <template v-else>{{ row.description }}</template>
          </td>
          <td>
            <template v-if="row.editing">
              <input v-model.number="row._draft.sortOrder" type="number" min="0" />
            </template>
            <template v-else>{{ row.sortOrder }}</template>
          </td>
          <td>
            <template v-if="row.editing">
              <select v-model="row._draft.status">
                <option value="enabled">启用</option>
                <option value="disabled">禁用</option>
              </select>
            </template>
            <template v-else>
              <span :class="['badge', row.status === 'enabled' ? 'ok' : 'off']">{{ row.status === 'enabled' ? '启用' : '禁用' }}</span>
            </template>
          </td>
          <td>{{ row.postCount }}</td>
          <td>
            <div class="table-actions" v-if="row.editing">
              <button type="button" @click="saveEdit(row)">保存</button>
              <button type="button" @click="cancelEdit(row)">取消</button>
            </div>
            <div class="table-actions" v-else>
              <button type="button" @click="enableEdit(row)">编辑</button>
              <button type="button" :class="row.status === 'enabled' ? 'danger' : ''" @click="quickToggleStatus(row)">
                {{ row.status === 'enabled' ? '禁用' : '启用' }}
              </button>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
  </section>
</template>
