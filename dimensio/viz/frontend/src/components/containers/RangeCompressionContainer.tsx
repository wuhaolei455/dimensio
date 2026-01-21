/**
 * RangeCompressionContainer - 容器组件
 * 
 * 结合 Hook 和展示组件，实现完全独立的范围压缩可视化
 * 可以直接接收 CompressionHistory，无需父组件预处理
 */

import React from 'react';
import { CompressionHistory } from '../../types';
import { useCompressionPipeline, useChartVisibility } from '../../hooks';
import RangeCompression from '../RangeCompression';

interface RangeCompressionContainerProps {
  data: CompressionHistory;
}

/**
 * 范围压缩容器组件
 * 
 * @example
 * ```tsx
 * // 简单使用 - 自动处理所有逻辑
 * <RangeCompressionContainer data={compressionHistory} />
 * ```
 */
const RangeCompressionContainer: React.FC<RangeCompressionContainerProps> = ({ data }) => {
  const { activeSteps } = useCompressionPipeline(data);
  const { rangeCompressionSteps } = useChartVisibility(data);

  if (rangeCompressionSteps.length === 0) {
    return null;
  }

  return (
    <>
      {rangeCompressionSteps.map(({ step, index }) => (
        <section key={`range-${index}`} className="chart-section">
          <RangeCompression
            step={step}
            stepIndex={index + 1}
          />
        </section>
      ))}
    </>
  );
};

export default RangeCompressionContainer;
