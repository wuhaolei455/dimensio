# 服务器端手动构建测试指南

## 🎯 目标

在服务器上手动构建前端，找出具体问题。

---

## 📋 步骤 1: 清理环境

```bash
# 进入前端目录
cd /root/dimensio/front

# 清理旧的构建产物和依赖
rm -rf node_modules dist package-lock.json

# 确认清理完成
ls -la
```

---

## 📋 步骤 2: 安装依赖

```bash
# 使用项目本地的 npm（避免系统全局冲突）
# 如果服务器有 npx，使用 npx
npm install --legacy-peer-deps

# 查看安装结果
echo "=== Checking installed packages ==="
ls -la node_modules/ | head -20

# 验证关键依赖
echo "=== Verifying key dependencies ==="
test -d node_modules/webpack && echo "✓ webpack installed" || echo "✗ webpack missing"
test -d node_modules/babel-loader && echo "✓ babel-loader installed" || echo "✗ babel-loader missing"
test -d node_modules/@babel/core && echo "✓ @babel/core installed" || echo "✗ @babel/core missing"
```

**预期输出：**
```
added 521 packages
✓ webpack installed
✓ babel-loader installed
✓ @babel/core installed
```

---

## 📋 步骤 3: 检查配置文件

```bash
# 查看 package.json 的 scripts 部分
echo "=== Package.json scripts ==="
cat package.json | grep -A 10 '"scripts"'

# 查看 webpack 配置
echo "=== Webpack config (first 50 lines) ==="
head -50 webpack.config.js

# 查看 babel 配置
echo "=== Babel config ==="
cat .babelrc
```

**预期输出：**
```json
"scripts": {
  "dev": "webpack serve --mode development",
  "build": "webpack --mode production",
  "start": "webpack serve --mode development --open"
}
```

---

## 📋 步骤 4: 手动运行 webpack（使用本地版本）

**重要：不要直接运行 `npm run build`，先用完整路径测试**

```bash
# 方法 1: 使用 npx（推荐，避免全局冲突）
echo "=== Building with npx (local webpack) ==="
npx webpack --mode production --config webpack.config.js

# 如果 npx 不可用，使用方法 2
```

```bash
# 方法 2: 使用本地 node_modules 的 webpack
echo "=== Building with local webpack binary ==="
./node_modules/.bin/webpack --mode production --config webpack.config.js
```

```bash
# 方法 3: 通过 npm run（但可能有冲突）
echo "=== Building with npm run ==="
npm run build
```

**如果构建成功，你会看到：**
```
asset bundle.xxxxxxxx.js 4.06 MiB [emitted] [immutable] (name: main)
asset index.html 363 bytes [emitted]
webpack 5.102.1 compiled successfully in 30000 ms
```

**如果失败，记录完整错误信息！**

---

## 📋 步骤 5: 验证构建产物

```bash
# 检查 dist 目录
echo "=== Checking build output ==="
ls -lh dist/

# 查看文件内容
echo "=== Files in dist ==="
find dist -type f -exec ls -lh {} \;

# 验证关键文件
test -f dist/index.html && echo "✓ index.html exists" || echo "✗ index.html missing"
test -f dist/bundle*.js && echo "✓ bundle.js exists" || echo "✗ bundle.js missing"

# 查看 index.html 内容
echo "=== index.html content ==="
cat dist/index.html
```

**预期输出：**
```
dist/
  bundle.8bca206f4b05a80f79a3.js  4.1M
  index.html                       363B

✓ index.html exists
✓ bundle.js exists
```

---

## 🔍 常见错误排查

### 错误 1: Cannot find module 'webpack-cli'

```
Error: Cannot find module './webpack-cli'
Require stack:
- /usr/share/nodejs/webpack-cli/bin/cli.js
```

**原因：** 使用了系统全局的 webpack

**解决：**
```bash
# 使用 npx 强制使用本地版本
npx webpack --mode production

# 或者指定完整路径
./node_modules/.bin/webpack --mode production
```

### 错误 2: Module not found: Error: Can't resolve 'react'

```
ERROR in ./src/index.tsx
Module not found: Error: Can't resolve 'react'
```

**原因：** 依赖安装不完整

**解决：**
```bash
# 重新安装
rm -rf node_modules
npm install --legacy-peer-deps

# 验证 react 已安装
ls -la node_modules/react
```

### 错误 3: babel-loader 错误

```
Module build failed (from ./node_modules/babel-loader/lib/index.js):
Error: Cannot find module '@babel/core'
```

**原因：** Babel 依赖缺失

**解决：**
```bash
# 检查 Babel 相关包
ls -la node_modules/@babel/

# 应该看到：
# @babel/core
# @babel/preset-env
# @babel/preset-react
# @babel/preset-typescript

# 如果缺失，重新安装
npm install @babel/core @babel/preset-env @babel/preset-react @babel/preset-typescript
```

### 错误 4: webpack 卡住不动

```
webpack --mode production
(no output for a long time)
```

**原因：** 可能是内存不足

**解决：**
```bash
# 增加 Node.js 内存
NODE_OPTIONS="--max-old-space-size=4096" npx webpack --mode production
```

---

## 📊 完整测试脚本

把上面所有命令整合成一个脚本：

```bash
#!/bin/bash
# test-frontend-build.sh

set -e

echo "=========================================="
echo "  Frontend Build Test"
echo "=========================================="
echo ""

cd /root/dimensio/front

echo "Step 1: Cleaning..."
rm -rf node_modules dist
echo "✓ Cleaned"
echo ""

echo "Step 2: Installing dependencies..."
npm install --legacy-peer-deps
echo "✓ Dependencies installed"
echo ""

echo "Step 3: Verifying dependencies..."
test -d node_modules/webpack && echo "✓ webpack" || echo "✗ webpack missing"
test -d node_modules/babel-loader && echo "✓ babel-loader" || echo "✗ babel-loader missing"
echo ""

echo "Step 4: Building (using npx)..."
npx webpack --mode production --config webpack.config.js
echo "✓ Build completed"
echo ""

echo "Step 5: Verifying output..."
ls -lh dist/
test -f dist/index.html && echo "✓ index.html" || echo "✗ index.html missing"
test -f dist/bundle*.js && echo "✓ bundle.js" || echo "✗ bundle.js missing"
echo ""

echo "=========================================="
echo "  ✓ Build Test Complete!"
echo "=========================================="
```

**使用方法：**
```bash
# 保存上面的脚本
cd /root/dimensio/deploy
cat > test-frontend-build.sh << 'EOF'
# (粘贴上面的脚本内容)
EOF

chmod +x test-frontend-build.sh
./test-frontend-build.sh
```

---

## 💡 如果手动构建成功

说明配置没问题，Docker 构建也应该能成功。

**接下来：**
```bash
# 回到 deploy 目录
cd /root/dimensio/deploy

# 使用 Docker 构建
cd docker
docker-compose build frontend --no-cache

# 应该成功！
```

---

## 💡 如果手动构建失败

**请记录以下信息：**

1. **失败的步骤：**
   - 是 npm install 失败？
   - 是 webpack 构建失败？
   - 还是验证失败？

2. **完整错误信息：**
   ```bash
   # 保存到文件
   npx webpack --mode production 2>&1 | tee /tmp/webpack-error.log
   ```

3. **环境信息：**
   ```bash
   node --version
   npm --version
   which node
   which npm
   ```

4. **依赖信息：**
   ```bash
   npm list webpack
   npm list babel-loader
   npm list @babel/core
   ```

**把这些信息发给我，我会帮你分析！**

---

## 🎯 总结

**执行顺序：**
```bash
cd /root/dimensio/front
rm -rf node_modules dist
npm install --legacy-peer-deps
npx webpack --mode production
ls -lh dist/
```

**成功标志：**
- ✅ dist/bundle.*.js (~4.1MB)
- ✅ dist/index.html (363B)
- ✅ 无错误信息

**失败时记录：**
- ❌ 哪一步失败
- ❌ 完整错误信息
- ❌ 环境信息

---

**现在在服务器上执行这些命令，告诉我结果！** 🚀
