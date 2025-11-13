# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-11-13

### Added
- 初始版本发布
- 核心压缩器类 `Compressor`
- 压缩管道 `CompressionPipeline`
- 三大类压缩策略：
  - 维度选择（Dimension Selection）
    - SHAP-based 维度选择
    - 专家知识维度选择
    - 相关性维度选择
    - 自适应维度选择
  - 范围压缩（Range Compression）
    - 边界范围压缩
    - 专家范围压缩
    - SHAP 边界范围压缩
    - KDE 边界范围压缩
  - 投影变换（Projection）
    - REMBO 投影
    - HesBO 投影
    - KPCA 投影
    - 量化投影
- 灵活的采样策略
  - 标准采样
  - 混合范围采样
- 填充策略
  - 默认值填充
  - 裁剪填充
- 标准日志系统（基于 Python logging）
- 便捷函数 `get_compressor()`
- 优化进度跟踪
- 多种更新策略（周期性、停滞检测、改进检测等）

### Changed


### Fixed


## [Unreleased]

### Planned
- 添加更多示例代码
- 完善单元测试
- 添加性能基准测试
- 支持更多压缩策略
- 改进文档和教程
