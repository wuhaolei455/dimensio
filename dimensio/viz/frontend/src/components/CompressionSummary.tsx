import React from 'react';
import ReactECharts from 'echarts-for-react';
import { CompressionHistory } from '../types';

interface CompressionSummaryProps {
  data: CompressionHistory;
}

const CompressionSummary: React.FC<CompressionSummaryProps> = ({ data }) => {
  const event = data.history[0];
  const pipeline = event.pipeline;

  // Filter out steps that don't actually change dimensions or are placeholders
  // A valid step should have meaningful output and not be a "none" step
  const activeSteps = pipeline.steps.filter((step, index) => {
    // Get input dimension from previous step or original space
    const inputDim = index === 0
      ? event.spaces.original.n_parameters
      : pipeline.steps[index - 1].output_space_params;
    const outputDim = step.output_space_params;

    // Filter out steps with these characteristics:
    // 1. Contains "none" in name (obvious placeholder)
    const isNoneStep = step.name.toLowerCase().includes('none') ||
                       step.name.toLowerCase() === 'nonecompressionstep';

    // 2. Projection steps that don't change dimensions are useless
    //    BUT: Range compression steps can keep the same dimensions (they compress ranges, not dimensions)
    //    AND: Steps with compression_info are meaningful (they have actual compression data)
    const hasCompressionInfo = step.compression_info &&
                               (step.compression_info.compressed_params?.length > 0 ||
                                step.compression_info.avg_compression_ratio !== undefined);

    const isProjectionStep = step.name.toLowerCase().includes('projection') ||
                             step.name.toLowerCase().includes('transformative') ||
                             step.type.toLowerCase().includes('projection');

    // A step is useless if it's a projection that doesn't change dimensions AND doesn't have compression info
    const isUselessProjection = isProjectionStep && inputDim === outputDim && !hasCompressionInfo;

    // Keep steps that are:
    // - Not none steps
    // - Not useless projections
    // - Have valid output dimensions
    return !isNoneStep && !isUselessProjection && outputDim > 0;
  });

  // Panel 1: Dimension Reduction Across Steps
  const getDimensionReductionOption = () => {
    const stepNames = ['Original', ...activeSteps.map(s => s.name)];
    const dimensions = [
      event.spaces.original.n_parameters,
      ...activeSteps.map(s => s.output_space_params),
    ];

    return {
      title: {
        text: 'Dimension Reduction Across Steps',
        left: 'center',
        textStyle: { fontWeight: 'bold', fontSize: 14 },
      },
      tooltip: {
        trigger: 'axis',
        axisPointer: { type: 'shadow' },
      },
      xAxis: {
        type: 'category',
        data: stepNames,
        axisLabel: {
          rotate: 45,
          fontSize: 10,
          interval: 0,
          overflow: 'truncate',
          width: 80,
        },
      },
      yAxis: {
        type: 'value',
        name: 'Parameters',
        nameTextStyle: { fontWeight: 'bold' },
      },
      grid: { left: '12%', right: '8%', bottom: '25%', top: '15%' },
      series: [
        {
          type: 'bar',
          data: dimensions.map((dim, idx) => ({
            value: dim,
            itemStyle: {
              color: `rgba(64, 158, 255, ${0.4 + idx * 0.15})`,
            },
          })),
          label: {
            show: true,
            position: 'top',
            fontWeight: 'bold',
          },
          barMaxWidth: 50,
        },
      ],
    };
  };

  // Panel 2: Compression Ratio by Step
  const getCompressionRatioOption = () => {
    const dimensions = [
      event.spaces.original.n_parameters,
      ...activeSteps.map(s => s.output_space_params),
    ];
    const compressionRatios = dimensions.slice(1).map((dim, idx) => ({
      name: activeSteps[idx].name,
      ratio: dim / dimensions[0],
    }));

    return {
      title: {
        text: 'Compression Ratio by Step',
        left: 'center',
        textStyle: { fontWeight: 'bold', fontSize: 14 },
      },
      tooltip: {
        trigger: 'axis',
        axisPointer: { type: 'shadow' },
        formatter: (params: any) => {
          const data = params[0];
          return `${data.name}<br/>Ratio: ${(data.value * 100).toFixed(1)}%`;
        },
      },
      xAxis: {
        type: 'category',
        data: compressionRatios.map(r => r.name),
        axisLabel: {
          rotate: 45,
          fontSize: 10,
          interval: 0,
          overflow: 'truncate',
          width: 80,
        },
      },
      yAxis: {
        type: 'value',
        name: 'Ratio',
        nameTextStyle: { fontWeight: 'bold' },
        max: 1,
      },
      grid: { left: '12%', right: '8%', bottom: '25%', top: '15%' },
      series: [
        {
          type: 'bar',
          data: compressionRatios.map(r => ({
            value: r.ratio,
            itemStyle: {
              color: r.ratio > 0.7 ? '#f56c6c' : r.ratio > 0.4 ? '#e6a23c' : '#67c23a',
            },
          })),
          label: {
            show: true,
            position: 'top',
            formatter: (params: any) => `${(params.value * 100).toFixed(1)}%`,
            fontWeight: 'bold',
          },
          barMaxWidth: 50,
        },
      ],
    };
  };

  // Panel 3: Range/Quantization Compression Statistics
  const getRangeCompressionStatsOption = () => {
    // Find any step with compression_info (range, quantization, etc.)
    const compressionStep = activeSteps.find(s =>
      s.compression_info &&
      s.compression_info.compressed_params &&
      s.compression_info.compressed_params.length > 0
    );

    if (!compressionStep || !compressionStep.compression_info) {
      return {
        title: {
          text: 'Range/Quantization Compression Statistics',
          left: 'center',
          textStyle: { fontWeight: 'bold', fontSize: 14 },
        },
        graphic: {
          type: 'text',
          left: 'center',
          top: 'middle',
          style: {
            text: 'No range/quantization compression data',
            fontSize: 14,
            fill: '#999',
          },
        },
      };
    }

    const nCompressed = compressionStep.compression_info.compressed_params?.length || 0;
    const nUnchanged = compressionStep.compression_info.unchanged_params?.length || 0;

    return {
      title: {
        text: 'Range/Quantization Compression Statistics',
        left: 'center',
        textStyle: { fontWeight: 'bold', fontSize: 14 },
      },
      tooltip: {
        trigger: 'axis',
        axisPointer: { type: 'shadow' },
      },
      legend: {
        data: ['Compressed', 'Unchanged'],
        bottom: 0,
      },
      xAxis: {
        type: 'category',
        data: [`Step ${compressionStep.step_index + 1}\n${compressionStep.name}`],
      },
      yAxis: {
        type: 'value',
        name: 'Parameters',
        nameTextStyle: { fontWeight: 'bold' },
      },
      grid: { left: '12%', right: '8%', bottom: '15%', top: '15%' },
      series: [
        {
          name: 'Compressed',
          type: 'bar',
          stack: 'total',
          data: [nCompressed],
          itemStyle: { color: '#ff7875' },
          label: {
            show: true,
            position: 'inside',
          },
        },
        {
          name: 'Unchanged',
          type: 'bar',
          stack: 'total',
          data: [nUnchanged],
          itemStyle: { color: '#91d5ff' },
          label: {
            show: true,
            position: 'inside',
          },
        },
      ],
    };
  };

  // Panel 4: Text Summary
  const getSummaryText = () => {
    const dimensions = [
      event.spaces.original.n_parameters,
      ...activeSteps.map(s => s.output_space_params),
    ];

    let text = `Compression Summary\n${'='.repeat(40)}\n\n`;
    text += `Original dimensions: ${dimensions[0]}\n`;
    text += `Final sample space: ${event.spaces.sample.n_parameters}\n`;
    text += `Final surrogate space: ${event.spaces.surrogate.n_parameters}\n`;
    text += `Overall compression: ${(event.spaces.surrogate.n_parameters / dimensions[0] * 100).toFixed(1)}%\n\n`;
    text += `Active Steps: ${activeSteps.length}\n`;

    activeSteps.forEach((step, i) => {
      const inputDim = dimensions[i];
      const outputDim = dimensions[i + 1];
      const dimRatio = outputDim / inputDim;

      text += `${i + 1}. ${step.name}\n`;
      text += `   ${inputDim} → ${outputDim} (${(dimRatio * 100).toFixed(1)}%)\n`;

      if (step.compression_info && step.compression_info.avg_compression_ratio) {
        text += `   Effective: ${(step.compression_info.avg_compression_ratio * 100).toFixed(1)}%\n`;
      }
    });

    return text;
  };

  return (
    <div style={{ width: '100%', background: '#fff', padding: '20px', borderRadius: '8px', marginBottom: '20px' }}>
      <h2 style={{ textAlign: 'center', marginBottom: '20px', fontSize: '20px', fontWeight: 'bold' }}>
        Compression Summary
      </h2>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
        <div>
          <ReactECharts option={getDimensionReductionOption()} style={{ height: '350px' }} />
        </div>
        <div>
          <ReactECharts option={getCompressionRatioOption()} style={{ height: '350px' }} />
        </div>
        <div>
          <ReactECharts option={getRangeCompressionStatsOption()} style={{ height: '350px' }} />
        </div>
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
            height: '350px',
          }}
        >
          {getSummaryText()}
        </div>
      </div>
    </div>
  );
};

export default CompressionSummary;
