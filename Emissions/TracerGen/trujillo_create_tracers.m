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
wrf_in = '../wrfinput_d01';
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

%%%%%%%%%%%%%% Automatically generate four regions in domain %%%%%%%%%%%%%%
% MODIFY this section for custom regions 

% Region Corners
rLON = [lon_0 lon_c lon_f];
rLAT = [lat_0 lat_c lat_f];

% Define Regions as quadrants in a cartesian graph:
% Counter clockwise starting with top right
reg_x{1} = rLON([2 2 3 3]);
reg_y{1} = rLAT([2 3 3 2]);

reg_x{2} = rLON([2 2 1 1]);
reg_y{2} = rLAT([2 3 3 2]);

reg_x{3} = rLON([2 1 1 2]);
reg_y{3} = rLAT([2 2 1 1]);

reg_x{4} = rLON([2 2 3 3]);
reg_y{4} = rLAT([2 1 1 2]);

% Number of Regions
N_reg = numel(reg_x);

% Region Labels
% MODIFY these for different regions
Name_reg = {'I' 'II' 'III' 'IV'};
Name_LON = [-114.5 -119.5 -119.5 -114.5];
Name_LAT = [41.5 41.5 37.5 37.5];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
%                              Plot regions                               %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PLOT = 0; % 1 for plots, zero for no plots
% Load and Plot Map Boundary lines and set proper axes
if PLOT==1 % Turn on or off plotting 
	load 'm_coasts.mat';
	load coast.mat
	load conus.mat
	figure(1)
	plot(long, lat, 'k-')
	axis([lon_0 lon_f lat_0 lat_f])
	hold on
	plot(uslon, uslat, 'k')
	plot(statelon, statelat, 'k')

	% Plot Regions
	for i = 1:N_reg
    	plot([reg_x{i} reg_x{i}(1)], [reg_y{i} reg_y{i}(1)])
	    text(Name_LON(i), Name_LAT(i), Name_reg(i));
	end
	hold off
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
%             Define Indices Inside and Outside of Each Region            %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Initialize values for grid cells in and out of each region
indx_in = cell(N_reg+1,1); % Grid cells in each region
indx_out = indx_in; % Grid cells outside of a particular region

%  Define a region in domain but out of all other defined regions
indx_in{N_reg + 1} = logical(zeros(size(LAT))); 

if PLOT==1
	% Plot settings
	figure(2)
	subplot_axis = ceil(sqrt(N_reg));

	% Define variables for indices in and out of each region and plot 
	for i = 1:N_reg
		% Define grid cell values for each region
		indx_in{i} = inpolygon(LON, LAT, reg_x{i}, reg_y{i}); % 1s in region 0s out
		indx_out{i} = ~indx_in{i};  % 1s out of region, 0s in
		
		% Plot
		subplot(subplot_axis, subplot_axis, i)
		contourf(LON,LAT,indx_in{i});
		
		% Put a 1 in a cell in a defined region
		indx_out{N_reg + 1} = indx_in{N_reg+1} & indx_in{i};
	end
end

% All grid cells in domain that are outside of all regions
indx_in{N_reg + 1} = ~indx_out{N_reg + 1};

%  Optional plot of outside regions
if PLOT == 1
	if all(indx_out{N_reg + 1}==0)
		disp('Regions cover entire Domain!')
	else % This will be relevant if regions are not defined automatically 
		disp('Regions do not cover entire domain - see Figure 3')
		figure(3)
		subplot(2,1,1)
		title('Area covered by defined regions')
		contourf(LON, LAT, indx_in{N_reg+1})
		title('Area NOT covered by defined regions')
		subplot(2,1,2)
		contourf(LON, LAT, indx_out{N_reg+1})
	end
end

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
intv = 4; % Interval for emission in hours

% Biomass Burning Names
wrffire_inpath = './';
wrffire_basename = 'wrffirechemi_d01_';
wrffire_invar = 'ebu_in_co';

% Anthropogenic Emissions Names
anthro_pref = 'wrfchemi_';
anthro_invar = 'E_CO';

% Output path for wrffire files with tracer inputs
tr_outpath = 'out/';

%%%%%%%%%%%%%%%%%%%%% Initialize files and constants %%%%%%%%%%%%%%%%%%%%%%
% If output path does not exist, create it
if 7~=exist(tr_outpath,'dir')
    unix(['mkdir ' tr_outpath]);
end

% Initialze and constants
datenow = date_0; % Initialize current date
Nhrs = hours(date_f - date_0); % Number of hours in simulation
Nemis_hrs = hours(date_emis_f - date_emis_0);
Nemis_phs = Nemis_hrs/intv; % Number of temporal emissions phases
date_emis_vec = date_emis_0:hours(intv):date_emis_f; % Vector of emission times
Ntra = Nemis_phs*(N_reg) + 2 ; % # tracers: 1 for each time/reg, one for no reg, one for NEI
ems_phs = 0; % Temporal Tracer Phase. Zero = no emissions

% Names
wrffire_invar = 'ebu_in_co'; % Variable to build tracer emissions tracers from
tr_basename_out = 'ebu_in_co_'; % Base name for tracer Emissions

%%%%%%%%%%%%%%%%%%%%%%%%%%%% Populate Tracers %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i = 1:Nhrs
    % Date in string form 
    datenow_str = datestr(datenow, 'yyyy-mm-dd_HH:MM:SS');
    
    % Name the correct wrffire file for now
    wrffire_infile = [wrffire_basename datenow_str];
    tracer_outfile = wrffire_infile; % Name of tracer output file
    
    % Update tracer temporal region \
    if datenow< date_emis_vec(1) | datenow >= date_emis_vec(end)
        ems_phs = 0; % No emissions outside of emission period
    elseif datenow==date_emis_vec(ems_phs+1)
        ems_phs = ems_phs+1;
    end
    
    % Tracer indices for current temporal tracer region
    tr_indx_lo = (ems_phs-1)*(N_reg); % Lower tr idx for current time reg
    tr_indx_hi = (ems_phs)*(N_reg); % Higher tr idx for current time reg
    
    % Get QFED data
    fire_data(i) = truj_read_nc(wrffire_infile, {wrffire_invar});

    % Create Tracer files with QFED data
    for p = 1:Ntra
        var_out =  [tr_basename_out num2str(p)];
        truj_create_nc_vars(wrffire_inpath, wrffire_infile, tr_outpath, wrffire_invar, var_out)
    end
    
    % Assign correct data values to each tracer for current hour and region
    for j = 1:Ntra-2 % Tracer index
        
        % Naming
        tr_var_outname =  [tr_basename_out num2str(j)];
        
        % Define emissions only in each region
        emis_yes{i,j} = fire_data{i}; % Initialize emission 
        emis_yes{i,j}(:) = 3.5e6;
        regnum = mod(j, N_reg);
        if regnum == 0 % 
            regnum = 4;
        end
        
        emis_yes{i,j}(indx_out{regnum}) = 0; % Set values outside of that region to zero
        emis_no = zeros(size(emis_yes{i,j})); % No fire data
        regnum = regnum+1; % Index region number
        
        % Write Emissions to files
        if j > tr_indx_lo && j <= tr_indx_hi && ems_phs~=0
            truj_write_nc(tr_outpath, tracer_outfile, {tr_var_outname}, {emis_yes{i,j}});
        elseif j <= tr_indx_lo | j > tr_indx_hi | ems_phs==0
            truj_write_nc(tr_outpath, tracer_outfile, {tr_var_outname}, {emis_no});
        else
            disp('Error - date outside of range')
        end
        
    end
    
    %%%% Tracer for locations of domain in none of the defined regions %%%%
    emis_yes{i,Ntra - 1} = fire_data{i}; % Initialize emission 
    emis_yes{i,Ntra - 1}(indx_out{end}) = 0; % Set all values inside any defined region to zero
    truj_write_nc(tr_outpath, tracer_outfile, {[tr_basename_out num2str(Ntra-1)]}, {emis_yes{i,Ntra - 1}})
    
    %%%%%%%%%%%%%% Final tracer for Anthropogenic Emissions %%%%%%%%%%%%%%%
    % Get current hour and set NEI index
    hr_now = str2num(datestr(datenow,'HH')); 
    anth_index = mod(hr_now,12)+1;
        
	hr_now
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
    anth_data{i} = anth_emis{i};
    anth_no = zeros(size(anth_emis{i}));

    % Put NEI Data in final tracer
    if datenow>=date_emis_0 && datenow<date_emis_f
        truj_write_nc(tr_outpath, tracer_outfile, {[tr_basename_out num2str(Ntra)]}, {anth_data{i}});
    elseif datenow<date_emis_0 | datenow>=date_emis_f
        truj_write_nc(tr_outpath, tracer_outfile, {[tr_basename_out num2str(Ntra)]}, {anth_no});
    else
        disp('Date error with Anthropogenic data')
    end
    
    % Incriment date by 1 hour
    datenow = datenow + hours(1); 
end
