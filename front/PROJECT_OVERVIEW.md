# Dimensio Visualization Project - Complete Overview

## 项目结构

```
front/
├── package.json              # 项目依赖和脚本
├── webpack.config.js         # Webpack配置
├── tsconfig.json            # TypeScript配置
├── start.sh                 # 快速启动脚本
├── README.md                # 项目说明
├── public/
│   └── index.html          # HTML模板
└── src/
    ├── index.tsx           # 应用入口
    ├── App.tsx             # 主应用组件
    ├── App.css             # 全局样式
    ├── types/
    │   └── index.ts        # TypeScript类型定义（基于API schemas）
    ├── services/
    │   └── api.ts          # API服务（包含mock数据）
    └── components/
        ├── CompressionSummary.tsx        # 压缩总览（4面板）
        ├── RangeCompression.tsx          # 范围压缩可视化
        ├── ParameterImportance.tsx       # 参数重要度
        ├── DimensionEvolution.tsx        # 维度演化
        ├── MultiTaskHeatmap.tsx          # 多任务热力图
        └── SourceSimilarities.tsx        # 源任务相似度
```

## 已实现的图表

### 1. Compression Summary (压缩总览) ✅
**文件**: `CompressionSummary.tsx`
**功能**: 4面板展示
- Panel 1: 维度递减（柱状图）
- Panel 2: 压缩比率（柱状图）
- Panel 3: 范围压缩统计（堆叠柱状图）
- Panel 4: 文本摘要

**对应Python函数**: `visualize_compression_summary()`

### 2. Range Compression (范围压缩) ✅
**文件**: `RangeCompression.tsx`
**功能**: 水平条形图展示
- 原始参数范围（灰色半透明）
- 压缩后范围（彩色，根据压缩比着色）
- 归一化到[0,1]显示
- 支持量化参数的虚线样式

**对应Python函数**: `visualize_range_compression_step()`

### 3. Parameter Importance (参数重要度) ✅
**文件**: `ParameterImportance.tsx`
**功能**:
- Top-K参数重要度排名
- 水平柱状图
- 自动取绝对值并排序

**对应Python函数**: `visualize_parameter_importance()`

### 4. Dimension Evolution (维度演化) ✅
**文件**: `DimensionEvolution.tsx`
**功能**:
- 折线图展示迭代过程中的维度变化
- 标注维度变化点
- 虚线标记变化位置

**对应Python函数**: `visualize_adaptive_dimension_evolution()`

### 5. Multi-Task Heatmap (多任务热力图) ✅
**文件**: `MultiTaskHeatmap.tsx`
**功能**:
- 热力图展示多任务参数重要度
- 颜色映射（蓝-黄-红）
- 自动限制显示Top 30参数
- 支持悬停查看详细数值

**对应Python函数**: `visualize_importance_heatmap()`

### 6. Source Similarities (源任务相似度) ✅
**文件**: `SourceSimilarities.tsx`
**功能**:
- 柱状图展示源任务相似度
- 颜色编码（绿色=高相似度，红色=低相似度）
- 显示具体相似度分数

**对应Python函数**: `visualize_source_task_similarities()`

## 核心技术实现

### ECharts图表配置要点

1. **CompressionSummary**: 使用4个独立的ECharts实例，grid布局
2. **RangeCompression**: 使用custom系列渲染复杂的水平条形图
3. **所有图表**: 统一的tooltip、颜色方案、字体样式

### 数据流

```
Mock Data (api.ts)
    ↓
CompressionHistory Interface
    ↓
React Components
    ↓
ECharts Options
    ↓
ReactECharts Renderer
```

## 如何运行

### 方式1: 使用启动脚本
```bash
cd front
./start.sh
```

### 方式2: 直接运行
```bash
cd front
npm start
```

### 方式3: 生产构建
```bash
cd front
npm run build
# 构建产物在 dist/ 目录
```

## 连接真实API

项目已配置webpack代理，自动将`/api`请求转发到`http://127.0.0.1:5000`

1. 启动后端API服务器：
```bash
python -m api.server
```

2. 修改`src/services/api.ts`，取消注释真实API调用：
```typescript
async getCompressionHistory(): Promise<CompressionHistory> {
  // 使用真实API
  const response = await axios.get(`${API_BASE_URL}/experiments`);
  return response.data;
}
```

## 数据说明

当前使用的mock数据来自您提供的JSON：
- 12个原始参数 → 6个压缩参数
- 2个pipeline步骤：dimension_selection + range_compression
- 包含完整的compression_info数据

## 浏览器访问

启动后访问: http://localhost:3000

## 图表特性

✅ 响应式设计
✅ 交互式tooltip
✅ 颜色编码（压缩比、相似度等）
✅ 自动数据归一化
✅ 参数名称自动截断
✅ 支持大数据集（自动限制显示数量）

## 技术栈版本

- React: 18.2.0
- TypeScript: 5.3.3
- Webpack: 5.89.0
- ECharts: 5.4.3
- echarts-for-react: 3.0.2

## 与Python可视化的对应关系

| Python函数 | React组件 | ECharts图表类型 |
|-----------|----------|----------------|
| `visualize_compression_summary()` | `CompressionSummary.tsx` | bar (4个) |
| `visualize_range_compression_step()` | `RangeCompression.tsx` | custom |
| `visualize_parameter_importance()` | `ParameterImportance.tsx` | bar |
| `visualize_adaptive_dimension_evolution()` | `DimensionEvolution.tsx` | line |
| `visualize_importance_heatmap()` | `MultiTaskHeatmap.tsx` | heatmap |
| `visualize_source_task_similarities()` | `SourceSimilarities.tsx` | bar |

## 下一步可扩展功能

- [ ] 实验选择下拉框（从API获取实验列表）
- [ ] 导出图表为PNG
- [ ] 实时数据更新
- [ ] 图表交互联动
- [ ] 自定义颜色主题
- [ ] 策略对比图（adaptive_strategies_comparison）
