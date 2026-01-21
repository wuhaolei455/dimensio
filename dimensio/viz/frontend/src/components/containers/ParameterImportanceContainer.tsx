/**
 * ParameterImportanceContainer - 容器组件
 * 
 * 结合 Hook 和展示组件，实现完全独立的参数重要性可视化
 * 可以直接接收 CompressionHistory，无需父组件预处理
 */

import React from 'react';
import { CompressionHistory } from '../../types';
import { useCompressionPipeline, useChartVisibility } from '../../hooks';
import ParameterImportance from '../ParameterImportance';

interface ParameterImportanceContainerProps {
  data: CompressionHistory;
  /** 显示前 K 个参数，默认 20 */
  topK?: number;
}

/**
 * 参数重要性容器组件
 * 
 * @example
 * ```tsx
 * // 简单使用 - 自动判断是否显示
 * <ParameterImportanceContainer data={compressionHistory} />
 * 
 * // 自定义 topK
 * <ParameterImportanceContainer data={compressionHistory} topK={10} />
 * ```
 */
const ParameterImportanceContainer: React.FC<ParameterImportanceContainerProps> = ({
  data,
  topK = 20,
}) => {
  const { event } = useCompressionPipeline(data);
  const { showParameterImportance, chartData } = useChartVisibility(data);

  // 不满足显示条件
  if (!showParameterImportance || !chartData.paramImportances || !event) {
    return null;
  }

  return (
    <section className="chart-section">
      <h2 className="section-title">Parameter Importance Analysis</h2>
      <ParameterImportance
        paramNames={event.spaces.original.parameters}
        importances={chartData.paramImportances}
        topK={Math.min(topK, event.spaces.original.parameters.length)}
      />
    </section>
  );
};

export default ParameterImportanceContainer;
