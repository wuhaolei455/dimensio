"""Dimensio API Server - Returns compression history metadata"""

import json
from pathlib import Path
from typing import Dict, List, Optional, Any
from datetime import datetime
import glob as glob_module
import logging
import subprocess

from flask import Flask, jsonify, request
from flask_cors import CORS

# Note: Compression is now executed via run_compression.sh script
# No need to import compress_from_config directly

app = Flask(__name__)
CORS(app, resources={
    r"/*": {
        "origins": "*",
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization", "X-Requested-With"],
        "expose_headers": ["Content-Type", "X-Total-Count"],
        "supports_credentials": True,
        "max_age": 3600
    }
})

# Configuration
app.config['MAX_CONTENT_LENGTH'] = 100 * 1024 * 1024  # 100MB max file size
ALLOWED_EXTENSIONS = {'json'}

PROJECT_ROOT = Path(__file__).parent.parent
DATA_DIR = PROJECT_ROOT / "data"
RESULT_DIR = PROJECT_ROOT / "result"

# Ensure directories exist
DATA_DIR.mkdir(parents=True, exist_ok=True)
RESULT_DIR.mkdir(parents=True, exist_ok=True)

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


# Helper Functions

def allowed_file(filename: str) -> bool:
    """Check if file has allowed extension"""
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


def clear_uploaded_files():
    """Clear previously uploaded files in data directory"""
    # Remove config_space.json
    config_space_path = DATA_DIR / 'config_space.json'
    if config_space_path.exists():
        config_space_path.unlink()

    # Remove steps.json
    steps_path = DATA_DIR / 'steps.json'
    if steps_path.exists():
        steps_path.unlink()

    # Remove all history files (history.json, history_1.json, history_2.json, etc.)
    for history_file in DATA_DIR.glob('history*.json'):
        history_file.unlink()

    # Remove metadata.json if exists
    metadata_path = DATA_DIR / 'metadata.json'
    if metadata_path.exists():
        metadata_path.unlink()


def validate_json_file(file_path: Path) -> Dict[str, Any]:
    """Validate that file is valid JSON and return parsed content"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        return {'valid': True, 'data': data}
    except json.JSONDecodeError as e:
        return {'valid': False, 'error': f'Invalid JSON: {str(e)}'}
    except Exception as e:
        return {'valid': False, 'error': f'Error reading file: {str(e)}'}


def validate_config_space(data: Any) -> Dict[str, Any]:
    """Validate config_space.json format"""
    if not isinstance(data, dict):
        return {'valid': False, 'error': 'Config space must be a JSON object'}

    for param_name, param_def in data.items():
        if not isinstance(param_def, dict):
            return {'valid': False, 'error': f'Parameter "{param_name}" definition must be an object'}

        if 'type' not in param_def:
            return {'valid': False, 'error': f'Parameter "{param_name}" missing "type" field'}

        param_type = param_def['type'].lower()
        if param_type in ['float', 'integer', 'int']:
            if 'min' not in param_def or 'max' not in param_def:
                return {'valid': False, 'error': f'Parameter "{param_name}" missing "min" or "max" field'}
        elif param_type == 'categorical':
            if 'choices' not in param_def:
                return {'valid': False, 'error': f'Parameter "{param_name}" missing "choices" field'}
        else:
            return {'valid': False, 'error': f'Parameter "{param_name}" has invalid type "{param_type}"'}

    return {'valid': True}


def validate_steps(data: Any) -> Dict[str, Any]:
    """Validate steps.json format"""
    if not isinstance(data, dict):
        return {'valid': False, 'error': 'Steps must be a JSON object'}

    required_fields = ['dimension_step', 'range_step', 'projection_step']
    for field in required_fields:
        if field not in data:
            return {'valid': False, 'error': f'Missing required field "{field}"'}

    valid_dimension_steps = ['d_shap', 'd_corr', 'd_expert', 'd_adaptive', 'd_none']
    valid_range_steps = ['r_boundary', 'r_shap', 'r_kde', 'r_expert', 'r_none']
    valid_projection_steps = ['p_quant', 'p_rembo', 'p_hesbo', 'p_kpca', 'p_none']

    if data['dimension_step'] not in valid_dimension_steps:
        return {'valid': False, 'error': f'Invalid dimension_step: {data["dimension_step"]}'}
    if data['range_step'] not in valid_range_steps:
        return {'valid': False, 'error': f'Invalid range_step: {data["range_step"]}'}
    if data['projection_step'] not in valid_projection_steps:
        return {'valid': False, 'error': f'Invalid projection_step: {data["projection_step"]}'}

    return {'valid': True}


def validate_history(data: Any) -> Dict[str, Any]:
    """Validate history.json format"""
    if not isinstance(data, list):
        return {'valid': False, 'error': 'History must be a JSON array'}

    if len(data) == 0:
        return {'valid': False, 'error': 'History array cannot be empty'}

    for i, observation in enumerate(data):
        if not isinstance(observation, dict):
            return {'valid': False, 'error': f'Observation {i} must be an object'}

        if 'config' not in observation:
            return {'valid': False, 'error': f'Observation {i} missing "config" field'}

        if 'objectives' not in observation and 'objective' not in observation:
            return {'valid': False, 'error': f'Observation {i} missing "objectives" or "objective" field'}

        if not isinstance(observation['config'], dict):
            return {'valid': False, 'error': f'Observation {i} "config" must be an object'}

    return {'valid': True}


def load_json_file(file_path: Path) -> Any:
    """Load and parse a JSON file."""
    with open(file_path, 'r', encoding='utf-8') as f:
        return json.load(f)


def find_history_files() -> List[Path]:
    """Find history JSON files in the data directory."""
    # Try default name first
    default_history = DATA_DIR / "history.json"
    if default_history.exists():
        return [default_history]

    # Look for files matching pattern history*.json
    history_files = sorted(DATA_DIR.glob("history*.json"))
    if not history_files:
        raise FileNotFoundError(
            f"No history files found in {DATA_DIR}. "
            "Please provide at least one history.json file."
        )

    logger.info(f"Found {len(history_files)} history files: {[f.name for f in history_files]}")
    return history_files




def get_latest_compression_history() -> Optional[Dict[str, Any]]:
    """Get the latest compression history from result directory"""
    try:
        # Check for compression_history.json directly in result directory
        history_file = RESULT_DIR / "compression_history.json"

        if not history_file.exists():
            # Try to find in subdirectories
            compression_dirs = sorted(RESULT_DIR.glob("compression_*"), key=lambda p: p.stat().st_mtime, reverse=True)

            for comp_dir in compression_dirs:
                if comp_dir.is_dir():
                    history_file = comp_dir / "compression_history.json"
                    if history_file.exists():
                        break
            else:
                return None

        if not history_file.exists():
            return None

        with open(history_file, 'r', encoding='utf-8') as f:
            history_data = json.load(f)

        # Add file info
        history_data['output_dir'] = str(RESULT_DIR)
        history_data['created_at'] = datetime.fromtimestamp(history_file.stat().st_ctime).isoformat()
        history_data['last_modified'] = datetime.fromtimestamp(history_file.stat().st_mtime).isoformat()

        return history_data

    except Exception as e:
        logger.error(f"Error loading latest compression history: {e}")
        return None


# API Routes

@app.route('/')
def index():
    return jsonify({
        'service': 'Dimensio API',
        'version': '3.0.0',
        'description': 'API for file upload and synchronous compression execution',
        'endpoints': {
            'POST /api/upload': 'Upload config_space, steps, and history files. Synchronously executes compression and returns result.',
            'GET /api/compression/history': 'Get latest compression history'
        },
        'upload_requirements': {
            'config_space': 'Configuration space definition (JSON file)',
            'steps': 'Compression steps configuration (JSON file)',
            'history': 'One or more history files (JSON files, can upload multiple)'
        },
        'upload_notes': [
            'Files are saved directly to data/ directory',
            'Previous files are automatically cleared on new upload',
            'All files are validated upon upload',
            'Compression executes SYNCHRONOUSLY - response includes compression result',
            'Compression results are saved to result/ directory (old results are cleared)',
            'Timeout: 10 minutes per compression task'
        ]
    })


@app.route('/api/compression/history', methods=['GET'])
def get_latest_history():
    """Get the latest compression history"""
    try:
        history_data = get_latest_compression_history()

        if history_data is None:
            return jsonify({
                'success': False,
                'error': 'No compression history found'
            }), 404

        return jsonify({
            'success': True,
            'data': history_data
        })

    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/api/upload', methods=['POST'])
def upload_files():
    """
    Upload configuration files for compression task

    Required files:
    - config_space: Configuration space definition (JSON)
    - steps: Compression steps configuration (JSON)
    - history: One or more history files (JSON)

    Files are saved directly to data/ directory.
    Previous files are automatically cleared before upload.

    Returns:
    - saved_files: List of saved file paths
    - validation_results: Validation status for each file
    """
    try:
        # Check if required files are present
        if 'config_space' not in request.files:
            return jsonify({
                'success': False,
                'error': 'Missing required file: config_space'
            }), 400

        if 'steps' not in request.files:
            return jsonify({
                'success': False,
                'error': 'Missing required file: steps'
            }), 400

        # History files can be multiple
        history_files = request.files.getlist('history')
        if not history_files:
            return jsonify({
                'success': False,
                'error': 'Missing required file(s): history'
            }), 400

        # Clear previously uploaded files
        clear_uploaded_files()

        saved_files = []
        validation_results = {}

        # Process config_space file
        config_space_file = request.files['config_space']
        if config_space_file.filename == '':
            return jsonify({
                'success': False,
                'error': 'config_space file has no filename'
            }), 400

        if not allowed_file(config_space_file.filename):
            return jsonify({
                'success': False,
                'error': 'config_space file must be JSON'
            }), 400

        # Save config_space
        config_space_path = DATA_DIR / 'config_space.json'
        config_space_file.save(str(config_space_path))
        saved_files.append('config_space.json')

        # Validate config_space
        json_result = validate_json_file(config_space_path)
        if not json_result['valid']:
            validation_results['config_space'] = json_result
        else:
            validation_result = validate_config_space(json_result['data'])
            validation_results['config_space'] = validation_result

        # Process steps file
        steps_file = request.files['steps']
        if steps_file.filename == '':
            return jsonify({
                'success': False,
                'error': 'steps file has no filename'
            }), 400

        if not allowed_file(steps_file.filename):
            return jsonify({
                'success': False,
                'error': 'steps file must be JSON'
            }), 400

        # Save steps
        steps_path = DATA_DIR / 'steps.json'
        steps_file.save(str(steps_path))
        saved_files.append('steps.json')

        # Validate steps
        json_result = validate_json_file(steps_path)
        if not json_result['valid']:
            validation_results['steps'] = json_result
        else:
            validation_result = validate_steps(json_result['data'])
            validation_results['steps'] = validation_result

        # Process history files
        validation_results['history'] = []
        for i, history_file in enumerate(history_files):
            if history_file.filename == '':
                return jsonify({
                    'success': False,
                    'error': f'history file {i+1} has no filename'
                }), 400

            if not allowed_file(history_file.filename):
                return jsonify({
                    'success': False,
                    'error': f'history file {i+1} must be JSON'
                }), 400

            # Save history file with index
            history_filename = f'history_{i+1}.json' if len(history_files) > 1 else 'history.json'
            history_path = DATA_DIR / history_filename
            history_file.save(str(history_path))
            saved_files.append(history_filename)

            # Validate history
            json_result = validate_json_file(history_path)
            if not json_result['valid']:
                validation_results['history'].append({
                    'file': history_filename,
                    **json_result
                })
            else:
                validation_result = validate_history(json_result['data'])
                validation_results['history'].append({
                    'file': history_filename,
                    **validation_result
                })

        # Check if all validations passed
        all_valid = True
        if not validation_results['config_space']['valid']:
            all_valid = False
        if not validation_results['steps']['valid']:
            all_valid = False
        for hist_result in validation_results['history']:
            if not hist_result['valid']:
                all_valid = False

        # Save upload metadata
        metadata = {
            'uploaded_at': datetime.now().isoformat(),
            'files': saved_files,
            'validation_results': validation_results,
            'status': 'validated' if all_valid else 'validation_failed'
        }

        metadata_path = DATA_DIR / 'metadata.json'
        with open(metadata_path, 'w') as f:
            json.dump(metadata, f, indent=2)

        response_data = {
            'success': True,
            'saved_files': saved_files,
            'validation_results': validation_results,
            'all_valid': all_valid,
            'message': 'Files uploaded and validated successfully' if all_valid else 'Files uploaded but validation failed'
        }

        # If all files are valid, execute compression synchronously
        if all_valid:
            logger.info("Files validated, executing compression task...")

            try:
                # Execute compression synchronously
                script_path = PROJECT_ROOT / "run_compression.sh"
                if not script_path.exists():
                    raise FileNotFoundError(f"run_compression.sh not found at {script_path}")

                cmd = [
                    str(script_path),
                    '--data-dir', str(DATA_DIR),
                    '--result-dir', str(RESULT_DIR),
                    '--verbose'
                ]

                # Pass history files if multiple were uploaded
                history_file_list = [f for f in saved_files if f.startswith('history')]
                if len(history_file_list) > 1:
                    # Multiple history files - pass them to the compression script
                    cmd.extend(['--history', ' '.join(history_file_list)])
                    logger.info(f"Multi-task scenario detected: {len(history_file_list)} history files")
                elif len(history_file_list) == 1 and history_file_list[0] != 'history.json':
                    # Single history file with non-default name
                    cmd.extend(['--history', history_file_list[0]])

                logger.info(f"Executing command: {' '.join(cmd)}")

                # Execute the shell script synchronously
                result_proc = subprocess.run(
                    cmd,
                    capture_output=True,
                    text=True,
                    encoding='utf-8',
                    errors='replace',  # Replace invalid UTF-8 bytes with replacement character
                    timeout=600,  # 10 minutes timeout
                    cwd=str(PROJECT_ROOT)
                )

                # Check if execution was successful
                if result_proc.returncode != 0:
                    raise RuntimeError(
                        f"Compression script failed with exit code {result_proc.returncode}\n"
                        f"stdout: {result_proc.stdout}\n"
                        f"stderr: {result_proc.stderr}"
                    )

                logger.info("Compression script completed successfully")

                # Load the result from result directory
                result_summary_path = RESULT_DIR / "result_summary.json"
                if not result_summary_path.exists():
                    raise FileNotFoundError(f"result_summary.json not found in {RESULT_DIR}")

                with open(result_summary_path, 'r', encoding='utf-8') as f:
                    compression_result = json.load(f)

                response_data['compression'] = {
                    'status': 'completed',
                    'message': 'Compression completed successfully',
                    'result': compression_result,
                    'output_dir': str(RESULT_DIR)
                }

                logger.info(f"Compression result: original_dim={compression_result.get('original_dim')}, "
                           f"surrogate_dim={compression_result.get('surrogate_dim')}, "
                           f"compression_ratio={compression_result.get('compression_ratio', 0):.2%}")

            except subprocess.TimeoutExpired:
                response_data['compression'] = {
                    'status': 'failed',
                    'message': 'Compression failed: Execution timeout (10 minutes)',
                    'error': 'Execution timeout'
                }
                logger.error("Compression failed: Timeout")

            except Exception as e:
                response_data['compression'] = {
                    'status': 'failed',
                    'message': f'Compression failed: {str(e)}',
                    'error': str(e)
                }
                logger.error(f"Compression failed: {str(e)}", exc_info=True)

        return jsonify(response_data)

    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500




# Error Handlers

@app.errorhandler(413)
def request_entity_too_large(error):
    return jsonify({
        'success': False,
        'error': 'File too large. Maximum file size is 100MB.'
    }), 413


@app.errorhandler(404)
def not_found(error):
    return jsonify({'success': False, 'error': 'Endpoint not found'}), 404


@app.errorhandler(500)
def internal_error(error):
    return jsonify({'success': False, 'error': 'Internal server error'}), 500


# Main Entry

if __name__ == '__main__':
    print("=" * 80)
    print(" " * 20 + "Dimensio API v3.0.0")
    print("=" * 80)
    print(f"\n📁 Data directory: {DATA_DIR.absolute()}")
    print(f"📁 Result directory: {RESULT_DIR.absolute()}")

    print(f"\n🚀 Starting server on http://0.0.0.0:5000")
    print(f"   API documentation: http://0.0.0.0:5000/")
    print("=" * 80 + "\n")

    app.run(host='0.0.0.0', port=5000, debug=True)
