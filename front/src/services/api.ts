import axios from 'axios';
import { CompressionHistory } from '../types';

const API_BASE_URL = '/api';

// Mock data for development (the data you provided)
const MOCK_DATA: CompressionHistory = {
  total_updates: 1,
  history: [
    {
      timestamp: '2025-11-18T01:23:34.536826',
      event: 'initial_compression' as any,
      iteration: null,
      spaces: {
        original: {
          n_parameters: 12,
          parameters: [
            'spark.default.parallelism',
            'spark.executor.cores',
            'spark.executor.instances',
            'spark.executor.memory',
            'spark.io.compression.codec',
            'spark.memory.fraction',
            'spark.memory.storageFraction',
            'spark.network.timeout',
            'spark.shuffle.compress',
            'spark.sql.adaptive.enabled',
            'spark.sql.autoBroadcastJoinThreshold',
            'spark.sql.shuffle.partitions',
          ],
        },
        sample: {
          n_parameters: 6,
          parameters: [
            'spark.default.parallelism',
            'spark.executor.cores',
            'spark.executor.memory',
            'spark.memory.fraction',
            'spark.shuffle.compress',
            'spark.sql.shuffle.partitions',
          ],
        },
        surrogate: {
          n_parameters: 6,
          parameters: [
            'spark.default.parallelism',
            'spark.executor.cores',
            'spark.executor.memory',
            'spark.memory.fraction',
            'spark.shuffle.compress',
            'spark.sql.shuffle.partitions',
          ],
        },
      },
      compression_ratios: {
        sample_to_original: 0.5,
        surrogate_to_original: 0.5,
      },
      pipeline: {
        n_steps: 2,
        steps: [
          {
            name: 'dimension_selection',
            type: 'SHAPDimensionStep',
            input_space_params: 12,
            output_space_params: 6,
            supports_adaptive_update: false,
            uses_progressive_compression: false,
            selected_parameters: [
              'spark.executor.cores',
              'spark.executor.memory',
              'spark.shuffle.compress',
              'spark.default.parallelism',
              'spark.memory.fraction',
              'spark.sql.shuffle.partitions',
            ],
            selected_indices: [1, 3, 8, 0, 5, 11],
            calculator: 'SHAPImportanceCalculator',
            compression_ratio: 0.5,
            topk: 6,
            step_index: 0,
          },
          {
            name: 'range_compression',
            type: 'SHAPBoundaryRangeStep',
            input_space_params: 6,
            output_space_params: 6,
            supports_adaptive_update: false,
            uses_progressive_compression: false,
            compression_info: {
              compressed_params: [
                {
                  name: 'spark.default.parallelism',
                  type: 'UniformIntegerHyperparameter',
                  original_range: [50.0, 500.0],
                  compressed_range: [55.0, 500.0],
                  compression_ratio: 0.9888888888888889,
                },
                {
                  name: 'spark.executor.memory',
                  type: 'UniformIntegerHyperparameter',
                  original_range: [1024.0, 16384.0],
                  compressed_range: [1140.0, 15940.0],
                  compression_ratio: 0.9635416666666666,
                },
                {
                  name: 'spark.memory.fraction',
                  type: 'UniformFloatHyperparameter',
                  original_range: [0.3, 0.9],
                  compressed_range: [0.3027792138027617, 0.8950859708096182],
                  compression_ratio: 0.9871779283447607,
                },
                {
                  name: 'spark.shuffle.compress',
                  type: 'UniformFloatHyperparameter',
                  original_range: [0.0, 1.0],
                  compressed_range: [0.006952130531190703, 0.9941393612211675],
                  compression_ratio: 0.9871872306899768,
                },
                {
                  name: 'spark.sql.shuffle.partitions',
                  type: 'UniformIntegerHyperparameter',
                  original_range: [50.0, 1000.0],
                  compressed_range: [51.0, 997.0],
                  compression_ratio: 0.9957894736842106,
                },
              ],
              unchanged_params: ['spark.executor.cores'],
              avg_compression_ratio: 0.9845170376549006,
            },
            top_ratio: 0.75,
            sigma: 2.0,
            enable_mixed_sampling: true,
            initial_prob: 0.9,
            step_index: 1,
          },
        ],
        sampling_strategy: 'MixedRangeSamplingStrategy',
      },
    },
  ],
};

class ApiService {
  /**
   * Get list of all experiments from the API
   */
  async getExperiments() {
    try {
      const response = await axios.get(`${API_BASE_URL}/experiments`);
      return response.data;
    } catch (error) {
      console.error('Error fetching experiments:', error);
      // Fallback to mock data if API is not available
      console.warn('Using mock data as fallback');
      return { success: true, count: 1, data: [{ experiment_id: 'mock' }] };
    }
  }

  /**
   * Get compression history for a specific experiment
   * This is the main method used by the App component
   */
  async getExperimentHistory(experimentId: string): Promise<CompressionHistory> {
    try {
      const response = await axios.get(`${API_BASE_URL}/experiments/${experimentId}/history`);

      if (response.data.success && response.data.data) {
        // API returns { success: true, data: { total_updates, events: [...] } }
        const historyData = response.data.data;

        // Transform API response to CompressionHistory format
        return {
          total_updates: historyData.total_updates,
          history: historyData.events || historyData.history || []
        };
      }

      throw new Error('Invalid API response format');
    } catch (error) {
      console.error('Error fetching experiment history:', error);
      // Fallback to mock data if API is not available
      console.warn('Using mock data as fallback');
      return MOCK_DATA;
    }
  }

  /**
   * Get compression history - automatically fetches from first available experiment
   * This is a convenience method that:
   * 1. Gets list of experiments
   * 2. Selects the first one
   * 3. Fetches its history
   */
  async getCompressionHistory(): Promise<CompressionHistory> {
    try {
      // First, get list of experiments
      const experimentsResponse = await this.getExperiments();

      if (experimentsResponse.success && experimentsResponse.data && experimentsResponse.data.length > 0) {
        // Use the first experiment
        const firstExperiment = experimentsResponse.data[0];
        const experimentId = firstExperiment.experiment_id;

        console.log(`Fetching history for experiment: ${experimentId}`);

        // Fetch history for this experiment
        return await this.getExperimentHistory(experimentId);
      }

      throw new Error('No experiments available');
    } catch (error) {
      console.error('Error in getCompressionHistory:', error);
      console.warn('Using mock data as fallback');
      return MOCK_DATA;
    }
  }

  /**
   * Get visualizations metadata for an experiment
   */
  async getVisualizations(experimentId: string) {
    try {
      const response = await axios.get(`${API_BASE_URL}/experiments/${experimentId}/visualizations`);
      return response.data;
    } catch (error) {
      console.error('Error fetching visualizations:', error);
      return { success: false, data: [] };
    }
  }
}

export default new ApiService();
