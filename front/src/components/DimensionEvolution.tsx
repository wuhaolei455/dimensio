import React from 'react';
import ReactECharts from 'echarts-for-react';

interface DimensionEvolutionProps {
  iterations: number[];
  dimensions: number[];
}

const DimensionEvolution: React.FC<DimensionEvolutionProps> = ({ iterations, dimensions }) => {
  const getOption = () => {
    return {
      title: {
        text: 'Adaptive Dimension Evolution',
        left: 'center',
        textStyle: { fontWeight: 'bold', fontSize: 16 },
      },
      tooltip: {
        trigger: 'axis',
        formatter: (params: any) => {
          const data = params[0];
          return `Iteration: ${data.axisValue}<br/>Dimensions: ${data.value}`;
        },
      },
      grid: {
        left: '10%',
        right: '10%',
        top: '15%',
        bottom: '10%',
        containLabel: true,
      },
      xAxis: {
        type: 'category',
        data: iterations,
        name: 'Iteration',
        nameLocation: 'middle',
        nameGap: 30,
        nameTextStyle: { fontWeight: 'bold', fontSize: 12 },
      },
      yAxis: {
        type: 'value',
        name: 'Number of Dimensions',
        nameTextStyle: { fontWeight: 'bold', fontSize: 12 },
        minInterval: 1,
      },
      series: [
        {
          name: 'Dimensions',
          type: 'line',
          data: dimensions,
          lineStyle: { width: 3, color: '#5470c6' },
          itemStyle: { color: '#5470c6' },
          symbol: 'circle',
          symbolSize: 10,
          label: {
            show: true,
            position: 'top',
            formatter: (params: any) => params.value,
            fontWeight: 'bold',
          },
          markLine: {
            silent: true,
            lineStyle: { type: 'dashed', color: '#ff4d4f', opacity: 0.5 },
            data: dimensions
              .map((dim, idx) => {
                if (idx > 0 && dim !== dimensions[idx - 1]) {
                  return { xAxis: iterations[idx] };
                }
                return null;
              })
              .filter(Boolean),
          },
        },
      ],
    };
  };

  return (
    <div style={{ width: '100%', background: '#fff', padding: '20px', borderRadius: '8px', marginBottom: '20px' }}>
      <ReactECharts option={getOption()} style={{ height: '400px' }} />
    </div>
  );
};

export default DimensionEvolution;
