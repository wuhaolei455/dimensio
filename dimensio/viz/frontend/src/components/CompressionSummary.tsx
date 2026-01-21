/**
 * CompressionSummary 组件
 * 
 * 重构后使用:
 * - useCompressionPipeline Hook 复用业务逻辑
 * - useDimensionReductionConfig / useCompressionRatioConfig 图表配置
 * 
 * 优化效果:
 * - 原代码: 316 行
 * - 重构后: ~180 行 (减少 ~43%)
 * - 图表配置使用 useMemo 缓存，FCP 优化
 */

import React, { useMemo } from 'react';
import ReactECharts from 'echarts-for-react';
import { CompressionHistory } from '../types';
import { useCompressionPipeline } from '../hooks';
import { 
  useDimensionReductionConfig, 
  useCompressionRatioConfig,
  useBarChartConfig,
  chartHeights,
} from '../charts';

interface CompressionSummaryProps {
  data: CompressionHistory;
}

const CompressionSummary: React.FC<CompressionSummaryProps> = ({ data }) => {
  // ✅ 复用 Hook - 业务逻辑
  const { event, activeSteps, getCompressionStats } = useCompressionPipeline(data);
  const stats = useMemo(() => getCompressionStats(), [getCompressionStats]);

  // ✅ 准备图表数据
  const stepNames = useMemo(() => 
    stats ? ['Original', ...activeSteps.map(s => s.name)] : null,
    [stats, activeSteps]
  );

  const compressionStepNames = useMemo(() =>
    activeSteps.map(s => s.name),
    [activeSteps]
  );

  const compressionRatios = useMemo(() => 
    stats ? stats.dimensionFlow.slice(1).map(dim => dim / stats.originalDim) : null,
    [stats]
  );

  // ✅ 使用图表配置 Hooks（自动 useMemo 缓存）
  const { option: dimReductionOption } = useDimensionReductionConfig(
    stepNames,
    stats?.dimensionFlow ?? null
  );

  const { option: ratioOption } = useCompressionRatioConfig(
    compressionStepNames,
    compressionRatios
  );

  // 范围压缩统计数据
  const rangeCompressionData = useMemo(() => {
    const compressionStep = activeSteps.find(s =>
      s.compression_info &&
      s.compression_info.compressed_params &&
      s.compression_info.compressed_params.length > 0
    );

    if (!compressionStep?.compression_info) return null;

    return {
      step: compressionStep,
      nCompressed: compressionStep.compression_info.compressed_params?.length || 0,
      nUnchanged: compressionStep.compression_info.unchanged_params?.length || 0,
    };
  }, [activeSteps]);

  // 范围压缩统计图表配置
  const { option: rangeStatsOption } = useBarChartConfig(
    rangeCompressionData ? {
      categories: [`Step ${rangeCompressionData.step.step_index + 1}\n${rangeCompressionData.step.name}`],
      values: [rangeCompressionData.nCompressed],
    } : null,
    {
      title: { text: 'Range/Quantization Compression Statistics' },
    }
  );

  // 文本摘要
  const getSummaryText = useMemo(() => {
    if (!event || !stats) return '';

    let text = `Compression Summary\n${'='.repeat(40)}\n\n`;
    text += `Original dimensions: ${stats.originalDim}\n`;
    text += `Final sample space: ${event.spaces.sample.n_parameters}\n`;
    text += `Final surrogate space: ${stats.finalDim}\n`;
    text += `Overall compression: ${(stats.ratio * 100).toFixed(1)}%\n\n`;
    text += `Active Steps: ${stats.stepCount}\n`;

    activeSteps.forEach((step, i) => {
      const inputDim = stats.dimensionFlow[i];
      const outputDim = stats.dimensionFlow[i + 1];
      const dimRatio = outputDim / inputDim;

      text += `${i + 1}. ${step.name}\n`;
      text += `   ${inputDim} → ${outputDim} (${(dimRatio * 100).toFixed(1)}%)\n`;

      if (step.compression_info?.avg_compression_ratio) {
        text += `   Effective: ${(step.compression_info.avg_compression_ratio * 100).toFixed(1)}%\n`;
      }
    });

    return text;
  }, [event, stats, activeSteps]);

  // 空状态
  if (!event || !stats) {
    return (
      <div style={{ width: '100%', background: '#fff', padding: '40px', borderRadius: '8px', textAlign: 'center' }}>
        <p style={{ color: '#999' }}>No compression data available</p>
      </div>
    );
  }

  return (
    <div style={{ width: '100%', background: '#fff', padding: '20px', borderRadius: '8px', marginBottom: '20px' }}>
      <h2 style={{ textAlign: 'center', marginBottom: '20px', fontSize: '20px', fontWeight: 'bold' }}>
        Compression Summary
      </h2>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
        {/* Panel 1: Dimension Reduction */}
        <div>
          <ReactECharts 
            option={dimReductionOption} 
            style={{ height: chartHeights.medium }}
            notMerge={true}
            lazyUpdate={true}
          />
        </div>
        
        {/* Panel 2: Compression Ratio */}
        <div>
          <ReactECharts 
            option={ratioOption} 
            style={{ height: chartHeights.medium }}
            notMerge={true}
            lazyUpdate={true}
          />
        </div>
        
        {/* Panel 3: Range Compression Stats */}
        <div>
          {rangeCompressionData ? (
            <ReactECharts 
              option={rangeStatsOption} 
              style={{ height: chartHeights.medium }}
              notMerge={true}
              lazyUpdate={true}
            />
          ) : (
            <div style={{ 
              height: chartHeights.medium, 
              display: 'flex', 
              alignItems: 'center', 
              justifyContent: 'center',
              background: '#fafafa',
              borderRadius: '4px',
            }}>
              <p style={{ color: '#999' }}>No range/quantization compression data</p>
            </div>
          )}
        </div>
        
        {/* Panel 4: Text Summary */}
        <div
          style={{
            padding: '20px',
            background: '#fffbf0',
            borderRadius: '8px',
            border: '1px solid #ffe58f',
            fontFamily: 'monospace',
            fontSize: '11px',
            whiteSpace: 'pre-wrap',
            overflowY: 'auto',
            height: chartHeights.medium,
          }}
        >
          {getSummaryText}
        </div>
      </div>
    </div>
  );
};

export default CompressionSummary;
