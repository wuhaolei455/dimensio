/**
 * DimensionEvolutionContainer - 容器组件
 * 
 * 结合 Hook 和展示组件，实现完全独立的维度演化可视化
 */

import React from 'react';
import { CompressionHistory } from '../../types';
import { useChartVisibility } from '../../hooks';
import DimensionEvolution from '../DimensionEvolution';

interface DimensionEvolutionContainerProps {
  data: CompressionHistory;
}

/**
 * 维度演化容器组件
 * 
 * @example
 * ```tsx
 * <DimensionEvolutionContainer data={compressionHistory} />
 * ```
 */
const DimensionEvolutionContainer: React.FC<DimensionEvolutionContainerProps> = ({ data }) => {
  const { showDimensionEvolution, chartData } = useChartVisibility(data);

  if (!showDimensionEvolution || !chartData.iterations || !chartData.dimensions) {
    return null;
  }

  return (
    <section className="chart-section">
      <h2 className="section-title">Dimension Evolution Over Iterations</h2>
      <DimensionEvolution
        iterations={chartData.iterations}
        dimensions={chartData.dimensions}
      />
    </section>
  );
};

export default DimensionEvolutionContainer;
