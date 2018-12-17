function truj_write_nc(path, filename, var_in, data)
% This function creates a netCDF file based on a previous file

% Open tmp file for writing
ncid = netcdf.open([path filename], 'WRITE');

% Return number of dimensions, vars, global attributes,
% and unlimited ID from file
[ndims, nvars, nglobalatts, ultdID] = netcdf.inq(ncid);

% Get each variable name, data type, dimension IDs
% and number of attributes
for i = 1:nvars
    [varname{i}, dtype{i}, dimIDs{i}, natts{i}] = netcdf.inqVar(ncid, i-1);
end

% Get netCDF file dimension name and length
% for each dimension
for i = 1:ndims
    [dimname{i} dimle(i)] = netcdf.inqDim(ncid,i-1);
end

% Fill new variable with given data in tmp file
for i = 1:nvars
    name_comp = strcmp(var_in, varname{i});
    indx(i) = find(name_comp); % Get index of variable name in tmp file
    a = indx(i)-1;
    netcdf.putVar(ncid, a, data{i}); % fill variable with with data
end

netcdf.close(ncid);

end

