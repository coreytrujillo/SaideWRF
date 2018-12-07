close all
clear

%Ntracer=121;
%Ntracer=145;
%Ntracer=100;
%Ntracer=16;
Ntracer=68;
sample_file='/glade/p/nacd0005/saide/WRF_run/ORACLES/emissions_fire/qfed/wrffirechemi_d01_2015-09-02_00:00:00';%emissions
%out_path='/glade/p/nacd0005/saide/WRF_run/ORACLES/emissions_fire/qfed/with_tracer/';
out_path='/glade/p/nacd0005/saide/ORACLES_forecast/input/fire_qfed2/';
var_in='ebu_in_co';
name_out='wrffirechemi_d01_tracer_base';

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

