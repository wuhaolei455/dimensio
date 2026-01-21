/**
 * LargeDataChartDemo 组件
 * 
 * 演示 10000+ 数据点的懒加载和分片渲染功能
 * 
 * 特性展示：
 * - Intersection Observer 懒加载
 * - requestIdleCallback 分片渲染
 * - 渲染进度反馈
 * - 多种图表类型支持
 */

import React, { useMemo, useState } from 'react';
import { LazyChart } from './lazyChart';

// 生成大量测试数据
const generateLargeData = (count: number, type: 'line' | 'scatter' = 'line'): any[] => {
  if (type === 'scatter') {
    // 散点图数据：[x, y] 格式
    return Array.from({ length: count }, (_, i) => [
      i + Math.random() * 10,
      Math.sin(i / 100) * 50 + Math.random() * 20 + 50,
    ]);
  }
  // 折线图数据：单值格式
  return Array.from({ length: count }, (_, i) => 
    Math.sin(i / 200) * 40 + Math.cos(i / 150) * 20 + Math.random() * 10 + 50
  );
};

const styles: Record<string, React.CSSProperties> = {
  container: {
    background: '#fff',
    borderRadius: '12px',
    padding: '24px',
    marginBottom: '24px',
    boxShadow: '0 4px 12px rgba(0, 0, 0, 0.08)',
  },
  header: {
    marginBottom: '24px',
  },
  title: {
    fontSize: '20px',
    fontWeight: 700,
    color: '#2c3e50',
    marginBottom: '8px',
    display: 'flex',
    alignItems: 'center',
    gap: '12px',
  },
  badge: {
    background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
    color: 'white',
    fontSize: '12px',
    padding: '4px 12px',
    borderRadius: '12px',
    fontWeight: 500,
  },
  description: {
    fontSize: '14px',
    color: '#666',
    lineHeight: 1.6,
  },
  controls: {
    display: 'flex',
    gap: '12px',
    marginBottom: '24px',
    flexWrap: 'wrap' as const,
  },
  button: {
    padding: '10px 20px',
    border: 'none',
    borderRadius: '8px',
    cursor: 'pointer',
    fontSize: '14px',
    fontWeight: 600,
    transition: 'all 0.2s ease',
  },
  activeButton: {
    background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
    color: 'white',
    boxShadow: '0 4px 12px rgba(102, 126, 234, 0.4)',
  },
  inactiveButton: {
    background: '#f0f2f5',
    color: '#666',
  },
  chartsGrid: {
    display: 'flex',
    flexDirection: 'column' as const,
    gap: '24px',
  },
  featureList: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
    gap: '16px',
    marginTop: '24px',
    padding: '20px',
    background: 'linear-gradient(135deg, #f5f7fa 0%, #e4e8ed 100%)',
    borderRadius: '8px',
  },
  feature: {
    display: 'flex',
    alignItems: 'center',
    gap: '8px',
    fontSize: '13px',
    color: '#555',
  },
  featureIcon: {
    width: '24px',
    height: '24px',
    background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
    borderRadius: '6px',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    color: 'white',
    fontSize: '12px',
  },
  spacer: {
    height: '600px',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    background: 'linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%)',
    borderRadius: '8px',
    marginBottom: '24px',
    border: '2px dashed #dee2e6',
  },
  spacerText: {
    color: '#868e96',
    fontSize: '16px',
    textAlign: 'center' as const,
  },
};

// 数据量配置
const DATA_CONFIGS = [
  { label: '5,000 点', value: 5000 },
  { label: '10,000 点', value: 10000 },
  { label: '20,000 点', value: 20000 },
  { label: '50,000 点', value: 50000 },
];

/**
 * 大数据图表演示组件
 */
const LargeDataChartDemo: React.FC = () => {
  const [dataSize, setDataSize] = useState(10000);
  
  // 生成测试数据
  const lineData = useMemo(() => generateLargeData(dataSize, 'line'), [dataSize]);
  const scatterData = useMemo(() => generateLargeData(dataSize, 'scatter'), [dataSize]);
  const barData = useMemo(() => generateLargeData(Math.min(dataSize, 5000), 'line'), [dataSize]);

  return (
    <div style={styles.container}>
      {/* 头部 */}
      <div style={styles.header}>
        <div style={styles.title}>
          🚀 大数据图表懒加载演示
          <span style={styles.badge}>性能优化</span>
        </div>
        <p style={styles.description}>
          展示基于 Intersection Observer 的图表懒加载和 ECharts 数据分片渲染技术。
          滚动页面查看图表时才会开始加载和渲染，支持 10000+ 数据点的流畅展示。
        </p>
      </div>

      {/* 数据量控制 */}
      <div style={styles.controls}>
        {DATA_CONFIGS.map(config => (
          <button
            key={config.value}
            style={{
              ...styles.button,
              ...(dataSize === config.value ? styles.activeButton : styles.inactiveButton),
            }}
            onClick={() => setDataSize(config.value)}
          >
            {config.label}
          </button>
        ))}
      </div>

      {/* 功能特性 */}
      <div style={styles.featureList}>
        <div style={styles.feature}>
          <span style={styles.featureIcon}>👁</span>
          <span>Intersection Observer 懒加载</span>
        </div>
        <div style={styles.feature}>
          <span style={styles.featureIcon}>⚡</span>
          <span>requestIdleCallback 分片渲染</span>
        </div>
        <div style={styles.feature}>
          <span style={styles.featureIcon}>📊</span>
          <span>渲染进度实时反馈</span>
        </div>
        <div style={styles.feature}>
          <span style={styles.featureIcon}>🎯</span>
          <span>Canvas/SVG 自动切换</span>
        </div>
      </div>

      {/* 滚动提示区域 */}
      <div style={styles.spacer}>
        <div style={styles.spacerText}>
          <div style={{ fontSize: '48px', marginBottom: '16px' }}>⬇️</div>
          <div>向下滚动查看懒加载图表</div>
          <div style={{ marginTop: '8px', fontSize: '14px' }}>
            图表将在进入视口时自动加载
          </div>
        </div>
      </div>

      {/* 图表区域 */}
      <div style={styles.chartsGrid}>
        {/* 折线图 */}
        <LazyChart
          data={lineData}
          type="line"
          title="📈 折线图 - 时序数据展示"
          height={400}
          chunkSize={1000}
          chunkThreshold={2000}
          showProgress={true}
        />

        {/* 散点图 */}
        <LazyChart
          data={scatterData}
          type="scatter"
          title="🔵 散点图 - 大规模数据分布"
          height={400}
          chunkSize={2000}
          chunkThreshold={3000}
          showProgress={true}
        />

        {/* 柱状图 */}
        <LazyChart
          data={barData}
          type="bar"
          title="📊 柱状图 - 分类数据对比"
          height={400}
          chunkSize={500}
          chunkThreshold={1000}
          showProgress={true}
        />
      </div>
    </div>
  );
};

export default LargeDataChartDemo;
