/**
 * TypeScript interfaces based on API schemas
 */

export enum EventType {
  INITIAL_COMPRESSION = 'initial_compression',
  ADAPTIVE_UPDATE = 'adaptive_update',
  PROGRESSIVE_COMPRESSION = 'progressive_compression',
}

export enum SpaceType {
  ORIGINAL = 'original',
  SAMPLE = 'sample',
  SURROGATE = 'surrogate',
}

export interface Space {
  n_parameters: number;
  parameters: string[];
  space_type?: SpaceType;
}

export interface SpaceSnapshot {
  original: Space;
  sample: Space;
  surrogate: Space;
}

export interface ParameterCompression {
  name: string;
  type: string;
  original_range: number[];
  compressed_range: number[];
  compression_ratio: number;
  original_num_values?: number;
  quantized_num_values?: number;
}

export interface CompressionInfo {
  compressed_params: ParameterCompression[];
  unchanged_params: string[];
  avg_compression_ratio: number;
}

export interface PipelineStep {
  name: string;
  type: string;
  step_index: number;
  input_space_params: number;
  output_space_params: number;
  supports_adaptive_update: boolean;
  uses_progressive_compression: boolean;
  compression_ratio?: number;
  compression_info?: CompressionInfo;
  selected_parameters?: string[];
  selected_indices?: number[];
  calculator?: string;
  topk?: number;
  top_ratio?: number;
  sigma?: number;
  enable_mixed_sampling?: boolean;
  initial_prob?: number;
}

export interface Pipeline {
  n_steps: number;
  steps: PipelineStep[];
  sampling_strategy?: string;
}

export interface PerformanceMetrics {
  multi_task_importances?: number[][]; // [n_tasks, n_params]
  task_names?: string[];
  source_similarities?: Record<string, number>; // {task_id: similarity}
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
  update_reason?: string;
  performance_metrics?: PerformanceMetrics;
}

export interface CompressionHistory {
  total_updates: number;
  history: CompressionEvent[];
}

// Chart data types
export interface DimensionData {
  stepName: string;
  dimension: number;
}

export interface CompressionRatioData {
  stepName: string;
  ratio: number;
}

export interface RangeCompressionData {
  paramName: string;
  originalMin: number;
  originalMax: number;
  compressedMin: number;
  compressedMax: number;
  compressionRatio: number;
  isQuantization: boolean;
  label: string;
}

export interface ParameterImportanceData {
  paramName: string;
  importance: number;
}

export interface DimensionEvolutionData {
  iteration: number;
  dimension: number;
}

export interface SourceSimilarityData {
  taskName: string;
  similarity: number;
}

/**
 * useCompressionData Hook 返回类型
 */
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

/**
 * 压缩统计信息
 */
export interface CompressionStats {
  /** 原始维度 */
  originalDim: number;
  /** 最终维度 */
  finalDim: number;
  /** 压缩比 */
  ratio: number;
  /** 有效步骤数 */
  stepCount: number;
  /** 各步骤维度变化 */
  dimensionFlow: number[];
}

/**
 * useCompressionPipeline Hook 返回类型
 */
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

/**
 * 图表可见性配置
 */
export interface ChartVisibility {
  /** 显示参数重要性图表 */
  showParameterImportance: boolean;
  /** 显示维度演化图表 */
  showDimensionEvolution: boolean;
  /** 显示多任务热力图 */
  showMultiTaskHeatmap: boolean;
  /** 显示源任务相似度图表 */
  showSourceSimilarities: boolean;
  /** 显示范围压缩图表 */
  showRangeCompression: boolean;
  /** 需要显示范围压缩的步骤 */
  rangeCompressionSteps: PipelineStep[];
}

/**
 * 图表数据（真实或模拟）
 */
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

/**
 * useChartVisibility Hook 返回类型
 */
export interface UseChartVisibilityReturn extends ChartVisibility {
  /** 图表所需的数据（真实或模拟） */
  chartData: ChartMockData;
}
