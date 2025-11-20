# 快速修复参考卡片

## 🚨 构建卡在 provenance（最常见问题）

**症状：** 卡在 `resolving provenance for metadata file`

**快速修复：**
```bash
cd /root/dimensio/deploy
sudo bash fix-build-stuck.sh
```

**或手动修复：**
```bash
cd /root/dimensio/deploy/docker
docker compose down

# 使用传统构建
cd /root/dimensio
docker build --network=host -f deploy/docker/Dockerfile.backend -t deploy-backend:latest .
docker build --network=host -f deploy/docker/Dockerfile.frontend -t deploy-frontend:latest .

cd deploy/docker
docker compose up -d
```

---

## 🐌 镜像拉取超时

**症状：** `dial tcp xxx:443: i/o timeout`

**快速修复：**
```bash
cd /root/dimensio/deploy
sudo bash fix-docker-registry.sh
```

---

## ❌ 端口被占用

**症状：** `bind: address already in use`

**快速修复：**
```bash
sudo lsof -i :80
sudo systemctl stop nginx
sudo systemctl stop apache2

cd /root/dimensio/deploy/docker
docker compose up -d
```

---

## 💾 磁盘空间不足

**症状：** `no space left on device`

**快速修复：**
```bash
docker system prune -a --volumes -f
rm -rf /root/dimensio/logs/*
```

---

## 🔍 查看日志

```bash
cd /root/dimensio/deploy/docker
docker compose logs -f
```

---

## 🔄 完全重置

```bash
cd /root/dimensio/deploy/docker
docker compose down -v
docker system prune -a -f

cd /root/dimensio/deploy
sudo bash deploy.sh
```

---

## 📞 查看详细文档

- 完整故障排除：`cat deploy/TROUBLESHOOTING.md`
- 部署文档：`cat deploy/README.md`
- 快速指南：`cat deploy/QUICKSTART.md`
