clear variables;clc;close all;

% Universal Gas Constant
Rig = 8.314/1000;          % kJ/(mol.K)
Rig_rxn = 8.314e-5;        % (m^3.bar)/(mol.K)

% Paper units - at Tr1 & Tr2
ksmr = 1.842e-4;           % kmol.bar^0.5  /(kg cat.hr)
kwgs = 7.558;              % kmol/(kg cat.hr.bar)
kgrr = 2.193e-5;           % kmol.bar^0.5  /(kg cat.hr)

Tr1 = 648;                 % K
Tr2 = 823;                 % K

Esmr = 240.1;              % kJ/mol
Ewgs = 67.13;              % kJ/mol
Egrr = 243.9;              % kJ/mol

KCH4 = 0.1791;             % bar^-1
KCO = 40.91;               % bar^-1
KH2 = 0.02960;             % bar^-1
KH2O = 0.4152;             % Dimensionless

delHCH4 = -38.28;          % kJ/mol
delHCO = -70.65;           % kJ/mol
delHH2 = -82.9;            % kJ/mol
delHH2O = 88.680;          % kJ/mol

delWGS = -41.2;                                   % kJ/mol
delSMR = 206.2;                                   % kJ/mol
delGRR = 165;                                     % kJ/mol
Vol_solid = pi*(0.003^2 - 0.00252^2)*0.5;         % m^3
PinByVolSolid = 2.97/Vol_solid;                   % (W/m^3)

% Parameter sets
n_spacing = 5;
% % Data generator
% T_rxn_values = 600:((800-600)/n_spacing):800;     % K, different reaction temperatures
% T_rxn_values =  T_rxn_values + 273.15;
% S_by_C_values = 1:((3-1)/n_spacing):3;                      % Different steam to carbon ratios
% Pt_values = 7:((20-7)/n_spacing):20;                        % Different total pressures in bar
% amt_catalyst_values = 500:((1000-500)/n_spacing):1000;            % Different catalyst amounts
% velocity_values = 1:((10-1)/n_spacing):10;
% t_end_values = 0.28./velocity_values;                % Different Tres

% put optimal conditions from neural network here 
T_rxn_values = 800+273.15;
S_by_C_values = 3;
Pt_values = 7;
amt_catalyst_values = 944.44;
T_in_values = 400+273.15;
velocity_values = 0.5;
t_end_values = 0.28/velocity_values;

% Initialize array to store results
results = [];
tic
% Loop through each combination of parameters
for i = 1:length(T_rxn_values)
    
        for k = 1:length(S_by_C_values)
            for l = 1:length(Pt_values)
                for m = 1:length(amt_catalyst_values)
                    for n = 1:length(t_end_values)


                        % Assign current parameters
                        T_rxn = T_rxn_values(i);
                        T_in = 400+273.15;
                        S_by_C = S_by_C_values(k);
                        Pt = Pt_values(l);
                        amt_catalyst = amt_catalyst_values(m);
                        t_end = t_end_values(n);
                        % Mole fractions
                        xCO = 0.001;
                        xCO2 = 0.001;
                        xCH4 = 0.299;
                        xH2 = 0.099;
                        xH2O = S_by_C * xCH4;
    
                        % Partial pressures
                        P_CO = xCO * Pt;
                        P_H2 = xH2 * Pt;
                        P_H2O = xH2O * Pt;
                        P_CO2 = xCO2 * Pt;
                        P_CH4 = xCH4 * Pt;
    
                        % Concentrations at the inlet
                        C_CH4_in = (xCH4 * Pt) / (Rig_rxn * T_in);
                        C_H2O_in = (xH2O * Pt) / (Rig_rxn * T_in);
                        C_CO_in = (xCO * Pt) / (Rig_rxn * T_in);
                        C_CO2_in = (xCO2 * Pt) / (Rig_rxn * T_in);
                        C_H2_in = (xH2 * Pt) / (Rig_rxn * T_in);
    
                        % Catalyst and geometry parameters
                        Sa = 9300;                         % m^2 cat/kg
                        Sa_cat = 2*pi*0.00252*0.28;        % m^2 cat
                        Vol_fluid = pi*(0.00252^2)*0.5;    % m^3
                        av = Sa_cat / Vol_fluid;           % m^2 cat / m^3
    
                        % ODE solver setup
                        par.T_rxn = T_rxn;
                        par.Rig = Rig;
                        par.Rig_rxn = Rig_rxn;
                        par.Sa = Sa;
                        par.av = av;
                        par.Esmr = Esmr;
                        par.Ewgs = Ewgs;
                        par.Egrr = Egrr;
                        par.Tr1 = Tr1;
                        par.Tr2 = Tr2;
                        par.ksmr = ksmr;
                        par.kwgs = kwgs;
                        par.kgrr = kgrr;
                        par.KCO = KCO;
                        par.KH2 = KH2;
                        par.KH2O = KH2O;
                        par.KCH4 = KCH4;
                        par.delHCO = delHCO;
                        par.delHH2 = delHH2;
                        par.delHH2O = delHH2O;
                        par.delHCH4 = delHCH4;
                        par.delSMR = delSMR;
                        par.delWGS = delWGS;
                        par.delGRR = delGRR;   
                        par.PinByVolSolid = PinByVolSolid;
                        par.Pt = Pt;
                        par.K_conv = (1000 / 3600) * amt_catalyst;  % kgcat --> mol/s
    
                        % Initial conditions
                        Y0 = [C_CH4_in; C_H2O_in; C_CO_in; C_H2_in; C_CO2_in];
    
                        % Time span for the simulation
                        tSpan = 0:0.00001:t_end;  % seconds
    
                        % Solve the ODE system
                        [tSol, YSol] = ode23s(@(t,Y) ZeroDSolver(t,Y,par), tSpan, Y0);
                        conc_CH4 = YSol(:,1);
                        conc_H2O = YSol(:,2);
                        conc_CO = YSol(:,3);
                        conc_H2 = YSol(:,4);
                        conc_CO2 = YSol(:,5);
                                            
                        % Mole fractions at the final time step
                        y_co = conc_CO(end) / (conc_CO(end) + conc_H2(end) + conc_CO2(end) + conc_H2O(end) + conc_CH4(end));
                        y_co2 = conc_CO2(end) / (conc_CO(end) + conc_H2(end) + conc_CO2(end) + conc_H2O(end) + conc_CH4(end));
                        y_ch4 = conc_CH4(end) / (conc_CO(end) + conc_H2(end) + conc_CO2(end) + conc_H2O(end) + conc_CH4(end));
                        
                        % Calculate conversion based on Wisman method
                        wisman_conv_act = (y_co + y_co2) / (y_ch4 + y_co + y_co2);
                        velocity_used = 0.28/t_end;
                        % Store the conversion and corresponding parameter set
                        results(end+1, :) = [T_rxn, S_by_C, Pt, amt_catalyst, velocity_used, wisman_conv_act];
                    end
                end
            end
        end
    
end
elapsed_time = toc
% Step 4: Convert to table (if needed) and add column names
combinedTable = array2table(results, 'VariableNames', {'T_rxn', 'SbyC', 'Pt', 'CatalystAmt', 'U','Conversion'});

% Step 5: Write to Excel file
% writetable(combinedTable, 'OptimiserDataU_Included_NewRangeWithoutTin.xlsx');

function [dCdz, r_SMR, r_WGS, r_GRR] = ZeroDSolver(t,Y,par)

    % Parsing pars    
    Rig = par.Rig;
    Rig_rxn = par.Rig_rxn;
    Sa = par.Sa;
    av = par.av;
    Tr1 = par.Tr1;
    Tr2 = par.Tr2;
    T_rxn = par.T_rxn;
    Esmr = par.Esmr;
    Ewgs = par.Ewgs;
    Egrr = par.Egrr;
    ksmr = par.ksmr;
    kwgs= par.kwgs;
    kgrr = par.kgrr;
    KCO = par.KCO;
    KH2 = par.KH2;
    KH2O = par.KH2O;
    KCH4 = par.KCH4;
    delHCO = par.delHCO;
    delHH2 = par.delHH2;
    delHH2O = par.delHH2O;
    delHCH4 = par.delHCH4;
    delSMR = par.delSMR;
    delWGS = par.delWGS;
    delGRR = par.delGRR;
    PinByVolSolid = par.PinByVolSolid;
    % Kpsmr = par.Kpsmr;
    % Kpwgs = par.Kpwgs;

    % Initializing
    c_CH4 = Y(1);
    c_H2O = Y(2);
    c_CO = Y(3);
    c_H2 = Y(4);
    c_CO2 = Y(5);
   

    % Temperature as a function of time [340Nml/min --> 400-600C]
    % T_rxn = 0*t + 673;             % [K]
    % T_rxn = 873 - 0.5*t;             % [K]
    % T_rxn = 873 - 70*t;
    % T_rxn = 50*t + 673;
    % T_rxn = 70*t + 673;
    % T_rxn = 80*t + 673; 
    % T_rxn = 0*t + 733;


    % Kpwgs as a function of Temperature - Function satisfies Shell values
    % [Wikipedia - link] - Same used in COMSOL
    Kpwgs = 10^(-2.4198 + 0.0003855*T_rxn + (2180.6/T_rxn));
    % Kpwgs = 1.191e1;

    % Kpsmr as a function of Temperature - Same used in COMSOL
    % Kpsmr = ((1.39629510e-18)*(T_rxn^8)) + ((-7.69054733e-15)*(T_rxn^7)) +  ((1.81360131e-11)*(T_rxn^6)) +  ((-2.38586465e-08)*(T_rxn^5)) + ((1.91023740e-05)*(T_rxn^4)) + ((-9.50700717e-03)*(T_rxn^3)) + ((2.86472938)*(T_rxn^2)) - ((4.76612786e+02)*T_rxn) + 3.34357266e+04;
    Kpsmr = 10^(12.1472 + ((4.3527e-4)*T_rxn) + (-1.1159e4/T_rxn));
    % Kpsmr = 5.937e-5;


    % Defining the parameters

    kMSR	= ksmr*exp(-Esmr/Rig *(1/T_rxn - 1/Tr1))  ;                % [(kmol*bar^0.5)/(kgcat. hr)]
    kWGS	= kwgs*exp(-Ewgs/Rig *(1/T_rxn - 1/Tr1))	;              % [(kmol)/(kgcat. hr .bar)]
    kGRR	= kgrr*exp(-Egrr/Rig *(1/T_rxn - 1/Tr1))	 ;             % [(kmol*bar^0.5)/(kgcat. hr)]
    K_CO	= KCO*exp(-delHCO/Rig * (1/T_rxn - 1/Tr1))    ;            % [bar^-1] 
    K_H2	= KH2*exp(-delHH2/Rig * (1/T_rxn - 1/Tr1)) 	   ;           % [bar^-1]
    K_H2O	= KH2O*exp(-delHH2O/Rig * (1/T_rxn - 1/Tr2))	;	      % unitless
    K_CH4	= KCH4*exp(-delHCH4/Rig * (1/T_rxn - 1/Tr2))     ;         % [bar^-1]
    
    Kpgrr = Kpsmr*Kpwgs;                                              % [bar^2]

    DEN	= (1 + (K_CO*c_CO*Rig_rxn*T_rxn) +(K_H2*c_H2*Rig_rxn*T_rxn) + (K_CH4*c_CH4*Rig_rxn*T_rxn)+ (K_H2O*(c_H2O/c_H2)));                       % unitless
    r_SMR = (kMSR/((c_H2*Rig_rxn*T_rxn)^2.5)) * ((c_CH4*c_H2O*((Rig_rxn*T_rxn)^2)) - ((c_H2^3)*c_CO*((Rig_rxn*T_rxn)^4))/(Kpsmr))/DEN^2         % kmol/(kgcat. hr)
    r_WGS = (kWGS/(c_H2*Rig_rxn*T_rxn)) * ((c_CO*c_H2O*((Rig_rxn*T_rxn)^2)) - ((c_H2*c_CO2*((Rig_rxn*T_rxn)^2))/Kpwgs))/DEN^2 ;                  % kmol/(kgcat. hr)  
    r_GRR = (kGRR/((c_H2*Rig_rxn*T_rxn)^3.5)) * ((c_CH4*(c_H2O^2)*((Rig_rxn*T_rxn)^3)) - ((c_H2^4)*c_CO2*((Rig_rxn*T_rxn)^5))/(Kpgrr))/DEN^2 ;   % kmol/(kgcat. hr)
 
    % Conversion Factor [converts kmol/(kgcat. hr) into mol/s]
    K_conv = par.K_conv;         

    % Defining the ODE's
    dCdz(1,1) = K_conv * (-r_SMR - r_GRR);                                                                     % kmol/(kgcat.hr) -->  mol/(m^3. s)
    dCdz(2,1) = K_conv * (-r_SMR - r_WGS - (2*r_GRR));                                                         % kmol/(kgcat.hr) -->  mol/(m^3. s)
    dCdz(3,1) = K_conv * (r_SMR - r_WGS);                                                                      % kmol/(kgcat.hr) -->  mol/(m^3. s)
    dCdz(4,1) = K_conv * ((3*r_SMR) + r_WGS + (4*r_GRR));                                                      % kmol/(kgcat.hr) -->  mol/(m^3. s)
    dCdz(5,1) = K_conv * (r_WGS + r_GRR);                                                                      % kmol/(kgcat.hr) -->  mol/(m^3. s)
    
end
