# Docker 镜像 Digest 更新指南

## 为什么使用 Digest？

使用 `@sha256:xxx` digest 可以：
- ✅ **跳过元数据检查** - 不需要每次构建都访问 Docker Registry 获取元数据
- ✅ **加快构建速度** - 节省 15-20 秒的元数据加载时间
- ✅ **版本锁定** - 确保每次构建使用完全相同的基础镜像
- ✅ **提高安全性** - 防止镜像标签被恶意替换

## 当前使用的镜像版本

| 镜像 | Digest | 用途 |
|------|--------|------|
| `python:3.9-slim` | `sha256:5f0192a4f58a6ce99f732fe05e3b3d00f12ae62e183886bca3ebe3d202686c7f` | Backend 基础镜像 |
| `node:18-alpine` | `sha256:8d6421d663b4c28fd3ebc498332f249011d118945588d0a35cb9bc4b8ca09d9e` | Frontend 构建阶段 |
| `nginx:alpine` | `sha256:b3c656d55d7ad751196f21b7fd2e8d4da9cb430e32f646adcf92441b72f82b14` | Frontend 生产镜像 & Nginx 服务 |

## 如何更新 Digest

当你想升级到新版本的基础镜像时：

### 1. 拉取新版本镜像

```bash
docker pull python:3.9-slim
docker pull node:18-alpine
docker pull nginx:alpine
```

### 2. 获取镜像的 Digest

```bash
# 方法 1: 使用 docker inspect
docker inspect --format='{{index .RepoDigests 0}}' python:3.9-slim
docker inspect --format='{{index .RepoDigests 0}}' node:18-alpine
docker inspect --format='{{index .RepoDigests 0}}' nginx:alpine

# 方法 2: 使用 docker images
docker images --digests | grep python
docker images --digests | grep node
docker images --digests | grep nginx

# 方法 3: 从拉取输出中查看
# docker pull 输出中的 "Digest: sha256:xxxx" 就是你需要的
```

### 3. 更新 Dockerfile

将获取到的 digest 更新到对应的 Dockerfile：

**Dockerfile.backend:**
```dockerfile
FROM python:3.9-slim@sha256:新的digest值
```

**Dockerfile.frontend:**
```dockerfile
FROM node:18-alpine@sha256:新的digest值 as builder
...
FROM nginx:alpine@sha256:新的digest值
```

### 4. 测试构建

```bash
cd deploy/docker
docker compose build
```

## 注意事项

⚠️ **重要提示：**

1. **定期检查更新** - digest 锁定版本后不会自动更新，需要手动检查并更新安全补丁
2. **安全更新** - 建议每月检查一次基础镜像是否有安全更新
3. **兼容性测试** - 更新 digest 后务必测试应用是否正常运行
4. **记录变更** - 每次更新 digest 时在 git commit 中说明原因

## 自动化更新脚本

你可以使用以下脚本自动获取最新的 digest：

```bash
#!/bin/bash
# update-digests.sh

echo "获取最新的镜像 digest..."

echo ""
echo "python:3.9-slim:"
docker pull python:3.9-slim | grep Digest
docker inspect --format='{{index .RepoDigests 0}}' python:3.9-slim

echo ""
echo "node:18-alpine:"
docker pull node:18-alpine | grep Digest
docker inspect --format='{{index .RepoDigests 0}}' node:18-alpine

echo ""
echo "nginx:alpine:"
docker pull nginx:alpine | grep Digest
docker inspect --format='{{index .RepoDigests 0}}' nginx:alpine
```

## 回退到标签模式

如果需要回退到使用标签而不是 digest：

```dockerfile
# 将
FROM python:3.9-slim@sha256:xxx

# 改回
FROM python:3.9-slim
```

这样会在每次构建时检查最新版本，但构建速度会慢 15-20 秒。
