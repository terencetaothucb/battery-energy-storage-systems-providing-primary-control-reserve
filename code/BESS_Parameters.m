classdef BESS_Parameters
    % BESS_Parameters - Contains all system parameters and settings
    
    properties (Constant)
        % System physical parameters
        DEFAULT_FREQUENCY = 60;        % Hz
        DEFAULT_CAPACITY = 2;          % MWh
        DEFAULT_POWER = 1;             % MW
        EFFICIENCY_CHARGE = 0.9;
        EFFICIENCY_DISCHARGE = 0.9;
        SELF_CONSUMPTION = 3.85e-8;    % MWh/s
        
        % Operational parameters
        DEFAULT_SOC_LIMITS_ST = [39 41];  % Schedule transaction limits [%]
        DEFAULT_SOC_LIMITS_OF = [50 50];  % Overfulfillment limits [%]
        DEFAULT_SOC_LIMITS_DU = [50 50];  % Deadband utilization limits [%]
        INITIAL_SOC = 40;

        % Schedule transaction defaults
        DEFAULT_TRANSACTION_POWER = 0.5;   % MW
        DEFAULT_CONTRACT_DURATION = 0.5;      % hours
        DEFAULT_LEAD_TIME = 0.75;              % hours
        
        % Deadband definition
        DEADBAND_RANGE = 60 + [-0.01 +0.01];    % Hz
        
        % Simulation defaults
        DEFAULT_SIMULATION_TIME = 6;       % hours
        DEFAULT_SAMPLING_RATE = 1;          % Hz
    end
    
    methods (Static)
        function params = getDefaultParameters()
            % Returns a struct with all default parameters
            params = struct();
            
            % System parameters
            params.fn = BESS_Parameters.DEFAULT_FREQUENCY;
            params.C = BESS_Parameters.DEFAULT_CAPACITY;
            params.P_PQ = BESS_Parameters.DEFAULT_POWER;
            params.eta_ch = BESS_Parameters.EFFICIENCY_CHARGE;
            params.eta_dis = BESS_Parameters.EFFICIENCY_DISCHARGE;
            params.delta_E_SC = BESS_Parameters.SELF_CONSUMPTION;
            
            % Charge management parameters
            params.SOC_limits_ST = BESS_Parameters.DEFAULT_SOC_LIMITS_ST;
            params.SOC_limits_OF = BESS_Parameters.DEFAULT_SOC_LIMITS_OF;
            params.SOC_limits_DU = BESS_Parameters.DEFAULT_SOC_LIMITS_DU;
            params.initial_SOC = BESS_Parameters.INITIAL_SOC;
            
            % Transaction parameters
            params.P_ST = BESS_Parameters.DEFAULT_TRANSACTION_POWER;
            params.delta_t_contract = BESS_Parameters.DEFAULT_CONTRACT_DURATION;
            params.delta_t_lead = BESS_Parameters.DEFAULT_LEAD_TIME;
            
            % Operation flags
            params.use_OF = false;
            params.use_DU = false;
        end
    end
end