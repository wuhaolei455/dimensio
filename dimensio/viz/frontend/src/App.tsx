/**
 * App.tsx - 使用容器组件的极简版本
 * 
 * 架构：
 * - useCompressionData: 数据获取
 * - 容器组件: 自动处理可见性和数据转换
 * 
 * 优化效果：
 * - 原始版本: 200+ 行
 * - 重构后: ~80 行 (减少 60%)
 */

import React from 'react';
import { useCompressionData } from './hooks';
import CompressionSummary from './components/CompressionSummary';
// import MultiStepUpload from './components/MultiStepUpload';
import MultiStepUploadFSM from './components/MultiStepUploadFSM'; // 使用状态机版本
import LargeDataChartDemo from './components/LargeDataChartDemo';
import {
  RangeCompressionContainer,
  ParameterImportanceContainer,
  DimensionEvolutionContainer,
  MultiTaskHeatmapContainer,
  SourceSimilaritiesContainer,
} from './components/containers';
import './App.css';

/** Loading 状态 */
const LoadingState: React.FC<{ onUploadSuccess: () => void }> = ({ onUploadSuccess }) => (
  <div className="app-container">
    <MultiStepUploadFSM onUploadSuccess={onUploadSuccess} />
    <div className="loading">Loading compression history...</div>
  </div>
);

/** Error 状态 */
const ErrorState: React.FC<{
  error: string | null;
  onUploadSuccess: () => void;
  onRetry: () => void;
}> = ({ error, onUploadSuccess, onRetry }) => (
  <div className="app-container">
    <MultiStepUploadFSM onUploadSuccess={onUploadSuccess} />
    <div className="error-container">
      <div className="error">Error: {error || 'No data available'}</div>
      <button className="refresh-button" onClick={onRetry}>Retry</button>
    </div>
  </div>
);

/** 主应用 */
const App: React.FC = () => {
  const { data, isLoading, error, refetch, hasData } = useCompressionData();

  if (isLoading) return <LoadingState onUploadSuccess={refetch} />;
  if (error || !hasData) return <ErrorState error={error} onUploadSuccess={refetch} onRetry={refetch} />;

  return (
    <div className="app-container">
      {/* 固定按钮 - 使用状态机版本 */}
      <MultiStepUploadFSM onUploadSuccess={refetch} />
      <button className="refresh-button-main" onClick={refetch} title="Refresh">⟳ Refresh</button>

      {/* Header */}
      <header className="app-header">
        <h1>Openbox Compression Visualization</h1>
        <p>Interactive visualization of compression history and parameter space analysis</p>
      </header>

      {/* Main - 容器组件自动处理可见性 */}
      <main className="app-main">
        <CompressionSummary data={data!} />
        
        {/* 🚀 大数据图表懒加载演示 */}
        {/* <LargeDataChartDemo /> */}
        
        <RangeCompressionContainer data={data!} />
        <ParameterImportanceContainer data={data!} />
        <DimensionEvolutionContainer data={data!} />
        <MultiTaskHeatmapContainer data={data!} />
        <SourceSimilaritiesContainer data={data!} />
      </main>

      {/* Footer */}
      <footer className="app-footer">
        <p>Dimensio Visualization Dashboard v1.0 | Powered by React + TypeScript + ECharts</p>
      </footer>
    </div>
  );
};

export default App;
