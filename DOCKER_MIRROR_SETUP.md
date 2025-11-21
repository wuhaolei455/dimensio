# Docker 镜像加速器配置指南

## 问题说明

Docker 构建时卡在 `load metadata` 阶段，原因：
1. 直接访问 Docker Hub (registry-1.docker.io) 在中国大陆网络受限
2. 之前的 Dockerfile 使用了 digest (@sha256:...) 强制从原始 registry 验证

## 解决方案

### 1. 配置 Docker Desktop 镜像加速器 (macOS/Windows)

#### macOS:
1. 打开 Docker Desktop
2. 点击右上角设置图标 (齿轮) → Settings
3. 进入 Docker Engine
4. 在 JSON 配置中添加以下内容：

```json
{
  "registry-mirrors": [
    "https://docker.1panel.live",
    "https://docker.1ms.run",
    "https://docker.nju.edu.cn",
    "https://docker.mirrors.sjtug.sjtu.edu.cn",
    "https://hub.rat.dev",
    "https://docker.m.daocloud.io",
    "https://dockerproxy.net",
    "https://docker.mirrors.ustc.edu.cn"
  ],
  "max-concurrent-downloads": 10,
  "max-concurrent-uploads": 5
}
```

5. 点击 "Apply & Restart" 重启 Docker
6. 等待 Docker 重启完成（右上角状态显示绿色）

#### Windows:
同样在 Docker Desktop → Settings → Docker Engine 中配置相同的 JSON。

### 2. 验证配置是否生效

```bash
docker info | grep -A 10 "Registry Mirrors"
```

应该能看到配置的镜像地址列表。

### 3. 测试构建

```bash
cd deploy/docker
docker-compose build
```

### 4. 额外优化（可选）

如果仍然遇到超时，可以尝试：

#### 方案 A: 预先拉取镜像
```bash
docker pull node:18-alpine
docker pull nginx:alpine
docker pull python:3.9-slim
```

#### 方案 B: 使用代理
如果有 HTTP 代理，可以在 Docker Engine 配置中添加：
```json
{
  "proxies": {
    "http-proxy": "http://proxy.example.com:8080",
    "https-proxy": "http://proxy.example.com:8080",
    "no-proxy": "localhost,127.0.0.1"
  }
}
```

#### 方案 C: 增加超时时间
在 docker-compose.yml 中添加构建参数：
```yaml
services:
  backend:
    build:
      context: ../..
      dockerfile: deploy/docker/Dockerfile.backend
      network: host  # 使用主机网络
```

### 5. 常见问题

#### Q: 镜像加速器配置后仍然超时？
A:
1. 确认 Docker Desktop 已完全重启
2. 尝试不同的镜像源（有些可能暂时不可用）
3. 检查本地网络是否稳定
4. 尝试使用 VPN 或代理

#### Q: 某个镜像源不可用怎么办？
A: Docker 会自动尝试列表中的下一个镜像源，保留多个镜像源可以提高成功率。

#### Q: 为什么之前使用 digest (@sha256:...) 会有问题？
A:
- digest 是镜像的内容哈希，用于精确版本控制
- 但它会强制 Docker 从原始 registry 验证
- 这会绕过镜像加速器，导致超时
- 对于国内网络，使用 tag (如 `nginx:alpine`) 更稳定

## 已完成的修改

✅ 已移除 Dockerfile 中的 digest 限制：
- `deploy/docker/Dockerfile.frontend` - 改用 `node:18-alpine` 和 `nginx:alpine`
- `deploy/docker/Dockerfile.backend` - 改用 `python:3.9-slim`

✅ 已创建镜像加速器配置文件：
- `~/.docker/daemon.json` (仅供参考，macOS 实际需在 Docker Desktop 中配置)

## 镜像源说明

使用的镜像源按优先级排列：
1. **docker.1panel.live** - 1Panel 镜像，速度快
2. **docker.1ms.run** - 毫秒镜像，低延迟
3. **docker.nju.edu.cn** - 南京大学镜像
4. **docker.mirrors.sjtug.sjtu.edu.cn** - 上海交大镜像
5. **hub.rat.dev** - 新兴镜像源
6. **docker.m.daocloud.io** - DaoCloud 镜像
7. **dockerproxy.net** - Docker Proxy
8. **docker.mirrors.ustc.edu.cn** - 中科大镜像

这些镜像源都是公开可用的，Docker 会按顺序尝试直到成功。
