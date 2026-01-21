/**
 * SourceSimilaritiesContainer - 容器组件
 * 
 * 结合 Hook 和展示组件，实现完全独立的源任务相似度可视化
 */

import React from 'react';
import { CompressionHistory } from '../../types';
import { useChartVisibility } from '../../hooks';
import SourceSimilarities from '../SourceSimilarities';

interface SourceSimilaritiesContainerProps {
  data: CompressionHistory;
}

/**
 * 源任务相似度容器组件
 * 
 * @example
 * ```tsx
 * <SourceSimilaritiesContainer data={compressionHistory} />
 * ```
 */
const SourceSimilaritiesContainer: React.FC<SourceSimilaritiesContainerProps> = ({ data }) => {
  const { showSourceSimilarities, chartData } = useChartVisibility(data);

  if (!showSourceSimilarities || !chartData.sourceSimilarities) {
    return null;
  }

  return (
    <section className="chart-section">
      <h2 className="section-title">Source Task Similarities</h2>
      <SourceSimilarities
        similarities={chartData.sourceSimilarities}
        taskNames={chartData.taskNames || undefined}
      />
    </section>
  );
};

export default SourceSimilaritiesContainer;
