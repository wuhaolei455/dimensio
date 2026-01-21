/**
 * LazyChart 组件
 * 
 * 虚拟化 + 懒加载大数据图表
 * 结合 Intersection Observer 懒加载和数据分片渲染
 * 支持 10000+ 数据点的流畅展示
 * 
 * 特性：
 * - 基于 Intersection Observer 的懒加载
 * - 使用 requestIdleCallback 的数据分片渲染
 * - 渲染进度反馈
 * - 占位符显示
 */

import React, { useMemo, useCallback } from 'react';
import ReactECharts from 'echarts-for-react';
import type { EChartsOption } from 'echarts';
import { useLazyChart } from '../../hooks/useLazyChart';
import { useChunkedData } from '../../hooks/useChunkedData';
import { ChartPlaceholder } from './ChartPlaceholder';
import { LoadingBar } from './LoadingBar';
import type { LazyChartProps } from '../../types';

// 默认图表配置生成器
const defaultGetOption = (data: any[], type: string): EChartsOption => {
  const baseOption: EChartsOption = {
    tooltip: {
      trigger: type === 'pie' ? 'item' : 'axis',
    },
    grid: {
      left: '3%',
      right: '4%',
      bottom: '3%',
      containLabel: true,
    },
  };

  // 根据类型生成不同配置
  switch (type) {
    case 'line':
      return {
        ...baseOption,
        xAxis: {
          type: 'category',
          data: data.map((_, i) => i),
          boundaryGap: false,
        },
        yAxis: { type: 'value' },
        series: [{
          type: 'line',
          data: data,
          smooth: true,
          sampling: 'lttb', // 降采样优化
          areaStyle: {
            opacity: 0.3,
          },
        }],
      };

    case 'bar':
      return {
        ...baseOption,
        xAxis: {
          type: 'category',
          data: data.map((_, i) => i),
        },
        yAxis: { type: 'value' },
        series: [{
          type: 'bar',
          data: data,
          large: true, // 大数据优化
          largeThreshold: 500,
        }],
      };

    case 'scatter':
      return {
        ...baseOption,
        xAxis: { type: 'value' },
        yAxis: { type: 'value' },
        series: [{
          type: 'scatter',
          data: data,
          large: true,
          largeThreshold: 2000,
          symbolSize: 4,
        }],
      };

    default:
      return {
        ...baseOption,
        xAxis: { type: 'category', data: data.map((_, i) => i) },
        yAxis: { type: 'value' },
        series: [{ type: type as 'line', data: data }],
      };
  }
};

const styles: Record<string, React.CSSProperties> = {
  container: {
    width: '100%',
    background: '#fff',
    borderRadius: '8px',
    padding: '20px',
    marginBottom: '20px',
    boxShadow: '0 2px 8px rgba(0, 0, 0, 0.06)',
    position: 'relative',
  },
  title: {
    fontSize: '16px',
    fontWeight: 600,
    color: '#2c3e50',
    marginBottom: '16px',
    display: 'flex',
    alignItems: 'center',
    gap: '8px',
  },
  badge: {
    background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
    color: 'white',
    fontSize: '10px',
    padding: '2px 8px',
    borderRadius: '10px',
    fontWeight: 500,
  },
  chartWrapper: {
    position: 'relative',
  },
  stats: {
    position: 'absolute',
    top: '8px',
    right: '8px',
    background: 'rgba(255, 255, 255, 0.9)',
    padding: '4px 10px',
    borderRadius: '4px',
    fontSize: '11px',
    color: '#666',
    boxShadow: '0 1px 4px rgba(0,0,0,0.1)',
  },
};

/**
 * 懒加载大数据图表组件
 * 
 * @example
 * ```tsx
 * // 基础用法 - 使用默认配置
 * <LazyChart 
 *   data={largeDataset} 
 *   type="line" 
 *   height={400}
 * />
 * 
 * // 高级用法 - 自定义配置
 * <LazyChart 
 *   data={largeDataset}
 *   type="scatter"
 *   getOption={(data) => ({
 *     // 自定义 ECharts 配置
 *   })}
 *   chunkSize={1000}
 *   chunkThreshold={5000}
 *   showProgress={true}
 * />
 * ```
 */
export const LazyChart: React.FC<LazyChartProps> = ({
  data,
  type,
  getOption,
  option: directOption,
  height = 400,
  width = '100%',
  title,
  chunkSize = 500,
  chunkThreshold = 1000,
  lazyThreshold = 0.1,
  lazyRootMargin = '100px',
  disableLazy = false,
  disableChunking = false,
  onLoadComplete,
  placeholder,
  className = '',
  style = {},
  showProgress = true,
  notMerge = true,
  lazyUpdate = true,
}) => {
  // 懒加载 Hook
  const { ref, isVisible } = useLazyChart({
    threshold: lazyThreshold,
    rootMargin: lazyRootMargin,
    disabled: disableLazy,
  });

  // 分片渲染 Hook
  const { 
    displayData, 
    progress, 
    isComplete, 
    isLoading 
  } = useChunkedData(data, {
    chunkSize,
    threshold: chunkThreshold,
    enabled: !disableChunking && isVisible,
    onComplete: onLoadComplete,
  });

  // 生成图表配置
  const chartOption = useMemo<EChartsOption>(() => {
    // 优先使用直接传入的配置
    if (directOption) {
      return directOption;
    }
    
    // 使用自定义配置生成器
    if (getOption) {
      return getOption(displayData);
    }
    
    // 使用默认配置生成器
    return defaultGetOption(displayData, type);
  }, [directOption, getOption, displayData, type]);

  // 处理高度
  const chartHeight = typeof height === 'number' ? height : parseInt(height, 10) || 400;

  // 判断是否需要显示进度条
  const shouldShowProgress = showProgress && isVisible && !isComplete && data.length > chunkThreshold;

  // 判断是否为大数据集
  const isLargeDataset = data.length > chunkThreshold;

  return (
    <div 
      ref={ref}
      className={`lazy-chart ${className}`}
      style={{
        ...styles.container,
        ...style,
      }}
    >
      {/* 标题 */}
      {title && (
        <div style={styles.title}>
          {title}
          {isLargeDataset && (
            <span style={styles.badge}>
              {data.length.toLocaleString()} points
            </span>
          )}
        </div>
      )}

      {/* 图表内容区域 */}
      <div style={styles.chartWrapper}>
        {!isVisible ? (
          // 占位符
          placeholder || (
            <ChartPlaceholder 
              height={chartHeight} 
              title={title || 'Chart'}
              animate={true}
            />
          )
        ) : (
          <>
            {/* 进度条 */}
            {shouldShowProgress && (
              <LoadingBar 
                progress={progress}
                showText={true}
                dataInfo={{
                  loaded: displayData.length,
                  total: data.length,
                }}
              />
            )}
            
            {/* ECharts 图表 */}
            <ReactECharts
              option={chartOption}
              style={{ 
                height: chartHeight,
                width: typeof width === 'number' ? `${width}px` : width,
              }}
              notMerge={notMerge}
              lazyUpdate={lazyUpdate}
              opts={{
                renderer: data.length > 5000 ? 'canvas' : 'svg',
              }}
            />
            
            {/* 数据统计 */}
            {isLargeDataset && isComplete && (
              <div style={styles.stats}>
                ✓ {displayData.length.toLocaleString()} points rendered
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
};

export default LazyChart;
