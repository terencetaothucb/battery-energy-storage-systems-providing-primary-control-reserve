classdef BESS_Utilities
    % BESS_Utilities - Helper functions and demos
    
    methods (Static)

        function demo()
            % Demonstration of the complete BESS PCR model
            
            % Load crawler data
            load FreqData.mat FreqData
            f_data = FreqData.Freq;
            t_data = FreqData.Time;
            % Get default parameters
            params = BESS_Parameters.getDefaultParameters();
            
            % Create and run simulation
            simulator = BESS_Simulator(params);
            simulator = simulator.runSimulation(f_data, t_data);
            
            % Visualize results
            figure;
            subplot(2,1,1);
            plot(t_data/(3600*24), f_data);
            xlabel('Time [days]');
            ylabel('Frequency [Hz]');
            title('Generated Grid Frequency');
            grid on;
            
            subplot(2,1,2);
            histogram(f_data, 50, 'Normalization', 'probability');
            xlabel('Frequency [Hz]');
            ylabel('Probability');
            title('Frequency Distribution');
            grid on;
            
            BESS_Visualization.plotSimulationOverview(...
                t_data, f_data, simulator.Results.SOC_history);
            BESS_Visualization.plotSOCDistribution(simulator.Results.SOC_history);
            BESS_Visualization.plotERateDistribution(...
                simulator.Results.E_rate_history);
            BESS_Visualization.displayResults(simulator.Results);
        end
    end
end