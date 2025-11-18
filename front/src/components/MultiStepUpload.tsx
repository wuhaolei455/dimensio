import React, { useState } from 'react';
import ConfigSpaceForm from './ConfigSpaceForm';
import StepsForm, { StepsConfig } from './StepsForm';
import HistoryUploadForm from './HistoryUploadForm';
import './MultiStepUpload.css';

interface MultiStepUploadProps {
  onUploadSuccess: () => void;
}

interface UploadResponse {
  success: boolean;
  message?: string;
  error?: string;
  compression?: {
    status: string;
    message: string;
    result?: any;
  };
}

const MultiStepUpload: React.FC<MultiStepUploadProps> = ({ onUploadSuccess }) => {
  const [showModal, setShowModal] = useState(false);
  const [currentStep, setCurrentStep] = useState(1);
  const [configSpace, setConfigSpace] = useState<Record<string, any> | null>(null);
  const [stepsConfig, setStepsConfig] = useState<StepsConfig | null>(null);
  const [uploading, setUploading] = useState(false);
  const [uploadResult, setUploadResult] = useState<UploadResponse | null>(null);

  const handleConfigSpaceNext = (config: Record<string, any>) => {
    setConfigSpace(config);
    setCurrentStep(2);
  };

  const handleStepsNext = (steps: StepsConfig) => {
    setStepsConfig(steps);
    setCurrentStep(3);
  };

  const handleHistorySubmit = async (historyFiles: File[]) => {
    if (!configSpace || !stepsConfig) {
      alert('Missing configuration data');
      return;
    }

    setUploading(true);
    setUploadResult(null);

    try {
      const formData = new FormData();

      // Convert config space to JSON file
      const configSpaceBlob = new Blob([JSON.stringify(configSpace, null, 2)], {
        type: 'application/json',
      });
      formData.append('config_space', configSpaceBlob, 'config_space.json');

      // Helper function to convert parameters to backend format
      const convertStepParams = (params: Record<string, any>, stepKey: string): Record<string, any> => {
        const converted = { ...params };

        // Convert expert_params from comma-separated string to array
        if ('expert_params' in converted && typeof converted.expert_params === 'string') {
          converted.expert_params = converted.expert_params
            .split(',')
            .map((s: string) => s.trim())
            .filter((s: string) => s.length > 0);
        }

        // Convert expert_ranges from JSON string to object
        if ('expert_ranges' in converted && typeof converted.expert_ranges === 'string') {
          try {
            converted.expert_ranges = JSON.parse(converted.expert_ranges);
          } catch (e) {
            console.error('Failed to parse expert_ranges:', e);
            converted.expert_ranges = {};
          }
        }

        // Convert boolean strings to actual booleans
        for (const key in converted) {
          if (converted[key] === 'true') {
            converted[key] = true;
          } else if (converted[key] === 'false') {
            converted[key] = false;
          }
        }

        return converted;
      };

      // Convert steps config to JSON file with parameters
      const step_params: Record<string, any> = {};

      // Add dimension step params if any
      if (stepsConfig.dimension_params && Object.keys(stepsConfig.dimension_params).length > 0) {
        step_params[stepsConfig.dimension_step] = convertStepParams(
          stepsConfig.dimension_params,
          stepsConfig.dimension_step
        );
      }

      // Add range step params if any
      if (stepsConfig.range_params && Object.keys(stepsConfig.range_params).length > 0) {
        step_params[stepsConfig.range_step] = convertStepParams(
          stepsConfig.range_params,
          stepsConfig.range_step
        );
      }

      // Add projection step params if any
      if (stepsConfig.projection_params && Object.keys(stepsConfig.projection_params).length > 0) {
        step_params[stepsConfig.projection_step] = convertStepParams(
          stepsConfig.projection_params,
          stepsConfig.projection_step
        );
      }

      const stepsData = {
        dimension_step: stepsConfig.dimension_step,
        range_step: stepsConfig.range_step,
        projection_step: stepsConfig.projection_step,
        step_params: step_params,
      };

      const stepsBlob = new Blob([JSON.stringify(stepsData, null, 2)], {
        type: 'application/json',
      });
      formData.append('steps', stepsBlob, 'steps.json');

      // Append history files
      historyFiles.forEach((file) => {
        formData.append('history', file);
      });

      const response = await fetch('http://127.0.0.1:5000/api/upload', {
        method: 'POST',
        body: formData,
      });

      const data: UploadResponse = await response.json();
      setUploadResult(data);

      if (data.success) {
        setTimeout(() => {
          onUploadSuccess();
          handleClose();
        }, 2000);
      }
    } catch (error) {
      console.error('Upload error:', error);
      setUploadResult({
        success: false,
        error: error instanceof Error ? error.message : 'Upload failed',
      });
    } finally {
      setUploading(false);
    }
  };

  const handleClose = () => {
    if (!uploading) {
      setShowModal(false);
      setCurrentStep(1);
      setConfigSpace(null);
      setStepsConfig(null);
      setUploadResult(null);
    }
  };

  const handleBack = () => {
    if (currentStep > 1) {
      setCurrentStep(currentStep - 1);
    }
  };

  return (
    <>
      <button className="upload-button" onClick={() => setShowModal(true)}>
        Configure & Upload
      </button>

      {showModal && (
        <div className="modal-overlay" onClick={handleClose}>
          <div className="modal-content multi-step" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h2>Compression Configuration</h2>
              <button className="close-button" onClick={handleClose} disabled={uploading}>
                ×
              </button>
            </div>

            <div className="step-indicator">
              <div className={`step ${currentStep >= 1 ? 'active' : ''} ${currentStep > 1 ? 'completed' : ''}`}>
                <div className="step-number">1</div>
                <div className="step-label">Config Space</div>
              </div>
              <div className="step-line"></div>
              <div className={`step ${currentStep >= 2 ? 'active' : ''} ${currentStep > 2 ? 'completed' : ''}`}>
                <div className="step-number">2</div>
                <div className="step-label">Steps</div>
              </div>
              <div className="step-line"></div>
              <div className={`step ${currentStep >= 3 ? 'active' : ''}`}>
                <div className="step-number">3</div>
                <div className="step-label">History</div>
              </div>
            </div>

            <div className="modal-body">
              {currentStep === 1 && (
                <ConfigSpaceForm onNext={handleConfigSpaceNext} initialData={configSpace || undefined} />
              )}

              {currentStep === 2 && (
                <StepsForm
                  onNext={handleStepsNext}
                  onBack={handleBack}
                  initialData={stepsConfig || undefined}
                  configSpace={configSpace || undefined}
                />
              )}

              {currentStep === 3 && (
                <HistoryUploadForm
                  onSubmit={handleHistorySubmit}
                  onBack={handleBack}
                  uploading={uploading}
                />
              )}

              {uploadResult && (
                <div className={`upload-result ${uploadResult.success ? 'success' : 'error'}`}>
                  <h4>{uploadResult.success ? '✓ Success!' : '✗ Error'}</h4>
                  <p>{uploadResult.message || uploadResult.error}</p>
                  {uploadResult.compression && uploadResult.compression.result && (
                    <div className="compression-details">
                      <p>
                        <strong>Original Dimension:</strong>{' '}
                        {uploadResult.compression.result.original_dim}
                      </p>
                      <p>
                        <strong>Surrogate Dimension:</strong>{' '}
                        {uploadResult.compression.result.surrogate_dim}
                      </p>
                      <p>
                        <strong>Compression Ratio:</strong>{' '}
                        {(uploadResult.compression.result.compression_ratio * 100).toFixed(2)}%
                      </p>
                    </div>
                  )}
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </>
  );
};

export default MultiStepUpload;
