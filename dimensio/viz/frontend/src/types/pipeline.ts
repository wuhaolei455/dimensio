/**
 * 压缩管道相关类型定义
 * 
 * 包含管道步骤、压缩信息等数据结构
 */

// ============================================
// 参数压缩信息
// ============================================

/** 单个参数的压缩信息 */
export interface ParameterCompression {
  /** 参数名称 */
  name: string;
  /** 参数类型 */
  type: string;
  /** 原始范围 [min, max] */
  original_range: number[];
  /** 压缩后范围 [min, max] */
  compressed_range: number[];
  /** 压缩比率 */
  compression_ratio: number;
  /** 原始值数量（用于离散参数） */
  original_num_values?: number;
  /** 量化后值数量 */
  quantized_num_values?: number;
}

/** 压缩信息汇总 */
export interface CompressionInfo {
  /** 被压缩的参数列表 */
  compressed_params: ParameterCompression[];
  /** 未变化的参数名称列表 */
  unchanged_params: string[];
  /** 平均压缩比率 */
  avg_compression_ratio: number;
}

// ============================================
// 管道步骤
// ============================================

/** 管道步骤配置 */
export interface PipelineStep {
  /** 步骤名称 */
  name: string;
  /** 步骤类型 */
  type: string;
  /** 步骤索引 */
  step_index: number;
  /** 输入空间参数数量 */
  input_space_params: number;
  /** 输出空间参数数量 */
  output_space_params: number;
  /** 是否支持自适应更新 */
  supports_adaptive_update: boolean;
  /** 是否使用渐进式压缩 */
  uses_progressive_compression: boolean;
  /** 压缩比率 */
  compression_ratio?: number;
  /** 压缩详细信息 */
  compression_info?: CompressionInfo;
  /** 选中的参数列表 */
  selected_parameters?: string[];
  /** 选中的参数索引 */
  selected_indices?: number[];
  /** 计算器类型（如 SHAP, Correlation） */
  calculator?: string;
  /** Top-K 参数数量 */
  topk?: number;
  /** Top 比例 */
  top_ratio?: number;
  /** Sigma 参数 */
  sigma?: number;
  /** 是否启用混合采样 */
  enable_mixed_sampling?: boolean;
  /** 初始概率 */
  initial_prob?: number;
}

/** 压缩管道配置 */
export interface Pipeline {
  /** 步骤数量 */
  n_steps: number;
  /** 步骤列表 */
  steps: PipelineStep[];
  /** 采样策略 */
  sampling_strategy?: string;
}

// ============================================
// 步骤类型判断辅助
// ============================================

/** 步骤类型枚举 */
export enum StepType {
  DIMENSION_SELECTION = 'dimension_selection',
  RANGE_COMPRESSION = 'range_compression',
  QUANTIZATION = 'quantization',
  PROJECTION = 'projection',
  NONE = 'none',
}

/** 计算器类型枚举 */
export enum CalculatorType {
  SHAP = 'SHAP',
  CORRELATION = 'Correlation',
  MUTUAL_INFO = 'MutualInfo',
  VARIANCE = 'Variance',
}

/** 判断步骤是否为指定类型 */
export function isStepOfType(step: PipelineStep, type: StepType): boolean {
  return step.type.toLowerCase().includes(type.toLowerCase()) ||
         step.name.toLowerCase().includes(type.toLowerCase());
}

/** 判断步骤是否使用指定计算器 */
export function hasCalculator(step: PipelineStep, calculator: CalculatorType): boolean {
  return step.calculator?.includes(calculator) ?? false;
}
