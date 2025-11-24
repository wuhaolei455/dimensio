import React, { useEffect, useState, useCallback } from 'react';
import apiService from './services/api';
import { CompressionHistory } from './types';
import CompressionSummary from './components/CompressionSummary';
import RangeCompression from './components/RangeCompression';
import ParameterImportance from './components/ParameterImportance';
import DimensionEvolution from './components/DimensionEvolution';
import MultiTaskHeatmap from './components/MultiTaskHeatmap';
import SourceSimilarities from './components/SourceSimilarities';
import MultiStepUpload from './components/MultiStepUpload';
import './App.css';

const App: React.FC = () => {
  const [data, setData] = useState<CompressionHistory | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    try {
      setLoading(true);
      const history = await apiService.getCompressionHistory();
      setData(history);
      setError(null);
    } catch (err) {
      setError('Failed to load compression history');
      console.error(err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const handleUploadSuccess = () => {
    // Refresh data after successful upload
    fetchData();
  };

  const handleRefresh = () => {
    // Force refresh data
    fetchData();
  };

  if (loading) {
    return (
      <div className="app-container">
        <MultiStepUpload onUploadSuccess={handleUploadSuccess} />
        <div className="loading">Loading compression history...</div>
      </div>
    );
  }

  if (error || !data) {
    return (
      <div className="app-container">
        <MultiStepUpload onUploadSuccess={handleUploadSuccess} />
        <div className="error-container">
          <div className="error">Error: {error || 'No data available'}</div>
          <button className="refresh-button" onClick={handleRefresh}>
            Retry
          </button>
        </div>
      </div>
    );
  }

  const event = data.history[0];
  const pipeline = event.pipeline;

  // Helper function to check if a step type is used in the pipeline
  const hasStepType = (stepTypePrefix: string): boolean => {
    return pipeline.steps.some(step => step.type.toLowerCase().includes(stepTypePrefix.toLowerCase()));
  };

  // Check for SHAP, Correlation, or Adaptive dimension steps
  const hasSHAPDimension = hasStepType('SHAP') && pipeline.steps.some(step => step.calculator?.includes('SHAP'));
  const hasCorrelationDimension = hasStepType('Correlation');
  const hasAdaptiveDimension = hasStepType('Adaptive');
  const hasImportanceBasedDimension = hasSHAPDimension || hasCorrelationDimension || hasAdaptiveDimension;

  // Check for dimension step with calculator (for importance data)
  const dimensionStepWithCalculator = pipeline.steps.find(
    step => step.name === 'dimension_selection' && step.calculator
  );

  // Check if adaptive update history exists
  const hasAdaptiveUpdateHistory = data.history.length > 1 &&
    data.history.some(e => e.event === 'adaptive_update');

  // Check if multi-task data exists
  const hasMultiTaskData = event.performance_metrics?.multi_task_importances !== undefined;

  // Check if transfer learning data exists (would have source similarities)
  const hasTransferLearningData = event.performance_metrics?.source_similarities !== undefined;

  // Generate mock importance data only if we have importance-based dimension step
  const mockParamImportances = hasImportanceBasedDimension
    ? event.spaces.original.parameters.map((_, idx) => 0.1 + Math.random() * 0.9)
    : null;

  // Mock dimension evolution data only if adaptive step with history
  const mockIterations = hasAdaptiveUpdateHistory ? [0, 10, 20, 30, 40, 50] : null;
  const mockDimensions = hasAdaptiveUpdateHistory ? [12, 12, 10, 8, 8, 6] : null;

  // Use real multi-task data if available, otherwise use mock data for demo
  const multiTaskImportances = hasMultiTaskData
    ? event.performance_metrics!.multi_task_importances
    : null;

  const taskNames = event.performance_metrics?.task_names ?? null;

  // Use real source similarities if available, otherwise use mock data for demo
  const sourceSimilarities = hasTransferLearningData
    ? event.performance_metrics!.source_similarities
    : null;

  return (
    <div className="app-container">
      <MultiStepUpload onUploadSuccess={handleUploadSuccess} />
      <button className="refresh-button-main" onClick={handleRefresh} title="Refresh data">
        ⟳ Refresh
      </button>
      <header className="app-header">
        <h1>Dimensio Compression Visualization</h1>
        <p>Interactive visualization of compression history and parameter space analysis</p>
      </header>

      <main className="app-main">
        {/* Compression Summary */}
        <section className="chart-section">
          <CompressionSummary data={data} />
        </section>

        {/* Range/Quantization Compression - Show from any step that has compression_info */}
        {pipeline.steps.map((step, idx) => {
          // Check if step has compression_info with actual compressed parameters
          // This includes range compression steps AND projection steps with quantization
          const hasCompressionInfo = step.compression_info &&
                                     step.compression_info.compressed_params &&
                                     step.compression_info.compressed_params.length > 0;

          if (hasCompressionInfo) {
            return (
              <section key={idx} className="chart-section">
                <RangeCompression step={step} stepIndex={idx + 1} />
              </section>
            );
          }
          return null;
        })}

        {/* Parameter Importance - Only show if using SHAP/Correlation/Adaptive dimension selection */}
        {hasImportanceBasedDimension && dimensionStepWithCalculator && mockParamImportances && (
          <section className="chart-section">
            <h2 className="section-title">Parameter Importance Analysis</h2>
            <ParameterImportance
              paramNames={event.spaces.original.parameters}
              importances={mockParamImportances}
              topK={Math.min(20, event.spaces.original.parameters.length)}
            />
          </section>
        )}

        {/* Dimension Evolution - Only show if adaptive dimension step with update history */}
        {hasAdaptiveDimension && hasAdaptiveUpdateHistory && mockIterations && mockDimensions && (
          <section className="chart-section">
            <h2 className="section-title">Dimension Evolution Over Iterations</h2>
            <DimensionEvolution iterations={mockIterations} dimensions={mockDimensions} />
          </section>
        )}

        {/* Multi-Task Heatmap - Only show if multi-task data exists */}
        {hasMultiTaskData && multiTaskImportances && (
          <section className="chart-section">
            <h2 className="section-title">Multi-Task Parameter Importance</h2>
            <MultiTaskHeatmap
              paramNames={event.spaces.original.parameters}
              importances={multiTaskImportances}
              tasks={taskNames || undefined}
            />
          </section>
        )}

        {/* Source Task Similarities - Only show if transfer learning data exists */}
        {hasTransferLearningData && sourceSimilarities && (
          <section className="chart-section">
            <h2 className="section-title">Source Task Similarities</h2>
            <SourceSimilarities similarities={sourceSimilarities} taskNames={taskNames || undefined} />
          </section>
        )}
      </main>

      <footer className="app-footer">
        <p>Dimensio Visualization Dashboard v1.0 | Powered by React + TypeScript + ECharts</p>
      </footer>
    </div>
  );
};

export default App;
