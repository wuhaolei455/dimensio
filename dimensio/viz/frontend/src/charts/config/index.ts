/**
 * 图表配置统一导出
 */

// 主题配置
export {
  lightPalette,
  darkPalette,
  brandPalette,
  getPalette,
  getCompressionRatioColor,
  compressionRatioLegend,
  defaultGrid,
  compactGrid,
  spaciousGrid,
  defaultTitleStyle,
  defaultTooltip,
  defaultAnimation,
  noAnimation,
  chartHeights,
} from './theme';

// 颜色工具
export {
  hexToRgb,
  generateGradientColors,
  generateOpacityGradient,
} from './colors';

// 预设配置
export {
  chartPresets,
  getPreset,
  getPresetNames,
} from './presets';
