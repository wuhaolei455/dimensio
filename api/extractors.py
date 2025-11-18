"""
Data Extractors for Visualization Types

This module provides specialized extractors that retrieve exactly
the data needed for each visualization type from compression history.
"""

from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass
import numpy as np

from .schemas import (
    CompressionHistory,
    CompressionEvent,
    PipelineStep,
    VisualizationType,
    ParameterCompression
)


# ============================================================================
# Base Extractor
# ============================================================================

class BaseExtractor:
    """Base class for data extractors"""

    def __init__(self, history: CompressionHistory):
        self.history = history

    def can_extract(self) -> bool:
        """Check if required data is available"""
        raise NotImplementedError

    def extract(self) -> Dict[str, Any]:
        """Extract data for visualization"""
        raise NotImplementedError


# ============================================================================
# Compression Summary Data
# ============================================================================

@dataclass
class CompressionSummaryData:
    """
    Data required for compression_summary visualization.

    This includes dimension changes across steps and compression ratios.
    """
    # Dimension progression
    step_names: List[str]  # ['Original', 'Step1', 'Step2', ...]
    dimensions: List[int]  # [15, 10, 8, ...]

    # Compression ratios per step
    compression_ratios: List[float]  # [0.67, 0.8, ...]

    # Range compression statistics
    range_stats: List[Dict[str, int]]  # [{'compressed': 5, 'unchanged': 3}, ...]

    # Text summary data
    original_dimensions: int
    final_sample_dimensions: int
    final_surrogate_dimensions: int
    overall_compression_ratio: float

    # Pipeline steps summary
    steps_summary: List[Dict[str, Any]]


class CompressionSummaryExtractor(BaseExtractor):
    """Extract data for compression summary visualization"""

    def can_extract(self) -> bool:
        return len(self.history.history) > 0

    def extract(self) -> CompressionSummaryData:
        initial_event = self.history.get_initial_event()
        if not initial_event:
            raise ValueError("No initial event found")

        # Get dimension progression
        step_names = ['Original']
        dimensions = [initial_event.spaces.original.n_parameters]

        for step in initial_event.pipeline.steps:
            step_names.append(step.name)
            dimensions.append(step.output_space_params)

        # Calculate compression ratios
        compression_ratios = []
        for i in range(1, len(dimensions)):
            ratio = dimensions[i] / dimensions[0]
            compression_ratios.append(ratio)

        # Get range compression statistics
        range_stats = []
        for step in initial_event.pipeline.steps:
            if step.compression_info:
                range_stats.append({
                    'step_name': step.name,
                    'compressed': len(step.compression_info.compressed_params),
                    'unchanged': len(step.compression_info.unchanged_params)
                })

        # Steps summary
        steps_summary = []
        for i, step in enumerate(initial_event.pipeline.steps):
            input_dim = dimensions[i]
            output_dim = dimensions[i + 1]
            dim_ratio = output_dim / input_dim if input_dim > 0 else 1.0

            step_info = {
                'step_index': i + 1,
                'name': step.name,
                'type': step.step_type,
                'input_dim': input_dim,
                'output_dim': output_dim,
                'dimension_ratio': dim_ratio
            }

            if step.compression_info:
                step_info['effective_compression'] = step.compression_info.avg_compression_ratio

            steps_summary.append(step_info)

        return CompressionSummaryData(
            step_names=step_names,
            dimensions=dimensions,
            compression_ratios=compression_ratios,
            range_stats=range_stats,
            original_dimensions=initial_event.spaces.original.n_parameters,
            final_sample_dimensions=initial_event.spaces.sample.n_parameters,
            final_surrogate_dimensions=initial_event.spaces.surrogate.n_parameters,
            overall_compression_ratio=initial_event.compression_ratios['surrogate_to_original'],
            steps_summary=steps_summary
        )


# ============================================================================
# Range Compression Data
# ============================================================================

@dataclass
class RangeCompressionData:
    """
    Data required for range_compression visualization.

    Shows how parameter ranges were compressed for a specific step.
    """
    step_index: int
    step_name: str
    step_type: str

    # Parameter data
    param_names: List[str]
    param_types: List[str]  # Float, Integer, etc.

    # Range data
    original_ranges: List[Tuple[float, float]]
    compressed_ranges: List[Tuple[float, float]]
    compression_ratios: List[float]

    # Quantization info (optional)
    param_labels: List[str]  # e.g., "100→50 values" or ""
    is_quantization: List[bool]


class RangeCompressionExtractor(BaseExtractor):
    """Extract data for range compression visualization"""

    def __init__(self, history: CompressionHistory, step_index: int):
        super().__init__(history)
        self.step_index = step_index

    def can_extract(self) -> bool:
        initial_event = self.history.get_initial_event()
        if not initial_event:
            return False

        if self.step_index >= len(initial_event.pipeline.steps):
            return False

        step = initial_event.pipeline.steps[self.step_index]
        return (step.compression_info is not None and
                len(step.compression_info.compressed_params) > 0)

    def extract(self) -> RangeCompressionData:
        initial_event = self.history.get_initial_event()
        step = initial_event.pipeline.steps[self.step_index]

        if not step.compression_info:
            raise ValueError(f"No compression info for step {self.step_index}")

        compressed_params = step.compression_info.compressed_params

        # Limit to top 30 parameters
        if len(compressed_params) > 30:
            compressed_params = compressed_params[:30]

        param_names = [p.name.split('.')[-1] for p in compressed_params]
        param_types = [p.param_type for p in compressed_params]
        original_ranges = [tuple(p.original_range) for p in compressed_params]
        compressed_ranges = [tuple(p.compressed_range) for p in compressed_params]
        compression_ratios = [p.compression_ratio for p in compressed_params]

        # Process quantization labels
        param_labels = []
        is_quantization = []
        for param in compressed_params:
            if param.original_num_values is not None:
                label = f"{param.original_num_values}→{param.quantized_num_values} values"
                param_labels.append(label)
                is_quantization.append(True)
            else:
                param_labels.append("")
                is_quantization.append(False)

        return RangeCompressionData(
            step_index=self.step_index,
            step_name=step.name,
            step_type=step.step_type,
            param_names=param_names,
            param_types=param_types,
            original_ranges=original_ranges,
            compressed_ranges=compressed_ranges,
            compression_ratios=compression_ratios,
            param_labels=param_labels,
            is_quantization=is_quantization
        )


# ============================================================================
# Parameter Importance Data
# ============================================================================

@dataclass
class ParameterImportanceData:
    """
    Data required for parameter_importance visualization.

    Shows importance scores for parameters selected by importance-based methods.
    """
    step_index: int
    step_name: str
    step_type: str
    importance_calculator: str

    # Parameter importance
    param_names: List[str]
    importances: List[float]  # Absolute importance values

    # Top-k information
    topk: int
    top_param_names: List[str]
    top_importances: List[float]


class ParameterImportanceExtractor(BaseExtractor):
    """Extract data for parameter importance visualization"""

    def __init__(self, history: CompressionHistory, step_index: int, topk: int = 20):
        super().__init__(history)
        self.step_index = step_index
        self.topk = topk

    def can_extract(self) -> bool:
        # This would need access to step internal cache
        # For now, check if step type is importance-based
        initial_event = self.history.get_initial_event()
        if not initial_event or self.step_index >= len(initial_event.pipeline.steps):
            return False

        step = initial_event.pipeline.steps[self.step_index]
        return step.importance_calculator is not None

    def extract(self) -> ParameterImportanceData:
        """
        Note: This extractor requires additional runtime data
        that may not be fully stored in history JSON.

        In practice, you'd need to pass importance data separately
        or extend the history format to include it.
        """
        initial_event = self.history.get_initial_event()
        step = initial_event.pipeline.steps[self.step_index]

        # This is a placeholder - in real implementation,
        # importance data would come from step cache or be stored in history
        raise NotImplementedError(
            "Parameter importance data requires runtime cache access. "
            "Consider extending history format to include importance scores."
        )


# ============================================================================
# Dimension Evolution Data
# ============================================================================

@dataclass
class DimensionEvolutionData:
    """
    Data required for dimension_evolution visualization.

    Shows how dimensions change over iterations in adaptive compression.
    """
    iterations: List[int]
    dimensions: List[int]
    events: List[str]  # Event types at each point

    # Change points
    change_iterations: List[int]
    dimension_changes: List[int]  # Delta at each change


class DimensionEvolutionExtractor(BaseExtractor):
    """Extract data for dimension evolution visualization"""

    def can_extract(self) -> bool:
        adaptive_events = self.history.get_adaptive_events()
        return len(adaptive_events) > 0

    def extract(self) -> DimensionEvolutionData:
        initial_event = self.history.get_initial_event()
        adaptive_events = self.history.get_adaptive_events()

        if not initial_event:
            raise ValueError("No initial event found")

        # Collect dimension data across iterations
        iterations = [0]  # Start with iteration 0
        dimensions = [initial_event.spaces.surrogate.n_parameters]
        events = [initial_event.event.value]

        for event in adaptive_events:
            if event.iteration is not None:
                iterations.append(event.iteration)
                dimensions.append(event.spaces.surrogate.n_parameters)
                events.append(event.event.value)

        # Find change points
        change_iterations = []
        dimension_changes = []

        for i in range(1, len(dimensions)):
            if dimensions[i] != dimensions[i - 1]:
                change_iterations.append(iterations[i])
                dimension_changes.append(dimensions[i] - dimensions[i - 1])

        return DimensionEvolutionData(
            iterations=iterations,
            dimensions=dimensions,
            events=events,
            change_iterations=change_iterations,
            dimension_changes=dimension_changes
        )


# ============================================================================
# Multi-Task Importance Heatmap Data
# ============================================================================

@dataclass
class MultiTaskImportanceData:
    """
    Data required for multi-task importance heatmap.

    Shows importance of parameters across multiple tasks.
    """
    step_index: int
    step_name: str

    # Task information
    task_names: List[str]
    n_tasks: int

    # Parameter information
    param_names: List[str]
    n_params: int

    # Importance matrix [n_tasks, n_params]
    importance_matrix: List[List[float]]

    # Top parameters (sorted by mean importance)
    top_param_indices: List[int]


class MultiTaskImportanceExtractor(BaseExtractor):
    """Extract data for multi-task importance heatmap"""

    def __init__(self, history: CompressionHistory, step_index: int, topk: int = 30):
        super().__init__(history)
        self.step_index = step_index
        self.topk = topk

    def can_extract(self) -> bool:
        # This requires multi-task importance data
        # which is stored in step cache, not history JSON
        return False

    def extract(self) -> MultiTaskImportanceData:
        raise NotImplementedError(
            "Multi-task importance data requires runtime cache access. "
            "Consider extending history format to include per-task importance scores."
        )


# ============================================================================
# Extractor Factory
# ============================================================================

class ExtractorFactory:
    """
    Factory for creating appropriate extractors based on visualization type.
    """

    @staticmethod
    def create_extractor(
        viz_type: VisualizationType,
        history: CompressionHistory,
        **kwargs
    ) -> BaseExtractor:
        """
        Create appropriate extractor for visualization type.

        Args:
            viz_type: Type of visualization
            history: Compression history data
            **kwargs: Additional parameters (e.g., step_index, topk)

        Returns:
            Configured extractor instance
        """
        if viz_type == VisualizationType.COMPRESSION_SUMMARY:
            return CompressionSummaryExtractor(history)

        elif viz_type == VisualizationType.RANGE_COMPRESSION:
            step_index = kwargs.get('step_index', 0)
            return RangeCompressionExtractor(history, step_index)

        elif viz_type == VisualizationType.PARAMETER_IMPORTANCE:
            step_index = kwargs.get('step_index', 0)
            topk = kwargs.get('topk', 20)
            return ParameterImportanceExtractor(history, step_index, topk)

        elif viz_type == VisualizationType.DIMENSION_EVOLUTION:
            return DimensionEvolutionExtractor(history)

        elif viz_type == VisualizationType.MULTI_TASK_HEATMAP:
            step_index = kwargs.get('step_index', 0)
            topk = kwargs.get('topk', 30)
            return MultiTaskImportanceExtractor(history, step_index, topk)

        else:
            raise ValueError(f"Unsupported visualization type: {viz_type}")

    @staticmethod
    def get_available_visualizations(history: CompressionHistory) -> Dict[str, List[Dict[str, Any]]]:
        """
        Analyze history and return all available visualizations.

        Returns:
            Dictionary mapping visualization type to list of available instances.
            Each instance includes parameters needed to extract the data.
        """
        available = {}

        # Compression summary - always available if we have data
        summary_extractor = CompressionSummaryExtractor(history)
        if summary_extractor.can_extract():
            available[VisualizationType.COMPRESSION_SUMMARY.value] = [{
                'description': 'Overall compression summary',
                'parameters': {}
            }]

        # Range compression - one per step with compression info
        initial_event = history.get_initial_event()
        if initial_event:
            range_viz = []
            for i, step in enumerate(initial_event.pipeline.steps):
                extractor = RangeCompressionExtractor(history, i)
                if extractor.can_extract():
                    range_viz.append({
                        'step_index': i,
                        'step_name': step.name,
                        'description': f'Range compression for {step.name}',
                        'parameters': {'step_index': i}
                    })
            if range_viz:
                available[VisualizationType.RANGE_COMPRESSION.value] = range_viz

        # Dimension evolution
        dim_extractor = DimensionEvolutionExtractor(history)
        if dim_extractor.can_extract():
            available[VisualizationType.DIMENSION_EVOLUTION.value] = [{
                'description': 'Dimension changes across iterations',
                'parameters': {}
            }]

        return available
