/**
 * useChartVisibility Hook
 * 
 * 根据数据内容决定哪些图表组件应该显示
 * 集中管理所有图表的显示/隐藏逻辑
 */

import { useMemo } from 'react';
import {
  CompressionHistory,
  ChartVisibility,
  ChartMockData,
  UseChartVisibilityReturn,
} from '../types';
import { useCompressionPipeline } from './useCompressionPipeline';

/**
 * 图表可见性控制 Hook
 * 
 * @param data - 压缩历史数据
 * @returns 图表可见性配置和数据
 * 
 * @example
 * ```tsx
 * const { showParameterImportance, chartData } = useChartVisibility(data);
 * 
 * {showParameterImportance && (
 *   <ParameterImportance importances={chartData.paramImportances} />
 * )}
 * ```
 */
export const useChartVisibility = (
  data: CompressionHistory | null
): UseChartVisibilityReturn => {
  const {
    event,
    activeSteps,
    hasImportanceBasedDimension,
    hasAdaptive,
    dimensionStepWithCalculator,
  } = useCompressionPipeline(data);

  // 检查是否有自适应更新历史
  const hasAdaptiveUpdateHistory = useMemo(() => {
    if (!data?.history) return false;
    return data.history.length > 1 &&
           data.history.some(e => e.event === 'adaptive_update');
  }, [data]);

  // 检查多任务数据
  const hasMultiTaskData = useMemo(() => {
    return event?.performance_metrics?.multi_task_importances !== undefined;
  }, [event]);

  // 检查迁移学习数据
  const hasTransferLearningData = useMemo(() => {
    return event?.performance_metrics?.source_similarities !== undefined;
  }, [event]);

  // 找出需要显示范围压缩的步骤
  const rangeCompressionSteps = useMemo(() => {
    return activeSteps.filter(step =>
      step.compression_info &&
      step.compression_info.compressed_params &&
      step.compression_info.compressed_params.length > 0
    );
  }, [activeSteps]);

  // 图表可见性配置
  const visibility = useMemo((): ChartVisibility => ({
    showParameterImportance: hasImportanceBasedDimension && !!dimensionStepWithCalculator,
    showDimensionEvolution: hasAdaptive && hasAdaptiveUpdateHistory,
    showMultiTaskHeatmap: hasMultiTaskData,
    showSourceSimilarities: hasTransferLearningData,
    showRangeCompression: rangeCompressionSteps.length > 0,
    rangeCompressionSteps,
  }), [
    hasImportanceBasedDimension,
    dimensionStepWithCalculator,
    hasAdaptive,
    hasAdaptiveUpdateHistory,
    hasMultiTaskData,
    hasTransferLearningData,
    rangeCompressionSteps,
  ]);

  // 准备图表数据（真实或模拟）
  const chartData = useMemo((): ChartMockData => {
    if (!event) {
      return {
        paramImportances: null,
        iterations: null,
        dimensions: null,
        multiTaskImportances: null,
        taskNames: null,
        sourceSimilarities: null,
      };
    }

    // 模拟参数重要性数据（仅当需要显示时）
    const paramImportances = visibility.showParameterImportance
      ? event.spaces.original.parameters.map((_, idx) => 0.1 + Math.random() * 0.9)
      : null;

    // 模拟维度演化数据（仅当需要显示时）
    const iterations = visibility.showDimensionEvolution
      ? [0, 10, 20, 30, 40, 50]
      : null;
    const dimensions = visibility.showDimensionEvolution
      ? [12, 12, 10, 8, 8, 6]
      : null;

    // 使用真实数据
    const multiTaskImportances = hasMultiTaskData
      ? event.performance_metrics!.multi_task_importances!
      : null;

    const taskNames = event.performance_metrics?.task_names ?? null;

    const sourceSimilarities = hasTransferLearningData
      ? event.performance_metrics!.source_similarities!
      : null;

    return {
      paramImportances,
      iterations,
      dimensions,
      multiTaskImportances,
      taskNames,
      sourceSimilarities,
    };
  }, [event, visibility, hasMultiTaskData, hasTransferLearningData]);

  return {
    ...visibility,
    chartData,
  };
};

export default useChartVisibility;
