function truj_create_nc_vars(inpath, filename, outpath, var_in, var_out)
% This function writes a single variable 'var_out' to a netCDF file
% based on 'var_in' read in from 'filename' and fills it with 'data'

% File names 
tmp_file = ['tmp'];
tracer_file = ['tmp_tracer'];
% final_file = [infilename '_tracer'];

% Read in data from var_in, place in tmp file and make data zeros
% num_var = numel(var_in)
unix(['ncks -O -v ' var_in ' ' inpath filename ' ' outpath tmp_file]);
old_data = truj_read_nc([inpath filename],  {var_in});
old_data{1}(:,:) = 0.0;

% Open tmp file for writing
ncid = netcdf.open([outpath tmp_file], 'WRITE');

% Return number of dimensions, vars, global attributes,
% and unlimited ID from file
[ndims, nvars, nglobalatts, ultdID] = netcdf.inq(ncid);

% Get each variable name, data type, dimension IDs
% and number of attributes
for i = 1:nvars
    [varname{i}, dtype{i}, dimIDs{i}, natts{i}] = netcdf.inqVar(ncid, i-1);
end

% Get netCDF file dimension name and length for each dimension
for i = 1:ndims
    [dimname{i} dimle(i)] = netcdf.inqDim(ncid,i-1);
end

if isfile([outpath filename])
    unix(['cp ' outpath filename ' ' outpath tracer_file]);
else
    unix(['cp ' inpath filename ' ' outpath tracer_file]);
end

% Rename variable, then copy to permanent file
unix(['ncrename -v ' var_in ',' var_out ' ' outpath tmp_file]);
unix(['ncks -A ' outpath tmp_file ' ' outpath tracer_file]);
unix(['cp ' outpath tracer_file ' ' outpath filename]);
unix(['rm ' outpath tmp_file ' ' outpath tracer_file]);

netcdf.close(ncid);
end