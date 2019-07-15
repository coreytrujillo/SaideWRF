

export WRFRUN_DIR=$PBS_O_WORKDIR/WRF/test/em_real/
export EMIS_DIR=$PBS_O_WORDIR/Emissions 
#export QFED_DIR=$EMIS_DIR/QFED
#export NEI_DIR=$EMIS_DIR/NEI
export START_DATE=XXX
export END_DATE=XXXX

source Reference/Pleiades_EnvVars.sh

# 24 hour run of real.exe without chemistry
cd $WRF_RUN
mpiexec_mpt ./real.exe
mv wrfinput_d01 $EMIS_DIR

# Generate biomass burning emissions
cd $EMIS_DIR/QFED/qfed_to_finn
/nasa/matlab/2017b/bin/matlab -nodisplay -r format_QFED_into_FINN_PM10

cd $EMIS_DIR/QFED/finn_to_wrffire/
make
./fire_emis.exe <Header_fire_emis

# Generate anthropogenic Emissions
cd $EMIS_DIR/NEI/
vim emiss_v04_Rimfire_4k.F XXXXX
make
./emiss_v04_Rimfire_4km

# Generate Tracers
cd $EMIS_DIR/TracerGen
/nasa/matlab/2017b/bin/matlab -nodisplay -r trujillo_create_tracers


# Link emissions files
cd $WWRFRUN_DIR
#ln -sf $QFED_DIR/fin_to_wrffire/wrffirechemi* .
ln -sf $EMIS_DIR/TracerGen/out/wrffirechemi
ln -sf $EMIS_DIR/NEI/wrfem_00to12Z wrfem_00to12z_d01
ln -sf $EMIS_DIR/NEI/wrfem_12to24Z wrfem_12to24z_d01

# Convert anthropogenic emissions to netcdf
vim namelist.inputXXXXX
mpiexec_mpt ./convert_emiss.exe

# Run real.exe for full simulation
vim namelist.inputXXXXX
mpiexec_mpt -np 1 ./real.exe

# Run WRF
vim namelist.inputXXXXX
mpiexec_mpt ./wrf.exe
