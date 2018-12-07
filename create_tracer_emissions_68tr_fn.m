function create_tracer_emissions_68tr_fn(date_i,date_f,date_i_emiss,date_f_emiss,Ntracer, ...
           input_path,out_path,input_path_anthro,lat_lon_file) 

%close all
%clear

%date_i=[2015 09 16 0 0 0];
%date_f=[2015 09 21 0 0 0];
%date_i_emiss=[2015 09 16  0 0 0];
%date_f_emiss=[2015 09 19 16 0 0];

rlat = [51.2, 53.5, 49.0, 48.8, 41.9, ...
        41.9, 31.3, 31.3, 41.9, 45.9, ...
        43.4, 30.6, 39.9, 30.1, 50.3, ...
        38.15,38.15,37.75,37.75 ];
rlon = [-128.3, -112.0, -125.8, -109.9, -124.9, ...
        -105.8, -123.2, -110.8, -115.0, -100.7, ...
        -93.8,  -103.7, -102.8, -97.4,  -91.8, ...
        -120.3, -119.05,-119.05,-120.3 ];

regions_x{1}=rlon([1 2 4 3]); 
regions_y{1}=rlat([1 2 4 3]); 
regions_x{2}=rlon([3 4 6 9 5]);
regions_y{2}=rlat([3 4 6 9 5]);
regions_x{3}=rlon([5 9 8 7]); 
regions_y{3}=rlat([5 9 8 7]); 
regions_x{4}=rlon([2 15 11 10 4]); 
regions_y{4}=rlat([2 15 11 10 4]); 
regions_x{5}=rlon([9 6 13 12 8]); 
regions_y{5}=rlat([9 6 13 12 8]); 
regions_x{6}=rlon([16 17 18 19]);    %Rimfire should be excluded from region#3 
regions_y{6}=rlat([16 17 18 19]); 


Nregions=numel(regions_x);

dt_wrffile_minutes=60;% it has to complete 1 hour
Nhours_emiss=round((24/(dt_wrffile_minutes/60))*(datenum(date_f_emiss)-datenum(date_i_emiss)));

%Ntracer=90;
%input_path='/glade/p/nacd0005/saide/WRF_run/ORACLES/emissions_fire/qfed/';
%out_path='/glade/p/nacd0005/saide/WRF_run/ORACLES/emissions_fire/qfed/with_tracer/';
%input_path_anthro='/glade/p/nacd0005/saide/WRF_run/ORACLES/emissions_anthro/epres_edgar_htap/';
var_in='ebu_in_co';
base_file='wrffirechemi_d01_tracer_base';
%lat_lon_file='/glade/p/nacd0005/saide/WRF_run/ORACLES/WRF_v3.6.1_chem_tracer_run1/wrfinput_d01';


if 1==0
%Plot regions
 h=figure('Visible','off');
 load('/u/project/saide/xye/apps/m_map/private/m_coasts.mat')
 load coast.mat;
 load conus.mat;
%plot(regions_x(2,:),regions_y(2,:))
% plot(ncst(:,1),ncst(:,2),'k-','LineWidth',0.5);
 plot(long,lat,'k-','LineWidth',0.5) % land-sea border
 hold on
% plot(POline(1).long,POline(1).lat,'k-','LineWidth',0.5) %country borders
 plot(uslon,uslat,'k-','LineWidth',0.5) %US borders only
% plot(stateborder.long,stateborder.lat,'k-','LineWidth',0.5) %US states bordes
 plot(statelon,statelat,'k-','LineWidth',0.5) %US states bordes
for i=1:numel(regions_x)
 plot([regions_x{i} regions_x{i}(1)],[regions_y{i} regions_y{i}(1)])
end
hold off
lat_i=29.0;
lat_f= 55.0;
lon_i=-130.0;
lon_f=-90.0;
axis([lon_i lon_f lat_i lat_f])
str={'NW','CW','SW','NE','SE','Rimfire'};
xt=[-119. -118. -120. -101. -107. -120.];
yt=[50. 44. 36. 48. 37. 38.2];
text(xt,yt,str);
print -painters -dpng -r600 temp_crop.png
%unix(['pdfcrop temp.pdf temp_crop.pdf']);
%unix(['gs -SDEVICE=png16m -r1200 -dAutoRotatePages=/none -sOutputFile=temp_crop.png '...
%     '-dNOPAUSE -dBATCH temp_crop.pdf']);
unix(['mv temp_crop.png figs/MAP_inversion_regions.png']);
end


datestr_aux=datestr(date_i,'yyyy-mm-dd_HH:MM:SS');
[varname data] = read_netcdf_vars([input_path 'wrffirechemi_d01_' datestr_aux],{var_in});
[Nx,Ny]=size(data{1});
[varname2 data2] = read_netcdf_vars(lat_lon_file,{'XLONG','XLAT'});
lat_wrf=double(data2{2}(:,:,1)); 
lon_wrf=double(data2{1}(:,:,1)); 

x=1:Nx;
y=1:Ny;
[x2d,y2d]=ndgrid(x,y);
index_in_all=logical(zeros(size(x2d)));
for k=1:Nregions
%  index_in{k}=((x2d>=x_i(k)) & (x2d<=x_f(k)) & (y2d>=y_i(k)) & (y2d<=y_f(k)));
  if k==3
  index_in{k}=inpolygon(lon_wrf,lat_wrf,regions_x{k},regions_y{k})  ...
           & ~inpolygon(lon_wrf,lat_wrf,regions_x{6},regions_y{6});
  else
  index_in{k}=inpolygon(lon_wrf,lat_wrf,regions_x{k},regions_y{k});
  end 
  index_out{k}=~index_in{k};
  index_in_all=index_in_all | index_in{k};
  length(find(index_in{k}==1))
end
index_out_all=~index_in_all;

% Before
datenum_aux=datenum(date_i);
count=0;
while(datenum_aux < datenum(date_i_emiss))
 datestr_aux=datestr(datenum_aux,'yyyy-mm-dd_HH:MM:SS')
 hh = str2num(datestr(datenum_aux,'HH'))
 if hh<12
 [varname_anthro e_anthro] = read_netcdf_vars([input_path_anthro 'wrfchemi_00z_d01'],{'E_CO'});
  else
 [varname_anthro e_anthro] = read_netcdf_vars([input_path_anthro 'wrfchemi_12z_d01'],{'E_CO'});
 end
  emis_tra=zeros([Nx Ny 1 1]);
  emis_tra(:,:,1,1)=e_anthro{1}(:,:,1,mod(hh,12)+1);
  data_anthro={emis_tra};

 unix(['cp ' input_path 'wrffirechemi_d01_' datestr_aux ' ' out_path 'wrffirechemi_d01_' datestr_aux]);
 unix(['cp ' out_path base_file ' ' out_path base_file '_aux']);
 write_netcdf_vars([out_path base_file '_aux'],{[var_in '_' num2str(Ntracer)]},data_anthro); %put the rest in the other tracers
% unix(['ncks -A ' out_path base_file ' ' out_path 'wrffirechemi_d01_' datestr_aux]);
 unix(['ncks -A ' out_path base_file '_aux ' out_path 'wrffirechemi_d01_' datestr_aux]);
 count=count+1;
 datenum_aux=datenum(date_i)+(count)/(24.0/(dt_wrffile_minutes/60)); %increase time step   
end

datenum_aux=datenum(date_i_emiss);
for i=1:Nhours_emiss
 datestr_aux=datestr(datenum_aux,'yyyy-mm-dd_HH:MM:SS')
 [varname data1] = read_netcdf_vars([input_path 'wrffirechemi_d01_' datestr_aux],{var_in});
 hh = str2num(datestr(datenum_aux,'HH'));
 if hh<12
 [varname_anthro e_anthro] = read_netcdf_vars([input_path_anthro 'wrfchemi_00z_d01'],{'E_CO'});
  else
 [varname_anthro e_anthro] = read_netcdf_vars([input_path_anthro 'wrfchemi_12z_d01'],{'E_CO'});
 end
  emis_tra=zeros([Nx Ny 1 1]);
  emis_tra(:,:,1,1)=e_anthro{1}(:,:,1,mod(hh,12)+1);
  data_anthro={emis_tra};
% [varname_anthro data_anthro] = read_netcdf_vars([input_path_anthro 'wrfchemi_d01_' datestr_aux '_co'],{'E_CO'});
 data2=data1;
 data3=data1;
 data4=data1;
 data5=data1;
 data6=data1;
 data7=data1;
% data8=data1;
% data9=data1;
 data1{1}(index_out{1})=0.0;
 data2{1}(index_out{2})=0.0;
 data3{1}(index_out{3})=0.0;
 data4{1}(index_out{4})=0.0;
 data5{1}(index_out{5})=0.0; 
 data6{1}(index_out{6})=0.0;
 data7{1}(index_in_all)=0.0; %the rest
% data7{1}(index_out{7})=0.0;
% data8{1}(index_out{8})=0.0;
% data9{1}(index_in_all)=0.0; %the rest

 unix(['cp ' input_path 'wrffirechemi_d01_' datestr_aux ' ' out_path 'wrffirechemi_d01_' datestr_aux]);
 unix(['cp ' out_path base_file ' ' out_path base_file '_aux']);
 write_netcdf_vars([out_path base_file '_aux'],{[var_in '_' num2str(ceil(i/8))]},data1);
 write_netcdf_vars([out_path base_file '_aux'],{[var_in '_' num2str(ceil(i/8)+round(Nhours_emiss/8))]},data2); %put the rest in the other tracers
 write_netcdf_vars([out_path base_file '_aux'],{[var_in '_' num2str(ceil(i/8)+round(2*Nhours_emiss/8))]},data3); %put the rest in the other tracers
 write_netcdf_vars([out_path base_file '_aux'],{[var_in '_' num2str(ceil(i/8)+round(3*Nhours_emiss/8))]},data4); %put the rest in the other tracers
 write_netcdf_vars([out_path base_file '_aux'],{[var_in '_' num2str(ceil(i/8)+round(4*Nhours_emiss/8))]},data5); %put the rest in the other tracers
 write_netcdf_vars([out_path base_file '_aux'],{[var_in '_' num2str(ceil(i/8)+round(5*Nhours_emiss/8))]},data6); %put the rest in the other tracers
 write_netcdf_vars([out_path base_file '_aux'],{[var_in '_' num2str(Ntracer-1)]},data7); %Replacing the last tracer
% write_netcdf_vars([out_path base_file '_aux'],{[var_in '_' num2str(ceil(i/8)+round(6*Nhours_emiss/8))]},data7); %put the rest in the other tracers
% write_netcdf_vars([out_path base_file '_aux'],{[var_in '_' num2str(ceil(i/8)+round(7*Nhours_emiss/8))]},data8); %put the rest in the other tracers
% write_netcdf_vars([out_path base_file '_aux'],{[var_in '_' num2str(Ntracer-1)]},data9); %Replacing the last tracer
 write_netcdf_vars([out_path base_file '_aux'],{[var_in '_' num2str(Ntracer)]},data_anthro); %anthro tracer
 unix(['ncks -A ' out_path base_file '_aux ' out_path 'wrffirechemi_d01_' datestr_aux]);
 datenum_aux=datenum(date_i_emiss)+i/(24.0/(dt_wrffile_minutes/60)); %increase time step 
end

%after
count=0;
while(datenum_aux < datenum(date_f))
 datestr_aux=datestr(datenum_aux,'yyyy-mm-dd_HH:MM:SS')
 %  [varname_anthro data_anthro] = read_netcdf_vars([input_path_anthro 'wrfchemi_d01_' datestr_aux '_co'],{'E_CO'});
 hh = str2num(datestr(datenum_aux,'HH'))
 if hh<12
 [varname_anthro e_anthro] = read_netcdf_vars([input_path_anthro 'wrfchemi_00z_d01'],{'E_CO'});
  else
 [varname_anthro e_anthro] = read_netcdf_vars([input_path_anthro 'wrfchemi_12z_d01'],{'E_CO'});
 end
  emis_tra=zeros([Nx Ny 1 1]);
  emis_tra(:,:,1,1)=e_anthro{1}(:,:,1,mod(hh,12)+1);
  data_anthro={emis_tra};

 unix(['cp ' input_path 'wrffirechemi_d01_' datestr_aux ' ' out_path 'wrffirechemi_d01_' datestr_aux]);
 unix(['cp ' out_path base_file ' ' out_path base_file '_aux']);
 write_netcdf_vars([out_path base_file '_aux'],{[var_in '_' num2str(Ntracer-1)]},data7); %Replacing the last tracer
 write_netcdf_vars([out_path base_file '_aux'],{[var_in '_' num2str(Ntracer)]},data_anthro); %put the rest in the other tracers
% unix(['ncks -A ' out_path base_file ' ' out_path 'wrffirechemi_d01_' datestr_aux]);
 unix(['ncks -A ' out_path base_file '_aux ' out_path 'wrffirechemi_d01_' datestr_aux]);
 count=count+1;
 datenum_aux=datenum(date_i_emiss)+(Nhours_emiss+count)/(24.0/(dt_wrffile_minutes/60)); %increase time step   
end
