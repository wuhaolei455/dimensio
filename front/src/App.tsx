import React, { useEffect, useState } from 'react';
import apiService from './services/api';
import { CompressionHistory } from './types';
import CompressionSummary from './components/CompressionSummary';
import RangeCompression from './components/RangeCompression';
import ParameterImportance from './components/ParameterImportance';
import DimensionEvolution from './components/DimensionEvolution';
import MultiTaskHeatmap from './components/MultiTaskHeatmap';
import SourceSimilarities from './components/SourceSimilarities';
import './App.css';

const App: React.FC = () => {
  const [data, setData] = useState<CompressionHistory | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchData = async () => {
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
    };

    fetchData();
  }, []);

  if (loading) {
    return (
      <div className="app-container">
        <div className="loading">Loading compression history...</div>
      </div>
    );
  }

  if (error || !data) {
    return (
      <div className="app-container">
        <div className="error">Error: {error || 'No data available'}</div>
      </div>
    );
  }

  const event = data.history[0];
  const pipeline = event.pipeline;

  // Generate mock importance data for demonstration
  const mockParamImportances = event.spaces.original.parameters.map((_, idx) => 0.1 + Math.random() * 0.9);

  // Mock dimension evolution data
  const mockIterations = [0, 10, 20, 30, 40, 50];
  const mockDimensions = [12, 12, 10, 8, 8, 6];

  // Mock multi-task heatmap data (2 tasks)
  const mockMultiTaskImportances = [
    event.spaces.original.parameters.map(() => Math.random()),
    event.spaces.original.parameters.map(() => Math.random()),
  ];

  // Mock source similarities
  const mockSourceSimilarities = {
    0: 0.85,
    1: 0.62,
    2: 0.73,
  };

  return (
    <div className="app-container">
      <header className="app-header">
        <h1>Dimensio Compression Visualization</h1>
        <p>Interactive visualization of compression history and parameter space analysis</p>
      </header>

      <main className="app-main">
        {/* Compression Summary */}
        <section className="chart-section">
          <CompressionSummary data={data} />
        </section>

        {/* Range Compression Steps */}
        {pipeline.steps.map((step, idx) => {
          if (step.compression_info && step.compression_info.compressed_params.length > 0) {
            return (
              <section key={idx} className="chart-section">
                <RangeCompression step={step} stepIndex={idx + 1} />
              </section>
            );
          }
          return null;
        })}

        {/* Parameter Importance */}
        <section className="chart-section">
          <h2 className="section-title">Parameter Importance Analysis</h2>
          <ParameterImportance
            paramNames={event.spaces.original.parameters}
            importances={mockParamImportances}
            topK={Math.min(20, event.spaces.original.parameters.length)}
          />
        </section>

        {/* Dimension Evolution */}
        <section className="chart-section">
          <h2 className="section-title">Dimension Evolution Over Iterations</h2>
          <DimensionEvolution iterations={mockIterations} dimensions={mockDimensions} />
        </section>

        {/* Multi-Task Heatmap */}
        <section className="chart-section">
          <h2 className="section-title">Multi-Task Parameter Importance</h2>
          <MultiTaskHeatmap
            paramNames={event.spaces.original.parameters}
            importances={mockMultiTaskImportances}
            tasks={['Task A', 'Task B']}
          />
        </section>

        {/* Source Task Similarities */}
        <section className="chart-section">
          <h2 className="section-title">Source Task Similarities</h2>
          <SourceSimilarities similarities={mockSourceSimilarities} />
        </section>
      </main>

      <footer className="app-footer">
        <p>Dimensio Visualization Dashboard v1.0 | Powered by React + TypeScript + ECharts</p>
      </footer>
    </div>
  );
};

export default App;
