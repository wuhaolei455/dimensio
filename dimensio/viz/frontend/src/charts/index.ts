/**
 * 图表配置系统统一导出
 */

// 类型导出
export type {
  ChartType,
  ChartTheme,
  ColorPalette,
  ChartDimensions,
  GridConfig,
  TitleConfig,
  TooltipConfig,
  LegendConfig,
  DataItem,
  BarChartData,
  LineChartData,
  PieChartData,
  HeatmapChartData,
  CustomChartData,
  ChartData,
  ChartConfigContext,
  IChartStrategy,
  IChartConfigFactory,
  UseChartConfigParams,
  UseChartConfigReturn,
  ChartPreset,
  PresetName,
} from './types';

// 配置导出
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
  hexToRgb,
  generateGradientColors,
  generateOpacityGradient,
  chartPresets,
  getPreset,
  getPresetNames,
} from './config';

// 策略导出
export {
  BaseChartStrategy,
  BarChartStrategy,
  HorizontalBarChartStrategy,
  CompressionRatioBarStrategy,
  LineChartStrategy,
  DimensionEvolutionStrategy,
  HeatmapChartStrategy,
  MultiTaskHeatmapStrategy,
} from './strategies';

// 工厂导出
export {
  getChartFactory,
  createChartConfig,
  createFromPreset,
  createCompressionRatioStrategy,
  createDimensionEvolutionStrategy,
  createMultiTaskHeatmapStrategy,
} from './factory';

// Hooks 导出
export {
  useChartConfig,
  useBarChartConfig,
  useHorizontalBarConfig,
  useLineChartConfig,
  useHeatmapConfig,
  useParameterImportanceConfig,
  useDimensionReductionConfig,
  useCompressionRatioConfig,
  useDimensionEvolutionConfig,
  useMultiTaskHeatmapConfig,
} from './hooks';
