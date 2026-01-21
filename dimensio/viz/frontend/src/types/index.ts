/**
 * 类型定义统一导出
 * 
 * 按领域拆分的类型文件：
 * - api.ts: API 响应相关类型
 * - pipeline.ts: 压缩管道相关类型
 * - chart.ts: 图表数据相关类型
 * - hooks.ts: Hook 返回类型
 */

// API 相关类型
export {
  EventType,
  SpaceType,
  type Space,
  type SpaceSnapshot,
  type PerformanceMetrics,
  type CompressionEvent,
  type CompressionHistory,
  type ApiResponse,
  type HealthCheckResponse,
  type UploadResponse,
} from './api';

// 管道相关类型
export {
  StepType,
  CalculatorType,
  isStepOfType,
  hasCalculator,
  type ParameterCompression,
  type CompressionInfo,
  type PipelineStep,
  type Pipeline,
} from './pipeline';

// 图表数据类型
export {
  type ChartVisibilityConfig,
} from './chart';

// Hook 返回类型
export {
  type UseCompressionDataReturn,
  type CompressionStats,
  type UseCompressionPipelineReturn,
  type ChartMockData,
  type RangeCompressionStepInfo,
  type UseChartVisibilityReturn,
  type UseChartConfigParams,
  type UseChartConfigReturn,
  // 大数据优化 Hooks 类型
  type UseLazyChartOptions,
  type UseLazyChartReturn,
  type UseChunkedDataOptions,
  type UseChunkedDataReturn,
} from './hooks';

// LazyChart 组件类型
export {
  type LazyChartProps,
  type ChartPlaceholderProps,
  type LoadingBarProps,
} from './lazyChart';

// ============================================
// 向后兼容的类型别名
// ============================================

// 保持旧的导出名称以兼容现有代码
export type { ChartVisibilityConfig as ChartVisibility } from './chart';
