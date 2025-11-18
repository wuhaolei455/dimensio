"""Core data schemas for compression history"""

from dataclasses import dataclass, field, asdict
from typing import List, Dict, Optional, Any, Union
from datetime import datetime
from enum import Enum


class EventType(str, Enum):
    INITIAL_COMPRESSION = "initial_compression"
    ADAPTIVE_UPDATE = "adaptive_update"
    PROGRESSIVE_COMPRESSION = "progressive_compression"


class SpaceType(str, Enum):
    ORIGINAL = "original"
    SAMPLE = "sample"
    SURROGATE = "surrogate"


class StepType(str, Enum):
    DIMENSION_SELECTION = "dimension_selection"
    RANGE_COMPRESSION = "range_compression"
    PROJECTION = "projection"


@dataclass
class Space:
    n_parameters: int
    parameters: List[str]
    space_type: Optional[SpaceType] = None

    def to_dict(self) -> Dict[str, Any]:
        return {
            "n_parameters": self.n_parameters,
            "parameters": self.parameters,
            "space_type": self.space_type.value if self.space_type else None
        }


@dataclass
class SpaceSnapshot:
    original: Space
    sample: Space
    surrogate: Space

    def to_dict(self) -> Dict[str, Any]:
        return {
            "original": self.original.to_dict(),
            "sample": self.sample.to_dict(),
            "surrogate": self.surrogate.to_dict()
        }


@dataclass
class ParameterCompression:
    name: str
    param_type: str
    original_range: List[Union[int, float]]
    compressed_range: List[Union[int, float]]
    compression_ratio: float
    original_num_values: Optional[int] = None
    quantized_num_values: Optional[int] = None


@dataclass
class CompressionInfo:
    compressed_params: List[ParameterCompression]
    unchanged_params: List[str]
    avg_compression_ratio: float

    def to_dict(self) -> Dict[str, Any]:
        return {
            "compressed_params": [asdict(p) for p in self.compressed_params],
            "unchanged_params": self.unchanged_params,
            "avg_compression_ratio": self.avg_compression_ratio
        }


@dataclass
class PipelineStep:
    name: str
    step_type: str
    step_index: int
    input_space_params: int
    output_space_params: int
    supports_adaptive_update: bool
    uses_progressive_compression: bool
    compression_ratio: Optional[float] = None
    compression_info: Optional[CompressionInfo] = None
    selected_parameters: Optional[List[str]] = None
    selected_indices: Optional[List[int]] = None
    importance_calculator: Optional[str] = None
    update_strategy: Optional[str] = None
    current_topk: Optional[int] = None
    metadata: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        result = {
            "name": self.name,
            "step_type": self.step_type,
            "step_index": self.step_index,
            "input_space_params": self.input_space_params,
            "output_space_params": self.output_space_params,
            "supports_adaptive_update": self.supports_adaptive_update,
            "uses_progressive_compression": self.uses_progressive_compression,
        }
        if self.compression_ratio is not None:
            result["compression_ratio"] = self.compression_ratio
        if self.compression_info is not None:
            result["compression_info"] = self.compression_info.to_dict()
        if self.selected_parameters is not None:
            result["selected_parameters"] = self.selected_parameters
        if self.selected_indices is not None:
            result["selected_indices"] = self.selected_indices
        if self.importance_calculator is not None:
            result["importance_calculator"] = self.importance_calculator
        if self.update_strategy is not None:
            result["update_strategy"] = self.update_strategy
        if self.current_topk is not None:
            result["current_topk"] = self.current_topk
        if self.metadata:
            result["metadata"] = self.metadata

        return result


@dataclass
class Pipeline:
    n_steps: int
    steps: List[PipelineStep]
    sampling_strategy: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        return {
            "n_steps": self.n_steps,
            "steps": [step.to_dict() for step in self.steps],
            "sampling_strategy": self.sampling_strategy
        }


@dataclass
class CompressionEvent:
    timestamp: str
    event: EventType
    iteration: Optional[int]
    spaces: SpaceSnapshot
    compression_ratios: Dict[str, float]
    pipeline: Pipeline
    update_reason: Optional[str] = None
    performance_metrics: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        result = {
            "timestamp": self.timestamp,
            "event": self.event.value,
            "iteration": self.iteration,
            "spaces": self.spaces.to_dict(),
            "compression_ratios": self.compression_ratios,
            "pipeline": self.pipeline.to_dict()
        }

        if self.update_reason:
            result["update_reason"] = self.update_reason
        if self.performance_metrics:
            result["performance_metrics"] = self.performance_metrics

        return result


@dataclass
class CompressionHistory:
    total_updates: int
    history: List[CompressionEvent]
    experiment_name: Optional[str] = None
    created_at: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        return {
            "total_updates": self.total_updates,
            "history": [event.to_dict() for event in self.history],
            "experiment_name": self.experiment_name,
            "created_at": self.created_at
        }

    def get_initial_event(self) -> Optional[CompressionEvent]:
        return self.history[0] if self.history else None

    def get_adaptive_events(self) -> List[CompressionEvent]:
        return [e for e in self.history if e.event == EventType.ADAPTIVE_UPDATE]

    def get_event_at_iteration(self, iteration: int) -> Optional[CompressionEvent]:
        for event in self.history:
            if event.iteration == iteration:
                return event
        return None


class VisualizationType(str, Enum):
    COMPRESSION_SUMMARY = "compression_summary"
    RANGE_COMPRESSION = "range_compression"
    PARAMETER_IMPORTANCE = "parameter_importance"
    DIMENSION_EVOLUTION = "dimension_evolution"
    MULTI_TASK_HEATMAP = "multi_task_importance_heatmap"
    SOURCE_SIMILARITIES = "source_task_similarities"
    STRATEGIES_COMPARISON = "adaptive_strategies_comparison"

def parse_compression_history(data: Dict[str, Any]) -> CompressionHistory:
    """Parse raw JSON into CompressionHistory object"""
    events = []

    for event_data in data.get("history", []):
        spaces_data = event_data["spaces"]
        spaces = SpaceSnapshot(
            original=Space(
                n_parameters=spaces_data["original"]["n_parameters"],
                parameters=spaces_data["original"]["parameters"],
                space_type=SpaceType.ORIGINAL
            ),
            sample=Space(
                n_parameters=spaces_data["sample"]["n_parameters"],
                parameters=spaces_data["sample"]["parameters"],
                space_type=SpaceType.SAMPLE
            ),
            surrogate=Space(
                n_parameters=spaces_data["surrogate"]["n_parameters"],
                parameters=spaces_data["surrogate"]["parameters"],
                space_type=SpaceType.SURROGATE
            )
        )

        pipeline_data = event_data["pipeline"]
        steps = []

        for step_data in pipeline_data["steps"]:
            compression_info = None
            if "compression_info" in step_data:
                ci_data = step_data["compression_info"]
                compressed_params = []

                for param_data in ci_data.get("compressed_params", []):
                    compressed_params.append(ParameterCompression(
                        name=param_data["name"],
                        param_type=param_data["type"],
                        original_range=param_data["original_range"],
                        compressed_range=param_data["compressed_range"],
                        compression_ratio=param_data["compression_ratio"],
                        original_num_values=param_data.get("original_num_values"),
                        quantized_num_values=param_data.get("quantized_num_values")
                    ))

                compression_info = CompressionInfo(
                    compressed_params=compressed_params,
                    unchanged_params=ci_data.get("unchanged_params", []),
                    avg_compression_ratio=ci_data.get("avg_compression_ratio", 1.0)
                )

            step = PipelineStep(
                name=step_data["name"],
                step_type=step_data["type"],
                step_index=step_data["step_index"],
                input_space_params=step_data["input_space_params"],
                output_space_params=step_data["output_space_params"],
                supports_adaptive_update=step_data["supports_adaptive_update"],
                uses_progressive_compression=step_data["uses_progressive_compression"],
                compression_ratio=step_data.get("compression_ratio"),
                compression_info=compression_info,
                selected_parameters=step_data.get("selected_parameters"),
                selected_indices=step_data.get("selected_indices"),
                importance_calculator=step_data.get("importance_calculator"),
                update_strategy=step_data.get("update_strategy"),
                current_topk=step_data.get("current_topk"),
                metadata={k: v for k, v in step_data.items() if k not in [
                    "name", "type", "step_index", "input_space_params",
                    "output_space_params", "supports_adaptive_update",
                    "uses_progressive_compression", "compression_ratio",
                    "compression_info", "selected_parameters", "selected_indices",
                    "importance_calculator", "update_strategy", "current_topk"
                ]}
            )
            steps.append(step)

        pipeline = Pipeline(
            n_steps=pipeline_data["n_steps"],
            steps=steps,
            sampling_strategy=pipeline_data.get("sampling_strategy")
        )

        event = CompressionEvent(
            timestamp=event_data["timestamp"],
            event=EventType(event_data["event"]),
            iteration=event_data.get("iteration"),
            spaces=spaces,
            compression_ratios=event_data["compression_ratios"],
            pipeline=pipeline,
            update_reason=event_data.get("update_reason"),
            performance_metrics=event_data.get("performance_metrics", {})
        )
        events.append(event)

    return CompressionHistory(
        total_updates=data["total_updates"],
        history=events
    )
