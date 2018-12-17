close all
clear

Ntracer=4;
sample_file='wrffirechemi_d01_2013-08-22_00:00:00';%emissions
name_out='wrf_tracer_base';
out_path='./';
var_in='ebu_in_co';

%create zero var
unix(['ncks -O -v ' var_in ' ' sample_file ' ' out_path name_out '_0emiss']);
[varname data] = read_netcdf_vars([out_path name_out '_0emiss'],{var_in});
data{1}(:,:)=0.0;
write_netcdf_vars([out_path name_out '_0emiss'],{var_in},data);

%Concatenate all tracers
unix(['cp ' out_path name_out '_0emiss ' out_path name_out]);
unix(['ncrename -v ' var_in ',' var_in '_1 ' out_path name_out]);
for i=2:Ntracer
 i
 unix(['cp ' out_path name_out '_0emiss ' out_path name_out '_aux']);
 unix(['ncrename -v ' var_in ',' var_in '_' num2str(i)  ' ' out_path name_out '_aux']);
 unix(['ncks -A -v ' var_in '_' num2str(i) ' ' out_path name_out '_aux' ' ' out_path name_out]);
end

