/**
 * Hooks 统一导出
 * 
 * 组合式 Hooks 架构：
 * - useCompressionData: 数据获取层
 * - useCompressionPipeline: 业务逻辑层
 * - useChartVisibility: 视图控制层
 * - useChartConfig: 图表配置层
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

// 类型重新导出
export type {
  UseCompressionDataReturn,
  UseCompressionPipelineReturn,
  UseChartVisibilityReturn,
  CompressionStats,
  ChartMockData,
} from '../types';
