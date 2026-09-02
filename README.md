# 智能共享自习室预约系统（Smart Study Room）

![CI](https://github.com/imicola/smart-study-room/actions/workflows/ci.yml/badge.svg)
![Go](https://img.shields.io/badge/backend-Go%201.27%20%2B%20Gin-00ADD8)
![Vue](https://img.shields.io/badge/frontend-Vue%203%20%2B%20Vite-42b883)
![PostgreSQL](https://img.shields.io/badge/db-PostgreSQL%2018-336791)
![License](https://img.shields.io/badge/license-MIT-green)

> 《系统分析与设计》课程设计 —— 面向高校共享自习室场景的座位预约与管理平台。

## 项目简介

随着高校与城市共享自习室的普及，传统"到店找座"模式存在座位资源利用率不均、
占座严重、违约成本低等问题。本系统提供**在线选座预约、智能自动分配、
座位热力图、信用分体系、满座候补**等能力，帮助学生高效获得学习座位，
帮助管理员数据化运营自习室资源。

## 技术栈

| 层次 | 选型 |
| --- | --- |
| 后端 | Go 1.27 + Gin + pgx |
| 前端 | Vite + Vue 3 + Element Plus + ECharts + Pinia |
| 数据库 | PostgreSQL 18 |
| 认证 | JWT（HS256）+ bcrypt |
| CI | GitHub Actions |

## 功能总览

- 身份鉴别与认证：注册 / 登录 / JWT 会话 / 学生与管理员双角色
- 座位管理：自习室、座位的增删改查与批量生成，靠窗 / 电源 / 区域属性
- 在线预约：座位平面图选座、时段冲突检测
- 智能自动分配：按偏好加权评分自动推荐 / 分配座位
- 座位热力图：座位 × 时段利用率可视化
- 预约全生命周期：签到、临时离开、签退、超时违约自动处理
- 信用分体系：违约扣分、履约加分、低分限约
- 满座候补：候补排队、空位自动递补
- 消息中心：预约 / 违约 / 递补等事件通知
- 统计仪表盘：使用率趋势、高峰时段、热门座位

## 快速开始

### 1. 初始化数据库（PostgreSQL 用户级集群）

```bash
./scripts/db_init.sh     # 首次：初始化集群并创建 studyroom 库
./scripts/db_start.sh    # 启动
./scripts/apply_migrations.sh
./scripts/apply_seed.sh  # 演示种子数据（含 14 天历史预约）
```

### 2. 启动后端

```bash
cd backend
go run ./cmd/server    # 默认监听 :8080
```

### 3. 启动前端

```bash
cd frontend
npm install
npm run dev            # 默认 http://localhost:5173
```

默认管理员账号：`admin / admin123`（演示用）。

## 项目结构

```
backend/    Go 后端（handler / service / repository 分层）
frontend/   Vue 3 前端
docs/       课程设计文档（可行性研究/范围说明/报告/需求/概要/详细/进度日志）
diagrams/   系统分析设计图（Mermaid × 16：用例/架构/ER/类图/状态/时序/DFD 等）
scripts/    数据库与运维脚本
```

## 课程设计文档索引

> 以下文档均基于课程模板文件（`.doc` / `.docx`）修改生成，保留模板封面、目录、标题样式与页脚格式；文档中图片已按模板要求以 `【插图位置】` 占位符标记。Word 版（`.docx`）可直接提交。

| 文档 | 内容 |
| --- | --- |
| [00_可行性研究报告.docx](docs/00_可行性研究报告.docx) | 技术/经济/操作/社会四维度可行性论证、方案对比、投资效益分析 |
| [00_项目范围说明书.docx](docs/00_项目范围说明书.docx) | 项目目标、工作范围（8 任务）、验收标准、假定与约束 |
| [02_需求规格说明书.docx](docs/02_需求规格说明书.docx) | 数据字典、FR-01~10、非功能需求 |
| [00_可行性研究报告.md](docs/00_可行性研究报告.md) | 上述 Word 文档的 Markdown 源文件 |
| [00_项目范围说明书.md](docs/00_项目范围说明书.md) | 上述 Word 文档的 Markdown 源文件 |
| [01_课程设计报告.md](docs/01_课程设计报告.md) | 前言/系统概述/系统分析/系统设计/系统实现/收获体会 |
| [02_需求规格说明书.md](docs/02_需求规格说明书.md) | 数据字典、FR-01~10、非功能需求 |
| [03_概要设计说明书.md](docs/03_概要设计说明书.md) | 四层架构、接口设计、ER/物理结构 |
| [04_详细设计说明书.md](docs/04_详细设计说明书.md) | 逐模块十要素、算法与测试要点 |
| [05_开发进度日志.md](docs/05_开发进度日志.md) | 28 项活动记录与工时统计 |

文档中的 `【插图位置】` 标记与 `diagrams/` 下 Mermaid 文件一一对应，终稿排版时渲染插入。

## 小组分工

| 成员 | 角色 | 职责 |
| --- | --- | --- |
| imicola | 组长 | 总体架构、数据库设计、CI/CD、代码审查与合并 |
| Glassous | 后端 | 认证与权限、用户与信用分模块 |
| DonGKids | 后端 | 预约核心、自动分配、候补与通知、统计 |
| hjsdjuhv8 | 前端 | 全部页面与交互实现 |
| polaris | 测试/文档 | 单元测试、需求文档、进度管理 |

## 许可证

[MIT](./LICENSE)
