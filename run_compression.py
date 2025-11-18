#!/usr/bin/env python3
"""
Dimensio Compression Service Runner

This script provides a convenient wrapper for running Dimensio compression:
- Reads configuration files from ./data/ directory
- Supports single or multiple history files
- Outputs results to ./result/ directory
- Can be called by external services/servers

Usage:
    # Single history file
    python run_compression.py

    # Multiple history files (multi-source transfer learning)
    python run_compression.py --history history1.json history2.json history3.json

    # Custom paths
    python run_compression.py --data-dir ./custom_data --result-dir ./custom_results

    # Verbose mode
    python run_compression.py --verbose
"""

import argparse
import json
import logging
import sys
import shutil
from pathlib import Path
from typing import Dict, Any, List, Optional
from datetime import datetime

# Add current directory to Python path
PROJECT_ROOT = Path(__file__).parent.absolute()
sys.path.insert(0, str(PROJECT_ROOT))

# Import the compression API
try:
    from dimensio.api.compress_api import compress_from_config
except ImportError:
    print("Error: Could not import dimensio. Make sure the package is installed.", file=sys.stderr)
    print("Run: pip install -e .", file=sys.stderr)
    sys.exit(1)


class CompressionRunner:
    """Manages the compression service execution."""

    def __init__(
        self,
        data_dir: str = "./data",
        result_dir: str = "./result",
        verbose: bool = False
    ):
        """
        Initialize the compression runner.

        Args:
            data_dir: Directory containing input JSON files
            result_dir: Directory for output results
            verbose: Enable verbose logging
        """
        self.data_dir = Path(data_dir)
        self.result_dir = Path(result_dir)
        self.verbose = verbose

        # Configure logging
        log_level = logging.INFO if verbose else logging.WARNING
        logging.basicConfig(
            level=log_level,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        self.logger = logging.getLogger(__name__)

    def initialize(self) -> bool:
        """
        Initialize directories and check required files.

        Returns:
            True if initialization successful, False otherwise
        """
        self.logger.info("Initializing Dimensio Compression Service...")

        # Create data directory if it doesn't exist
        if not self.data_dir.exists():
            self.logger.info(f"Creating data directory: {self.data_dir}")
            self.data_dir.mkdir(parents=True, exist_ok=True)

        # Clean and recreate result directory
        if self.result_dir.exists():
            self.logger.info(f"Cleaning result directory: {self.result_dir}")
            shutil.rmtree(self.result_dir)

        self.logger.info(f"Creating result directory: {self.result_dir}")
        self.result_dir.mkdir(parents=True, exist_ok=True)


        # Check for required files
        required_files = ['config_space.json', 'steps.json']
        missing_files = []

        for filename in required_files:
            file_path = self.data_dir / filename
            if not file_path.exists():
                missing_files.append(filename)
                self.logger.warning(f"Missing required file: {file_path}")

        if missing_files:
            self.logger.error(f"Missing required files in {self.data_dir}: {', '.join(missing_files)}")
            self.logger.error("Please ensure config_space.json and steps.json exist in the data directory")
            return False

        self.logger.info("Initialization completed successfully")
        return True

    def load_json_file(self, file_path: Path) -> Any:
        """
        Load and parse a JSON file.

        Args:
            file_path: Path to the JSON file

        Returns:
            Parsed JSON data

        Raises:
            FileNotFoundError: If file doesn't exist
            json.JSONDecodeError: If file contains invalid JSON
        """
        self.logger.info(f"Loading JSON file: {file_path}")

        if not file_path.exists():
            raise FileNotFoundError(f"File not found: {file_path}")

        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)

        self.logger.debug(f"Successfully loaded {file_path}")
        return data

    def find_history_files(self, history_files: Optional[List[str]] = None) -> List[Path]:
        """
        Find history JSON files in the data directory.

        Args:
            history_files: Optional list of specific history filenames

        Returns:
            List of Path objects for history files

        Raises:
            FileNotFoundError: If no history files found
        """
        if history_files:
            # Use specified history files
            paths = [self.data_dir / filename for filename in history_files]
            for path in paths:
                if not path.exists():
                    raise FileNotFoundError(f"Specified history file not found: {path}")
            return paths
        else:
            # Auto-discover history files
            # Try default name first
            default_history = self.data_dir / "history.json"
            if default_history.exists():
                return [default_history]

            # Look for files matching pattern history*.json
            history_files = sorted(self.data_dir.glob("history*.json"))
            if not history_files:
                raise FileNotFoundError(
                    f"No history files found in {self.data_dir}. "
                    "Please provide at least one history.json file."
                )

            self.logger.info(f"Found {len(history_files)} history files: {[f.name for f in history_files]}")
            return history_files

    def run(
        self,
        history_files: Optional[List[str]] = None,
        no_save: bool = False
    ) -> Dict[str, Any]:
        """
        Execute the compression process.

        Args:
            history_files: Optional list of history filenames to use
            no_save: If True, don't save compression info to disk

        Returns:
            Dictionary with compression results

        Raises:
            Exception: If compression fails
        """
        self.logger.info("=" * 60)
        self.logger.info("Starting Dimensio Compression")
        self.logger.info("=" * 60)

        # Load configuration space
        config_space_path = self.data_dir / "config_space.json"
        config_space_def = self.load_json_file(config_space_path)
        self.logger.info(f"Loaded configuration space with {len(config_space_def)} parameters")

        # Load steps configuration
        steps_path = self.data_dir / "steps.json"
        step_config = self.load_json_file(steps_path)
        self.logger.info(f"Loaded steps configuration: {step_config.get('dimension_step', 'N/A')}, "
                        f"{step_config.get('range_step', 'N/A')}, "
                        f"{step_config.get('projection_step', 'N/A')}")

        # Load history files
        history_paths = self.find_history_files(history_files)
        self.logger.info(f"Loading {len(history_paths)} history file(s)")

        histories_list = []
        for hist_path in history_paths:
            hist_data = self.load_json_file(hist_path)

            # Handle different formats
            if isinstance(hist_data, dict) and 'observations' in hist_data:
                # Extract observations from dict wrapper
                hist_data = hist_data['observations']

            if not isinstance(hist_data, list):
                raise ValueError(f"History data in {hist_path.name} must be a list of observations")

            histories_list.append(hist_data)
            self.logger.info(f"  {hist_path.name}: {len(hist_data)} observations")

        # Calculate source similarities
        num_histories = len(histories_list)
        if num_histories > 1:
            similarity = 1.0 / num_histories
            self.logger.info(f"Multi-source transfer learning: {num_histories} sources, "
                           f"auto-calculated similarity = {similarity:.4f} per source")

        # Set output directory
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        output_dir = self.result_dir

        # Execute compression
        self.logger.info("Executing compression...")
        try:
            result = compress_from_config(
                config_space_def=config_space_def,
                step_config=step_config,
                history_data=histories_list,
                output_dir=str(output_dir) if not no_save else None,
                save_info=not no_save
            )

            # Save result summary
            if not no_save:
                result_file = output_dir / "result_summary.json"
                output_dir.mkdir(parents=True, exist_ok=True)
                with open(result_file, 'w', encoding='utf-8') as f:
                    json.dump(result, f, indent=2, ensure_ascii=False)
                self.logger.info(f"Result summary saved to: {result_file}")

            self.logger.info("=" * 60)
            self.logger.info("Compression Completed Successfully")
            self.logger.info("=" * 60)
            self.logger.info(f"Original dimensions: {result['original_dim']}")
            self.logger.info(f"Compressed dimensions: {result['surrogate_dim']}")
            self.logger.info(f"Compression ratio: {result['compression_ratio']:.2%}")
            if not no_save:
                self.logger.info(f"Results saved to: {output_dir}")

            return result

        except Exception as e:
            self.logger.error(f"Compression failed: {str(e)}", exc_info=self.verbose)
            raise

    def create_sample_configs(self):
        """Create sample configuration files for demonstration."""
        self.logger.info("Creating sample configuration files...")

        # Sample config space
        sample_config_space = {
            "spark.memory.fraction": {
                "type": "float",
                "min": 0.1,
                "max": 0.9,
                "default": 0.6
            },
            "spark.stage.maxConsecutiveAttempts": {
                "type": "integer",
                "min": 1,
                "max": 10,
                "default": 4
            },
            "spark.executor.cores": {
                "type": "integer",
                "min": 1,
                "max": 8,
                "default": 4
            },
            "spark.shuffle.compress": {
                "type": "categorical",
                "choices": ["true", "false"],
                "default": "true"
            }
        }

        # Sample steps config
        sample_steps = {
            "dimension_step": "d_shap",
            "range_step": "r_boundary",
            "projection_step": "p_none",
            "step_params": {
                "d_shap": {"topk": 3}
            }
        }

        # Sample history
        sample_history = [
            {
                "config": {
                    "spark.memory.fraction": 0.6,
                    "spark.stage.maxConsecutiveAttempts": 4,
                    "spark.executor.cores": 4,
                    "spark.shuffle.compress": "true"
                },
                "objectives": [52.5],
                "constraints": None,
                "trial_state": 0,
                "elapsed_time": 0.3
            },
            {
                "config": {
                    "spark.memory.fraction": 0.7,
                    "spark.stage.maxConsecutiveAttempts": 5,
                    "spark.executor.cores": 6,
                    "spark.shuffle.compress": "false"
                },
                "objectives": [48.2],
                "constraints": None,
                "trial_state": 0,
                "elapsed_time": 0.4
            },
            {
                "config": {
                    "spark.memory.fraction": 0.5,
                    "spark.stage.maxConsecutiveAttempts": 3,
                    "spark.executor.cores": 2,
                    "spark.shuffle.compress": "true"
                },
                "objectives": [55.1],
                "constraints": None,
                "trial_state": 0,
                "elapsed_time": 0.25
            }
        ]

        # Write files
        self.data_dir.mkdir(parents=True, exist_ok=True)

        with open(self.data_dir / "config_space.json", 'w', encoding='utf-8') as f:
            json.dump(sample_config_space, f, indent=2, ensure_ascii=False)

        with open(self.data_dir / "steps.json", 'w', encoding='utf-8') as f:
            json.dump(sample_steps, f, indent=2, ensure_ascii=False)

        with open(self.data_dir / "history.json", 'w', encoding='utf-8') as f:
            json.dump(sample_history, f, indent=2, ensure_ascii=False)

        self.logger.info(f"Sample files created in {self.data_dir}:")
        self.logger.info("  - config_space.json")
        self.logger.info("  - steps.json")
        self.logger.info("  - history.json")


def main():
    """Main entry point for the script."""
    parser = argparse.ArgumentParser(
        description='Dimensio Compression Service Runner',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Run with default settings (data/ and result/ directories)
  python run_compression.py

  # Run with multiple history files
  python run_compression.py --history history1.json history2.json history3.json

  # Use custom directories
  python run_compression.py --data-dir ./my_data --result-dir ./my_results

  # Create sample configuration files
  python run_compression.py --create-samples

  # Verbose mode
  python run_compression.py --verbose
        """
    )

    parser.add_argument(
        '--data-dir',
        type=str,
        default='./data',
        help='Directory containing input JSON files (default: ./data)'
    )

    parser.add_argument(
        '--result-dir',
        type=str,
        default='./result',
        help='Directory for output results (default: ./result)'
    )

    parser.add_argument(
        '--history',
        type=str,
        nargs='+',
        default=None,
        help='Specific history file(s) to use (default: auto-discover from data directory)'
    )

    parser.add_argument(
        '--no-save',
        action='store_true',
        help='Do not save compression info to disk'
    )

    parser.add_argument(
        '--verbose',
        action='store_true',
        help='Enable verbose logging'
    )

    parser.add_argument(
        '--create-samples',
        action='store_true',
        help='Create sample configuration files in data directory and exit'
    )

    args = parser.parse_args()

    # Create runner instance
    runner = CompressionRunner(
        data_dir=args.data_dir,
        result_dir=args.result_dir,
        verbose=args.verbose
    )

    # Handle create-samples command
    if args.create_samples:
        try:
            runner.create_sample_configs()
            print(f"\nSample configuration files created in {args.data_dir}/")
            print("You can now run: python run_compression.py")
            return 0
        except Exception as e:
            print(f"Error creating sample configs: {e}", file=sys.stderr)
            return 1

    # Initialize
    if not runner.initialize():
        print("\nInitialization failed. Run with --create-samples to create sample files.",
              file=sys.stderr)
        return 1

    # Run compression
    try:
        result = runner.run(
            history_files=args.history,
            no_save=args.no_save
        )

        # Print summary to stdout
        print("\n" + "=" * 60)
        print("COMPRESSION SUMMARY")
        print("=" * 60)
        print(json.dumps(result, indent=2, ensure_ascii=False))
        print("=" * 60)

        return 0

    except FileNotFoundError as e:
        print(f"\nError: {e}", file=sys.stderr)
        print("\nRun with --create-samples to create sample configuration files.",
              file=sys.stderr)
        return 1

    except Exception as e:
        print(f"\nError during compression: {e}", file=sys.stderr)
        if args.verbose:
            import traceback
            traceback.print_exc()
        return 1


if __name__ == '__main__':
    sys.exit(main())
