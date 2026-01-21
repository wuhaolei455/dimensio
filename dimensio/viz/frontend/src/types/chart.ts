/**
 * 图表显示配置类型定义
 */

/** 图表可见性配置 */
export interface ChartVisibilityConfig {
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
}
