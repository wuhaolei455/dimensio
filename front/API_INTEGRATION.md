# API集成说明

## 概览

前端项目已完全配置为使用真实的后端API。本文档详细说明API集成方式和数据流。

## API服务配置

### 基础配置

**文件**: `src/services/api.ts`

```typescript
const API_BASE_URL = '/api';  // Webpack proxy会转发到 http://127.0.0.1:5000/api
```

### Webpack代理配置

**文件**: `webpack.config.js`

```javascript
devServer: {
  proxy: {
    '/api': {
      target: 'http://127.0.0.1:5000',
      changeOrigin: true,
    },
  },
}
```

这个配置确保：
- 前端请求 `/api/*` 会自动转发到 `http://127.0.0.1:5000/api/*`
- 避免CORS问题
- 开发环境和生产环境统一使用相对路径

## API端点使用

### 1. 获取实验列表

**端点**: `GET /api/experiments`

**使用**:
```typescript
const response = await apiService.getExperiments();
```

**返回格式**:
```json
{
  "success": true,
  "count": 3,
  "data": [
    {
      "experiment_id": "basic_usage/basic_compression",
      "name": "basic_compression",
      "category": "basic_usage",
      "total_updates": 1,
      "n_events": 1,
      "n_visualizations": 3,
      "created_at": "2025-11-18T01:23:34.536826",
      "last_modified": "2025-11-18T01:23:35.123456"
    }
  ]
}
```

### 2. 获取压缩历史（主要使用）

**端点**: `GET /api/experiments/{experiment_id}/history`

**使用**:
```typescript
const history = await apiService.getExperimentHistory('basic_usage/basic_compression');
```

**API返回格式**:
```json
{
  "success": true,
  "data": {
    "experiment_id": "basic_usage/basic_compression",
    "total_updates": 1,
    "n_events": 1,
    "events": [
      {
        "timestamp": "2025-11-18T01:23:34.536826",
        "event": "initial_compression",
        "iteration": null,
        "spaces": {
          "original": {
            "n_parameters": 12,
            "parameters": ["param1", "param2", ...]
          },
          "sample": { ... },
          "surrogate": { ... }
        },
        "compression_ratios": {
          "sample_to_original": 0.5,
          "surrogate_to_original": 0.5
        },
        "pipeline": {
          "n_steps": 2,
          "steps": [
            {
              "name": "dimension_selection",
              "type": "SHAPDimensionStep",
              "step_index": 0,
              "input_space_params": 12,
              "output_space_params": 6,
              "compression_ratio": 0.5,
              "selected_parameters": [...],
              ...
            },
            {
              "name": "range_compression",
              "type": "SHAPBoundaryRangeStep",
              "step_index": 1,
              "compression_info": {
                "compressed_params": [
                  {
                    "name": "param_name",
                    "type": "UniformFloatHyperparameter",
                    "original_range": [0.0, 1.0],
                    "compressed_range": [0.1, 0.9],
                    "compression_ratio": 0.8
                  }
                ],
                "unchanged_params": ["param2"],
                "avg_compression_ratio": 0.85
              }
            }
          ]
        }
      }
    ]
  }
}
```

**前端转换**:
```typescript
// API返回 { success, data: { events: [...] } }
// 转换为 CompressionHistory 格式
return {
  total_updates: historyData.total_updates,
  history: historyData.events
};
```

### 3. 自动加载（便捷方法）

**使用**:
```typescript
// 在 App.tsx 中
const history = await apiService.getCompressionHistory();
```

**工作流程**:
1. 调用 `GET /api/experiments` 获取实验列表
2. 自动选择第一个实验
3. 调用 `GET /api/experiments/{id}/history` 获取数据
4. 返回 `CompressionHistory` 对象

### 4. 获取可视化元数据

**端点**: `GET /api/experiments/{experiment_id}/visualizations`

**使用**:
```typescript
const vizData = await apiService.getVisualizations('basic_usage/basic_compression');
```

**返回格式**:
```json
{
  "success": true,
  "experiment_id": "basic_usage/basic_compression",
  "count": 3,
  "data": [
    {
      "filename": "compression_summary.png",
      "viz_type": "compression_summary",
      "step_index": null,
      "file_size": 123456,
      "created_at": "2025-11-18T01:23:35.123456",
      "url": "/api/experiments/basic_usage/basic_compression/visualizations/compression_summary.png"
    }
  ]
}
```

## 数据流程

```
用户打开前端 (http://localhost:3000)
    ↓
App.tsx useEffect 触发
    ↓
apiService.getCompressionHistory()
    ↓
[1] GET /api/experiments
    ↓ (webpack proxy)
    ↓
http://127.0.0.1:5000/api/experiments
    ↓
获取实验列表 { data: [{ experiment_id: "..." }] }
    ↓
[2] 选择第一个实验
    ↓
[3] GET /api/experiments/{id}/history
    ↓ (webpack proxy)
    ↓
http://127.0.0.1:5000/api/experiments/{id}/history
    ↓
获取压缩历史 { data: { events: [...] } }
    ↓
转换为 CompressionHistory 格式
    ↓
setState(data)
    ↓
React渲染6个图表组件
```

## 错误处理

### 三层错误处理

#### 1. API级别
```typescript
try {
  const response = await axios.get(...);
  if (response.data.success) {
    return response.data;
  }
  throw new Error('Invalid API response');
} catch (error) {
  console.error('Error:', error);
  return MOCK_DATA;  // Fallback
}
```

#### 2. 数据验证
```typescript
if (response.data.success && response.data.data) {
  const historyData = response.data.data;
  return {
    total_updates: historyData.total_updates,
    history: historyData.events || historyData.history || []
  };
}
```

#### 3. UI级别
```typescript
// App.tsx
if (error || !data) {
  return <div className="error">Error: {error}</div>;
}
```

### Fallback机制

**智能降级**:
- ✅ API可用 → 使用真实数据
- ⚠️ API不可用 → 自动使用mock数据
- 📝 控制台显示明确的警告信息

**Mock数据来源**:
```typescript
// src/services/api.ts
const MOCK_DATA: CompressionHistory = {
  // 您提供的示例JSON数据
  total_updates: 1,
  history: [...]
};
```

## TypeScript类型系统

### 核心接口（基于API schemas）

**文件**: `src/types/index.ts`

```typescript
export interface CompressionHistory {
  total_updates: number;
  history: CompressionEvent[];
}

export interface CompressionEvent {
  timestamp: string;
  event: EventType;
  iteration: number | null;
  spaces: SpaceSnapshot;
  compression_ratios: {
    sample_to_original: number;
    surrogate_to_original: number;
  };
  pipeline: Pipeline;
}

export interface Pipeline {
  n_steps: number;
  steps: PipelineStep[];
  sampling_strategy?: string;
}

export interface PipelineStep {
  name: string;
  type: string;
  step_index: number;
  input_space_params: number;
  output_space_params: number;
  compression_info?: CompressionInfo;
  // ... 其他字段
}

export interface CompressionInfo {
  compressed_params: ParameterCompression[];
  unchanged_params: string[];
  avg_compression_ratio: number;
}
```

**完全匹配Python schemas**:
- ✅ `api/schemas.py` 中的所有类
- ✅ 支持optional字段
- ✅ 嵌套结构完整

## 测试API连接

### 使用测试脚本

```bash
cd front
./test-api.sh
```

**测试内容**:
1. ✓ API服务器运行状态
2. ✓ `/api/experiments` 端点响应
3. ✓ 实验列表数据格式
4. ✓ `/api/experiments/{id}/history` 端点响应
5. ✓ 压缩历史数据格式
6. ✓ `/api/experiments/{id}/visualizations` 端点响应

### 手动测试

```bash
# 测试API服务器
curl http://127.0.0.1:5000/

# 测试实验列表
curl http://127.0.0.1:5000/api/experiments | python -m json.tool

# 测试压缩历史（替换experiment_id）
curl "http://127.0.0.1:5000/api/experiments/basic_usage/basic_compression/history" | python -m json.tool
```

## 生产环境配置

### 修改API地址

如果部署到生产环境，需要修改 `src/services/api.ts`:

```typescript
const API_BASE_URL = process.env.REACT_APP_API_URL || '/api';
```

然后创建 `.env` 文件:
```
REACT_APP_API_URL=https://your-api-server.com/api
```

### 构建和部署

```bash
# 构建
npm run build

# 部署 dist/ 目录到静态服务器
# 确保配置API代理或CORS
```

## 调试技巧

### 查看网络请求

1. 打开浏览器开发者工具 (F12)
2. 切换到 Network 标签
3. 筛选 XHR 请求
4. 查看请求/响应详情

### 查看控制台日志

API服务会打印详细日志：
```javascript
console.log(`Fetching history for experiment: ${experimentId}`);
console.warn('Using mock data as fallback');
console.error('Error fetching experiment history:', error);
```

## 常见问题

### Q: CORS错误
**A**: Webpack代理已配置，开发环境不应出现CORS问题。如果出现，检查：
- API服务器是否启动
- `webpack.config.js` 中的proxy配置
- API服务器是否启用了CORS (`flask_cors`)

### Q: 404错误
**A**:
- 确认实验ID正确
- 检查 `examples/results/` 目录是否有数据
- 验证API路由配置

### Q: 数据格式错误
**A**:
- 检查API返回的JSON格式
- 对比 `src/types/index.ts` 中的接口定义
- 查看控制台错误信息

## 参考文档

- **后端API**: `api/server.py`
- **数据模型**: `api/schemas.py`
- **TypeScript类型**: `src/types/index.ts`
- **API服务**: `src/services/api.ts`

---

**总结**: 前端已完全配置为使用真实API，支持自动实验发现、智能fallback和完整的错误处理。只需启动后端服务即可使用。
