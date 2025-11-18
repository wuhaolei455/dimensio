import React from 'react';
import ReactECharts from 'echarts-for-react';

interface SourceSimilaritiesProps {
  similarities: Record<number, number>; // task_index -> similarity
  taskNames?: string[];
}

const SourceSimilarities: React.FC<SourceSimilaritiesProps> = ({ similarities, taskNames }) => {
  const getOption = () => {
    const taskIndices = Object.keys(similarities)
      .map(Number)
      .sort((a, b) => a - b);
    const simValues = taskIndices.map(idx => similarities[idx]);

    const labels = taskNames
      ? taskIndices.map(idx => taskNames[idx])
      : taskIndices.map(idx => `Source Task ${idx}`);

    return {
      title: {
        text: 'Source Task Similarity to Target Task',
        left: 'center',
        textStyle: { fontWeight: 'bold', fontSize: 16 },
      },
      tooltip: {
        trigger: 'axis',
        axisPointer: { type: 'shadow' },
        formatter: (params: any) => {
          const data = params[0];
          return `${data.name}<br/>Similarity: ${data.value.toFixed(3)}`;
        },
      },
      grid: {
        left: '10%',
        right: '10%',
        top: '15%',
        bottom: '15%',
        containLabel: true,
      },
      xAxis: {
        type: 'category',
        data: labels,
        axisLabel: {
          rotate: 45,
          fontSize: 11,
          interval: 0,
        },
        name: 'Source Tasks',
        nameLocation: 'middle',
        nameGap: 60,
        nameTextStyle: { fontWeight: 'bold', fontSize: 12 },
      },
      yAxis: {
        type: 'value',
        name: 'Similarity Score',
        nameTextStyle: { fontWeight: 'bold', fontSize: 12 },
        max: Math.max(...simValues) * 1.1,
      },
      series: [
        {
          type: 'bar',
          data: simValues.map((val, idx) => ({
            value: val,
            itemStyle: {
              color:
                val > 0.7
                  ? '#52c41a'
                  : val > 0.4
                  ? '#faad14'
                  : '#ff4d4f',
            },
          })),
          label: {
            show: true,
            position: 'top',
            formatter: (params: any) => params.value.toFixed(3),
            fontWeight: 'bold',
            fontSize: 11,
          },
          barMaxWidth: 60,
        },
      ],
    };
  };

  return (
    <div style={{ width: '100%', background: '#fff', padding: '20px', borderRadius: '8px', marginBottom: '20px' }}>
      <ReactECharts option={getOption()} style={{ height: '450px' }} />
    </div>
  );
};

export default SourceSimilarities;
