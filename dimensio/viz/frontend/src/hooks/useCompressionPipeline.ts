/**
 * useCompressionPipeline Hook
 * 
 * 处理压缩管道相关的业务逻辑：
 * - 过滤有效步骤
 * - 检测步骤类型
 * - 计算压缩统计信息
 */

import { useMemo, useCallback } from 'react';
import {
  CompressionHistory,
  PipelineStep,
  CompressionStats,
  UseCompressionPipelineReturn,
} from '../types';

/**
 * 过滤有效的管道步骤
 * 排除：
 * - 名称包含 "none" 的步骤
 * - 不改变维度且没有压缩信息的投影步骤
 */
const filterActiveSteps = (
  steps: PipelineStep[],
  originalParams: number
): PipelineStep[] => {
  return steps.filter((step, index) => {
    // 获取输入维度
    const inputDim = index === 0
      ? originalParams
      : steps[index - 1].output_space_params;
    const outputDim = step.output_space_params;

    // 排除 "none" 步骤
    const isNoneStep = step.name.toLowerCase().includes('none') ||
                       step.name.toLowerCase() === 'nonecompressionstep';
    if (isNoneStep) return false;

    // 检查是否有压缩信息
    const hasCompressionInfo = step.compression_info &&
      (step.compression_info.compressed_params?.length > 0 ||
       step.compression_info.avg_compression_ratio !== undefined);

    // 投影步骤必须改变维度或有压缩信息
    const isProjectionStep = step.name.toLowerCase().includes('projection') ||
                             step.name.toLowerCase().includes('transformative') ||
                             step.type.toLowerCase().includes('projection');

    const isUselessProjection = isProjectionStep && inputDim === outputDim && !hasCompressionInfo;
    if (isUselessProjection) return false;

    // 保留有效输出维度的步骤
    return outputDim > 0;
  });
};

/**
 * 压缩管道处理 Hook
 * 
 * @param data - 压缩历史数据
 * @returns 处理后的管道信息和工具函数
 * 
 * @example
 * ```tsx
 * const { activeSteps, hasSHAP, getCompressionStats } = useCompressionPipeline(data);
 * 
 * const stats = getCompressionStats();
 * console.log(`压缩比: ${stats?.ratio}`);
 * ```
 */
export const useCompressionPipeline = (
  data: CompressionHistory | null
): UseCompressionPipelineReturn => {
  // 获取最新事件
  const event = useMemo(() => {
    if (!data?.history?.length) return null;
    return data.history[0];
  }, [data]);

  // 获取管道配置
  const pipeline = useMemo(() => event?.pipeline ?? null, [event]);

  // 过滤有效步骤
  const activeSteps = useMemo(() => {
    if (!pipeline?.steps || !event) return [];
    return filterActiveSteps(pipeline.steps, event.spaces.original.n_parameters);
  }, [pipeline, event]);

  // 检查步骤类型
  const hasStepType = useCallback((typePrefix: string): boolean => {
    return activeSteps.some(step =>
      step.type.toLowerCase().includes(typePrefix.toLowerCase())
    );
  }, [activeSteps]);

  // 预计算常用的步骤类型检查
  const hasSHAP = useMemo(() => {
    return hasStepType('SHAP') &&
           activeSteps.some(step => step.calculator?.includes('SHAP'));
  }, [hasStepType, activeSteps]);

  const hasCorrelation = useMemo(() => hasStepType('Correlation'), [hasStepType]);
  const hasAdaptive = useMemo(() => hasStepType('Adaptive'), [hasStepType]);

  const hasImportanceBasedDimension = useMemo(() => {
    return hasSHAP || hasCorrelation || hasAdaptive;
  }, [hasSHAP, hasCorrelation, hasAdaptive]);

  // 获取带有计算器的维度步骤
  const dimensionStepWithCalculator = useMemo(() => {
    return activeSteps.find(
      step => step.name === 'dimension_selection' && step.calculator
    );
  }, [activeSteps]);

  // 计算压缩统计信息
  const getCompressionStats = useCallback((): CompressionStats | null => {
    if (!event) return null;

    const originalDim = event.spaces.original.n_parameters;
    const finalDim = event.spaces.surrogate.n_parameters;
    
    // 构建维度流
    const dimensionFlow = [
      originalDim,
      ...activeSteps.map(s => s.output_space_params),
    ];

    return {
      originalDim,
      finalDim,
      ratio: event.compression_ratios.surrogate_to_original,
      stepCount: activeSteps.length,
      dimensionFlow,
    };
  }, [event, activeSteps]);

  return {
    event,
    pipeline,
    activeSteps,
    hasStepType,
    getCompressionStats,
    hasSHAP,
    hasCorrelation,
    hasAdaptive,
    hasImportanceBasedDimension,
    dimensionStepWithCalculator,
  };
};

export default useCompressionPipeline;
