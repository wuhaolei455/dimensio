/**
 * useUploadWizard Hook
 * 
 * 封装 holly-fsm 状态机的 React Hook
 * 提供响应式的状态管理和副作用处理
 */

import { useState, useCallback, useEffect, useRef, useMemo } from 'react';
import { 
  createUploadWizardMachine, 
  WizardState, 
  stateToStep,
  UploadWizardMachine,
} from '../machines/uploadWizardMachine';
import { StepsConfig } from '../components/StepsForm';

/** 上传响应类型 */
export interface UploadResponse {
  success: boolean;
  message?: string;
  error?: string;
  compression?: {
    status: string;
    message: string;
    result?: {
      original_dim: number;
      surrogate_dim: number;
      compression_ratio: number;
    };
  };
}

/** 向导上下文数据 */
export interface WizardContext {
  configSpace: Record<string, any> | null;
  stepsConfig: StepsConfig | null;
  historyFiles: File[];
  uploadResult: UploadResponse | null;
}

/** useUploadWizard Hook 返回类型 */
export interface UseUploadWizardReturn {
  // 状态
  state: WizardState;
  step: number;
  context: WizardContext;
  isUploading: boolean;
  
  // 动作
  next: (data?: any) => Promise<void>;
  back: () => Promise<void>;
  submit: (files: File[]) => Promise<void>;
  reset: () => void;
  retry: () => Promise<void>;
  
  // 辅助方法
  setConfigSpace: (config: Record<string, any>) => void;
  setStepsConfig: (config: StepsConfig) => void;
}

/**
 * 上传向导 Hook
 * 
 * @param onUploadSuccess - 上传成功回调
 * @returns 向导状态和方法
 * 
 * @example
 * ```tsx
 * const { state, step, context, next, back, submit, reset } = useUploadWizard({
 *   onUploadSuccess: () => refetch(),
 * });
 * 
 * // 根据状态渲染
 * if (state === 'configSpace') {
 *   return <ConfigSpaceForm onNext={(data) => next(data)} />;
 * }
 * ```
 */
export function useUploadWizard(options: {
  onUploadSuccess?: () => void;
} = {}): UseUploadWizardReturn {
  const { onUploadSuccess } = options;
  
  // 状态机实例（使用 ref 保持引用稳定）
  const machineRef = useRef<UploadWizardMachine | null>(null);
  
  // React 状态
  const [state, setState] = useState<WizardState>('configSpace');
  const [context, setContext] = useState<WizardContext>({
    configSpace: null,
    stepsConfig: null,
    historyFiles: [],
    uploadResult: null,
  });
  const [isUploading, setIsUploading] = useState(false);
  
  // 初始化状态机
  useEffect(() => {
    const machine = createUploadWizardMachine('configSpace');
    machineRef.current = machine;
    
    // 监听状态进入
    const unsubEnter = machine.onEnter(({ current }) => {
      setState(current as WizardState);
    });
    
    return () => {
      unsubEnter();
    };
  }, []);
  
  // 计算当前步骤
  const step = useMemo(() => stateToStep[state], [state]);
  
  // 设置配置空间
  const setConfigSpace = useCallback((config: Record<string, any>) => {
    setContext(prev => ({ ...prev, configSpace: config }));
  }, []);
  
  // 设置步骤配置
  const setStepsConfig = useCallback((config: StepsConfig) => {
    setContext(prev => ({ ...prev, stepsConfig: config }));
  }, []);
  
  // 下一步
  const next = useCallback(async (data?: any) => {
    const machine = machineRef.current;
    if (!machine) return;
    
    const currentState = machine.getState();
    
    // 根据当前状态保存数据
    if (currentState === 'configSpace' && data) {
      setConfigSpace(data);
    } else if (currentState === 'stepsConfig' && data) {
      setStepsConfig(data);
    }
    
    await machine.next();
  }, [setConfigSpace, setStepsConfig]);
  
  // 上一步
  const back = useCallback(async () => {
    const machine = machineRef.current;
    if (!machine) return;
    await machine.back();
  }, []);
  
  // 执行上传
  const performUpload = useCallback(async (files: File[]) => {
    const { configSpace, stepsConfig } = context;
    
    if (!configSpace || !stepsConfig) {
      throw new Error('Missing configuration data');
    }
    
    const formData = new FormData();
    
    // 配置空间
    const configSpaceBlob = new Blob([JSON.stringify(configSpace, null, 2)], {
      type: 'application/json',
    });
    formData.append('config_space', configSpaceBlob, 'config_space.json');
    
    // 步骤配置（复用原有的转换逻辑）
    const convertStepParams = (params: Record<string, any>): Record<string, any> => {
      const converted = { ...params };
      
      if ('expert_params' in converted) {
        if (typeof converted.expert_params === 'string') {
          converted.expert_params = converted.expert_params
            .split(',')
            .map((s: string) => s.trim())
            .filter((s: string) => s.length > 0);
        } else if (!Array.isArray(converted.expert_params)) {
          converted.expert_params = [];
        }
      }
      
      if ('expert_ranges' in converted && converted.expert_ranges) {
        if (typeof converted.expert_ranges === 'string') {
          try {
            converted.expert_ranges = JSON.parse(converted.expert_ranges);
          } catch {
            converted.expert_ranges = {};
          }
        }
        
        if (typeof converted.expert_ranges === 'object' && !Array.isArray(converted.expert_ranges)) {
          const normalizedRanges: Record<string, [number, number]> = {};
          Object.entries(converted.expert_ranges as Record<string, any>).forEach(([paramName, rangeValue]) => {
            if (!rangeValue) return;
            let minVal: any, maxVal: any;
            if (Array.isArray(rangeValue)) {
              [minVal, maxVal] = rangeValue;
            } else if (typeof rangeValue === 'object') {
              minVal = (rangeValue as any).min ?? rangeValue[0];
              maxVal = (rangeValue as any).max ?? rangeValue[1];
            }
            if (minVal === undefined || maxVal === undefined) return;
            const minNum = typeof minVal === 'number' ? minVal : parseFloat(String(minVal));
            const maxNum = typeof maxVal === 'number' ? maxVal : parseFloat(String(maxVal));
            if (Number.isNaN(minNum) || Number.isNaN(maxNum)) return;
            normalizedRanges[paramName] = [minNum, maxNum];
          });
          converted.expert_ranges = normalizedRanges;
        }
      }
      
      for (const key in converted) {
        if (converted[key] === 'true') converted[key] = true;
        else if (converted[key] === 'false') converted[key] = false;
      }
      
      if ('similarity_method' in converted) {
        if (!converted.importance_calculator && converted.similarity_method) {
          converted.importance_calculator = converted.similarity_method;
        }
        delete converted.similarity_method;
      }
      
      return converted;
    };
    
    const step_params: Record<string, any> = {};
    
    if (stepsConfig.dimension_params && Object.keys(stepsConfig.dimension_params).length > 0) {
      step_params[stepsConfig.dimension_step] = convertStepParams(stepsConfig.dimension_params);
    }
    if (stepsConfig.range_params && Object.keys(stepsConfig.range_params).length > 0) {
      step_params[stepsConfig.range_step] = convertStepParams(stepsConfig.range_params);
    }
    if (stepsConfig.projection_params && Object.keys(stepsConfig.projection_params).length > 0) {
      step_params[stepsConfig.projection_step] = convertStepParams(stepsConfig.projection_params);
    }
    
    const stepsData = {
      dimension_step: stepsConfig.dimension_step,
      range_step: stepsConfig.range_step,
      projection_step: stepsConfig.projection_step,
      step_params,
      ...(stepsConfig.filling_config?.fixed_values &&
        Object.keys(stepsConfig.filling_config.fixed_values).length > 0
        ? { filling_config: stepsConfig.filling_config }
        : {}),
    };
    
    const stepsBlob = new Blob([JSON.stringify(stepsData, null, 2)], {
      type: 'application/json',
    });
    formData.append('steps', stepsBlob, 'steps.json');
    
    files.forEach((file) => {
      formData.append('history', file);
    });
    
    const response = await fetch('/api/upload', {
      method: 'POST',
      body: formData,
    });
    
    return response.json();
  }, [context]);
  
  // 提交
  const submit = useCallback(async (files: File[]) => {
    const machine = machineRef.current;
    if (!machine) return;
    
    setContext(prev => ({ ...prev, historyFiles: files }));
    await machine.submit();
    setIsUploading(true);
    
    try {
      const result = await performUpload(files);
      setContext(prev => ({ ...prev, uploadResult: result }));
      
      if (result.success) {
        await machine.uploadSuccess();
        setTimeout(() => {
          onUploadSuccess?.();
        }, 2000);
      } else {
        await machine.uploadError();
      }
    } catch (error) {
      setContext(prev => ({
        ...prev,
        uploadResult: {
          success: false,
          error: error instanceof Error ? error.message : 'Upload failed',
        },
      }));
      await machine.uploadError();
    } finally {
      setIsUploading(false);
    }
  }, [performUpload, onUploadSuccess]);
  
  // 重置
  const reset = useCallback(() => {
    const machine = machineRef.current;
    if (!machine) return;
    
    machine.reset();
    setContext({
      configSpace: null,
      stepsConfig: null,
      historyFiles: [],
      uploadResult: null,
    });
    setIsUploading(false);
  }, []);
  
  // 重试
  const retry = useCallback(async () => {
    const machine = machineRef.current;
    if (!machine) return;
    
    setContext(prev => ({ ...prev, uploadResult: null }));
    await machine.retry();
  }, []);
  
  return {
    state,
    step,
    context,
    isUploading,
    next,
    back,
    submit,
    reset,
    retry,
    setConfigSpace,
    setStepsConfig,
  };
}

export default useUploadWizard;
