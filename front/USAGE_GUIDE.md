# Dimensio前端可视化使用指南

## 🚀 快速开始

### 1. 安装依赖（首次运行）
```bash
cd front
npm install
```

### 2. 启动开发服务器
```bash
npm start
# 或
./start.sh
```

浏览器会自动打开 http://localhost:3000

## 📊 图表说明

### Compression Summary (压缩总览)
显示4个关键指标面板：
1. **维度递减图**: 展示每个压缩步骤后的参数数量变化
2. **压缩比率图**: 每个步骤的压缩比率（相对于原始空间）
3. **范围压缩统计**: 被压缩和未改变的参数数量
4. **文本摘要**: 详细的压缩信息文本

### Range Compression (范围压缩)
- 水平条形图展示每个参数的范围压缩情况
- **灰色条**: 原始参数范围（归一化到0-1）
- **彩色条**: 压缩后的范围
  - 🟢 绿色: 压缩率 < 50%（压缩效果好）
  - 🟡 黄色: 压缩率 50-70%（中等压缩）
  - 🟠 橙色: 压缩率 70-90%（轻微压缩）
  - 🔴 红色: 压缩率 > 90%（几乎未压缩）
- 条形图下方显示压缩后的具体范围值

### Parameter Importance (参数重要度)
- Top-20最重要参数排名
- 横向柱状图，值越大越重要
- 基于SHAP或其他重要度计算方法

### Dimension Evolution (维度演化)
- 折线图展示自适应优化过程中维度的变化
- 红色虚线标记维度发生变化的迭代点
- 数据点标签显示具体维度值

### Multi-Task Heatmap (多任务热力图)
- 热力图展示不同任务中各参数的重要度
- **颜色编码**:
  - 🔵 蓝色: 重要度低
  - 🟡 黄色: 重要度中等
  - 🔴 红色: 重要度高
- 自动选择平均重要度最高的30个参数显示

### Source Similarities (源任务相似度)
- 柱状图显示源任务与目标任务的相似度
- **颜色编码**:
  - 🟢 绿色: 相似度 > 0.7（高度相似）
  - 🟡 黄色: 相似度 0.4-0.7（中等相似）
  - 🔴 红色: 相似度 < 0.4（低相似度）

## 🔧 开发说明

### 目录结构
```
src/
├── components/       # 所有图表组件
├── services/        # API服务
├── types/          # TypeScript类型定义
├── App.tsx         # 主应用
└── index.tsx       # 入口文件
```

### 修改Mock数据
编辑 `src/services/api.ts` 中的 `MOCK_DATA` 常量

### 连接真实API
1. 启动后端服务:
```bash
cd ..
python -m api.server
```

2. 在 `src/services/api.ts` 中修改:
```typescript
async getCompressionHistory(): Promise<CompressionHistory> {
  const response = await axios.get(`${API_BASE_URL}/experiments`);
  return response.data;
}
```

### 添加新图表
1. 在 `src/components/` 创建新组件
2. 在 `src/App.tsx` 中导入并使用
3. 确保组件接收正确的props类型

## 🎨 自定义样式

### 修改全局样式
编辑 `src/App.css`

### 修改图表颜色
在各组件的ECharts option中修改 `itemStyle.color` 或 `visualMap.inRange.color`

### 修改布局
在 `src/App.tsx` 中调整grid/section样式

## 📦 构建部署

### 生产构建
```bash
npm run build
```

构建产物在 `dist/` 目录，可直接部署到静态服务器。

### 构建优化
- 代码分割: 使用dynamic import
- Tree shaking: 自动删除未使用代码
- 压缩: Webpack自动压缩JS/CSS

## 🐛 常见问题

### Q: 图表不显示？
A: 检查浏览器控制台是否有错误，确认数据格式正确

### Q: 样式错乱？
A: 清除浏览器缓存，重新运行 `npm start`

### Q: API连接失败？
A: 确认后端服务已启动，检查webpack代理配置

### Q: TypeScript报错？
A: 运行 `npm install` 确保所有类型定义已安装

## 📚 相关资源

- [ECharts文档](https://echarts.apache.org/handbook/zh/get-started/)
- [React文档](https://react.dev/)
- [TypeScript文档](https://www.typescriptlang.org/docs/)
- [Webpack文档](https://webpack.js.org/concepts/)

## 🎯 核心ECharts配置示例

### 柱状图
```typescript
{
  type: 'bar',
  data: [...],
  itemStyle: { color: '#409EFF' },
  barMaxWidth: 50
}
```

### 折线图
```typescript
{
  type: 'line',
  data: [...],
  smooth: true,
  symbol: 'circle',
  symbolSize: 10
}
```

### 热力图
```typescript
{
  type: 'heatmap',
  data: [[x, y, value], ...],
  visualMap: {
    min: 0,
    max: 1,
    inRange: { color: ['blue', 'yellow', 'red'] }
  }
}
```

### 自定义渲染
```typescript
{
  type: 'custom',
  renderItem: (params, api) => ({
    type: 'rect',
    shape: { x, y, width, height },
    style: { fill: 'color' }
  })
}
```

## ✨ 项目亮点

✅ **完整的TypeScript类型系统**: 基于API schemas生成，保证类型安全
✅ **响应式设计**: 适配不同屏幕尺寸
✅ **模块化架构**: 每个图表独立组件，易于维护
✅ **ECharts深度定制**: 使用custom系列实现复杂可视化
✅ **Mock数据支持**: 无需后端即可开发测试
✅ **Webpack优化**: 代码分割、压缩、source map

## 🔄 数据流程

```
JSON Data
    ↓
parse_compression_history()
    ↓
CompressionHistory Interface
    ↓
React Components (props)
    ↓
ECharts Options
    ↓
ReactECharts (render)
    ↓
Interactive Charts
```

## 💡 最佳实践

1. **数据验证**: 使用TypeScript确保数据结构正确
2. **性能优化**: 大数据集自动限制显示数量（Top 30）
3. **错误处理**: 所有API调用都有try-catch
4. **代码复用**: 颜色映射、格式化函数可提取为utils
5. **可访问性**: 所有图表都有tooltip说明
