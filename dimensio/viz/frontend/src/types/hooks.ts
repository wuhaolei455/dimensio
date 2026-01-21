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

// ============================================
// useLazyChart Hook 类型 (懒加载)
// ============================================

/** useLazyChart Hook 配置选项 */
export interface UseLazyChartOptions {
  /** 触发阈值，0.1 表示元素 10% 可见时触发 */
  threshold?: number;
  /** 根元素边距，用于提前加载 */
  rootMargin?: string;
  /** 可见时的回调函数 */
  onVisible?: () => void;
  /** 是否禁用懒加载（直接显示） */
  disabled?: boolean;
}

/** useLazyChart Hook 返回类型 */
export interface UseLazyChartReturn {
  /** 需要绑定到容器元素的 ref */
  ref: React.RefObject<HTMLDivElement>;
  /** 当前是否可见 */
  isVisible: boolean;
  /** 是否已经加载过（用于防止重复加载） */
  hasLoaded: boolean;
}

// ============================================
// useChunkedData Hook 类型 (分片渲染)
// ============================================

/** useChunkedData Hook 配置选项 */
export interface UseChunkedDataOptions {
  /** 每次渲染的数据块大小 */
  chunkSize?: number;
  /** 是否启用分片加载（数据量小时可禁用） */
  enabled?: boolean;
  /** 数据量阈值，小于此值时禁用分片 */
  threshold?: number;
  /** 渲染完成回调 */
  onComplete?: () => void;
  /** requestIdleCallback 超时时间(ms) */
  idleTimeout?: number;
}

/** useChunkedData Hook 返回类型 */
export interface UseChunkedDataReturn<T> {
  /** 当前已渲染的数据 */
  displayData: T[];
  /** 渲染进度 (0-100) */
  progress: number;
  /** 是否渲染完成 */
  isComplete: boolean;
  /** 是否正在加载 */
  isLoading: boolean;
  /** 重置并重新开始加载 */
  reset: () => void;
}
