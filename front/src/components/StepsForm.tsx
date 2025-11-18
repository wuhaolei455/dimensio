import React, { useState } from 'react';

export interface StepsConfig {
  dimension_step: string;
  range_step: string;
  projection_step: string;
  dimension_params?: Record<string, any>;
  range_params?: Record<string, any>;
  projection_params?: Record<string, any>;
}

interface StepParameter {
  name: string;
  label: string;
  type: 'number' | 'text' | 'select';
  default: any;
  options?: { value: any; label: string }[];
  min?: number;
  max?: number;
  step?: number;
  description?: string;
}

interface StepsFormProps {
  onNext: (steps: StepsConfig) => void;
  onBack: () => void;
  initialData?: StepsConfig;
  configSpace?: Record<string, any>;
}

const StepsForm: React.FC<StepsFormProps> = ({ onNext, onBack, initialData, configSpace }) => {
  // Calculate the number of dimensions in config space
  const maxDimensions = configSpace ? Object.keys(configSpace).length : undefined;

  const [steps, setSteps] = useState<StepsConfig>(
    initialData || {
      dimension_step: 'd_shap',
      range_step: 'r_boundary',
      projection_step: 'p_none',
      dimension_params: { topk: 20 },
      range_params: { top_ratio: 0.8, sigma: 2.0, enable_mixed_sampling: true, initial_prob: 0.9 },
      projection_params: {},
    }
  );

  // Step descriptions mapping
  const dimensionSteps = [
    { value: 'd_shap', label: 'SHAP-based Selection', description: 'Select important dimensions using SHAP values' },
    { value: 'd_corr', label: 'Correlation-based Selection', description: 'Select dimensions based on correlation analysis' },
    { value: 'd_expert', label: 'Expert-defined Selection', description: 'Use expert knowledge for dimension selection' },
    { value: 'd_adaptive', label: 'Adaptive Selection', description: 'Dynamic dimension selection with topk adjustment' },
    { value: 'd_none', label: 'No Dimension Selection', description: 'Skip dimension selection step' },
  ];

  const rangeSteps = [
    { value: 'r_boundary', label: 'Boundary-based Range', description: 'Simple boundary analysis for range compression' },
    { value: 'r_shap', label: 'SHAP-weighted Boundary', description: 'Use SHAP values to weight boundary compression' },
    { value: 'r_kde', label: 'KDE-based Range', description: 'Kernel density estimation for range compression' },
    { value: 'r_expert', label: 'Expert-specified Range', description: 'Use expert-defined range compression' },
    { value: 'r_none', label: 'No Range Compression', description: 'Skip range compression step' },
  ];

  const projectionSteps = [
    { value: 'p_quant', label: 'Quantization Projection', description: 'Discretize continuous parameters' },
    { value: 'p_rembo', label: 'REMBO Projection', description: 'Random EMbedding Bayesian Optimization' },
    { value: 'p_hesbo', label: 'HeSBO Projection', description: 'Heterogeneous and Structured BO' },
    { value: 'p_kpca', label: 'Kernel PCA Projection', description: 'Non-linear dimensionality reduction' },
    { value: 'p_none', label: 'No Projection', description: 'Skip projection step' },
  ];

  // Define parameters for each step type
  const stepParameters: Record<string, StepParameter[]> = {
    'd_shap': [
      { name: 'topk', label: 'Top K', type: 'number', default: 20, min: 1, max: maxDimensions, description: maxDimensions ? `Number of top dimensions to select (max: ${maxDimensions})` : 'Number of top dimensions to select' },
    ],
    'd_corr': [
      { name: 'topk', label: 'Top K', type: 'number', default: 20, min: 1, max: maxDimensions, description: maxDimensions ? `Number of top dimensions to select (max: ${maxDimensions})` : 'Number of top dimensions to select' },
      { name: 'method', label: 'Method', type: 'select', default: 'spearman', options: [
        { value: 'spearman', label: 'Spearman' },
        { value: 'pearson', label: 'Pearson' },
      ], description: 'Correlation method' },
    ],
    'd_expert': [
      { name: 'expert_params', label: 'Expert Parameters', type: 'text', default: '', description: 'Comma-separated parameter names' },
    ],
    'd_adaptive': [
      { name: 'initial_topk', label: 'Initial Top K', type: 'number', default: 30, min: 1, max: maxDimensions, description: maxDimensions ? `Initial number of dimensions (max: ${maxDimensions})` : 'Initial number of dimensions' },
      { name: 'reduction_ratio', label: 'Reduction Ratio', type: 'number', default: 0.2, min: 0, max: 1, step: 0.1, description: 'Ratio for dimension reduction' },
      { name: 'min_dimensions', label: 'Min Dimensions', type: 'number', default: 5, min: 1, max: maxDimensions, description: maxDimensions ? `Minimum dimensions to keep (max: ${maxDimensions})` : 'Minimum dimensions to keep' },
    ],
    'r_boundary': [
      { name: 'top_ratio', label: 'Top Ratio', type: 'number', default: 0.8, min: 0, max: 1, step: 0.1, description: 'Ratio of top observations to consider' },
      { name: 'sigma', label: 'Sigma', type: 'number', default: 2.0, min: 0, step: 0.1, description: 'Sigma for boundary calculation' },
      { name: 'enable_mixed_sampling', label: 'Enable Mixed Sampling', type: 'select', default: 'true', options: [
        { value: 'true', label: 'True' },
        { value: 'false', label: 'False' },
      ], description: 'Enable mixed sampling strategy' },
      { name: 'initial_prob', label: 'Initial Probability', type: 'number', default: 0.9, min: 0, max: 1, step: 0.1, description: 'Initial sampling probability' },
    ],
    'r_shap': [
      { name: 'top_ratio', label: 'Top Ratio', type: 'number', default: 0.8, min: 0, max: 1, step: 0.1, description: 'Ratio of top observations to consider' },
      { name: 'sigma', label: 'Sigma', type: 'number', default: 2.0, min: 0, step: 0.1, description: 'Sigma for boundary calculation' },
      { name: 'enable_mixed_sampling', label: 'Enable Mixed Sampling', type: 'select', default: 'true', options: [
        { value: 'true', label: 'True' },
        { value: 'false', label: 'False' },
      ], description: 'Enable mixed sampling strategy' },
      { name: 'initial_prob', label: 'Initial Probability', type: 'number', default: 0.9, min: 0, max: 1, step: 0.1, description: 'Initial sampling probability' },
    ],
    'r_kde': [
      { name: 'source_top_ratio', label: 'Source Top Ratio', type: 'number', default: 0.3, min: 0, max: 1, step: 0.1, description: 'Ratio of top source observations' },
      { name: 'kde_coverage', label: 'KDE Coverage', type: 'number', default: 0.6, min: 0, max: 1, step: 0.1, description: 'KDE coverage ratio' },
      { name: 'enable_mixed_sampling', label: 'Enable Mixed Sampling', type: 'select', default: 'true', options: [
        { value: 'true', label: 'True' },
        { value: 'false', label: 'False' },
      ], description: 'Enable mixed sampling strategy' },
      { name: 'initial_prob', label: 'Initial Probability', type: 'number', default: 0.9, min: 0, max: 1, step: 0.1, description: 'Initial sampling probability' },
    ],
    'r_expert': [
      { name: 'expert_ranges', label: 'Expert Ranges', type: 'text', default: '{}', description: 'JSON object with parameter ranges' },
      { name: 'enable_mixed_sampling', label: 'Enable Mixed Sampling', type: 'select', default: 'false', options: [
        { value: 'true', label: 'True' },
        { value: 'false', label: 'False' },
      ], description: 'Enable mixed sampling strategy' },
    ],
    'p_quant': [
      { name: 'max_num_values', label: 'Max Number of Values', type: 'number', default: 10, min: 2, description: 'Maximum number of discrete values' },
      { name: 'adaptive', label: 'Adaptive', type: 'select', default: 'false', options: [
        { value: 'true', label: 'True' },
        { value: 'false', label: 'False' },
      ], description: 'Use adaptive quantization' },
    ],
    'p_rembo': [
      { name: 'low_dim', label: 'Low Dimension', type: 'number', default: 10, min: 1, description: 'Target low dimension' },
    ],
    'p_hesbo': [
      { name: 'low_dim', label: 'Low Dimension', type: 'number', default: 10, min: 1, description: 'Target low dimension' },
      { name: 'max_num_values', label: 'Max Number of Values', type: 'number', default: 10, min: 2, description: 'Maximum number of discrete values' },
    ],
    'p_kpca': [
      { name: 'n_components', label: 'Number of Components', type: 'number', default: 10, min: 1, description: 'Number of principal components' },
      { name: 'kernel', label: 'Kernel', type: 'select', default: 'rbf', options: [
        { value: 'rbf', label: 'RBF' },
        { value: 'linear', label: 'Linear' },
        { value: 'poly', label: 'Polynomial' },
        { value: 'sigmoid', label: 'Sigmoid' },
      ], description: 'Kernel type' },
    ],
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    // Validate topk values against max dimensions
    if (maxDimensions) {
      const dimensionParams = steps.dimension_params || {};

      if (steps.dimension_step === 'd_shap' || steps.dimension_step === 'd_corr') {
        const topk = dimensionParams.topk;
        if (topk && topk > maxDimensions) {
          alert(`Top K (${topk}) cannot exceed the number of dimensions in config space (${maxDimensions})`);
          return;
        }
      }

      if (steps.dimension_step === 'd_adaptive') {
        const initialTopk = dimensionParams.initial_topk;
        const minDimensions = dimensionParams.min_dimensions;

        if (initialTopk && initialTopk > maxDimensions) {
          alert(`Initial Top K (${initialTopk}) cannot exceed the number of dimensions in config space (${maxDimensions})`);
          return;
        }

        if (minDimensions && minDimensions > maxDimensions) {
          alert(`Min Dimensions (${minDimensions}) cannot exceed the number of dimensions in config space (${maxDimensions})`);
          return;
        }
      }
    }

    onNext(steps);
  };

  const updateStep = (field: keyof StepsConfig, value: string) => {
    const newSteps = { ...steps, [field]: value };

    // Initialize default parameters for the selected step
    const paramField = field === 'dimension_step' ? 'dimension_params' :
                      field === 'range_step' ? 'range_params' : 'projection_params';

    // If the step is '*_none', clear the parameters completely
    if (value.endsWith('_none')) {
      newSteps[paramField] = {};
    } else {
      const params = stepParameters[value] || [];
      const defaultParams: Record<string, any> = {};
      params.forEach((param) => {
        defaultParams[param.name] = param.default;
      });
      newSteps[paramField] = defaultParams;
    }

    setSteps(newSteps);
  };

  const updateStepParam = (
    stepType: 'dimension_params' | 'range_params' | 'projection_params',
    paramName: string,
    value: any
  ) => {
    // Validate topk related parameters against max dimensions
    if (maxDimensions && stepType === 'dimension_params' &&
        (paramName === 'topk' || paramName === 'initial_topk' || paramName === 'min_dimensions')) {
      const numValue = typeof value === 'number' ? value : parseFloat(value);
      if (!isNaN(numValue) && numValue > maxDimensions) {
        // Clamp the value to maxDimensions
        value = maxDimensions;
      }
    }

    setSteps({
      ...steps,
      [stepType]: {
        ...steps[stepType],
        [paramName]: value,
      },
    });
  };

  const getStepLabel = (value: string, stepList: { value: string; label: string }[]) => {
    return stepList.find(s => s.value === value)?.label || value;
  };

  const renderStepParameters = (
    stepValue: string,
    paramType: 'dimension_params' | 'range_params' | 'projection_params'
  ) => {
    const params = stepParameters[stepValue];
    if (!params || params.length === 0 || stepValue.endsWith('_none')) {
      return null;
    }

    return (
      <div className="step-parameters">
        <h4>Parameters</h4>
        {params.map((param) => (
          <div key={param.name} className="param-field">
            <label>{param.label}</label>
            {param.type === 'number' && (
              <input
                type="number"
                value={steps[paramType]?.[param.name] ?? param.default}
                onChange={(e) => updateStepParam(paramType, param.name, parseFloat(e.target.value))}
                min={param.min}
                max={param.max}
                step={param.step || 1}
              />
            )}
            {param.type === 'text' && (
              <input
                type="text"
                value={steps[paramType]?.[param.name] ?? param.default}
                onChange={(e) => updateStepParam(paramType, param.name, e.target.value)}
                placeholder={param.description}
              />
            )}
            {param.type === 'select' && param.options && (
              <select
                value={steps[paramType]?.[param.name] ?? param.default}
                onChange={(e) => updateStepParam(paramType, param.name, e.target.value === 'true' ? true : e.target.value === 'false' ? false : e.target.value)}
              >
                {param.options.map((opt) => (
                  <option key={opt.value} value={opt.value}>
                    {opt.label}
                  </option>
                ))}
              </select>
            )}
            {param.description && (
              <p className="param-hint">{param.description}</p>
            )}
          </div>
        ))}
      </div>
    );
  };

  return (
    <form onSubmit={handleSubmit} className="steps-form">
      <div className="form-header">
        <h3>Step 2: Configure Compression Steps</h3>
        <p className="form-description">Select the compression pipeline configuration</p>
      </div>

      <div className="form-content">
        <div className="form-section">
          <div className="form-field">
            <label>Dimension Selection Step</label>
            <select
              value={steps.dimension_step}
              onChange={(e) => updateStep('dimension_step', e.target.value)}
              required
            >
              {dimensionSteps.map((step) => (
                <option key={step.value} value={step.value}>
                  {step.label}
                </option>
              ))}
            </select>
            <p className="field-hint">
              {dimensionSteps.find(s => s.value === steps.dimension_step)?.description}
            </p>
            {renderStepParameters(steps.dimension_step, 'dimension_params')}
          </div>

          <div className="form-field">
            <label>Range Compression Step</label>
            <select
              value={steps.range_step}
              onChange={(e) => updateStep('range_step', e.target.value)}
              required
            >
              {rangeSteps.map((step) => (
                <option key={step.value} value={step.value}>
                  {step.label}
                </option>
              ))}
            </select>
            <p className="field-hint">
              {rangeSteps.find(s => s.value === steps.range_step)?.description}
            </p>
            {renderStepParameters(steps.range_step, 'range_params')}
          </div>

          <div className="form-field">
            <label>Projection Step</label>
            <select
              value={steps.projection_step}
              onChange={(e) => updateStep('projection_step', e.target.value)}
              required
            >
              {projectionSteps.map((step) => (
                <option key={step.value} value={step.value}>
                  {step.label}
                </option>
              ))}
            </select>
            <p className="field-hint">
              {projectionSteps.find(s => s.value === steps.projection_step)?.description}
            </p>
            {renderStepParameters(steps.projection_step, 'projection_params')}
          </div>
        </div>

        <div className="info-box">
          <h4>Configuration Summary</h4>
          <ul>
            <li>
              <strong>Dimension Step:</strong> {getStepLabel(steps.dimension_step, dimensionSteps)}
            </li>
            <li>
              <strong>Range Step:</strong> {getStepLabel(steps.range_step, rangeSteps)}
            </li>
            <li>
              <strong>Projection Step:</strong> {getStepLabel(steps.projection_step, projectionSteps)}
            </li>
          </ul>
        </div>
      </div>

      <div className="form-actions">
        <button type="button" className="btn btn-secondary" onClick={onBack}>
          Back
        </button>
        <button type="submit" className="btn btn-primary">
          Next: Upload History
        </button>
      </div>
    </form>
  );
};

export default StepsForm;
