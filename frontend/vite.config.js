import { defineConfig, loadEnv } from 'vite'
import vue from '@vitejs/plugin-vue'
import { fileURLToPath } from 'node:url'
import path from 'node:path'

// https://vitejs.dev/config/
export default defineConfig(({ mode }) => {
  // 读取项目根目录 .env 中的 STUDYROOM_HOST_PORT(与 docker compose 共用)，
  // 让前端代理端口与容器后端宿主端口保持一致; 未配置时回退 8080
  const projectRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
  const env = loadEnv(mode, projectRoot, '')
  const backendPort = env.STUDYROOM_HOST_PORT || '8080'

  return {
    plugins: [vue()],
    server: {
      port: 5173,
      proxy: {
        // 开发期将 API 请求代理到后端, 规避跨域
        '/api': {
          target: `http://127.0.0.1:${backendPort}`,
          changeOrigin: true
        }
      }
    }
  }
})
