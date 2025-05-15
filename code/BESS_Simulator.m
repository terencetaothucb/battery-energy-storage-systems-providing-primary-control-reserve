classdef BESS_Simulator
    % BESS_Simulator - Core simulation engine for Battery Energy Storage System
    % providing Primary Control Reserve (PCR) according to ENTSO-E regulations
    
    properties
        Parameters      % System configuration parameters
        Results         % Simulation results storage
    end
    
    methods
        function obj = BESS_Simulator(parameters)
            % Constructor - Initialize simulator with parameters
            % Input:
            %   parameters - Struct containing system parameters
            
            % Validate required parameters
            required_fields = {'C', 'P_PQ', 'eta_ch', 'eta_dis', 'delta_E_SC', ...
                'SOC_limits_ST', 'SOC_limits_OF', 'SOC_limits_DU', ...
                'P_ST', 'delta_t_contract', 'delta_t_lead', 'initial_SOC', 'fn'};
            for f = required_fields
                if ~isfield(parameters, f{1})
                    error('Missing required parameter: %s', f{1});
                end
            end
            
            obj.Parameters = parameters;
            obj.Results = struct();
        end
        
        function obj = runSimulation(obj, f_data, t_data)
            % Main simulation loop for BESS operation
            % Inputs:
            %   f_data - Frequency time series [Hz]
            %   t_data - Corresponding time vector [s]
            
            % Validate inputs
            if length(f_data) ~= length(t_data)
                error('Frequency data and time vector must have same length');
            end
            
            % Initialize result storage
            n_steps = length(f_data);
            obj = obj.initializeResultStorage(n_steps);
            
            % Initialize state variables
            [E, transaction] = obj.initializeSimulationState();
            obj.Results.SOC_history(1) = obj.Parameters.initial_SOC; 
            
            % Main simulation loop
            for k = 2:n_steps
                delta_t = t_data(k) - t_data(k-1);
                
                % Calculate all power flows for current timestep
                [flows, current_power] = obj.calculatePowerFlows(...
                    f_data(k), t_data(k), E, transaction, delta_t);
                
                % Update transaction status (must happen AFTER power flow calculation)
                transaction = obj.updateTransactionStatus(...
                    t_data(k), E, transaction, delta_t);
                
                % Update energy balance
                [E, obj] = obj.updateEnergyBalance(...
                    E, flows, delta_t, k);
                
                % Record system state
                obj.Results.SOC_history(k) = (E / obj.Parameters.C) * 100;
                obj.Results.E_rate_history(k) = abs(current_power) / obj.Parameters.C;
            end
            
            % Calculate final performance metrics
            obj = obj.calculatePerformanceMetrics();
        end
    end
    
    methods (Access = private)
        function obj = initializeResultStorage(obj, n_steps)
            % Initialize data structures for storing simulation results
            
            obj.Results.SOC_history = zeros(n_steps, 1);
            obj.Results.E_rate_history = zeros(n_steps, 1);
            
            % Energy flow tracking [MWh]
            obj.Results.energy_flows = struct(...
                'primary_control', zeros(n_steps, 1), ...  % PCR response
                'overfulfillment', zeros(n_steps, 1), ...  % OF energy
                'deadband_util', zeros(n_steps, 1), ...    % DU energy  
                'schedule_tx', zeros(n_steps, 1), ...      % ST energy
                'self_consumption', zeros(n_steps, 1));    % SC losses
        end
        
        function [E, transaction] = initializeSimulationState(obj)
            % Initialize simulation state variables
            
            E = obj.Parameters.C * (obj.Parameters.initial_SOC/100); % Convert % to fraction
            
            % Transaction tracking
            transaction = struct(...
                'active', false, ...        % Transaction status flag
                'start_time', 0, ...       % Scheduled start time [s]
                'end_time', 0, ...          % Scheduled end time [s]
                'type', 0, ...              % 1=charge, -1=discharge
                'power', 0, ...             % Transaction power [MW]
                'scheduled', false);        % Whether transaction has been scheduled
        end
        
        function [flows, current_power] = calculatePowerFlows(...
                obj, f, t, E, transaction, delta_t)
            % Calculate all power flows for current timestep
            % Returns:
            %   flows - Struct containing all energy flow components
            %   current_power - Total BESS power output [MW]
            
            flows = struct();
            SOC = (E / obj.Parameters.C) * 100;
            
            % 1. Primary Control Response (PCR)
            delta_f = obj.Parameters.fn - f; % Frequency deviation [Hz]
            P_grid = obj.Parameters.P_PQ * (delta_f); % Grid demand [MW]
            
            % Apply charging/discharging efficiency
            if P_grid < 0 % Charging mode
                P_PC = -obj.Parameters.eta_ch * P_grid;
            else % Discharging mode
                P_PC = (1/obj.Parameters.eta_dis) * P_grid;
            end
            flows.primary_control = P_PC * delta_t / 3600; % [MWh]
            
            % 2. Schedule Transaction (ST)
            if transaction.active && t >= transaction.start_time && t <= transaction.end_time
                if transaction.type == 1 % Charging transaction
                    % Energy from grid to battery (positive)
                    grid_energy = obj.Parameters.P_ST * delta_t / 3600;
                    % Apply charging efficiency to get actual stored energy
                    flows.schedule_tx = grid_energy * obj.Parameters.eta_ch;
                else % Discharging transaction
                    % Energy from battery to grid (negative)
                    battery_energy = -obj.Parameters.P_ST * delta_t / 3600;
                    % Apply discharging efficiency to get actual delivered energy
                    flows.schedule_tx = battery_energy / obj.Parameters.eta_dis;
                end
            else
                flows.schedule_tx = 0;
            end
            
            % 3. Overfulfillment (OF)
            flows.overfulfillment = 0;
            if obj.Parameters.use_OF
                if SOC <= obj.Parameters.SOC_limits_OF(1) && f > obj.Parameters.fn
                    % Additional charging during underfrequency
                    flows.overfulfillment = 0.2 * flows.primary_control;
                elseif SOC >= obj.Parameters.SOC_limits_OF(2) && f < obj.Parameters.fn
                    % Additional discharging during overfrequency
                    flows.overfulfillment = 0.2 * flows.primary_control;
                end
            end
            
            % 4. Deadband Utilization (DU)
            flows.deadband_util = 0;
            if obj.Parameters.use_DU
                in_deadband = (f >= obj.Parameters.fn-0.01 && f <= obj.Parameters.fn+0.01);
                if in_deadband
                    if SOC <= obj.Parameters.SOC_limits_DU(1) && f < obj.Parameters.fn
                        % Skip required discharging in deadband
                        flows.deadband_util = -flows.primary_control;
                    elseif SOC >= obj.Parameters.SOC_limits_DU(2) && f > obj.Parameters.fn
                        % Skip required charging in deadband
                        flows.deadband_util = -flows.primary_control;
                    end
                end
            end
            
            % 5. Self-consumption (always negative)
            flows.self_consumption = -obj.Parameters.delta_E_SC * delta_t;
            
            % Calculate total current power output
            current_power = P_PC;
            if transaction.active && t >= transaction.start_time && t <= transaction.end_time
                current_power = current_power + transaction.type * obj.Parameters.P_ST;
            end
        end
        
        function transaction = updateTransactionStatus(obj, t, E, transaction, delta_t)
            % Manage schedule transaction lifecycle
            if transaction.type == 1
                disp(['Charging transaction activated at t = ' num2str(t)]);
            elseif transaction.type == -1
                disp(['Discharging transaction activated at t = ' num2str(t)]);
            end
            
            SOC = (E / obj.Parameters.C) * 100;
            delta_t_lead_sec = obj.Parameters.delta_t_lead * 3600;
            
            % Complete current transaction if time has elapsed
            if transaction.active && t > transaction.end_time
                transaction.active = false;
                transaction.scheduled = false;
            end
            
            % Schedule new transaction if needed and none is active or scheduled
            if ~transaction.active && ~transaction.scheduled
                if SOC <= obj.Parameters.SOC_limits_ST(1)
                    % Schedule charging transaction
                    transaction.active = false;
                    transaction.scheduled = true;
                    transaction.start_time = t + delta_t_lead_sec;
                    transaction.end_time = transaction.start_time + obj.Parameters.delta_t_contract*3600;
                    transaction.type = 1;
                    transaction.power = obj.Parameters.P_ST;
                    
                elseif SOC >= obj.Parameters.SOC_limits_ST(2)
                    % Schedule discharging transaction
                    transaction.active = false;
                    transaction.scheduled = true;
                    transaction.start_time = t + delta_t_lead_sec;
                    transaction.end_time = transaction.start_time + obj.Parameters.delta_t_contract*3600;
                    transaction.type = -1;
                    transaction.power = obj.Parameters.P_ST;
                end
            end
            
            % Activate scheduled transaction when start time is reached
            if transaction.scheduled && t >= transaction.start_time
                transaction.active = true;
                transaction.scheduled = false;
            end
        end
        
        function [E, obj] = updateEnergyBalance(obj, E, flows, delta_t, k)
            % Update battery energy state and record energy flows
            
            % Update energy balance (all values in MWh)
            E = E + flows.primary_control + flows.overfulfillment + ...
                flows.deadband_util + flows.schedule_tx + flows.self_consumption;
            
            % Apply physical SOC limits (0-100%)
            E = max(0, min(E, obj.Parameters.C));
            
            % Record all energy flows
            obj.Results.energy_flows.primary_control(k) = flows.primary_control;
            obj.Results.energy_flows.overfulfillment(k) = flows.overfulfillment;
            obj.Results.energy_flows.deadband_util(k) = flows.deadband_util;
            obj.Results.energy_flows.schedule_tx(k) = flows.schedule_tx;
            obj.Results.energy_flows.self_consumption(k) = flows.self_consumption;
        end
        
        function obj = calculatePerformanceMetrics(obj)
            % Calculate key performance indicators after simulation
            
            % 1. Full Cycle Equivalents (FCE)
            total_throughput = sum(abs(obj.Results.energy_flows.primary_control)) + ...
                sum(abs(obj.Results.energy_flows.overfulfillment)) + ...
                sum(abs(obj.Results.energy_flows.deadband_util)) + ...
                sum(abs(obj.Results.energy_flows.schedule_tx));
            obj.Results.FCE = total_throughput / (2 * obj.Parameters.C);
            
            % 2. Schedule Transaction Energy
            st_energy = obj.Results.energy_flows.schedule_tx;
            obj.Results.schedule_tx_energy = struct(...
                'charged', sum(st_energy(st_energy > 0)), ...  % Positive = charging
                'discharged', -sum(st_energy(st_energy < 0))); % Negative = discharging
            
            % 3. Total Energy Charged/Discharged (from all sources)
            pc_energy = obj.Results.energy_flows.primary_control;
            of_energy = obj.Results.energy_flows.overfulfillment;
            
            total_charged = sum(pc_energy(pc_energy > 0)) + ...
                sum(of_energy(of_energy > 0)) + ...
                obj.Results.schedule_tx_energy.charged;
            
            total_discharged = -sum(pc_energy(pc_energy < 0)) + ...
                -sum(of_energy(of_energy < 0)) + ...
                obj.Results.schedule_tx_energy.discharged;
            
            % 4. Calculate percentage shares
            if total_charged > 0
                obj.Results.energy_shares = struct(...
                    'pct_charged_via_st', (obj.Results.schedule_tx_energy.charged / total_charged) * 100, ...
                    'pct_discharged_via_st', (obj.Results.schedule_tx_energy.discharged / total_discharged) * 100);
            else
                obj.Results.energy_shares = struct(...
                    'pct_charged_via_st', 0, ...
                    'pct_discharged_via_st', 0);
            end
            
            obj.Results.total_energy = struct(...
                'charged', total_charged, ...
                'discharged', total_discharged);
        end
    end
end