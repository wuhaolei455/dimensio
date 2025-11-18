# Dimensio可视化 - 快速启动指南

## 🚀 30秒快速开始

### 方式1：使用真实API数据（推荐）

```bash
# Terminal 1: 启动后端API（在项目根目录）
python -m api.server

# Terminal 2: 启动前端（在front目录）
cd front
npm start
```

浏览器会自动打开 http://localhost:3000

### 方式2：仅前端（使用mock数据）

```bash
cd front
npm start
```

## 📋 前置要求

### 首次运行需要安装依赖
```bash
cd front
npm install
```

## 🔧 API配置说明

### 默认配置
前端已配置为使用真实API：
- API地址: `http://127.0.0.1:5000/api`
- Webpack代理自动转发请求
- 自动获取实验列表并加载第一个实验的数据

### API工作流程
```
前端启动
    ↓
GET /api/experiments → 获取实验列表
    ↓
选择第一个实验 (experiment_id)
    ↓
GET /api/experiments/{id}/history → 获取压缩历史
    ↓
解析数据并渲染6个图表
```

### 智能Fallback
如果API不可用：
- ✅ 自动切换到mock数据
- ✅ 在控制台显示警告
- ✅ 所有功能正常工作

## 🧪 测试API连接

```bash
cd front
./test-api.sh
```

这个脚本会测试：
- ✓ API服务器是否运行
- ✓ `/api/experiments` 端点
- ✓ `/api/experiments/{id}/history` 端点
- ✓ `/api/experiments/{id}/visualizations` 端点

## 📊 查看效果

启动后你会看到6个图表：

1. **Compression Summary** - 4面板压缩总览
2. **Range Compression** - 参数范围压缩详情
3. **Parameter Importance** - Top-20参数重要度
4. **Dimension Evolution** - 维度演化趋势
5. **Multi-Task Heatmap** - 多任务重要度热力图
6. **Source Similarities** - 源任务相似度

## 🎨 使用自己的数据

### 运行examples生成数据
```bash
# 在项目根目录
cd examples
python basic_usage.py
# 或其他example脚本
```

数据会保存在 `examples/results/` 目录，API会自动发现。

### 数据格式
确保 `compression_history.json` 包含：
```json
{
  "total_updates": 1,
  "history": [
    {
      "timestamp": "...",
      "event": "initial_compression",
      "spaces": { "original": {...}, "sample": {...}, "surrogate": {...} },
      "pipeline": { "steps": [...] },
      "compression_ratios": {...}
    }
  ]
}
```

## 🐛 常见问题

### Q: 前端启动后显示"Error loading data"
**A**: 检查后端API是否启动：
```bash
curl http://127.0.0.1:5000/api/experiments
```

### Q: 图表不显示
**A**:
1. 打开浏览器控制台查看错误
2. 确认API返回的数据格式正确
3. 检查 `compression_info` 字段是否存在

### Q: 端口被占用
**A**: 修改 `webpack.config.js` 中的 `port`:
```javascript
devServer: {
  port: 3001, // 改为其他端口
  ...
}
```

### Q: TypeScript报错
**A**:
```bash
cd front
npm install
```

## 📁 项目结构

```
front/
├── src/
│   ├── components/        # 6个图表组件
│   ├── services/
│   │   └── api.ts        # API服务（已配置使用真实API）
│   ├── types/            # TypeScript类型定义
│   ├── App.tsx           # 主应用
│   └── index.tsx         # 入口
├── package.json          # 依赖
├── webpack.config.js     # Webpack配置（含API代理）
└── tsconfig.json         # TypeScript配置
```

## 🔗 相关资源

- **API文档**: 启动API后访问 http://127.0.0.1:5000/
- **项目文档**:
  - `README.md` - 项目说明
  - `SUMMARY.md` - 完整功能总结
  - `USAGE_GUIDE.md` - 详细使用指南
  - `PROJECT_OVERVIEW.md` - 项目结构

## ✨ 核心特性

- ✅ 使用真实API数据（默认）
- ✅ 自动实验发现和加载
- ✅ 智能fallback到mock数据
- ✅ 6个完整的ECharts可视化
- ✅ 完整的TypeScript类型系统
- ✅ 响应式设计
- ✅ 实时热重载

## 🎯 下一步

1. **查看示例数据**: 运行 `python examples/basic_usage.py`
2. **启动后端**: `python -m api.server`
3. **启动前端**: `cd front && npm start`
4. **浏览图表**: http://localhost:3000

---

**问题反馈**: 查看浏览器控制台和终端输出获取详细错误信息
