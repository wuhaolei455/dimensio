/**
 * API 响应相关类型定义
 * 
 * 包含与后端 API 交互的数据结构
 */

// ============================================
// 枚举类型
// ============================================

/** 压缩事件类型 */
export enum EventType {
  INITIAL_COMPRESSION = 'initial_compression',
  ADAPTIVE_UPDATE = 'adaptive_update',
  PROGRESSIVE_COMPRESSION = 'progressive_compression',
}

/** 空间类型 */
export enum SpaceType {
  ORIGINAL = 'original',
  SAMPLE = 'sample',
  SURROGATE = 'surrogate',
}

// ============================================
// 空间相关类型
// ============================================

/** 参数空间定义 */
export interface Space {
  /** 参数数量 */
  n_parameters: number;
  /** 参数名称列表 */
  parameters: string[];
  /** 空间类型 */
  space_type?: SpaceType;
}

/** 空间快照 - 包含三种空间的当前状态 */
export interface SpaceSnapshot {
  /** 原始空间 */
  original: Space;
  /** 采样空间 */
  sample: Space;
  /** 代理模型空间 */
  surrogate: Space;
}

// ============================================
// 性能指标
// ============================================

/** 性能指标数据 */
export interface PerformanceMetrics {
  /** 多任务参数重要性 [n_tasks, n_params] */
  multi_task_importances?: number[][];
  /** 任务名称列表 */
  task_names?: string[];
  /** 源任务相似度 {task_id: similarity} */
  source_similarities?: Record<string, number>;
}

// ============================================
// 压缩事件与历史
// ============================================

/** 压缩事件记录 */
export interface CompressionEvent {
  /** 时间戳 */
  timestamp: string;
  /** 事件类型 */
  event: EventType;
  /** 迭代次数 */
  iteration: number | null;
  /** 空间快照 */
  spaces: SpaceSnapshot;
  /** 压缩比率 */
  compression_ratios: {
    /** 采样空间相对原始空间的压缩比 */
    sample_to_original: number;
    /** 代理空间相对原始空间的压缩比 */
    surrogate_to_original: number;
  };
  /** 压缩管道配置 */
  pipeline: import('./pipeline').Pipeline;
  /** 更新原因 */
  update_reason?: string;
  /** 性能指标 */
  performance_metrics?: PerformanceMetrics;
}

/** 压缩历史记录 */
export interface CompressionHistory {
  /** 总更新次数 */
  total_updates: number;
  /** 历史事件列表 */
  history: CompressionEvent[];
}

// ============================================
// API 响应类型
// ============================================

/** API 通用响应结构 */
export interface ApiResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: string;
}

/** 健康检查响应 */
export interface HealthCheckResponse {
  status: 'healthy' | 'unhealthy';
  service: string;
  data_dir: string;
  timestamp: string;
}

/** 上传响应 */
export interface UploadResponse {
  success: boolean;
  message?: string;
  files_received?: string[];
  error?: string;
}
