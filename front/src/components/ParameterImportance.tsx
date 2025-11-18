import React from 'react';
import ReactECharts from 'echarts-for-react';

interface ParameterImportanceProps {
  paramNames: string[];
  importances: number[];
  topK?: number;
}

const ParameterImportance: React.FC<ParameterImportanceProps> = ({
  paramNames,
  importances,
  topK = 20,
}) => {
  const getOption = () => {
    // Get absolute importances and sort
    const absImportances = importances.map(Math.abs);
    const indices = absImportances
      .map((_, idx) => idx)
      .sort((a, b) => absImportances[b] - absImportances[a])
      .slice(0, topK);

    const topNames = indices.map(i => paramNames[i].split('.').pop() || paramNames[i]);
    const topValues = indices.map(i => absImportances[i]);

    return {
      title: {
        text: `Top-${topK} Parameter Importance`,
        left: 'center',
        textStyle: { fontWeight: 'bold', fontSize: 16 },
      },
      tooltip: {
        trigger: 'axis',
        axisPointer: { type: 'shadow' },
        formatter: (params: any) => {
          const data = params[0];
          return `${data.name}<br/>Importance: ${data.value.toFixed(4)}`;
        },
      },
      grid: {
        left: '5%',
        right: '15%',
        top: '10%',
        bottom: '5%',
        containLabel: true,
      },
      xAxis: {
        type: 'value',
        name: 'Importance Score',
        nameLocation: 'middle',
        nameGap: 30,
        nameTextStyle: { fontWeight: 'bold', fontSize: 12 },
      },
      yAxis: {
        type: 'category',
        data: topNames,
        axisLabel: { fontSize: 11 },
        inverse: true,
      },
      series: [
        {
          type: 'bar',
          data: topValues,
          itemStyle: {
            color: '#ff7875',
          },
          label: {
            show: true,
            position: 'right',
            formatter: (params: any) => params.value.toFixed(4),
            fontSize: 10,
          },
          barMaxWidth: 30,
        },
      ],
    };
  };

  return (
    <div style={{ width: '100%', background: '#fff', padding: '20px', borderRadius: '8px', marginBottom: '20px' }}>
      <ReactECharts option={getOption()} style={{ height: '600px' }} />
    </div>
  );
};

export default ParameterImportance;
