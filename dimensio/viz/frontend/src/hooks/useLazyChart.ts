/**
 * useLazyChart Hook
 * 
 * 基于 Intersection Observer 的图表懒加载
 * 当图表进入视口时才开始渲染，优化大量图表页面的性能
 * 
 * 特性：
 * - 支持自定义阈值和边距
 * - 只触发一次加载（防止重复渲染）
 * - 支持可见性回调
 */

import { useRef, useState, useEffect } from 'react';
import type { UseLazyChartOptions, UseLazyChartReturn } from '../types';

/**
 * 图表懒加载 Hook
 * 
 * @param options - 配置选项
 * @returns 包含 ref、isVisible 和 hasLoaded 的对象
 * 
 * @example
 * ```tsx
 * const { ref, isVisible, hasLoaded } = useLazyChart({
 *   threshold: 0.1,
 *   rootMargin: '100px',
 *   onVisible: () => console.log('Chart is now visible'),
 * });
 * 
 * return (
 *   <div ref={ref}>
 *     {isVisible ? <RealChart /> : <Placeholder />}
 *   </div>
 * );
 * ```
 */
export const useLazyChart = (options: UseLazyChartOptions = {}): UseLazyChartReturn => {
  const {
    threshold = 0.1,
    rootMargin = '100px',
    onVisible,
    disabled = false,
  } = options;

  const ref = useRef<HTMLDivElement>(null);
  const [isVisible, setIsVisible] = useState(disabled);
  const [hasLoaded, setHasLoaded] = useState(disabled);
  const onVisibleRef = useRef(onVisible);

  // 更新回调引用
  useEffect(() => {
    onVisibleRef.current = onVisible;
  }, [onVisible]);

  useEffect(() => {
    // 如果禁用懒加载，直接设置为可见
    if (disabled) {
      setIsVisible(true);
      setHasLoaded(true);
      return;
    }

    // 如果已经加载过，不再观察
    if (hasLoaded) return;

    const element = ref.current;
    if (!element) return;

    const observer = new IntersectionObserver(
      (entries) => {
        const [entry] = entries;
        if (entry.isIntersecting && !hasLoaded) {
          setIsVisible(true);
          setHasLoaded(true);
          onVisibleRef.current?.();
          // 一旦加载，停止观察
          observer.disconnect();
        }
      },
      {
        threshold,
        rootMargin,
      }
    );

    observer.observe(element);

    return () => {
      observer.disconnect();
    };
  }, [threshold, rootMargin, hasLoaded, disabled]);

  return { ref, isVisible, hasLoaded };
};

export default useLazyChart;
