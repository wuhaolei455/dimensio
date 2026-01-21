/**
 * useChunkedData Hook
 * 
 * 大数据分片渲染，支持 10000+ 数据点的流畅展示
 * 使用 requestIdleCallback 在空闲时间渲染，不阻塞主线程
 * 
 * 特性：
 * - 分片加载大数据集
 * - 渲染进度反馈
 * - 支持自定义分片大小
 * - 使用 requestIdleCallback 优化性能
 */

import { useState, useEffect, useRef, useCallback, useMemo } from 'react';
import type { UseChunkedDataOptions, UseChunkedDataReturn } from '../types';

// requestIdleCallback polyfill
const requestIdleCallbackPolyfill = 
  typeof window !== 'undefined' && 'requestIdleCallback' in window
    ? window.requestIdleCallback
    : (callback: IdleRequestCallback, options?: IdleRequestOptions): number => {
        const start = Date.now();
        return window.setTimeout(() => {
          callback({
            didTimeout: false,
            timeRemaining: () => Math.max(0, 50 - (Date.now() - start)),
          });
        }, options?.timeout ?? 1) as unknown as number;
      };

const cancelIdleCallbackPolyfill = 
  typeof window !== 'undefined' && 'cancelIdleCallback' in window
    ? window.cancelIdleCallback
    : (id: number) => window.clearTimeout(id);

/**
 * 大数据分片渲染 Hook
 * 
 * @param data - 需要分片渲染的数据数组
 * @param options - 配置选项
 * @returns 包含 displayData、progress、isComplete 等状态的对象
 * 
 * @example
 * ```tsx
 * // 处理 10000+ 数据点
 * const { displayData, progress, isComplete } = useChunkedData(largeDataset, {
 *   chunkSize: 500,
 *   threshold: 1000,
 * });
 * 
 * return (
 *   <>
 *     {!isComplete && <ProgressBar progress={progress} />}
 *     <Chart data={displayData} />
 *   </>
 * );
 * ```
 */
export function useChunkedData<T>(
  data: T[],
  options: UseChunkedDataOptions = {}
): UseChunkedDataReturn<T> {
  const {
    chunkSize = 500,
    enabled = true,
    threshold = 1000,
    onComplete,
    idleTimeout = 50,
  } = options;

  // 判断是否需要分片
  const shouldChunk = useMemo(() => 
    enabled && data.length > threshold, 
    [enabled, data.length, threshold]
  );

  const [displayData, setDisplayData] = useState<T[]>(() => 
    shouldChunk ? [] : data
  );
  const [progress, setProgress] = useState(() => shouldChunk ? 0 : 100);
  const [isLoading, setIsLoading] = useState(shouldChunk);
  
  const idleCallbackRef = useRef<number | null>(null);
  const currentIndexRef = useRef(0);
  const onCompleteRef = useRef(onComplete);

  // 更新回调引用
  useEffect(() => {
    onCompleteRef.current = onComplete;
  }, [onComplete]);

  // 重置函数
  const reset = useCallback(() => {
    if (idleCallbackRef.current !== null) {
      cancelIdleCallbackPolyfill(idleCallbackRef.current);
      idleCallbackRef.current = null;
    }
    currentIndexRef.current = 0;
    
    if (shouldChunk) {
      setDisplayData([]);
      setProgress(0);
      setIsLoading(true);
    } else {
      setDisplayData(data);
      setProgress(100);
      setIsLoading(false);
    }
  }, [shouldChunk, data]);

  // 主要的分片加载逻辑
  useEffect(() => {
    // 数据为空时直接返回
    if (!data.length) {
      setDisplayData([]);
      setProgress(100);
      setIsLoading(false);
      return;
    }

    // 不需要分片时直接设置全部数据
    if (!shouldChunk) {
      setDisplayData(data);
      setProgress(100);
      setIsLoading(false);
      return;
    }

    // 清理之前的回调
    if (idleCallbackRef.current !== null) {
      cancelIdleCallbackPolyfill(idleCallbackRef.current);
    }

    // 重置状态
    currentIndexRef.current = 0;
    setDisplayData([]);
    setProgress(0);
    setIsLoading(true);

    // 分片渲染函数
    const renderChunk = () => {
      const startIndex = currentIndexRef.current;
      const endIndex = Math.min(startIndex + chunkSize, data.length);
      const chunk = data.slice(startIndex, endIndex);
      
      setDisplayData(prev => [...prev, ...chunk]);
      currentIndexRef.current = endIndex;
      
      const newProgress = Math.min(100, (endIndex / data.length) * 100);
      setProgress(newProgress);

      if (endIndex < data.length) {
        // 还有数据，继续调度
        idleCallbackRef.current = requestIdleCallbackPolyfill(renderChunk, { 
          timeout: idleTimeout 
        });
      } else {
        // 完成
        setIsLoading(false);
        idleCallbackRef.current = null;
        onCompleteRef.current?.();
      }
    };

    // 开始分片渲染
    idleCallbackRef.current = requestIdleCallbackPolyfill(renderChunk, { 
      timeout: idleTimeout 
    });

    // 清理函数
    return () => {
      if (idleCallbackRef.current !== null) {
        cancelIdleCallbackPolyfill(idleCallbackRef.current);
        idleCallbackRef.current = null;
      }
    };
  }, [data, chunkSize, shouldChunk, idleTimeout]);

  const isComplete = progress >= 100;

  return { 
    displayData, 
    progress, 
    isComplete, 
    isLoading,
    reset,
  };
}

export default useChunkedData;
