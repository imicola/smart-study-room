import { createApp } from 'vue'
import { createPinia } from 'pinia'
import { gsap } from 'gsap'
import { ScrollTrigger } from 'gsap/ScrollTrigger'

import App from './App.vue'
import { revealDirective, listMotionDirective, activeTrackDirective } from './composables/motion'
import router from './router'
import { loadingDirective } from './components/ui/loading'
import { useThemeStore } from './stores/theme'
import './styles/main.css'

gsap.registerPlugin(ScrollTrigger)

const app = createApp(App)
const pinia = createPinia()

app.use(pinia)
app.use(router)
app.directive('loading', loadingDirective)
app.directive('reveal', revealDirective)
app.directive('list-motion', listMotionDirective)
app.directive('active-track', activeTrackDirective)

const themeStore = useThemeStore(pinia)
themeStore.initTheme()

app.mount('#app')
