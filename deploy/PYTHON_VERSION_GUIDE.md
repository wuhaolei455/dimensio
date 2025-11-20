# Python 版本选择指南

本文档帮助你选择合适的 Python 版本并完成部署。

## 🎯 推荐配置

### ⭐ 最佳选择: Python 3.8.20

```bash
✅ 推荐理由:
- 与所有科学计算库完美兼容
- 无 scipy/pythran 编译问题
- 稳定可靠，经过充分测试
- 所有依赖都有预编译包
```

**快速安装:**
```bash
cd deploy
sudo ./install-python38.sh
```

详细文档: [Python 3.8 使用指南](./PYTHON38.md)

---

## 📊 版本对比

| Python 版本 | 兼容性 | 性能 | 推荐度 | 说明 |
|------------|--------|------|--------|------|
| **3.8.20** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ✅ 强烈推荐 | 最佳选择，无兼容性问题 |
| 3.9.x | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ✅ 可以使用 | 兼容性好，推荐 |
| 3.10.x | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⚠️ 谨慎使用 | 需要从源码编译部分包 |
| 3.11.x | ⭐⭐ | ⭐⭐⭐⭐⭐ | ❌ 不推荐 | pythran 兼容性问题 |
| 3.12.x | ⭐ | ⭐⭐⭐⭐⭐ | ❌ 不推荐 | 部分库尚未适配 |
| 3.7.x | ⭐⭐⭐ | ⭐⭐⭐ | ⚠️ 即将 EOL | 即将停止支持 |

---

## 🚀 快速决策

### 场景 1: 全新部署

```bash
# 推荐方案: 使用 Python 3.8
cd deploy
sudo ./install-python38.sh
sudo ./fix-deps-py38.sh
sudo ./deploy.sh install
```

### 场景 2: 已有 Python 3.11

```bash
# 选项 A: 安装 Python 3.8（推荐）
sudo ./install-python38.sh

# 选项 B: 使用预编译包
cd deploy
sudo ./fix-scipy-pythran.sh

# 选项 C: Docker 部署（最简单）
cd deploy/docker
docker-compose up -d
```

### 场景 3: 已有 Python 3.10

```bash
# 可以直接使用，但建议先修复依赖
cd deploy
sudo ./fix-deps-py38.sh  # 会自动检测并使用 Python 3.10
```

### 场景 4: 已有 Python 3.9

```bash
# 完全兼容，直接部署
cd deploy
sudo ./deploy.sh install
```

---

## 🔧 安装方法对比

### 方法 1: 使用安装脚本（最简单）

```bash
cd deploy
sudo ./install-python38.sh
```

**优点**:
- ✅ 自动化，一键完成
- ✅ 自动检测系统类型
- ✅ 提供 PPA 和源码编译两种方式

**时间**: 5-20分钟（取决于选择的方式）

### 方法 2: 使用 PPA（Ubuntu）

```bash
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt update
sudo apt install -y python3.8 python3.8-venv python3.8-dev
```

**优点**:
- ✅ 快速（5分钟内）
- ✅ 自动更新
- ✅ 简单可靠

**限制**: 仅限 Ubuntu

### 方法 3: 从源码编译

```bash
# 查看 install-python38.sh 脚本
# 或参考 PYTHON38.md 文档
```

**优点**:
- ✅ 适用所有 Linux 发行版
- ✅ 可以自定义编译选项

**缺点**:
- ⏰ 耗时（10-20分钟）
- 📦 需要安装大量编译依赖

### 方法 4: 使用 Docker

```bash
cd deploy/docker
docker-compose up -d
```

**优点**:
- ✅ 零配置
- ✅ 环境隔离
- ✅ Python 版本已内置

**缺点**:
- 📦 需要安装 Docker

---

## ⚠️ 常见问题

### Q1: 我应该卸载现有的 Python 吗？

**A**: **不需要！** 可以同时安装多个 Python 版本：

```bash
python3 --version    # 系统默认
python3.8 --version  # 新安装的
python3.11 --version # 如果有的话
```

使用虚拟环境时指定版本即可：
```bash
python3.8 -m venv venv  # 使用 Python 3.8
```

### Q2: Python 3.8 会影响系统其他应用吗？

**A**: **不会！** 因为：
1. 我们使用 `altinstall` 安装，不覆盖系统 Python
2. 使用虚拟环境，完全隔离
3. 系统应用继续使用系统默认的 Python

### Q3: Python 3.8 安全吗？还有更新吗？

**A**:
- Python 3.8.20 是 Python 3.8 系列的最新版本
- 官方支持到 2024年10月
- PyPI 包会继续支持更久
- 对于生产环境，稳定性比最新版本更重要

### Q4: 我能用 Python 3.12 吗？

**A**: **不推荐**，因为：
- scipy 等库的适配还不完善
- 可能遇到各种兼容性问题
- 建议等待生态成熟后再升级

---

## 📝 部署检查清单

### 安装前检查

- [ ] 确定服务器操作系统版本
- [ ] 检查当前 Python 版本: `python3 --version`
- [ ] 确认有 sudo 权限
- [ ] 网络连接正常

### 安装步骤

- [ ] 安装 Python 3.8: `sudo ./install-python38.sh`
- [ ] 验证安装: `python3.8 --version`
- [ ] 修复依赖: `sudo ./fix-deps-py38.sh`
- [ ] 执行部署: `sudo ./deploy.sh install`

### 部署后验证

- [ ] 服务状态正常: `sudo ./deploy.sh status`
- [ ] Python 版本正确: `source /var/www/dimensio/venv/bin/activate && python --version`
- [ ] 依赖导入成功: `python -c "import numpy, scipy, sklearn"`
- [ ] API 响应正常: `curl http://localhost:5000/`
- [ ] 前端访问正常: 浏览器访问 `http://your-domain.com`

---

## 🆘 遇到问题？

### 1. Python 安装失败

查看: [PYTHON38.md](./PYTHON38.md) - Python 3.8 详细安装指南

### 2. 依赖安装失败

查看: [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) - 完整故障排查文档

### 3. 编译错误

使用修复脚本:
```bash
cd deploy
sudo ./fix-deps-py38.sh
```

### 4. 仍然无法解决

使用 Docker 部署:
```bash
cd deploy/docker
docker-compose up -d
```

---

## 📚 相关文档

- **[PYTHON38.md](./PYTHON38.md)** - Python 3.8 详细使用指南
- **[README.md](./README.md)** - 完整部署文档
- **[QUICKSTART.md](./QUICKSTART.md)** - 快速开始指南
- **[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)** - 故障排查文档
- **[INDEX.md](./INDEX.md)** - 文档索引

---

## 🎓 总结

1. **最佳选择**: Python 3.8.20
2. **安装方式**: 使用 `install-python38.sh` 脚本
3. **部署流程**: 安装 Python → 修复依赖 → 执行部署
4. **备用方案**: Docker 部署（零配置）

**推荐命令序列**:
```bash
cd /path/to/dimensio/deploy

# 1. 安装 Python 3.8
sudo ./install-python38.sh

# 2. 修复依赖
sudo ./fix-deps-py38.sh

# 3. 配置环境
cp .env.example .env
nano .env  # 修改 SERVER_NAME

# 4. 部署
sudo ./deploy.sh install

# 5. 验证
sudo ./deploy.sh status
```

**祝你部署顺利！** 🚀
