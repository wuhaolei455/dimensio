/**
 * Hook 返回类型定义
 * 
 * 定义各个自定义 Hook 的返回值类型
 */

import type { CompressionHistory, CompressionEvent } from './api';
import type { Pipeline, PipelineStep } from './pipeline';
import type { ChartVisibilityConfig } from './chart';

// ============================================
// useCompressionData Hook 类型
// ============================================

/** useCompressionData Hook 返回类型 */
export interface UseCompressionDataReturn {
  /** 压缩历史数据 */
  data: CompressionHistory | null;
  /** 是否正在加载 */
  isLoading: boolean;
  /** 错误信息 */
  error: string | null;
  /** 手动刷新数据 */
  refetch: () => Promise<void>;
  /** 是否有数据 */
  hasData: boolean;
}

// ============================================
// useCompressionPipeline Hook 类型
// ============================================

/** 压缩统计信息 */
export interface CompressionStats {
  /** 原始维度 */
  originalDim: number;
  /** 最终维度 */
  finalDim: number;
  /** 压缩比 */
  ratio: number;
  /** 有效步骤数 */
  stepCount: number;
  /** 各步骤维度变化 [original, step1_output, step2_output, ...] */
  dimensionFlow: number[];
}

/** useCompressionPipeline Hook 返回类型 */
export interface UseCompressionPipelineReturn {
  /** 当前事件（最新的压缩记录） */
  event: CompressionEvent | null;
  /** 管道配置 */
  pipeline: Pipeline | null;
  /** 过滤后的有效步骤 */
  activeSteps: PipelineStep[];
  /** 检查是否包含指定类型的步骤 */
  hasStepType: (typePrefix: string) => boolean;
  /** 获取压缩统计信息 */
  getCompressionStats: () => CompressionStats | null;
  /** 是否使用 SHAP 维度选择 */
  hasSHAP: boolean;
  /** 是否使用相关性维度选择 */
  hasCorrelation: boolean;
  /** 是否使用自适应维度选择 */
  hasAdaptive: boolean;
  /** 是否有基于重要性的维度选择 */
  hasImportanceBasedDimension: boolean;
  /** 获取带有计算器的维度步骤 */
  dimensionStepWithCalculator: PipelineStep | undefined;
}

// ============================================
// useChartVisibility Hook 类型
// ============================================

/** 图表模拟数据 */
export interface ChartMockData {
  /** 模拟的参数重要性数据 */
  paramImportances: number[] | null;
  /** 模拟的迭代数据 */
  iterations: number[] | null;
  /** 模拟的维度数据 */
  dimensions: number[] | null;
  /** 多任务重要性数据 */
  multiTaskImportances: number[][] | null;
  /** 任务名称 */
  taskNames: string[] | null;
  /** 源任务相似度 */
  sourceSimilarities: Record<string, number> | null;
}

/** 需要显示范围压缩的步骤信息 */
export interface RangeCompressionStepInfo {
  step: PipelineStep;
  index: number;
}

/** useChartVisibility Hook 返回类型 */
export interface UseChartVisibilityReturn extends ChartVisibilityConfig {
  /** 图表所需的数据（真实或模拟） */
  chartData: ChartMockData;
  /** 需要显示范围压缩的步骤列表 */
  rangeCompressionSteps: RangeCompressionStepInfo[];
}

// ============================================
// useChartConfig Hook 类型 (图表配置系统)
// ============================================

/** 图表配置 Hook 参数 */
export interface UseChartConfigParams<T = unknown> {
  /** 图表类型 */
  type: string;
  /** 图表数据 */
  data: T;
  /** 配置选项 */
  options?: Record<string, unknown>;
  /** 额外依赖项 */
  deps?: unknown[];
}

/** 图表配置 Hook 返回类型 */
export interface UseChartConfigReturn {
  /** ECharts 配置对象 */
  option: Record<string, unknown>;
  /** 图表尺寸 */
  dimensions: {
    width?: string | number;
    height: string | number;
  };
  /** 数据是否有效 */
  isValid: boolean;
  /** 错误信息 */
  error: string | null;
}
