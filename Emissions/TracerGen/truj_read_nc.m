% This function reads data from a netCDF file 
% and outputs it as ?????????

function data = truj_read_nc(filename, extracted_vars)

% Extracted var must be in curly braces 

% Open netCDF file in read-only mode
ncid = netcdf.open(filename); 

% Return number of dimensions, vars, global attributes,
% and unlimited ID from file
[ndims, nvars, nglobalatts, ultdID] = netcdf.inq(ncid);

% Get each variable name, data type, dimension IDs and number of attributes
for i = 1:nvars
    [varname{i}, dtype{i}, dimIDs{i}, natts{i}] = netcdf.inqVar(ncid, i-1);
end

% If extracted_vars = all, pull all data
if strcmp(lower(extracted_vars{1}), 'all')
    data = cell(nvars, 1);
    for i = 1: nvars
        data{i} = netcdf.getVar(ncid, i-1);
    end
    
% Otherwise pull only data for vars requested
else
    nvars_ext = numel(extracted_vars); % Number of vars to extract
    data = cell(nvars_ext,1); % Empty cell array for each var's data
    for i = 1:nvars_ext
        compare_var = strcmp(extracted_vars{i}, varname); % find matching var name
        var_index(i) = find(compare_var); % Find index of matching var name
        data{i} = netcdf.getVar(ncid, var_index(i)-1); % Store data for var
    end
end

netcdf.close(ncid)
end