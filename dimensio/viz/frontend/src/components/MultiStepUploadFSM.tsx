/**
 * MultiStepUploadFSM 组件
 * 
 * 使用 holly-fsm 状态机重构的多步骤表单
 * 实现可预测的状态转换和回退逻辑
 * 
 * 优势：
 * - 状态转换清晰可预测
 * - 类型安全的状态和动作
 * - 易于测试和调试
 * - 支持状态监听和副作用
 */

import React, { useState, useCallback } from 'react';
import ConfigSpaceForm from './ConfigSpaceForm';
import StepsForm, { StepsConfig } from './StepsForm';
import HistoryUploadForm from './HistoryUploadForm';
import { useUploadWizard } from '../hooks/useUploadWizard';
import './MultiStepUpload.css';

interface MultiStepUploadFSMProps {
  onUploadSuccess: () => void;
}

/**
 * 步骤指示器组件
 */
const StepIndicator: React.FC<{ currentStep: number }> = ({ currentStep }) => (
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
);

/**
 * 上传结果显示组件
 */
const UploadResult: React.FC<{ result: NonNullable<ReturnType<typeof useUploadWizard>['context']['uploadResult']> }> = ({ result }) => (
  <div className={`upload-result ${result.success ? 'success' : 'error'}`}>
    <h4>{result.success ? '✓ Success!' : '✗ Error'}</h4>
    <p>{result.message || result.error}</p>
    {result.compression?.result && (
      <div className="compression-details">
        <p><strong>Original Dimension:</strong> {result.compression.result.original_dim}</p>
        <p><strong>Surrogate Dimension:</strong> {result.compression.result.surrogate_dim}</p>
        <p><strong>Compression Ratio:</strong> {(result.compression.result.compression_ratio * 100).toFixed(2)}%</p>
      </div>
    )}
  </div>
);

/**
 * 状态机驱动的多步骤上传组件
 */
const MultiStepUploadFSM: React.FC<MultiStepUploadFSMProps> = ({ onUploadSuccess }) => {
  const [showModal, setShowModal] = useState(false);
  
  // 使用状态机 Hook
  const {
    state,
    step,
    context,
    isUploading,
    next,
    back,
    submit,
    reset,
    retry,
  } = useUploadWizard({ onUploadSuccess });

  // 关闭弹窗
  const handleClose = useCallback(() => {
    if (!isUploading) {
      setShowModal(false);
      reset();
    }
  }, [isUploading, reset]);

  // 打开弹窗
  const handleOpen = useCallback(() => {
    setShowModal(true);
  }, []);

  // 配置空间提交
  const handleConfigSpaceNext = useCallback((config: Record<string, any>) => {
    next(config);
  }, [next]);

  // 步骤配置提交
  const handleStepsNext = useCallback((steps: StepsConfig) => {
    next(steps);
  }, [next]);

  // 历史文件提交
  const handleHistorySubmit = useCallback((files: File[]) => {
    submit(files);
  }, [submit]);

  // 渲染当前步骤内容
  const renderStepContent = () => {
    switch (state) {
      case 'configSpace':
        return (
          <ConfigSpaceForm 
            onNext={handleConfigSpaceNext} 
            initialData={context.configSpace || undefined} 
          />
        );
      
      case 'stepsConfig':
        return (
          <StepsForm
            onNext={handleStepsNext}
            onBack={back}
            initialData={context.stepsConfig || undefined}
            configSpace={context.configSpace || undefined}
          />
        );
      
      case 'historyUpload':
        return (
          <HistoryUploadForm
            onSubmit={handleHistorySubmit}
            onBack={back}
            uploading={false}
          />
        );
      
      case 'uploading':
        return (
          <div className="uploading-state">
            <div className="spinner"></div>
            <p>Uploading and processing...</p>
          </div>
        );
      
      case 'success':
      case 'error':
        return null; // 结果显示在下方
      
      default:
        return null;
    }
  };

  return (
    <>
      <button className="upload-button" onClick={handleOpen}>
        Configure & Upload
      </button>

      {showModal && (
        <div className="modal-overlay" onClick={handleClose}>
          <div className="modal-content multi-step" onClick={(e) => e.stopPropagation()}>
            {/* 头部 */}
            <div className="modal-header">
              <h2>Compression Configuration</h2>
              <div className="modal-header-badge">
                <span className="fsm-badge">FSM</span>
              </div>
              <button className="close-button" onClick={handleClose} disabled={isUploading}>
                ×
              </button>
            </div>

            {/* 步骤指示器 */}
            <StepIndicator currentStep={step} />

            {/* 内容区域 */}
            <div className="modal-body">
              {renderStepContent()}
              
              {/* 上传结果 */}
              {context.uploadResult && (
                <UploadResult result={context.uploadResult} />
              )}
              
              {/* 错误状态操作 */}
              {state === 'error' && (
                <div className="error-actions">
                  <button className="btn-retry" onClick={retry}>
                    Retry Upload
                  </button>
                  <button className="btn-reset" onClick={reset}>
                    Start Over
                  </button>
                </div>
              )}
              
              {/* 成功状态操作 */}
              {state === 'success' && (
                <div className="success-actions">
                  <button className="btn-close" onClick={handleClose}>
                    Close
                  </button>
                </div>
              )}
            </div>

            {/* 调试信息（开发模式） */}
            {process.env.NODE_ENV === 'development' && (
              <div className="fsm-debug">
                <span>State: <code>{state}</code></span>
                <span>Step: <code>{step}</code></span>
              </div>
            )}
          </div>
        </div>
      )}
    </>
  );
};

export default MultiStepUploadFSM;
