# 智能共享自习室预约系统（Smart Study Room）

![CI](https://github.com/imicola/smart-study-room/actions/workflows/ci.yml/badge.svg)
![Go](https://img.shields.io/badge/backend-Go%201.27%20%2B%20Gin-00ADD8)
![Vue](https://img.shields.io/badge/frontend-Vue%203%20%2B%20Vite-42b883)
![PostgreSQL](https://img.shields.io/badge/db-PostgreSQL%2018-336791)
![Redis](https://img.shields.io/badge/cache-Redis%207-DC382D)
![License](https://img.shields.io/badge/license-MIT-green)

> 《系统分析与设计》课程设计 —— 面向高校共享自习室场景的座位预约与管理平台。

## 目录

- [项目简介](#项目简介)
- [核心亮点](#核心亮点)
- [技术栈](#技术栈)
- [功能总览](#功能总览)
- [系统架构](#系统架构)
- [快速开始](#快速开始)
- [AI 助手配置](#ai-助手配置)
- [接口速览](#接口速览)
- [项目结构](#项目结构)
- [测试与质量保障](#测试与质量保障)
- [课程设计文档索引](#课程设计文档索引)
- [小组分工](#小组分工)
- [已知限制与演进方向](#已知限制与演进方向)
- [许可证](#许可证)

## 项目简介

随着高校与城市共享自习室的普及，传统"到店找座"模式存在座位资源利用率不均、
占座严重、违约成本低等问题。本系统提供**在线选座预约、智能自动分配、
座位热力图、信用分体系、满座候补**等能力，并引入 **Redis 内存中间件** 支撑高并发分布式锁、
旁路缓存防雪崩、接口级限流与 JWT 登出黑名单，帮助学生高效获得学习座位，
帮助管理员数据化运营自习室资源。

项目采用面向对象分析与设计方法（OOA/OOD）与增量开发过程，配套完整的课程设计文档体系
（需求规格说明书、概要设计说明书、详细设计说明书、开发进度日志、系统测试报告）与
21 张 Mermaid 分析设计图。

## 核心亮点

| 亮点 | 实现要点 |
| --- | --- |
| **三层并发防超卖** | Redis 细粒度分布式互斥锁（SETNX + UUID 属主 + 看门狗续租 + Lua 原子解锁）→ 应用层冲突预检 → PostgreSQL GiST 排除约束最终兜底 |
| **Redis 优雅降级** | 未配置或无法连接 Redis 时自动切换为纯 PostgreSQL 模式，核心预约链路不中断；缓存/锁/黑名单/调度按用途差异化失败策略 |
| **防雪崩缓存** | 旁路缓存（Cache-Aside）在基础 TTL 上叠加 ±10% 随机抖动，打散热点键过期时点；写操作主动失效关联键前缀 |
| **高可用调度器** | 多实例通过 Redis 锁竞选 Leader，仅当选节点执行违约扫描/候补递补/提醒，支持水平扩展 |
| **可解释的智能分配** | 偏好加权评分（区域 30 + 电源 25 + 靠窗 15）− 近 7 日利用率 × 20 + 随机微扰，输出 Top-N 与推荐理由 |
| **AI 助手（只读推荐）** | OpenAI 兼容 SSE 流式对话，上下文一次性注入本人业务数据；座位推荐经后端二次核验，**AI 无写权限**，下单须用户确认 |
| **3D 座位探索** | Three.js 渲染座位三维视图，GSAP Flip 完成平面图与 3D 视图转场，支持 reduced-motion 降级 |
| **会话主动注销** | JWT 登出时按令牌剩余有效期写入 Redis 黑名单，中间件实时校验，弥补无状态 JWT 无法提前作废的缺陷 |

## 技术栈

| 层次 | 选型 | 用途 |
| --- | --- | --- |
| 后端 | Go 1.27 + Gin 1.12 + pgx 5.10 | RESTful API 服务与业务领域模型 |
| 前端 | Vite 8 + Vue 3.5 + Pinia 4 + Vue Router 5 | 响应式单页应用与状态管理 |
| UI 与图表 | Element Plus 2.14 + ECharts 6.1 | 组件库、热力图与统计大屏 |
| 动效与 3D | GSAP 3.15 + Three.js 0.185 | 页面动效、3D 座位探索视图 |
| 关系数据库 | PostgreSQL 18 | 持久化主库，GiST 排除约束兜底防超卖 |
| 缓存与互斥 | Redis 7（Docker 容器） | 旁路缓存、分布式锁、限流与黑名单 |
| 认证机制 | JWT（HS256）+ bcrypt + Redis 黑名单 | 安全会话与主动注销 |
| AI 助手 | OpenAI Chat Completions 兼容接口（SSE + tools） | 自然语言查数与座位推荐 |
| 测试 | Go testing + miniredis + Python 3 标准库 | 单元测试、E2E 接口测试、并发压测 |
| 容器与 CI | Docker Compose + GitHub Actions | 一键本地编排与自动化构建测试 |

## 功能总览

- **身份鉴别与认证**：注册 / 登录 / JWT 会话 / 登出主动注销（Redis 黑名单） / 登录防爆破限流
- **座位管理**：自习室与座位增删改查、批量生成、靠窗 / 电源 / 区域属性维护、座位平面图与 3D 座位探索
- **高并发在线预约**：基于 Redis 分布式互斥锁（Lua 脚本）排队抢座 + PostgreSQL 排除约束最终兜底
- **智能自动分配**：按偏好加权评分自动推荐 / 分配座位（偏好得分 + 削峰填谷热度均衡）
- **座位热力图**：座位 × 时段利用率可视化，Redis 旁路缓存聚合报表（TTL 抖动防雪崩）
- **预约全生命周期**：签到、临时离开、返回、签退、超时违约自动处理
- **高可用后台调度**：基于 Redis 分布式锁竞选 Leader 主备节点，支持多实例水平扩展
- **信用分体系**：违约扣分、履约加分、低分限约与流水追溯
- **满座候补**：候补排队、空位自动递补
- **消息中心**：预约 / 违约 / 递补等事件站内通知
- **统计仪表盘**：使用率趋势、高峰时段、热门座位分析
- **AI 助手**：流式对话查询本人资料 / 信用 / 预约 / 候补 / 通知，按自然语言偏好推荐座位（须二次确认）

## 系统架构

```text
浏览器（Vue 3 SPA）
    │  HTTP/JSON + Bearer JWT，AI 对话走 SSE
    ▼
接入层  Gin 路由 + 中间件链
    │  CORS → RateLimit（Redis 计数） → JWT 认证（含黑名单校验） → RBAC
    ▼
业务层  handler → service（10 个业务模块 + 高可用调度器）
    │  读：旁路缓存优先    写：分布式锁 + 事务
    ▼
缓存与协调层  Redis 7（座位图/统计缓存、互斥锁、Leader 选举、限流、黑名单）
    ▼
持久化层  PostgreSQL 18（GiST 排除约束兜底）
```

## 快速开始

> 推荐使用 **Docker Compose** 一键启动 PostgreSQL + Redis + 后端（起库即用）；如需纯本地运行调试，系统具备**优雅降级（Fallback）**能力：若不配置或无法连接 Redis，系统会自动降级为纯 PostgreSQL 模式运行。

### 方式一：Docker 启动（数据库 + Redis + 后端，推荐）

前置条件：已安装并启动 [Docker Desktop](https://www.docker.com/products/docker-desktop/)。

```bash
cp .env.example .env            # Windows: copy .env.example .env
docker compose up -d --build    # 构建并启动 PostgreSQL、Redis 7 与后端
docker compose ps               # 查看状态：db / redis 应 healthy，backend 应 running
docker compose logs -f backend  # 跟踪后端日志
```

- **后端 API**：http://localhost:8080
- **PostgreSQL 数据库**：宿主机 `localhost:5433`（容器内 5432，数据卷持久化于 `db-data`）
- **Redis 缓存服务**：宿主机 `localhost:6380`（容器内 6379，数据卷持久化于 `redis-data`，避免与宿主机既有 6379 冲突）
- **数据迁移与初始化**：首次启动时自动按序导入 `001_init.sql`（建表/约束/索引）、`002_seed.sql`（14 天演示种子数据）、`003_ai_assistant.sql`（AI 会话表）
- **停止服务（保留数据）**：`docker compose down`
- **重置数据与镜像**：`docker compose down -v`
- **本地前端联调**：`cd frontend && npm install && npm run dev`，Vite 已将 `/api` 代理到 `http://127.0.0.1:8080`（端口跟随 `.env` 的 `STUDYROOM_HOST_PORT`），可直接对接容器内后端

### 方式二：纯本地运行（开发调试用）

#### 1. 初始化数据库（PostgreSQL 用户级集群）

```bash
./scripts/db_init.sh     # 首次：初始化集群并创建 studyroom 库
./scripts/db_start.sh    # 启动
./scripts/apply_migrations.sh
./scripts/apply_seed.sh  # 演示种子数据（含 14 天历史预约）
```

#### 2. 启动后端

```bash
cd backend
go run ./cmd/server    # 默认监听 :8080
```

后端会自动读取仓库根目录的 `.env`（或从 `backend/` 目录回退读取上级 `.env`），已注入的系统环境变量优先级最高。

#### 3. 启动前端

```bash
cd frontend
npm install
npm run dev            # 默认 http://localhost:5173
```

### 演示账号

| 账号 | 口令 | 角色 | 说明 |
| --- | --- | --- | --- |
| `admin` | `admin123` | 管理员 | 管理端、热力图与统计 |
| `stu01` … `stu40` | `123456` | 学生 | 选座预约、候补、通知、AI 助手 |

种子数据包含 3 间自习室（1F-静音自习室 6×8、2F-综合学习区 8×10、3F-电脑研学区 5×6，共 158 个座位）与近 14 天历史预约，便于演示热力图与统计。

## AI 助手配置

学生登录后可通过右下角悬浮球打开 AI 助手。助手支持查询本人资料、信用状态、预约、候补和通知，也可根据自然语言偏好推荐座位；推荐结果必须由学生在卡片中再次确认，实际下单仍执行原有信用、时段和并发冲突校验。

后端通过 OpenAI Chat Completions 兼容接口调用模型，至少配置：

```bash
STUDYROOM_AI_BASE_URL=https://api.openai.com/v1
STUDYROOM_AI_API_KEY=your-key
STUDYROOM_AI_MODEL=gpt-4o-mini
```

兼容服务需支持 SSE 流式输出及 tools/function calling。可选配置包括连接超时、响应超时和历史上下文条数，详见 `.env.example`。未配置 AI 时其他预约功能照常运行。

> AI 等环境变量统一填写在仓库根目录的 `.env`（模板见根目录 `.env.example`）。Docker 部署时由 `docker-compose.yml` 将其注入后端容器；本地直跑（`cd backend && go run ./cmd/server`）同样读取该文件。`backend/` 目录下不再需要、也不再维护单独的 `.env`。

AI 会话保存在 PostgreSQL 的 `ai_conversations`、`ai_messages` 表中。部署升级时需执行 `./scripts/apply_migrations.sh` 以应用 `002_ai_assistant.sql`。

## 接口速览

统一响应结构：`{"code": <业务码>, "message": "<提示>", "data": <载荷>}`，认证方式 `Authorization: Bearer <JWT>`。

| 分组 | 路径前缀 | 主要端点 | 保护与限流 |
| --- | --- | --- | --- |
| 认证 | `/api/auth` | register、login、logout、profile | login 每 IP 每分钟 10 次 |
| 房间座位 | `/api/rooms` | 房间列表、座位平面图（含时段占用） | 需登录，房间列表 Redis 缓存 |
| 预约 | `/api/reservations` | 创建、auto、mine、cancel/checkin/leave/return/checkout | 每用户每秒 2 次 + 分布式锁 |
| 信用 | `/api/credit` | 信用分与流水 | 需登录 |
| 候补 | `/api/waitlist` | 加入、mine、cancel | 需登录 |
| 通知 | `/api/notifications` | 列表、unread_count、read、read_all | 需登录 |
| 统计 | `/api/stats` | heatmap、trend、peak、top-seats、overview | 需登录，3 分钟缓存 + 抖动 |
| AI 助手 | `/api/ai` | conversations CRUD、chat/stream（SSE） | 仅 student，每用户每分钟 10 次 |
| 管理端 | `/api/admin` | 房间/座位 CRUD、批量生成、用户管理 | 仅 admin（RBAC） |
| 健康检查 | `/api/health` | 存活与数据库连通性 | 公开 |

## 项目结构

```
backend/
├── cmd/server/       入口主程序（依赖注入、优雅降级装配）
├── internal/
│   ├── config/       配置加载（PostgreSQL、Redis、AI 等环境变量 + .env）
│   ├── handler/      HTTP 适配器（参数解析、响应输出）
│   ├── middleware/   中间件链（CORS、JWT 认证、Redis 黑名单、RBAC、API 频次限流）
│   ├── model/        领域模型与 DTO 传输对象
│   ├── pkg/
│   │   ├── rediscache/ 旁路缓存助手（Cache-Aside、防雪崩、优雅降级）
│   │   └── redissync/  分布式互斥锁（Lua 脚本原子加锁与解锁、看门狗续租）
│   ├── repository/   PostgreSQL 数据访问与 Redis 客户端连接池
│   ├── router/       路由注册与依赖装配
│   ├── scheduler/    后台周期任务（基于 Redis 锁竞选 Leader 主备节点）
│   └── service/      核心业务逻辑（认证、座位、预约、分配、生命周期、信用、候补、通知、统计、AI）
├── migrations/       数据库迁移脚本（001_init.sql、002_ai_assistant.sql）
└── seed/             演示种子数据（3 间自习室、158 座位、14 天历史预约）
frontend/             Vue 3 前端应用（views / components / stores / api / styles）
docs/                 课程设计文档（报告、需求、概要、详细、进度日志、测试计划/用例/缺陷/报告、项目管理计划）+ 图表插图
diagrams/             系统分析设计图（Mermaid × 21 + drawdb/schema SQL）
scripts/              数据库初始化、测试自动化脚本（run_tests.ps1、test_api_e2e.py、test_concurrency.py）
docker-compose.yml    PostgreSQL 18 + Redis 7 + 后端多容器编排
.env.example          环境变量模板（AI 密钥、端口、密码统一入口）
```

## 测试与质量保障

| 层次 | 工具与脚本 | 覆盖内容 | 结果 |
| --- | --- | --- | --- |
| 单元测试 | `cd backend && go test ./...` | 分配评分、时段校验、缓存抖动、分布式锁、限流、JWT 黑名单、AI 客户端 | 22 项全部通过 |
| 接口 E2E | `python scripts/test_api_e2e.py` | 鉴权、RBAC、选座、状态机、候补、信用、通知、热力图、注销 | 23 项全部通过（约 3.23s） |
| 并发压测 | `python scripts/test_concurrency.py` | 20 并发抢同一座位，验证防超卖 | 1 成功 / 19 冲突 / 0 超卖，P95 190.86ms |
| 前端构建 | `cd frontend && npm run build` | 9 个路由页面生产构建 | Build Success |
| 持续集成 | `.github/workflows/ci.yml` | 后端构建+单测、前端构建 | GitHub Actions |

一键运行全套测试（需先启动后端与数据库）：

```powershell
./scripts/run_tests.ps1
```

> 端到端与并发脚本默认指向 `http://localhost:8095/api`，请按实际后端端口调整脚本中的 `BASE_URL`。详细测试数据见《系统测试报告》SSR-TEST-001。

## 课程设计文档索引

> 以下 Markdown 文档为定稿源文件，可直接提交或按模板转换为 Word；文档中的 `【插图位置】` 标记与 `diagrams/` 下 Mermaid 文件一一对应，终稿排版时渲染插入。

| 文档 | 内容 |
| --- | --- |
| [01_课程设计报告.md](docs/01_课程设计报告.md) | 前言/系统概述/系统分析/系统设计/系统实现/测试/收获体会（含全部附录） |
| [02_需求规格说明书.md](docs/02_需求规格说明书.md) | 数据字典（9 张表）、FR-01~FR-15、M1~M10 模块、性能与安全需求 |
| [03_概要设计说明书.md](docs/03_概要设计说明书.md) | 四层架构、模块划分与负责人、接口设计、ER/物理结构、出错处理 |
| [04_详细设计说明书.md](docs/04_详细设计说明书.md) | 逐模块十要素、算法与程序逻辑、Redis 组件设计、测试要点 |
| [05_开发进度日志.md](docs/05_开发进度日志.md) | 8 项工作计划、成员分工、问题与下一阶段计划 |
| [06_系统测试报告.md](docs/06_系统测试报告.md) | 单元测试、E2E 集成测试、并发性能测试、前端构建验证 |
| [07_测试计划.md](docs/07_测试计划.md) | 测试目标与范围、三层测试策略、环境、准入准出标准、风险 |
| [08_测试用例.md](docs/08_测试用例.md) | 50 条用例（单元 22 / E2E 23 / 并发 3 / 构建 2） |
| [09_缺陷报告.md](docs/09_缺陷报告.md) | 8 项缺陷与改进项明细、分级、处理状态与遗留计划 |
| [10_项目管理计划.md](docs/10_项目管理计划.md) | 目标范围、组织分工、里程碑、质量、配置与风险管理 |

> 每份 Markdown 均配套同名 `.docx`（如 `docs/测试计划.docx`），可直接提交。

## 已知限制与演进方向

1. **通知渠道**：目前仅站内通知，后续可对接企业微信/钉钉 Webhook 或校园短信网关；
2. **签到防伪**：当前基于时间窗口 + 用户操作，可引入动态刷新二维码或蓝牙 Beacon 杜绝代打卡；
3. **部署形态**：已完成 Docker Compose 多容器编排，生产级可进一步探索 Kubernetes 与只读从库读写分离；
4. **前端体积**：Element Plus 图标、ECharts 与 Three.js 分包体积较大，可继续按需引入与懒加载优化；
5. **CORS 策略**：开发配置允许任意来源，正式部署前应收紧为可信来源白名单。

## 许可证

[MIT](./LICENSE)
