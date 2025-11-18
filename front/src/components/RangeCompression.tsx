import React from 'react';
import ReactECharts from 'echarts-for-react';
import { PipelineStep } from '../types';

interface RangeCompressionProps {
  step: PipelineStep;
  stepIndex: number;
}

const RangeCompression: React.FC<RangeCompressionProps> = ({ step, stepIndex }) => {
  if (!step.compression_info || !step.compression_info.compressed_params.length) {
    return null;
  }

  const getOption = () => {
    const compressedParams = step.compression_info!.compressed_params.slice(0, 30);
    const paramNames = compressedParams.map(p => p.name.split('.').pop() || p.name);

    // Prepare data for visualization
    const chartData = compressedParams.map((param, idx) => {
      const origMin = param.original_range[0];
      const origMax = param.original_range[1];
      const compMin = param.compressed_range[0];
      const compMax = param.compressed_range[1];

      const isQuantization = param.original_num_values !== undefined;

      // Normalize to [0, 1]
      let normCompStart = 0;
      let normCompEnd = 1;

      if (!isQuantization && origMax - origMin > 0) {
        normCompStart = (compMin - origMin) / (origMax - origMin);
        normCompEnd = (compMax - origMin) / (origMax - origMin);
      }

      return {
        idx,
        paramName: paramNames[idx],
        origMin,
        origMax,
        compMin,
        compMax,
        ratio: param.compression_ratio,
        isQuantization,
        normCompStart,
        normCompEnd,
        label: isQuantization
          ? `${param.original_num_values}→${param.quantized_num_values} values`
          : '',
      };
    });

    // Custom series data
    const originalBars = chartData.map(d => [0, d.idx, 1]);
    const compressedBars = chartData.map(d => [
      d.normCompStart,
      d.idx,
      d.normCompEnd - d.normCompStart,
    ]);

    return {
      title: {
        text: `${step.name}: Range Compression Details (Top ${chartData.length} params)`,
        left: 'center',
        textStyle: { fontWeight: 'bold', fontSize: 16 },
      },
      tooltip: {
        trigger: 'item',
        formatter: (params: any) => {
          const data = chartData[params.value[1]];
          if (params.seriesName === 'Original') {
            return `${data.paramName}<br/>Original: [${data.origMin.toFixed(0)}, ${data.origMax.toFixed(0)}]`;
          } else {
            return `${data.paramName}<br/>Compressed: [${data.compMin.toFixed(2)}, ${data.compMax.toFixed(2)}]<br/>Ratio: ${(data.ratio * 100).toFixed(1)}%${data.label ? '<br/>' + data.label : ''}`;
          }
        },
      },
      legend: {
        data: ['Original', 'Compressed'],
        top: 30,
      },
      grid: {
        left: '15%',
        right: '20%',
        top: 60,
        bottom: 30,
        containLabel: true,
      },
      xAxis: {
        type: 'value',
        name: 'Normalized Range [0=lower, 1=upper]',
        nameLocation: 'middle',
        nameGap: 25,
        nameTextStyle: { fontWeight: 'bold', fontSize: 12 },
        min: -0.15,
        max: 1.25,
      },
      yAxis: {
        type: 'category',
        data: paramNames,
        axisLabel: { fontSize: 10 },
        inverse: false,
      },
      series: [
        {
          name: 'Original',
          type: 'custom',
          renderItem: (params: any, api: any) => {
            const yValue = api.value(1);
            const start = api.coord([0, yValue]);
            const end = api.coord([1, yValue]);
            const height = api.size([0, 1])[1] * 0.4;

            return {
              type: 'rect',
              shape: {
                x: start[0],
                y: start[1] - height / 2,
                width: end[0] - start[0],
                height: height,
              },
              style: {
                fill: 'rgba(150, 150, 150, 0.3)',
                stroke: 'rgba(150, 150, 150, 0.5)',
              },
            };
          },
          data: originalBars,
          z: 1,
        },
        {
          name: 'Compressed',
          type: 'custom',
          renderItem: (params: any, api: any) => {
            const dataIndex = params.dataIndex;
            const data = chartData[dataIndex];
            const yValue = api.value(1);
            const start = api.coord([api.value(0), yValue]);
            const size = api.size([api.value(2), 1]);
            const height = size[1] * 0.4;

            // Color based on ratio
            const ratio = data.ratio;
            let color = '#67c23a'; // green
            if (ratio > 0.9) color = '#f56c6c'; // red
            else if (ratio > 0.7) color = '#e6a23c'; // orange
            else if (ratio > 0.5) color = '#f0a020'; // yellow

            return {
              type: 'rect',
              shape: {
                x: start[0],
                y: start[1] - height / 2,
                width: size[0],
                height: height,
              },
              style: {
                fill: color,
                opacity: 0.8,
                stroke: data.isQuantization ? color : 'transparent',
                lineDash: data.isQuantization ? [5, 5] : undefined,
                lineWidth: 2,
              },
            };
          },
          data: compressedBars,
          z: 2,
        },
        {
          name: 'Labels',
          type: 'custom',
          renderItem: (params: any, api: any) => {
            const dataIndex = params.dataIndex;
            const data = chartData[dataIndex];
            const yValue = api.value(1);
            const pos = api.coord([1.02, yValue]);

            return {
              type: 'text',
              x: pos[0],
              y: pos[1],
              style: {
                text: `${(data.ratio * 100).toFixed(1)}%${data.label ? ' (' + data.label + ')' : ''}`,
                fontSize: 9,
                fill: '#666',
              },
            };
          },
          data: compressedBars,
          z: 3,
        },
        {
          name: 'Compressed Range Text',
          type: 'custom',
          renderItem: (params: any, api: any) => {
            const dataIndex = params.dataIndex;
            const data = chartData[dataIndex];
            const yValue = api.value(1);
            const pos = api.coord([0.5, yValue]);

            return {
              type: 'text',
              x: pos[0],
              y: pos[1] + 15,
              style: {
                text: `→[${data.compMin.toFixed(0)}, ${data.compMax.toFixed(0)}]`,
                fontSize: 11,
                fontWeight: 'bold',
                fill: '#000',
                fontStyle: data.isQuantization ? 'italic' : 'normal',
              },
            };
          },
          data: compressedBars,
          z: 3,
        },
        {
          name: 'Original Min',
          type: 'custom',
          renderItem: (params: any, api: any) => {
            const dataIndex = params.dataIndex;
            const data = chartData[dataIndex];
            const yValue = api.value(1);
            const pos = api.coord([-0.05, yValue]);

            return {
              type: 'text',
              x: pos[0],
              y: pos[1] - 10,
              style: {
                text: data.origMin.toFixed(0),
                fontSize: 8,
                fill: '#999',
                align: 'right',
              },
            };
          },
          data: compressedBars,
          z: 3,
        },
        {
          name: 'Original Max',
          type: 'custom',
          renderItem: (params: any, api: any) => {
            const dataIndex = params.dataIndex;
            const data = chartData[dataIndex];
            const yValue = api.value(1);
            const pos = api.coord([1.05, yValue]);

            return {
              type: 'text',
              x: pos[0],
              y: pos[1] - 10,
              style: {
                text: data.origMax.toFixed(0),
                fontSize: 8,
                fill: '#999',
                align: 'left',
              },
            };
          },
          data: compressedBars,
          z: 3,
        },
      ],
    };
  };

  return (
    <div style={{ width: '100%', background: '#fff', padding: '20px', borderRadius: '8px', marginBottom: '20px' }}>
      <ReactECharts
        option={getOption()}
        style={{ height: `${Math.max(400, step.compression_info!.compressed_params.length * 25)}px` }}
      />
    </div>
  );
};

export default RangeCompression;
