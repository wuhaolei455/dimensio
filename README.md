# Dimensio

一个灵活的配置空间压缩库，用于贝叶斯优化（Bayesian Optimization）。

## 功能特性

- **多种压缩策略**: 支持维度选择、范围压缩和投影变换
- **自适应压缩**: 根据优化过程动态调整压缩策略
- **可扩展架构**: 易于添加自定义压缩步骤

## 安装

### 从 PyPI 安装（发布后）

```bash
pip install dimensio
```

### 从源码安装

```bash
git clone https://github.com/Elubrazione/dimensio.git
cd dimensio
pip install -e .
```

### 开发模式安装

```bash
pip install -e ".[dev]"
```

## 快速开始

### 基础使用

```python
from dimensio import Compressor, SHAPDimensionStep, BoundaryRangeStep
from ConfigSpace import ConfigurationSpace, UniformFloatHyperparameter

# 创建配置空间
config_space = ConfigurationSpace()
config_space.add_hyperparameter(UniformFloatHyperparameter('x1', -5, 5))
config_space.add_hyperparameter(UniformFloatHyperparameter('x2', -5, 5))
config_space.add_hyperparameter(UniformFloatHyperparameter('x3', -5, 5))

# 创建压缩器
steps = [
    SHAPDimensionStep(strategy='shap', topk=2),
    BoundaryRangeStep(method='boundary', top_ratio=0.8)
]

compressor = Compressor(config_space=config_space, steps=steps)

# 压缩配置空间
surrogate_space, sample_space = compressor.compress_space(space_history=None)

print(f"原始维度: {len(config_space.get_hyperparameters())}")
print(f"压缩后维度: {len(surrogate_space.get_hyperparameters())}")
```

### 使用便捷函数

```python
from dimensio import get_compressor

# 使用 SHAP 策略
compressor = get_compressor(
    compressor_type='shap',
    config_space=config_space,
    topk=5,
    top_ratio=0.8
)
```

### 配置日志

```python
import logging
from dimensio import setup_logging

# 设置日志级别
setup_logging(level=logging.DEBUG)

# 或者设置日志文件
setup_logging(level=logging.INFO, log_file='dimensio.log')

# 关闭日志
from dimensio import disable_logging
disable_logging()
```

## 压缩策略

### 1. 维度选择（Dimension Selection）

- **SHAPDimensionStep**: 基于 SHAP 值选择重要维度
- **ExpertDimensionStep**: 基于专家知识选择维度
- **CorrelationDimensionStep**: 基于相关性选择维度
- **AdaptiveDimensionStep**: 自适应维度选择

### 2. 范围压缩（Range Compression）

- **BoundaryRangeStep**: 基于历史数据边界压缩参数范围
- **ExpertRangeStep**: 基于专家知识压缩范围
- **SHAPBoundaryRangeStep**: 结合 SHAP 的范围压缩
- **KDEBoundaryRangeStep**: 基于核密度估计的范围压缩

### 3. 投影变换（Projection）

- **REMBOProjectionStep**: 随机嵌入投影
- **HesBOProjectionStep**: Hessian-based 投影
- **KPCAProjectionStep**: 核主成分分析投影
- **QuantizationProjectionStep**: 量化投影

## 项目结构

```
dimensio/
├── __init__.py              # 包初始化
├── core/                    # 核心模块
│   ├── compressor.py        # 压缩器主类
│   ├── pipeline.py          # 压缩管道
│   ├── step.py              # 压缩步骤基类
│   ├── progress.py          # 优化进度跟踪
│   └── update.py            # 更新策略
├── steps/                   # 压缩步骤实现
│   ├── dimension/           # 维度选择
│   ├── projection/          # 投影变换
│   └── range/               # 范围压缩
├── sampling/                # 采样策略
├── filling/                 # 填充策略
└── utils/                   # 工具函数
    ├── __init__.py
    └── logger.py            # 日志配置
```

## API 文档

### Compressor

主压缩器类，管理压缩管道和配置空间转换。

```python
Compressor(
    config_space: ConfigurationSpace,
    steps: List[CompressionStep] = None,
    filling_strategy: FillingStrategy = None,
    save_compression_info: bool = False,
    output_dir: str = './results/compression'
)
```

## 依赖项

- numpy >= 1.19.0
- pandas >= 1.2.0
- scikit-learn >= 0.24.0
- ConfigSpace >= 0.6.0
- shap >= 0.41.0
- openbox >= 0.8.0

## 开发

### 运行测试

```bash
pytest tests/ -v --cov=dimensio
```

### 代码格式化

```bash
black dimensio/ tests/
```

### 类型检查

```bash
mypy dimensio/
```

## 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 贡献

欢迎提交 Issue 和 Pull Request！

## 作者

Lingching Tung - lingchingtung@stu.pku.edu.cn

## 更新日志

### 0.1.0 (2025-11-13)

- 🎉 Dimensio 初始版本发布
- 实现基本的配置空间压缩功能
- 支持多种压缩策略
- 添加标准日志系统
- 完整的文档和示例

## 引用

如果您在研究中使用了本项目，请引用：

```bibtex
@software{dimensio2025,
  author = {Lingching Tung},
  title = {Dimensio: Configuration Space Compression for Bayesian Optimization},
  year = {2025},
  url = {https://github.com/Elubrazione/dimensio}
}
```

