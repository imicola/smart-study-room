<script setup>
defineProps({ modelValue: Number, pages: Number, total: Number })
defineEmits(['update:modelValue'])
</script>

<template>
  <nav v-if="total > 10" class="pagination" aria-label="记录分页">
    <span aria-live="polite">共 {{ total }} 条 · 第 {{ modelValue }} / {{ pages }} 页</span>
    <button type="button" :disabled="modelValue <= 1" @click="$emit('update:modelValue', modelValue - 1)">上一页</button>
    <button type="button" :disabled="modelValue >= pages" @click="$emit('update:modelValue', modelValue + 1)">下一页</button>
  </nav>
</template>
