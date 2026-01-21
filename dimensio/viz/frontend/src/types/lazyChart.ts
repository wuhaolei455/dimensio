/**
 * LazyChart 组件类型定义
 * 
 * 懒加载大数据图表相关的类型
 */

import type { EChartsOption } from 'echarts';

/** LazyChart 组件 Props */
export interface LazyChartProps {
  /** 原始数据数组 */
  data: any[];
  /** 图表类型 */
  type: 'line' | 'bar' | 'scatter' | 'heatmap' | 'pie';
  /** 图表配置生成函数 */
  getOption?: (data: any[]) => EChartsOption;
  /** 直接传入的 ECharts 配置（优先于 getOption） */
  option?: EChartsOption;
  /** 图表高度 */
  height?: number | string;
  /** 图表宽度 */
  width?: number | string;
  /** 标题 */
  title?: string;
  /** 数据分片大小 */
  chunkSize?: number;
  /** 数据量阈值，小于此值时禁用分片 */
  chunkThreshold?: number;
  /** 懒加载触发阈值 */
  lazyThreshold?: number;
  /** 懒加载根元素边距 */
  lazyRootMargin?: string;
  /** 是否禁用懒加载 */
  disableLazy?: boolean;
  /** 是否禁用分片加载 */
  disableChunking?: boolean;
  /** 加载完成回调 */
  onLoadComplete?: () => void;
  /** 自定义占位符组件 */
  placeholder?: React.ReactNode;
  /** 自定义类名 */
  className?: string;
  /** 自定义样式 */
  style?: React.CSSProperties;
  /** 是否显示进度条 */
  showProgress?: boolean;
  /** ECharts notMerge 选项 */
  notMerge?: boolean;
  /** ECharts lazyUpdate 选项 */
  lazyUpdate?: boolean;
}

/** 图表占位符组件 Props */
export interface ChartPlaceholderProps {
  /** 占位符高度 */
  height?: number | string;
  /** 占位符宽度 */
  width?: number | string;
  /** 标题文本 */
  title?: string;
  /** 是否显示脉冲动画 */
  animate?: boolean;
  /** 自定义类名 */
  className?: string;
  /** 自定义样式 */
  style?: React.CSSProperties;
}

/** 加载进度条组件 Props */
export interface LoadingBarProps {
  /** 进度值 (0-100) */
  progress: number;
  /** 进度条高度 */
  height?: number;
  /** 是否显示百分比文本 */
  showText?: boolean;
  /** 进度条颜色 */
  color?: string;
  /** 背景颜色 */
  backgroundColor?: string;
  /** 自定义类名 */
  className?: string;
  /** 自定义样式 */
  style?: React.CSSProperties;
  /** 数据点数量信息 */
  dataInfo?: {
    loaded: number;
    total: number;
  };
}
