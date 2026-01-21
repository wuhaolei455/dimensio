/**
 * 多任务热力图组件
 * 
 * 重构后使用 useMultiTaskHeatmapConfig Hook
 * - 原代码: ~120 行
 * - 重构后: ~50 行 (减少 ~58%)
 * - 性能: useMemo 缓存配置
 */

import React from 'react';
import ReactECharts from 'echarts-for-react';
import { useMultiTaskHeatmapConfig } from '../charts';

interface MultiTaskHeatmapProps {
  paramNames: string[];
  importances: number[][];
  tasks?: string[];
}

const MultiTaskHeatmap: React.FC<MultiTaskHeatmapProps> = ({
  paramNames,
  importances,
  tasks,
}) => {
  // 生成默认任务名称
  const taskNames = tasks || importances.map((_, i) => `Task ${i + 1}`);

  // ✅ 使用专用 Hook
  const { option, dimensions, isValid, error } = useMultiTaskHeatmapConfig(
    paramNames,
    taskNames,
    importances
  );

  if (!isValid) {
    return (
      <div style={{ 
        width: '100%', 
        background: '#fff', 
        padding: '40px', 
        borderRadius: '8px',
        textAlign: 'center',
        color: '#999',
      }}>
        {error || 'No data available'}
      </div>
    );
  }

  return (
    <div style={{ 
      width: '100%', 
      background: '#fff', 
      padding: '20px', 
      borderRadius: '8px', 
      marginBottom: '20px',
    }}>
      <ReactECharts 
        option={option} 
        style={{ height: dimensions.height }}
        notMerge={true}
        lazyUpdate={true}
      />
    </div>
  );
};

export default MultiTaskHeatmap;
