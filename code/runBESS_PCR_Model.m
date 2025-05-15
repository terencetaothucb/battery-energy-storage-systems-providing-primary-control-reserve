function runBESS_PCR_Model()
    % RUNBESS_PCR_MODEL - Main entry point for BESS PCR simulation

    % Option 1: Run demo with default parameters
    BESS_Utilities.demo();
    
    % Option 2: Custom simulation example
    %{
    % Get default parameters and modify as needed
    params = BESS_Parameters.getDefaultParameters();
    params.C = 5; % 5 MWh system
    params.P_PQ = 2; % 2 MW prequalified power
    
    % Load or generate frequency data
    [f_data, t_data] = load_your_frequency_data(); % User-provided function
    
    % Run simulation
    simulator = BESS_Simulator(params);
    simulator = simulator.runSimulation(f_data, t_data);
    
    % Visualize results
    BESS_Visualization.plotSimulationOverview(...
        t_data, f_data, simulator.Results.SOC_history);
    BESS_Visualization.displayResults(simulator.Results);
    %}
end