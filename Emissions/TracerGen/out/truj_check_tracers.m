% This script plots tracers alongside NEI and QFED inventories to check
% that the tracers are correct.

% Format
clc;clear;clf; format compact;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Inputs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% You should only need to modify this section for your files and dates

% WRF input file
wrf_in = '../wrfinput_d01'; % WRF input file


% Constants
Nhrs = 24; % Number of simulation hours
date_0 = datenum([2013 08 22 0 0 0]); % Initial date of simulation
Ntra = 14; % Number of tracers

% File names
fire_filebase = 'wrffirechemi_d01_'; % File basename for QFED and Tracers
tr_varname_base = 'ebu_in_co_'; % Tracer variable basename
anthro_filebase = '../wrfchemi_'; % File basename for NEI

%%%%%%%%%%%%%%%%%%%%%%%%%% Initial calculations %%%%%%%%%%%%%%%%%%%%%%%%%%%

% Get lat/lon data from input file
LAT = ncread(wrf_in, 'XLAT');
LON = ncread(wrf_in, 'XLONG');

% Subplot calculations and settings
sp_axx = ceil(sqrt(Ntra+2));
sp_axy = floor(sqrt(Ntra+2));
colormap jet


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Get Data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Initialize date
datenow = date_0;

% Import NEI and QFED data to memory for comparison
for k = 1:Nhrs
    
    % Current date string
    datenow_str = datestr(datenow, 'yyyy-mm-dd_HH:MM:SS');
   
    % Get current hour and set NEI hour index
    hr_now = str2num(datestr(datenow,'HH')); 
    anth_index = mod(hr_now,12)+1;
        
    % Choose correct NEI file to get data from
    if hr_now <12
        anth_data = ncread([anthro_filebase '00z_d01'], 'E_CO');
    elseif hr_now  < 24
        anth_data = ncread([anthro_filebase '12z_d01'], 'E_CO');
    else
        disp('Error reading anthropogenic emissions!')
    end
    
    % Get NEI data
    anth_emis{k} = anth_data(:,:,1,anth_index);
    
    
    % Get QFED data
    fire_filename = [fire_filebase datenow_str];
    fire_data{k} = ncread(fire_filename, 'ebu_in_co');
    
    % Get tracer data
    for m = 1:Ntra
        tr_name = [tr_varname_base num2str(m)];
        data{k,m} = ncread(fire_filename, tr_name);
    end
    
       
    % Update current date
    datenow = datenow + hours(1);
end

% Get maximum values for plotting range
anthro_max = max(max([anth_emis{:}]));
fire_max = max(max([fire_data{:}]));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Plotting %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Reinitialize current date
datenow = date_0;

for i = 1:Nhrs
    
    % Current date in string form 
    datenow_str = datestr(datenow, 'yyyy-mm-dd_HH:MM:SS');
    
    % Initialize figure 
    figure(1)
    clf
    sgtitle(datenow_str, 'Interpreter', 'none') % Figure title
    
    % Plot QFED
    subplot(sp_axx, sp_axy, 1)
    contourf(LON, LAT, fire_data{i}, 50, 'LineStyle', 'none')
    cQ = colorbar('Position', [0.05 0.1 0.01 0.85]); % QFED Colorbar
    cQ.Label.String = 'QFED';
    caxis([0,fire_max]) % Colorbar limits
    title('QFED')

    % Tracer Plots
    for j = 1:Ntra
        subplot(sp_axx, sp_axy, j+1)
        tr_name = [tr_varname_base num2str(j)];
        contourf(LON, LAT, data{i,j}, 50, 'LineStyle', 'none')
        title(tr_name, 'Interpreter', 'none') 
        
        % Colorbar limits
        if j <= Ntra/2
            caxis([0,fire_max])
        elseif j > Ntra/2 % Last tracer should be NEI
            caxis([0,anthro_max])
        end
    end
    
    % NEI plots
    subplot(sp_axx, sp_axy, Ntra+2)
    contourf(LON, LAT, anth_emis{i}, 50, 'LineStyle', 'none')
    title('NEI')
    cN = colorbar('Position', [0.95 0.1 0.01 0.85]);
    cN.Label.String = 'NEI';
    caxis([0,anthro_max]);
    
    % Save figure
    saveas(figure(1), ['fig_SF_' num2str(i, '%02d') '.png'])
    
    % Pause for animation 
    pause(0.1)
    
    % Incriment Date
    datenow = datenow + hours(1);
    
end