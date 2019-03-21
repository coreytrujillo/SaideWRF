% This function creates tracer files for Saide's WRF-Chem tracer code
% 22 August 2013
% Fire epicenter 37.85N, 120.08W
% Lat domain: [36, 42]N
% Lon domain: [-122, -112]W

% To run this script you need the following input files:
% wrfinput_d01
% wrffirechemi_d01_
% wrfchemi_

% Format
clc;clear;clf; format compact;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
%                Define Physical Domain and Regions within                %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%% Get lat lon data from domain as defined in wrfinput file %%%%%%%%%
wrf_in = 'wrfinput_d01';
[latlon_data] = truj_read_nc(wrf_in, {'XLAT', 'XLONG'});
LAT = double(latlon_data{1}(:,:,1));
LON = double(latlon_data{2}(:,:,1));

% Calculate domain lat/lon extremes and centers
lat_0 = min(min(LAT));
lat_f = max(max(LAT));
lat_c = (lat_0 + lat_f)/2;

lon_0 = min(min(LON));
lon_f = max(max(LON));
lon_c = (lon_0 + lon_f)/2;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
%                              Plot Domain                                %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Load and Plot Map Boundary lines and set proper axes
load 'm_coasts.mat';
load coast.mat
load conus.mat
figure(1)
plot(long, lat, 'k-')
axis([lon_0 lon_f lat_0 lat_f])
hold on
plot(uslon, uslat, 'k')
plot(statelon, statelat, 'k')


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
%                             Scaling Factors                             %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SF = [0.01 0.1 0.5 1 2 10 100];
NSF = length(SF); % Number of scaling factors
Ntra = 2*NSF; % Number of Tracers


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
%                          Create Tracer Files                            %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%% Settings to MODIFY %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Simulation times
% MODIFY date_0 to match your start date
% MODIFY date_f relative to date_0 using date functions
% MODIFY date_emis_0 relative to date_0
% MODIFY date_emis_f relative to date_0
% MODIFY intv based on how often you want to cycle to the next tracer
date_0 = datenum([2013 08 22 0 0 0]); % Initial date of simulation
date_f = date_0 + days(1); % Final date of simulation
date_emis_0 = date_0 + hours(4); % Initial date of emission
date_emis_f = date_0 + hours(20); % Final date of emission

% Biomass Burning Names
wrffire_inpath = './';
wrffire_basename = 'wrffirechemi_d01_';
wrffire_invar = 'ebu_in_co';

% Anthropogenic Emissions Names
anthro_pref = 'wrfchemi_';
anthro_invar = 'E_CO';

% Output path for wrffire files with tracer inputs
tr_outpath = 'out/';

%%%%%%%%%%%%%%%%%%%%% Initialize files adn constants %%%%%%%%%%%%%%%%%%%%%%
% If output path does not exist, create it
if 7~=exist(tr_outpath,'dir')
    unix(['mkdir ' tr_outpath]);
end

% Initialze and constants
datenow = date_0; % Initialize current date
Nhrs = hours(date_f - date_0); % Number of hours in simulation
Nemis_hrs = hours(date_emis_f - date_emis_0);

% Names
wrffire_invar = 'ebu_in_co'; % Variable to build tracer emissions tracers from
tr_basename_out = 'ebu_in_co_'; % Base name for tracer Emissions

%%%%%%%%%%%%%%%%%%%%%%%%%%%% Populate Tracers %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i = 1:Nhrs
    % Date in string form 
    datenow_str = datestr(datenow, 'yyyy-mm-dd_HH:MM:SS');
    
    % Name the correct files for current hour
    wrffire_infile = [wrffire_basename datenow_str];
    tracer_outfile = wrffire_infile; % Name of tracer output file
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% QFED %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Get QFED data
    fire_data = truj_read_nc(wrffire_infile, {wrffire_invar});

    % Create Tracer files with QFED data
    for p = 1:Ntra
        var_out =  [tr_basename_out num2str(p)];
        truj_create_nc_vars(wrffire_inpath, wrffire_infile, tr_outpath, wrffire_invar, var_out)
    end
    
    % Multiply QFED by proper scaling factors and include in tracers
    for j = 1:NSF
        tr_var_outname =  [tr_basename_out num2str(j)];
        emis{i,j} = SF(j)*fire_data{1};
        truj_write_nc(tr_outpath, tracer_outfile, {[tr_basename_out num2str(j)]}, {emis{i,j}});
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% NEI %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Get current hour and set NEI index
    hr_now = str2num(datestr(datenow,'HH')); 
    anth_index = mod(hr_now,12)+1;
        
    % Get NEI Data
    if hr_now <12
        anth_data = truj_read_nc([anthro_pref '00z_d01'], {'E_CO'});
    elseif hr_now  < 24
        anth_data = truj_read_nc([anthro_pref '12z_d01'], {'E_CO'});
    else
        disp('Error reading anthropogenic emissions!')
    end
    
    % Initialize emissions in and out of region
    anth_emis{i} = anth_data{1}(:,:,1,anth_index);
    anth_yes = anth_emis{i};
    
    % Multiply NEI by proper scaling factors and fill tracer values
    for k = NSF+1:Ntra
        tr_var_outname =  [tr_basename_out num2str(k)];
        emis{i,k} = SF(k-NSF)*anth_yes;
        truj_write_nc(tr_outpath, tracer_outfile, {[tr_basename_out num2str(k)]}, {emis{i,k}});
    end
    
    % Incriment date by 1 hour
    datenow = datenow + hours(1); 
end