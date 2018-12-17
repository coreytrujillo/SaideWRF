% This function creates tracer files for Saide's WRF-Chem tracer code
% 22 - 26 August 2013
% Fire epicenter 37.85N, 120.08W
% Lat domain: [36, 42]N
% Lon domain: [-122, -112]W

clc;clear all;clf; format compact;

%%%%%%%%%% Define and Plot regions %%%%%%%%%%
% Domain corners
loni = -124;
lonf = -114;
lati = 36;
latf = 42;

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

%%%%%%%%% Define Regions in Terms of Grid Cells %%%%%%%%%%
latlon_file = 'wrfinput_d01';
[wrf_latlon_data] = truj_read_nc(latlon_file, {'XLAT', 'XLONG'});
wrf_lat = double(wrf_latlon_data{1}(:,:,1));
wrf_lon = double(wrf_latlon_data{2}(:,:,1));

sp_axis = ceil(sqrt(Num_reg));
figure(2)
indx_in = cell(Num_reg+1,1); %logical(zeros([size(wrf_lat),Num_reg+1]));
indx_in{Num_reg + 1} = logical(zeros(size(wrf_lat)));
indx_out = indx_in;

for i = 1:Num_reg
    indx_in{i} = inpolygon(wrf_lon, wrf_lat, reg_x{i}, reg_y{i});
    indx_out{i} = ~indx_in{i};  % 1's out of region, 0s in
    subplot(sp_axis, sp_axis, i)
    contourf(wrf_lon,wrf_lat,indx_in{i});
    
    % All regions combined
    indx_in{Num_reg + 1} = indx_in{Num_reg+1} | indx_in{i};
end

% All areas in domain that are not in a region
indx_out{Num_reg + 1} = ~indx_in{Num_reg + 1};
% figure(3)
% subplot(2,1,1)
% contourf(wrf_lon, wrf_lat, indx_in{Num_reg+1})
% subplot(2,1,2)
% contourf(wrf_lon, wrf_lat, indx_out{Num_reg+1})

%%%%%%%%%% Create Tracer files %%%%%%%%%%
datei = datenum([2013 08 22 0 0 0]);
datef = datenum([2013 08 26 0 0 0]);
date_emis_i = datenum([2013 08 22 04 0 0]);
date_emis_f = datenum([2013 08 22 08 0 0]);
datenow = datei;
Nhrs = (datef - datei)*24;

wrffire_inpath = './';
tracer_outpath = 'out/';
wrffire_base = 'wrffirechemi_d01_';
anthro_pref = './wrfchemi_';
invar = 'ebu_in_co';
% unix([cp wrffire_inpath '/wrffirechemi* ' wrffire_outpath]);

k = 0;
for i = 1:2 % Nhrs
    datenowstr = datestr(datenow, 'yyyy-mm-dd_HH:MM:SS');
    wrffire_infile = [wrffire_base datenowstr];
    
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
    
    for j = 1:Num_reg
        k = k+1;
        tracer_file = [wrffire_infile];
        tracer_name = ['tracer_' num2str(k)];
        truj_create_nc_vars(wrffire_inpath, wrffire_infile, tracer_outpath, invar, tracer_name);
        data{i,j+1}(indx_out{j}) = 0;
        if datenow < date_emis_i
            truj_write_nc(tracer_outpath, tracer_file, {tracer_name}, {data{i,1}});
        elseif datenow >= date_emis_i && datenow <= date_emis_f
            data{i}(index_out) = 0;
            truj_write_nc(tracer_outpath, tracer_file, {tracer_name}, {data{i,j+1}});
        elseif datenow > date_emis_f
            truj_write_nc(tracer_outpath, tracer_file, {tracer_name}, {data{i,1}});
        else
            display('Error, datenow is not in date range!!!')
        end
    end
    
    datenow = datenow + 1/24; % Increase date by 1 hour
    disp(datestr(datenow))
end




