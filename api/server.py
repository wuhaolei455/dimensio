"""Dimensio API Server - Returns compression history metadata"""

import json
from pathlib import Path
from typing import Dict, List, Optional, Any
from datetime import datetime

from flask import Flask, jsonify, request
from flask_cors import CORS

from .schemas import (
    CompressionHistory,
    parse_compression_history
)

app = Flask(__name__)
CORS(app)

PROJECT_ROOT = Path(__file__).parent.parent
RESULTS_DIR = PROJECT_ROOT / "examples" / "results"


class DataManager:
    """Manages experiment discovery and compression history loading"""

    def __init__(self, results_dir: Path):
        self.results_dir = results_dir
        self._history_cache: Dict[str, CompressionHistory] = {}

    def discover_experiments(self) -> List[Dict[str, Any]]:
        """Discover all experiments with compression history"""
        experiments = []

        if not self.results_dir.exists():
            return experiments

        for history_file in self.results_dir.rglob("compression_history.json"):
            exp_path = history_file.parent
            rel_path = exp_path.relative_to(self.results_dir)

            path_parts = rel_path.parts
            category = path_parts[0] if len(path_parts) > 1 else None
            exp_id = str(rel_path).replace("\\", "/")

            try:
                with open(history_file, 'r') as f:
                    raw_data = json.load(f)
                    total_updates = raw_data.get('total_updates', 0)
                    n_events = len(raw_data.get('history', []))
            except Exception:
                total_updates = 0
                n_events = 0

            viz_dir = exp_path / "viz"
            viz_count = len(list(viz_dir.glob("*.png"))) if viz_dir.exists() else 0

            experiments.append({
                'experiment_id': exp_id,
                'name': exp_path.name,
                'category': category,
                'path': str(rel_path),
                'total_updates': total_updates,
                'n_events': n_events,
                'n_visualizations': viz_count,
                'created_at': datetime.fromtimestamp(history_file.stat().st_ctime).isoformat(),
                'last_modified': datetime.fromtimestamp(history_file.stat().st_mtime).isoformat()
            })

        experiments.sort(key=lambda x: x['last_modified'], reverse=True)
        return experiments

    def load_history(self, experiment_id: str, use_cache: bool = True) -> Optional[CompressionHistory]:
        """Load and parse compression history for an experiment"""
        if use_cache and experiment_id in self._history_cache:
            return self._history_cache[experiment_id]

        history_file = self.results_dir / experiment_id / "compression_history.json"
        if not history_file.exists():
            return None

        try:
            with open(history_file, 'r') as f:
                raw_data = json.load(f)

            history = parse_compression_history(raw_data)
            history.experiment_name = experiment_id
            self._history_cache[experiment_id] = history
            return history
        except Exception as e:
            print(f"Error loading history for {experiment_id}: {e}")
            return None



data_manager = DataManager(RESULTS_DIR)


# API Routes

@app.route('/')
def index():
    return jsonify({
        'service': 'Dimensio Visualization API',
        'version': '2.0.0',
        'description': 'Simplified API returning complete compression history metadata',
        'endpoints': {
            'experiments': {
                'GET /api/experiments': 'List all experiments',
                'GET /api/experiments/<id>/history': 'Get full compression history (complete meta_data)'
            }
        },
        'models': {
            'Space': 'Parameter space with n_parameters and parameter names',
            'CompressionEvent': 'Single event with spaces, pipeline, and ratios',
            'Pipeline': 'Compression pipeline with steps',
            'PipelineStep': 'Individual compression step with configuration'
        }
    })


@app.route('/api/experiments', methods=['GET'])
def list_experiments():
    try:
        experiments = data_manager.discover_experiments()
        return jsonify({
            'success': True,
            'count': len(experiments),
            'data': experiments
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/api/experiments/<path:experiment_id>/history', methods=['GET'])
def get_compression_history(experiment_id: str):
    try:
        history = data_manager.load_history(experiment_id)

        if history is None:
            return jsonify({
                'success': False,
                'error': 'History not found'
            }), 404

        output_format = request.args.get('format', 'structured')
        events_filter = request.args.get('events', 'all')
        if events_filter == 'initial':
            initial = history.get_initial_event()
            events = [initial] if initial else []
        elif events_filter == 'adaptive':
            events = history.get_adaptive_events()
        else:
            events = history.history

        if output_format == 'raw':
            result = {
                'total_updates': history.total_updates,
                'history': [event.to_dict() for event in events]
            }
        else:
            result = {
                'experiment_id': experiment_id,
                'total_updates': history.total_updates,
                'n_events': len(events),
                'events': [event.to_dict() for event in events]
            }

        return jsonify({
            'success': True,
            'data': result
        })

    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


# Error Handlers

@app.errorhandler(404)
def not_found(error):
    return jsonify({'success': False, 'error': 'Endpoint not found'}), 404


@app.errorhandler(500)
def internal_error(error):
    return jsonify({'success': False, 'error': 'Internal server error'}), 500


# Main Entry

if __name__ == '__main__':
    print("=" * 80)
    print(" " * 20 + "Dimensio Visualization API v2.0")
    print("=" * 80)
    print(f"\n📁 Results directory: {RESULTS_DIR.absolute()}")

    if not RESULTS_DIR.exists():
        print(f"\n⚠️  Warning: Results directory not found!")
        print(f"   Please run examples first to generate results.")
    else:
        experiments = data_manager.discover_experiments()
        print(f"\n📊 Found {len(experiments)} experiment(s)")
        for exp in experiments[:5]:
            print(f"   - {exp['name']} ({exp['n_visualizations']} visualizations, "
                  f"{exp['n_events']} events)")
        if len(experiments) > 5:
            print(f"   ... and {len(experiments) - 5} more")

    print(f"\n🚀 Starting server on http://127.0.0.1:5000")
    print(f"   API documentation: http://127.0.0.1:5000/")
    print("=" * 80 + "\n")

    app.run(host='127.0.0.1', port=5000, debug=True)
