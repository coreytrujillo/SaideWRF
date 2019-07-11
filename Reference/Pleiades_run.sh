

export WRFRUN_DIR=$PBS_O_WORKDIR/WRF/test/em_real/
export QFED_DIR=$PBS_O_WORKDIR XXX
export START_DATE=XXX
export END_DATE=XXXX

source Reference/Pleiades_EnvVars.sh

cd $WRF_RUN
mpiexec_mpt ./real.exe
mv wrfinput_d01 $QFED_DIR

cd qfed_to_finn/
/nasa/matlab/2017b/bin/matlab -nodisplay -r format_QFED_into_FINN_PM10

cd ../finn_to_wrffire/
make
./fire_emis.exe <Header_fire_emis

cd $WWRFRUN_DIR
ln -sf $QFED_DIR/fin_to_wrffire/wrffirechemi* .

