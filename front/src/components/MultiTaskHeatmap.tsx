import React from 'react';
import ReactECharts from 'echarts-for-react';

interface MultiTaskHeatmapProps {
  paramNames: string[];
  importances: number[][]; // [n_tasks, n_params]
  tasks?: string[];
}

const MultiTaskHeatmap: React.FC<MultiTaskHeatmapProps> = ({ paramNames, importances, tasks }) => {
  const getOption = () => {
    const nTasks = importances.length;
    const nParams = paramNames.length;

    // Limit to top 30 parameters by mean importance
    let finalParamNames = paramNames;
    let finalImportances = importances;

    if (nParams > 30) {
      const meanImportances = importances[0].map((_, paramIdx) => {
        const sum = importances.reduce((acc, task) => acc + Math.abs(task[paramIdx]), 0);
        return sum / nTasks;
      });

      const sortedIndices = meanImportances
        .map((_, idx) => idx)
        .sort((a, b) => meanImportances[b] - meanImportances[a])
        .slice(0, 30);

      finalParamNames = sortedIndices.map(i => paramNames[i]);
      finalImportances = importances.map(task => sortedIndices.map(i => task[i]));
    }

    const shortParamNames = finalParamNames.map(name =>
      name.length > 20 ? name.split('.').pop() || name : name
    );

    const taskNames = tasks || Array.from({ length: nTasks }, (_, i) => `Task ${i + 1}`);

    // Normalize importances
    const flatImportances = finalImportances.flat().map(Math.abs);
    const maxImportance = Math.max(...flatImportances);

    // Prepare heatmap data
    const heatmapData = finalImportances.flatMap((task, taskIdx) =>
      task.map((importance, paramIdx) => [paramIdx, taskIdx, Math.abs(importance) / maxImportance])
    );

    return {
      title: {
        text: 'Multi-Task Parameter Importance Heatmap',
        left: 'center',
        textStyle: { fontWeight: 'bold', fontSize: 16 },
      },
      tooltip: {
        position: 'top',
        formatter: (params: any) => {
          const [paramIdx, taskIdx, normalizedValue] = params.value;
          const actualValue = finalImportances[taskIdx][paramIdx];
          return `${taskNames[taskIdx]}<br/>${finalParamNames[paramIdx]}<br/>Importance: ${actualValue.toFixed(4)}`;
        },
      },
      grid: {
        left: '5%',
        right: '12%',
        top: '10%',
        bottom: '15%',
        containLabel: true,
      },
      xAxis: {
        type: 'category',
        data: shortParamNames,
        axisLabel: {
          rotate: 45,
          fontSize: 9,
          interval: 0,
        },
        splitArea: { show: true },
      },
      yAxis: {
        type: 'category',
        data: taskNames,
        axisLabel: { fontSize: 11 },
        splitArea: { show: true },
      },
      visualMap: {
        min: 0,
        max: 1,
        calculable: true,
        orient: 'vertical',
        right: '2%',
        top: '15%',
        text: ['High', 'Low'],
        inRange: {
          color: ['#50a3ba', '#eac736', '#d94e5d'], // Blue -> Yellow -> Red
        },
      },
      series: [
        {
          type: 'heatmap',
          data: heatmapData,
          label: {
            show: finalParamNames.length <= 20 && nTasks <= 5,
            formatter: (params: any) => params.value[2].toFixed(2),
            fontSize: 9,
          },
          emphasis: {
            itemStyle: {
              shadowBlur: 10,
              shadowColor: 'rgba(0, 0, 0, 0.5)',
            },
          },
        },
      ],
    };
  };

  return (
    <div style={{ width: '100%', background: '#fff', padding: '20px', borderRadius: '8px', marginBottom: '20px' }}>
      <ReactECharts
        option={getOption()}
        style={{ height: `${Math.max(400, importances.length * 60 + 200)}px` }}
      />
    </div>
  );
};

export default MultiTaskHeatmap;
