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
  performance_metrics?: Record<string, any>;
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
