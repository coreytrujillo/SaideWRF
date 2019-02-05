% This function creates tracer files for Saide's WRF-Chem tracer code
% 22 - 26 August 2013
% Fire epicenter 37.85N, 120.08W
% Lat domain: [36, 42]N
% Lon domain: [-122, -112]W

clc;clear all;clf; format compact;

%%%%%%%%%% Define and Plot regions %%%%%%%%%%
% Domain corners
loni = -114; %-124;
lonf = -109; %-114;
lati = 39.5; %36;
latf = 43.5; %42;

% Domain Center
lonc = (loni + lonf)/2;
latc = (lati + latf)/2;

% Region Corners
rlon = [loni lonc lonf];
rlat = [lati latc latf];

reg_x{1} = rlon([2 2 3 3]);
reg_y{1} = rlat([2 3 3 2]);

reg_x{2} = rlon([2 2 1 1]);
reg_y{2} = rlat([2 3 3 2]);

reg_x{3} = rlon([2 1 1 2]);
reg_y{3} = rlat([2 2 1 1]);

reg_x{4} = rlon([2 2 3 3]);
reg_y{4} = rlat([2 1 1 2]);

% Number of Regions
Num_reg = numel(reg_x);

% Region Labels
Name_reg = {'I' 'II' 'III' 'IV'};
Name_lon = [-114.5 -119.5 -119.5 -114.5];
Name_lat = [41.5 41.5 37.5 37.5];

% Load and Plot Map Boundary lines
load 'm_coasts.mat';
load coast.mat
load conus.mat
plot(long, lat, 'k-')
hold on
plot(uslon, uslat, 'k')
plot(statelon, statelat, 'k')

% Plot Regions
figure(1)
for i = 1:Num_reg
    plot([reg_x{i} reg_x{i}(1)], [reg_y{i} reg_y{i}(1)])
    text(Name_lon(i), Name_lat(i), Name_reg(i));
end
hold off
axis([loni lonf lati latf])

%%%%%%%%%% Define Regions in Terms of Grid Cells %%%%%%%%%%
% Get lat lon data from wrf region
latlon_file = 'wrfinput_d01';
[wrf_latlon_data] = truj_read_nc(latlon_file, {'XLAT', 'XLONG'});
wrf_lat = double(wrf_latlon_data{1}(:,:,1));
wrf_lon = double(wrf_latlon_data{2}(:,:,1));

% Plot settings
sp_axis = ceil(sqrt(Num_reg));
figure(2)

% Initial values for grid cells in and out of each region
indx_in = cell(Num_reg+1,1); % Grid cells in each region
indx_in{Num_reg + 1} = logical(zeros(size(wrf_lat))); % Grid cells in domain outside of all regions
indx_out = indx_in; % Grid cells outside of a particular region

for i = 1:Num_reg
    % Define grid cell values for each region
    indx_in{i} = inpolygon(wrf_lon, wrf_lat, reg_x{i}, reg_y{i}); % 1s in region 0s out
    indx_out{i} = ~indx_in{i};  % 1s out of region, 0s in
    
    % Plot
    subplot(sp_axis, sp_axis, i)
    contourf(wrf_lon,wrf_lat,indx_in{i});
    
    % All regions combined
    indx_in{Num_reg + 1} = indx_in{Num_reg+1} | indx_in{i};
end

% All grid cells in domain that are outside of all regions
indx_out{Num_reg + 1} = ~indx_in{Num_reg + 1};

% % Optional plot of outside regions
% figure(3)
% subplot(2,1,1)
% contourf(wrf_lon, wrf_lat, indx_in{Num_reg+1})
% subplot(2,1,2)
% contourf(wrf_lon, wrf_lat, indx_out{Num_reg+1})

%%%%%%%%%% Create Tracer files %%%%%%%%%%
% Simulation time
datei = datenum([2013 08 22 0 0 0]); % Initial date of simulation
datef = datenum([2013 08 23 0 0 0]); % Final date of simulation
datenow = datei; % "Current" date
Nhrs = (datef - datei)*24; % Number of hours in simulation

% Emission time
date_emis_i = datenum([2013 08 22 04 0 0]); % Initial date of emission
date_emis_f = datenum([2013 08 22 20 0 0]); % Final date of emission
intv = 4; % Interval for emission in hours
Nemiss = round((date_emis_f - date_emis_i)*24)/intv; % Number of emissions phases
date_emis_vec = date_emis_i:intv/24:date_emis_f;

Ntra = round((date_emis_f - date_emis_i)*24/intv)*(Num_reg + 1); % Number of Tracers

wrffire_inpath = './';
tracer_outpath = 'out/';
wrffire_base = 'wrffirechemi_d01_';
anthro_pref = './wrfchemi_';
var_in = 'ebu_in_co';

count = 0;
time_num = 0;
for i = 1:8 %Nhrs
    
    datenowstr = datestr(datenow, 'yyyy-mm-dd_HH:MM:SS');
    date_emis_str = datestr(date_emis_vec(1) + intv/24*time_num, 'yyyy-mm-dd_HH:MM:SS');
    if date_emis_str == datenowstr % && datenow <= date_emis_vec(end)
        time_num = time_num+1;
    end
    wrffire_infile = [wrffire_base datenowstr];
    
    % Create Tracer files
    for p = 1:Ntra
        var_out_base = 'tr17_';
        var_out =  [var_out_base num2str(p)];
        truj_create_nc_vars(wrffire_inpath, wrffire_infile, tracer_outpath, var_in, var_out)
    end
    
    % Get NEI Data
    hh = str2num(datestr(datenow,'HH'));
    if hh <12
        anth_data = truj_read_nc([anthro_pref '00z_d01'], {'E_CO'});
    elseif hh  < 24
        anth_data = truj_read_nc([anthro_pref '12z_d01'], {'E_CO'});
    else
        disp('Error reading anthropogenic emissions!')
    end
    
    anth_i = mod(hh,12)+1;
    anth_emis{i} = anth_data{1}(:,:,1,anth_i);
    data{i,1} = anth_emis{i};
    
    tracer_outfile = wrffire_infile;
    
    for m = 1:Ntra
        tracer_var_out_base = 'tr17_';
        tracer_var_out =  [tracer_var_out_base num2str(m)];
        
        regnum = mod(m, Num_reg+1);
        if regnum == 0
            regnum = 5;
        end
        
%         data{i} = truj_read_nc(wrffire_infile, {var_in});
        data_yes{i,m} = data{i};
        data_yes{i,m}(indx_out{regnum}) = 0;
        data_no = zeros(size(data_yes{i}));        

        t1 = (time_num-1)*(Num_reg+1);
        t2 = (time_num)*(Num_reg+1);
        
        if m > t1 && m <= t2 && time_num~=0
            truj_write_nc(tracer_outpath, tracer_outfile, {tracer_var_out}, {data_yes{i}});
        elseif m <= t1 | m > t2 | time_num==0
            truj_write_nc(tracer_outpath, tracer_outfile, {tracer_var_out}, {data_no});
        else
            disp('Error - date outside of range')
        end
    end
    
    datenow = datenow + 1/24; % Increase date by 1 hour
end

