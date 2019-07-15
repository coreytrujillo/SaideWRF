% Coded by Pablo Saide, pablo-saide@uiowa.edu

function write_netcdf_vars(name,vars_extract,data) 

file = netcdf.open(name, 'NC_WRITE');
[ndims_file,nvars_file,ngatts_file,unlimdimid_file] = netcdf.inq(file);

%vars and local atributes
for i=0:(nvars_file-1)
 [varname{i+1},xtype(i+1),dimids{i+1},natts(i+1)] = netcdf.inqVar(file,i);
% data_aux{i+1}= netcdf.getVar(file,i);
% attributes:
% for j=0:(natts(i+1)-1)
%  attname{i+1,j+1}=netcdf.inqAttName(file,i,j);
%  [xtype_att(i+1,j+1),attlen(i+1,j+1)] = netcdf.inqAtt(file,i,attname{i+1,j+1});
%  attrvalue{i+1,j+1} = netcdf.getAtt(file,i,attname{i+1,j+1});
% end
end

%dimensions
for i=0:(ndims_file-1)
 [dimname{i+1}, dimlen(i+1)] = netcdf.inqDim(file,i);
end

 indx_extract=zeros(numel(vars_extract),1);
 for i=1:numel(vars_extract)
%  vars_extract{i}
  logical=strcmp(vars_extract{i},varname);
  indx_extract(i)=find(logical);
%  varname{indx_extract(i)}
%  dimids{indx_extract(i)}
  netcdf.putVar(file,indx_extract(i)-1,data{i});
 end
 varname=varname(indx_extract);


netcdf.close(file)
