"""
Dimensio Visualization Example

This example demonstrates how to use Dimensio's visualization features:
- Basic mode: Generate standalone HTML file (no server required)
- Advanced mode: Start local HTTP server for interactive visualization

Both modes provide the same visualizations:
- Compression Summary (dimension reduction, compression ratios)
- Range Compression Details
- Parameter Importance Analysis
- Multi-Task Heatmap (if multi-task data available)
- Source Task Similarities (if transfer learning data available)
"""

import numpy as np
from ConfigSpace import ConfigurationSpace
from ConfigSpace.hyperparameters import UniformFloatHyperparameter, UniformIntegerHyperparameter
from openbox.utils.history import History, Observation
from openbox.utils.constants import SUCCESS

from dimensio import (
    Compressor,
    SHAPDimensionStep,
    BoundaryRangeStep,
    visualize_compression,
)


def create_config_space():
    """Create a sample configuration space for demonstration."""
    cs = ConfigurationSpace(seed=42)
    cs.add_hyperparameters([
        # Neural network hyperparameters
        UniformFloatHyperparameter('learning_rate', 1e-5, 1e-1, default_value=1e-3, log=True),
        UniformFloatHyperparameter('momentum', 0.1, 0.99, default_value=0.9),
        UniformFloatHyperparameter('weight_decay', 1e-6, 1e-2, default_value=1e-4, log=True),
        UniformIntegerHyperparameter('batch_size', 16, 512, default_value=64, log=True),
        UniformIntegerHyperparameter('num_layers', 1, 8, default_value=3),
        UniformIntegerHyperparameter('hidden_size', 32, 1024, default_value=256, log=True),
        UniformFloatHyperparameter('dropout', 0.0, 0.5, default_value=0.1),
        UniformFloatHyperparameter('warmup_ratio', 0.0, 0.2, default_value=0.1),
        # Optimizer hyperparameters
        UniformFloatHyperparameter('beta1', 0.8, 0.99, default_value=0.9),
        UniformFloatHyperparameter('beta2', 0.9, 0.999, default_value=0.999),
        UniformFloatHyperparameter('epsilon', 1e-9, 1e-6, default_value=1e-8, log=True),
        # Training hyperparameters
        UniformIntegerHyperparameter('epochs', 10, 200, default_value=50),
    ])
    return cs


def generate_mock_history(config_space, n_samples=50):
    """Generate mock evaluation history for demonstration."""
    history = History(
        task_id='visualization_demo',
        num_objectives=1,
        num_constraints=0,
        config_space=config_space
    )
    
    def mock_objective(config_dict):
        """Mock objective: learning_rate, batch_size, hidden_size are most important."""
        lr = config_dict.get('learning_rate', 0.01)
        bs = config_dict.get('batch_size', 32)
        hs = config_dict.get('hidden_size', 256)
        
        # Optimal: lr=0.001, batch_size=128, hidden_size=512
        score = abs(np.log10(lr) + 3.0) * 15
        score += abs(bs - 128) * 0.05
        score += abs(hs - 512) * 0.01
        score += np.random.normal(0, 3)
        return max(score, 0.5)
    
    for _ in range(n_samples):
        config = config_space.sample_configuration()
        obj_value = mock_objective(config.get_dictionary())
        obs = Observation(
            config=config,
            objectives=[obj_value],
            constraints=None,
            trial_state=SUCCESS,
            elapsed_time=0.1
        )
        history.update_observation(obs)
    
    return history


def example_basic_visualization():
    """
    Example 1: Basic Visualization Mode
    
    Generate a standalone HTML file that can be opened in any browser.
    No server required - perfect for sharing results.
    """
    print("\n" + "=" * 70)
    print(" " * 15 + "Example 1: Basic Visualization (Static HTML)")
    print("=" * 70)
    
    # Create configuration space and history
    config_space = create_config_space()
    history = generate_mock_history(config_space, n_samples=50)
    
    print(f"\n📊 Configuration space: {len(config_space.get_hyperparameters())} dimensions")
    print(f"📈 History samples: {len(history.observations)}")
    
    # Create compressor with visualization enabled
    compressor = Compressor(
        config_space=config_space,
        steps=[
            SHAPDimensionStep(strategy='shap', topk=6),
            BoundaryRangeStep(method='boundary', top_ratio=0.8, sigma=2.0)
        ],
        save_compression_info=True,
        output_dir='./results/visualization_basic',
    )
    
    # Compress space
    print("\n⚙️  Compressing configuration space...")
    surrogate_space, sample_space = compressor.compress_space(
        space_history=[history]
    )
    
    print(f"\n✅ Compression complete:")
    print(f"   Original: {len(config_space.get_hyperparameters())} dims")
    print(f"   Compressed: {len(surrogate_space.get_hyperparameters())} dims")
    print(f"   Ratio: {len(surrogate_space.get_hyperparameters())/len(config_space.get_hyperparameters()):.1%}")
    
    # Generate static HTML visualization
    print("\n🎨 Generating static HTML visualization...")
    html_path = compressor.visualize_html(
        mode='basic',
        open_html=True  # Set to True to auto-open in browser
    )
    
    print(f"\n📄 Visualization saved to: {html_path}")
    print("   Open this file in any browser to view the visualization.")
    
    return html_path


def example_advanced_visualization():
    """
    Example 2: Advanced Visualization Mode
    
    Start a local HTTP server for interactive visualization.
    Supports real-time data refresh and full React frontend.
    """
    print("\n" + "=" * 70)
    print(" " * 15 + "Example 2: Advanced Visualization (Local Server)")
    print("=" * 70)
    
    # Create configuration space and history
    config_space = create_config_space()
    history = generate_mock_history(config_space, n_samples=50)
    
    print(f"\n📊 Configuration space: {len(config_space.get_hyperparameters())} dimensions")
    print(f"📈 History samples: {len(history.observations)}")
    
    # Create compressor with advanced visualization
    compressor = Compressor(
        config_space=config_space,
        steps=[
            SHAPDimensionStep(strategy='shap', topk=6),
            BoundaryRangeStep(method='boundary', top_ratio=0.8, sigma=2.0)
        ],
        # Enable advanced visualization with auto-open
        visualization='advanced',
        auto_open_html=True,
        visualization_port=8050,
        save_compression_info=True,
        output_dir='./results/visualization_advanced',
    )
    
    # Compress space - visualization will start automatically
    print("\n⚙️  Compressing configuration space...")
    print("   (Browser will open automatically after compression)")
    
    surrogate_space, sample_space = compressor.compress_space(
        space_history=[history]
    )
    
    print(f"\n✅ Compression complete:")
    print(f"   Original: {len(config_space.get_hyperparameters())} dims")
    print(f"   Compressed: {len(surrogate_space.get_hyperparameters())} dims")
    
    print("\n🌐 Visualization server is running!")
    print("   Access at: http://localhost:8050")
    print("   Press Ctrl+C to stop the server.")
    
    return compressor


def example_standalone_visualization():
    """
    Example 3: Standalone Visualization Function
    
    Use the standalone visualize_compression() function to visualize
    existing compression results without creating a new compressor.
    """
    print("\n" + "=" * 70)
    print(" " * 15 + "Example 3: Standalone Visualization")
    print("=" * 70)
    
    # Assume compression results already exist in a directory
    data_dir = './results/visualization_basic'
    
    print(f"\n📁 Loading compression history from: {data_dir}")
    
    # Use standalone function
    try:
        # Basic mode - generate static HTML
        html_path = visualize_compression(
            data_dir=data_dir,
            mode='basic',
            open_browser=False
        )
        print(f"\n✅ Static HTML generated: {html_path}")
        
        # Advanced mode - start server (uncomment to use)
        # url = visualize_compression(
        #     data_dir=data_dir,
        #     mode='advanced',
        #     port=8051,
        #     open_browser=True
        # )
        # print(f"\n✅ Server running at: {url}")
        
    except FileNotFoundError as e:
        print(f"\n⚠️  {e}")
        print("   Run example_basic_visualization() first to generate data.")


def example_auto_visualization():
    """
    Example 4: Auto Visualization on Compression
    
    Configure the Compressor to automatically open visualization
    when compress_space() is called.
    """
    print("\n" + "=" * 70)
    print(" " * 15 + "Example 4: Auto Visualization")
    print("=" * 70)
    
    config_space = create_config_space()
    history = generate_mock_history(config_space, n_samples=50)
    
    print("\n🔧 Creating compressor with auto-visualization enabled...")
    
    # Method 1: Auto-open static HTML after compression
    compressor = Compressor(
        config_space=config_space,
        steps=[
            SHAPDimensionStep(strategy='shap', topk=6),
            BoundaryRangeStep(method='boundary', top_ratio=0.8)
        ],
        visualization='basic',    # 'none', 'basic', or 'advanced'
        auto_open_html=True,      # Auto-open browser
        output_dir='./results/visualization_auto',
    )
    
    print("\n⚙️  Compressing... (browser will open automatically)")
    surrogate_space, _ = compressor.compress_space(space_history=[history])
    
    print(f"\n✅ Done! Compressed to {len(surrogate_space.get_hyperparameters())} dims")
    
    return compressor


def main():
    """Run all visualization examples."""
    print("\n" + "=" * 70)
    print(" " * 20 + "Dimensio Visualization Examples")
    print("=" * 70)
    
    print("""
This example demonstrates Dimensio's visualization features:

  1. Basic Mode (Static HTML)
     - Generates standalone HTML file
     - Can be opened offline in any browser
     - Easy to share with others

  2. Advanced Mode (Local Server)
     - Starts Flask server with React frontend
     - Supports real-time data refresh
     - Full interactive visualization

  3. Standalone Function
     - Visualize existing compression results
     - No need to re-run compression

  4. Auto Visualization
     - Automatically open visualization after compression
""")
    
    # Run Example 1: Basic visualization
    html_path = example_basic_visualization()
    
    # Run Example 3: Standalone visualization
    # example_standalone_visualization()

    example_advanced_visualization()
    
    print("\n" + "=" * 70)
    print(" " * 20 + "Examples Complete!")
    print("=" * 70)
    print(f"""
📄 Generated files:
   - {html_path}
   - ./results/visualization_basic/compression_history.json

To try advanced mode (local server), run:
   python -c "from examples.visualization_example import example_advanced_visualization; example_advanced_visualization()"

Or use auto-visualization:
   python -c "from examples.visualization_example import example_auto_visualization; example_auto_visualization()"
""")


if __name__ == '__main__':
    main()
