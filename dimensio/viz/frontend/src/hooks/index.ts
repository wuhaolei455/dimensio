/**
 * Hooks 统一导出
 * 
 * 组合式 Hooks 架构：
 * - useCompressionData: 数据获取层
 * - useCompressionPipeline: 业务逻辑层
 * - useChartVisibility: 视图控制层
 * - useChartConfig: 图表配置层
 * - useLazyChart: 图表懒加载层
 * - useChunkedData: 大数据分片渲染层
 */

// 数据 Hooks
export { useCompressionData } from './useCompressionData';
export { useCompressionPipeline } from './useCompressionPipeline';
export { useChartVisibility } from './useChartVisibility';

// 图表配置 Hooks
export {
  useChartConfig,
  useBarChartConfig,
  useHorizontalBarConfig,
  useLineChartConfig,
  useHeatmapConfig,
  useParameterImportanceConfig,
  useDimensionReductionConfig,
  useCompressionRatioConfig,
  useDimensionEvolutionConfig,
  useMultiTaskHeatmapConfig,
} from './useChartConfig';

// 大数据优化 Hooks
export { useLazyChart } from './useLazyChart';
export { useChunkedData } from './useChunkedData';

// 类型重新导出
export type {
  UseCompressionDataReturn,
  UseCompressionPipelineReturn,
  UseChartVisibilityReturn,
  CompressionStats,
  ChartMockData,
  // 大数据优化 Hooks 类型
  UseLazyChartOptions,
  UseLazyChartReturn,
  UseChunkedDataOptions,
  UseChunkedDataReturn,
} from '../types';
