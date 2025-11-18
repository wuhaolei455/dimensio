"""Dimensio API - Compression history server

Usage:
    python -m api.server

Endpoints:
    GET /api/experiments - List all experiments
    GET /api/experiments/<id>/history - Get compression history
"""

__version__ = "2.0.0"

from .schemas import (
    Space,
    SpaceSnapshot,
    CompressionEvent,
    CompressionHistory,
    Pipeline,
    PipelineStep,
    VisualizationType,
    EventType,
    SpaceType,
    parse_compression_history
)

__all__ = [
    'Space',
    'SpaceSnapshot',
    'CompressionEvent',
    'CompressionHistory',
    'Pipeline',
    'PipelineStep',
    'VisualizationType',
    'EventType',
    'SpaceType',
    'parse_compression_history',
]
