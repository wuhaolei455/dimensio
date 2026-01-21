/**
 * 多步骤上传表单状态机
 * 
 * 使用 holly-fsm 实现可预测的状态转换和回退逻辑
 * 
 * 状态流程：
 * configSpace → stepsConfig → historyUpload → uploading → success/error
 */

import { createMachine } from 'holly-fsm';

/**
 * 状态机配置
 * 
 * 每个状态定义可触发的动作及其目标状态
 */
export const uploadWizardConfig = {
  // 步骤1：配置空间
  configSpace: {
    next: () => 'stepsConfig' as const,
  },
  // 步骤2：步骤配置
  stepsConfig: {
    next: () => 'historyUpload' as const,
    back: () => 'configSpace' as const,
  },
  // 步骤3：历史上传
  historyUpload: {
    submit: () => 'uploading' as const,
    back: () => 'stepsConfig' as const,
  },
  // 上传中
  uploading: {
    uploadSuccess: () => 'success' as const,
    uploadError: () => 'error' as const,
  },
  // 上传成功
  success: {
    reset: () => 'configSpace' as const,
  },
  // 上传失败
  error: {
    retry: () => 'historyUpload' as const,
    reset: () => 'configSpace' as const,
  },
} as const;

// 状态类型
export type WizardState = keyof typeof uploadWizardConfig;

// 动作类型
export type WizardAction = 
  | 'next' 
  | 'back' 
  | 'submit' 
  | 'uploadSuccess' 
  | 'uploadError' 
  | 'retry' 
  | 'reset';

/**
 * 创建上传向导状态机
 * 
 * @param initialState - 初始状态，默认为 'configSpace'
 * @returns 状态机实例
 * 
 * @example
 * ```tsx
 * const machine = createUploadWizardMachine();
 * // 监听状态变化
 * machine.onEnter(({ current, last, action }) => {
 *   console.log(`从 ${last} 转换到 ${current}，动作: ${action}`);
 * });
 * 
 * // 触发动作
 * await machine.next();  // configSpace → stepsConfig
 * await machine.back();  // stepsConfig → configSpace
 * 
 * // 获取当前状态
 * const currentState = machine.getState();
 * ```
 */
export function createUploadWizardMachine(initialState: WizardState = 'configSpace') {
  return createMachine(uploadWizardConfig, { initialState });
}

// 状态机实例类型
export type UploadWizardMachine = ReturnType<typeof createUploadWizardMachine>;

/**
 * 状态到步骤数字的映射
 */
export const stateToStep: Record<WizardState, number> = {
  configSpace: 1,
  stepsConfig: 2,
  historyUpload: 3,
  uploading: 3,
  success: 3,
  error: 3,
};

/**
 * 判断是否为表单步骤状态
 */
export const isFormStep = (state: WizardState): boolean => {
  return ['configSpace', 'stepsConfig', 'historyUpload'].includes(state);
};

/**
 * 判断是否为终态
 */
export const isFinalState = (state: WizardState): boolean => {
  return ['success', 'error'].includes(state);
};
