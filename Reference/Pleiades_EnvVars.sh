#!/bin/bash
module purge
module load comp-intel/2018.3.222 hdf4/4.2.12 mpi-hpe/mpt.2.17r13 hdf5/1.8.18_mpt netcdf/4.4.1.1_mpt matlab/2017b nco/4.6.7

export WRF_EM_CORE=1
export WRF_NMM_CORE=0
export WRF_DA_CORE=0
export BUFR=1
export CRTM=1
export NETCDF4=0
export NETCDF='/nasa/netcdf/4.4.1.1_serial/'
export HDF5='/nasa/hdf5/1.8.18_serial/'
export PATH=$NETCDF/lib:$PATH
export PATH=$HDF5/lib:$PATH
export LD_LIBRARY_PATH=$HDF5/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$NETCDF/lib:$LD_LIBRARY_PATH
export NETCDF_DIR='/nasa/netcdf/4.4.1.1_serial/'
export WRFIO_NCD_LARGE_FILE_SUPPORT=1
export OMP_NUM_THREADS=1
export MP_STACK_SIZE=64000000
export I_MPI_FABRICS=shm:tcp
# unlimit  
export WRF_CHEM=1
export WRF_KPP=0
# export FLEX_LIB_DIR='/usr/lib64'
export JASPERINC='/home6/ctrujil1/libraries/jasper/include/'
export JASPERLIB='/home6/ctrujil1/libraries/jasper/lib/'
