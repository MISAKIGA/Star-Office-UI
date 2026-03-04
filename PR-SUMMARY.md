# Star Office UI v1.1.0 - PR Summary

> 最近更新总结，用于提交 PR

---

## 📋 版本信息

- **版本**: v1.1.0
- **发布日期**: 2026-03

---

## ✨ 新增功能

### 1. Docker 部署支持

新增完整的 Docker 部署方案，一键启动：

```yaml
# docker-compose.yml
services:
  backend:
    build: .
    ports:
      - "5000:18791"
    volumes:
      # 挂载 memory 目录用于读取日记
      - /root/.openclaw/workspace/memory:/app/memory:ro
    environment:
      - API_TOKEN=${API_TOKEN}
      - ADMIN_TOKEN=${ADMIN_TOKEN}

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - ./frontend:/usr/share/nginx/html:ro
```

**部署方式**:
- ✅ Docker Compose 一键部署
- ✅ Docker Run 快速启动
- ✅ 预构建镜像 `msga/star-office-ui-backend:latest`

---

### 2. OpenClaw Plugin 集成

新增官方 OpenClaw 插件，实现 Agent 状态自动同步：

```json
// 配置 ~/.openclaw/openclaw.json
{
  "plugins": {
    "allow": ["star-office-plugin"],
    "entries": {
      "star-office-plugin": {
        "enabled": true,
        "config": {
          "apiUrl": "http://localhost:18791",
          "apiToken": "your-api-token",
          "agentId": "openclaw-main",
          "agentName": "Shinyi",
          "autoIdleSeconds": 300
        }
      }
    }
  }
}
```

**插件功能**:
- ✅ `onLoad` - 启动时显示"空闲"
- ✅ `beforeAgentStart` / `onAgentStart` - 自动显示"工作中"
- ✅ `onAgentEnd` - 结束显示"空闲"或"错误"
- ✅ `onAgentError` - 报错显示错误状态
- ✅ `onIdle` - 空闲时更新状态
- ⏱️ **自动空闲** - 超过超时自动切换空闲

---

### 3. 页面优化 - 日记功能

新增完整的日记展示功能：

| 功能 | 说明 |
|------|------|
| **昨日小记** | 自动读取 `memory/YYYY-MM-DD.md` |
| **今日日记** | 支持查看当天日记 |
| **切换功能** | 按钮切换昨日/今日 |
| **展开/收起** | 长内容可展开查看 |
| **Markdown 渲染** | 支持代码高亮、链接等 |

---

### 4. API Token 鉴权

新增完整的安全鉴权体系：

| Header | 用途 |
|--------|------|
| `X-API-Token` | 用户 API Token（读写状态） |
| `X-Admin-Token` | 管理员 Token（管理操作） |

**接口**:
- `POST /api/v1/admin/token/generate` - 生成 Token
- `GET /api/v1/admin/tokens` - 列出 Token
- `DELETE /api/v1/admin/token/<token>` - 撤销 Token

---

## 🎯 使用 OpenClaw 插件的好处

### 对比传统方式

| 维度 | 手动 set_state.py | OpenClaw Plugin |
|------|------------------|-----------------|
| **实时性** | 手动触发，有延迟 | ✅ 生命周期自动触发，秒级同步 |
| **准确性** | 容易忘记更新 | ✅ 状态来源权威，不会出错 |
| **自动化** | 需要定时任务/cron | ✅ 完全自动化，无需维护 |
| **可维护性** | 多处配置，容易遗漏 | ✅ 一次配置，永久生效 |
| **可靠性** | 脚本可能失败 | ✅ OpenClaw 原生集成，稳定可靠 |

### 核心优势

1. **实时同步**
   - Agent 启动 → 立即显示"工作中"
   - Agent 结束 → 立即显示"空闲"
   - Agent 报错 → 立即显示"错误"

2. **零手动操作**
   - 无需手动运行 `set_state.py`
   - 无需配置 cron 定时任务
   - 即插即用

3. **权威状态**
   - 状态来源为 OpenClaw 生命周期
   - 不会出现"忘记更新"的情况
   - 数据准确可靠

4. **自动空闲**
   - 支持配置自动空闲超时
   - Agent 长时间无活动自动切换"空闲"

---

## 📦 项目结构

```
star-office-ui/
├── backend/
│   ├── app.py              # Flask API (含 Token 鉴权)
│   ├── requirements.txt
│   └── plugins/            # 插件系统
├── frontend/
│   ├── index.html         # 主页面 (含日记功能)
│   ├── layout.js
│   └── assets/             # 像素素材
├── docs/
│   └── screenshots/
├── docker-compose.yml      # Docker 部署
├── Dockerfile              # 镜像构建
├── .env.example            # 环境变量模板
├── nginx.conf              # Nginx 配置
└── README.md               # 中英双语文档
```

---

## 🚀 快速开始

### Docker 部署（推荐）

```bash
# 1) 克隆
git clone https://github.com/MISAKIGA/Star-Office-UI.git
cd Star-Office-UI

# 2) 配置
cp .env.example .env
# 编辑 .env 填入 API_TOKEN 和 ADMIN_TOKEN

# 3) 启动
docker-compose up -d

# 4) 访问
# http://localhost:18791
```

### 使用 OpenClaw 插件

```bash
# 配置 ~/.openclaw/openclaw.json
# 添加插件配置（见上文）
# 重启 OpenClaw
```

---

## 📝 更新日志

### 2026-03 (v1.1.0)

- ✅ 新增 Docker Compose 部署
- ✅ 新增预构建镜像 `msga/star-office-ui-backend:latest`
- ✅ 新增 OpenClaw Plugin 自动状态同步
- ✅ 新增昨日/今日日记功能
- ✅ 新增 Markdown 渲染
- ✅ 新增 API Token 鉴权
- ✅ 新增 .env.example 环境变量
- ✅ 新增 GitHub Actions CI/CD
- ✅ 优化 README 中英双语支持

---

## 📄 License

- **代码**: MIT
- **美术资产**: 非商用
