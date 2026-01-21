/**
 * 容器组件统一导出
 * 
 * 容器组件 = Hook + 展示组件
 * 优势：
 * - 可独立使用，无需父组件预处理数据
 * - 内部自动处理数据获取和转换
 * - 展示组件保持纯净，只负责渲染
 */

export { default as RangeCompressionContainer } from './RangeCompressionContainer';
export { default as ParameterImportanceContainer } from './ParameterImportanceContainer';
export { default as DimensionEvolutionContainer } from './DimensionEvolutionContainer';
export { default as MultiTaskHeatmapContainer } from './MultiTaskHeatmapContainer';
export { default as SourceSimilaritiesContainer } from './SourceSimilaritiesContainer';
