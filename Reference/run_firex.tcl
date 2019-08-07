#!/usr/bin/wish -f

# This script runs the tracer version of WRF for FIREX-AQ
# It is assumed that WRF and WPS are already compiled
# Environment vars and modules should be sourced in the submit script

# ###########################################################################
#
# 
# 
# ###########################################################################



# ###########################################################################
#
# Set variables and options
# 
# ###########################################################################

# Upper Level Directories
set MAIN_DIR /nobackup/ctrujil1/WRF/Tracer_Code/runs/FIREX-AQ
set DATA_DIR /nobackup/ctrujil1/DATA

# Lower Level Directories
set ANLS_DIR [file join $MAIN_DIR]
set EMIS_DIR [file join $MAIN_DIR Emissions]
set REF_DIR [file join $MAIN_DIR Reference]
set WPS_DIR [file join $MAIN_DIR wps]
set WRF_DIR [file join $MAIN_DIR WRF]
set WRF_RUN_DIR [file join $WRF_DIR test/em_real]
set OUT_DIR [file join $MAIN_DIR Output]
set WRFTR_DIR [file join $WRF_DIR test/wrf_tracer]; # WRF tracer directory
set WRFNF_DIR [file join $WRF_DIR test/wrf_nofire]; # WRF no fire directory
set MAIAC_DIR [file join $DATA_DIR MAIAC]

# On/off Options
set wps "no";			# WPS
set real24 "no"; 		# 24 hour run of real.exe without chemistry
set qfed "no";			# QFED BB emissions
set nei "no";			# NEI athro emissions
set tracer_gen "yes";	# Tracer generation for Pablo's code
set wrf "no";			# Run WRF
set wrftr "no";			# Run wrf tracer code
set wrfnf "no";			# Run wrf without fires
set maiac_dl "no";		# Download MAIAC
set maiac "no";			# Run MAIAC


# Initialize log
set log_name [file join $REF_DIR RUN_[clock format [clock seconds] -format "%Y-%m-%d_%H:%M:%S" ]\.log]
set log [open $log_name w+]

# ###########################################################################
#
# Define Dates
# 
# ###########################################################################

set syyyy 2013
set smm 08
set sdd 22
set shh 00
set sdate $syyyy$smm$sdd
set start_datetime [clock add [clock scan $sdate] $shh hours]

# Define simulation length in hours
set time_step 12

# Set end date
set end_datetime [clock add $start_datetime $time_step hours]
set eyyyy [clock format $end_datetime -format %Y]
set emm   [clock format $end_datetime -format %m]
set edd   [clock format $end_datetime -format %d]
set ehh   [clock format $end_datetime -format %H]
set edate $eyyyy$emm$edd

# ###########################################################################
#
# MAIAC Dates 
# 
# ###########################################################################
set start_datewrf [expr [clock scan $syyyy$smm$sdd]+($shh*3600)-(24*3600*3)]
set wrf_yyyy [clock format $start_datewrf -format %Y]
set wrf_mm [clock format $start_datewrf -format %m]
set wrf_dd [clock format $start_datewrf -format %d]
set wrf_hh [clock format $start_datewrf -format %H]
set sdate_wrf $wrf_yyyy$wrf_mm$wrf_dd
puts start_datewrf

set timestep_tracer 88

# ###########################################################################
#
# Download necessary data
# 
# ###########################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Download MAIAC
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
if { $maiac == "yes" } {
puts $log "# ---------------------------------------------------------"
puts $log "# get maiac data from EARTHDATA, NASA"
puts $log "# ---------------------------------------------------------"

  # download data
  foreach hour [exec seq 0 24 $timestep_tracer ] {
      set str [eval "exec date -d \"$wrf_aaaa$wrf_mm$wrf_dd $wrf_hh $hour hour\" +\"%Y%m%d\""]
      set date_str [string map {\" {}} $str]
      puts $log "downloading: $date_str"
      flush $log
      set c [catch { eval "exec $MAIAC_DIR/Download/download_maiac.sh ${date_str} ${maiac_dir}" } msg ]
      puts $log $msg
      flush $log
  }
}


# ###########################################################################
#
# Run WPS
# 
# ###########################################################################
if { $wps == "yes" } {
	puts $log "# ---------------------------------------------------------"
	puts $log "# Start wps!"
	puts $log "# ---------------------------------------------------------"
	flush $log
	
	cd $WPS_DIR
	
	# Clean up leftover files: SST, FILE, GRIB, met_em, gfs, gdas, nam
	if {[llength [glob -nocomplain [file join SST*]]] > 0} {eval "file delete -force [glob -nocomplain [file join SST*]]"}
	if {[llength [glob -nocomplain [file join  FILE:*]]] > 0} {eval "file delete -force [glob -nocomplain [file join FILE:*]]"}
	if {[llength [glob -nocomplain [file join  GRIBFILE*]]] > 0} {eval "file delete -force [glob -nocomplain [file join GRIBFILE*]]"}
	if {[llength [glob -nocomplain [file join met_em.d*]]] > 0} {eval "file delete -force [glob -nocomplain [file join met_em.d*]]"}
	if {[llength [glob -nocomplain [file join gfs*]]] > 0} {eval "file delete -force [glob -nocomplain [file join gfs*]]"}
	if {[llength [glob -nocomplain [file join gdas*]]] > 0} {eval "file delete -force [glob -nocomplain [file join gdas*]]"}


	# Create sedcommand.sed file and fill it with commands
	exec cp namelist.wps namelist.wps.sed
	set sedcommand [open sedcommand.sed w+]
	puts $sedcommand "/start_date/c\\ start_date			= '$syyyy\-$smm\-$sdd\_$shh:00:00',"
	puts $sedcommand "/end_date/c\\ end_date			= '$eyyyy\-$emm\-$edd\_$ehh:00:00',"
	close $sedcommand
	exec sed -f sedcommand.sed namelist.wps.sed > namelist.wps
	file delete -force sedcommand.sed namelist.wps.sed


	# Run geogrid.exe	
	puts $log "# ---------------------------------------------------------"
	puts $log "# Run geogrid.exe!" 
	puts $log "# ---------------------------------------------------------"
	set c [catch { eval "exec mpiexec_mpt -np 1 ./geogrid.exe" } msg ]
	
	# Link NAM data and VTable
	eval "exec ./link_grib.csh [file join $DATA_DIR NAM $syyyy$smm]"
	if {[llength [glob -nocomplain VTable]] > 0 } {eval "file delete -force VTable" }
	exec ln -sf ungrib/Variable_Tables/Vtable.NAM Vtable

	# Run ungrib.exe
	puts $log "# ---------------------------------------------------------"
	puts $log "# Run ungrib.exe!"
	puts $log "# ---------------------------------------------------------"
	set c [catch { eval "exec ./ungrib.exe" } msg ]

	# Run metgrid.exe
	puts $log "# ---------------------------------------------------------"
	puts $log "# Run metgrid.exe!"
	puts $log "# ---------------------------------------------------------"
	set c [catch { eval "exec mpiexec_mpt -np 1 ./metgrid.exe" } msg ]

	puts $log "# ---------------------------------------------------------"
	puts $log "# End WPS!"
	puts $log "# ---------------------------------------------------------"
	flush $log

}
# ###########################################################################
#
# Run a real.exe for 24 hours for input files
# 
# ###########################################################################
if { $real24 == "yes" } {
	puts $log "# ---------------------------------------------------------"
	puts $log "# run real.exe "
	puts $log "# ---------------------------------------------------------"
	flush $log

	cd $WRF_RUN_DIR
	
	# Clean up old files
	if {[llength [glob -nocomplain met_em.d*]] > 0} {eval "file delete -force [glob -nocomplain met_em.d*]"}
	if {[llength [glob -nocomplain rsl.*]] > 0} {eval "file delete -force [glob -nocomplain rsl.*]"}
	if {[llength [glob -nocomplain  wrfout_d*]] > 0} {eval "file delete -force [glob -nocomplain  wrfout_d*]"}
	if {[llength [glob -nocomplain  wrfrst_d*]] > 0} {eval "file delete -force [glob -nocomplain  wrfrst_d*]"}; # ?????????????????????
	if {[llength [glob -nocomplain  wrffirechemi_d*]] > 0} {eval "file delete -force [glob -nocomplain  wrffirechemi_d*]"}
	

	# Create sedcommand.sed file and fill it with commands
	exec cp namelist.input namelist.input.sed
	set sedcommand [open sedcommand.sed w+]
	puts $sedcommand "/start_year/c\\ start_year								= $syyyy,"
	puts $sedcommand "/start_month/c\\ start_month							= $smm,"
	puts $sedcommand "/start_day/c\\ start_day							= $sdd,"
	puts $sedcommand "/start_hour/c\\ start_hour							= 00,"
	puts $sedcommand "/end_year/c\\ end_year							= $syyyy,"
	puts $sedcommand "/end_month/c\\ end_month							= $smm,"
	puts $sedcommand "/end_day/c\\ end_day							= [expr $sdd + 1],"
	puts $sedcommand "/end_hour/c\\ end_hour							= 00,"
	puts $sedcommand "/io_form_auxinput5/c\\ io_form_auxinput5							= 0,"
	puts $sedcommand "/io_form_auxinput7/c\\ io_form_auxinput7							= 0,"
	puts $sedcommand "/chem_opt/c\\ chem_opt							= 0,"
	puts $sedcommand "/biomass_burn_opt/c\\ biomass_burn_opt							= 0,"
	close $sedcommand
	exec sed -f sedcommand.sed namelist.input.sed > namelist.input
	file delete -force sedcommand.sed namelist.input.sed

	# link met files 
#	exec "ln -sf $WPS_DIR/met_em.d*"
#	set c [catch { eval "exec ln -sf [file join $WPS_DIR met_em.d*] ." } msg ]
	set met_f [glob -nocomplain [file join $WPS_DIR met_em.d*]]
	foreach x $met_f {
		exec ln -sf $x .
	}	

	# run real.exe
	set c [catch { eval "exec mpiexec_mpt ./real.exe" } msg ]

	# Move input file to Emission directory for next step
	cd $WRF_RUN_DIR
	exec ln -sf [file join $WRF_RUN_DIR wrfinput_d01] $EMIS_DIR
#	set c [catch { eval "exec mv wrfinput_d01 $EMIS_DIR" } msg ]
#	exec ln -sf wrfinput_d01 $EMIS_DIR
}

# ###########################################################################
#
# Generate Emissions: QFED Biomass Burning
# 
# ###########################################################################
if {$qfed == "yes"} {
	
	# Format QFED to FINN
	puts $log "# ---------------------------------------------------------"
	puts $log "# transform qfed to finn"
	puts $log "# ---------------------------------------------------------"
	flush $log

	cd [file join $EMIS_DIR QFED qfed_to_finn]

	exec cp format_QFED_into_FINN_PM10.m format_QFED_into_FINN_PM10.sed
	set sedcommand [open sedcommand.sed w+]
	puts $sedcommand "/date_i=/c\\date_i=\[$syyyy $smm $sdd $shh 0 0\]"
	puts $sedcommand "/date_f=/c\\date_f=\[$eyyyy $emm $edd $ehh 0 0\]"
	puts $sedcommand "/path_qfed=/c\\path_qfed='/nobackup/ctrujil1/DATA/QFED/$syyyy/$smm/'"
	close $sedcommand
	exec sed -f sedcommand.sed format_QFED_into_FINN_PM10.sed > format_QFED_into_FINN_PM10.m
	file delete -force sedcommand.sed format_QFED_into_FINN_PM10.sed

	puts $log "format_QFED_into_fin_PM10.m edited - running now"
	flush $log
	set c [catch { eval "exec /nasa/matlab/2017b/bin/matlab -nodisplay -r format_QFED_into_FINN_PM10" } msg ]
	puts $log $msg
	
	# Format FINN to wrffire
	puts $log "# ---------------------------------------------------------"
	puts $log "# transform finn to wrffire"
	puts $log "# ---------------------------------------------------------"
	flush $log

	cd [file join $EMIS_DIR QFED finn_to_wrffire]
	puts $log [file join $EMIS_DIR QFED finn_to_wrffire]
	if { $sdd < $edd } { set finn_edd [expr $edd - 1] } else { set finn_edd $edd }

	exec cp Header_fire_emis Header_fire_emis.sed 
	set sedcommand [open sedcommand.sed w+]
	puts $sedcommand "/start_date/c\\start_date		='$syyyy-$smm-$sdd',"
	puts $sedcommand "/end_date/c\\end_date		='$syyyy-$smm-$finn_edd',"
	puts $sedcommand "/fire_filename/c\\fire_filename(1)  = 'QFED_in_FINN_format_pm10_$sdate\_$edate.txt'"
	close $sedcommand
	exec sed -f sedcommand.sed Header_fire_emis.sed > Header_fire_emis
	file delete -force sedcommand.sed Header_fire_emis.sed
	
	set c [catch { eval "exec make clean" } msg ]
	puts $log $msg
	set c [catch { eval "exec make" } msg ]
	puts $log $msg
	set c [catch { eval "exec ./fire_emis.exe < Header_fire_emis" } msg ]
	puts $log $msg

	puts $log "# ---------------------------------------------------------"
	puts $log "# QFED donzeo burrito"
	puts $log "# ---------------------------------------------------------"

}

# ###########################################################################
#
# Generate Emissions: Anthropogenic
# 
# ###########################################################################
if { $nei =="yes" } {
	puts $log "# ---------------------------------------------------------"
	puts $log "# Start NEI"
	puts $log "# ---------------------------------------------------------"
	flush $log
	
	if { 0 == 1 } {
	cd [file join $EMIS_DIR NEI]
	
	set c [catch { eval "exec make clean" } msg ]
	puts $log $msg
	flush $log
	set c [catch { eval "exec make" } msg ]
	puts $log $msg
	flush $log
	set c [catch { eval "exec ./emiss_v04_Rimfire_4km.exe" } msg ]
	puts $log $msg
	flush $log

	set c [catch {eval "exec ln -sf [file join $EMIS_DIR NEI wrfem_00to12Z ] [file join $WRF_RUN_DIR wrfem_00to12z_d01]"}]
	set c [catch {eval "exec ln -sf [file join $EMIS_DIR NEI wrfem_12to24Z] [file join $WRF_RUN_DIR wrfem_12to24z_d01]"}]
	}
	
	cd $WRF_RUN_DIR
	
	exec cp namelist.input namelist.input.sed
	set sedcommand [open sedcommand.sed w+]
	puts $sedcommand "/start_year/c\\ start_year							= $syyyy,"
	puts $sedcommand "/start_month/c\\ start_month						= $smm,"
	puts $sedcommand "/start_day/c\\ start_day							= $sdd,"
	puts $sedcommand "/start_hour/c\\ start_hour							= 00,"
	puts $sedcommand "/end_year/c\\ end_year							= $syyyy,"
	puts $sedcommand "/end_month/c\\ end_month							= $smm,"
	puts $sedcommand "/end_day/c\\ end_day							= $sdd,"
	puts $sedcommand "/end_hour/c\\ end_hour							= 23,"
	puts $sedcommand "/run_hours/c\\ run_hours							= 23,"
	puts $sedcommand "/io_form_auxinput5/c\\ io_form_auxinput5							= 2,"
	puts $sedcommand "/io_form_auxinput7/c\\ io_form_auxinput7							= 2,"
	puts $sedcommand "/chem_opt/c\\ chem_opt							= 14,"
	puts $sedcommand "/biomass_burn_opt/c\\ biomass_burn_opt							= 0,"
	close $sedcommand
	exec sed -f sedcommand.sed namelist.input.sed > namelist.input
	file delete -force sedcommand.sed namelist.input.sed

	set c [catch { eval "exec mpiexec_mpt ./convert_emiss.exe" } msg ]
	puts $log $msg
	flush $log

}
# ###########################################################################
#
# Generate Emissions: Tracers
# 
# ###########################################################################
if { $tracer_gen == "yes" } {
	puts $log "# ---------------------------------------------------------"
	puts $log "# Start tracer gen"
	puts $log "# ---------------------------------------------------------"
	flush $log

	cd [file join $EMIS_DIR TracerGen]

	set wrffire_t [glob -nocomplain [file join $EMIS_DIR QFED finn_to_wrffire wrffire* ]]
	foreach x $wrffire_t {
		exec ln -sf $x .
	}
	
	set wrfchemi_t [glob [file join $WRF_RUN_DIR wrfchemi* ]]
	foreach x $wrfchemi_t {
		exec ln -sf $x .
	} 
	
	set c [catch { eval "exec /nasa/matlab/2017b/bin/matlab -nodisplay -r /nasa/matlab/2017b/bin/matlab -nodisplay -r \"try;trujillo_create_tracers;catch;disp('MATLAB issue');exit;end\" "} msg ]
	puts $log $msg
	flush $log
}
# ###########################################################################
#
# Run WRF with Tracers
# 
# ###########################################################################
if { $wrftr == "yes"} {

#	if { ![file exists $WRFTR_DIR]} {file mkdir $WRFTR_DIR; file attributes $WRFTR_DIR -permissions a+r;  puts $log "directory $WRFTR_DIR made"}

	cd $WRFTR_DIR
#	exec cp [file join $WRF_RUN_DIR	*] .
#	set c [catch {eval "exec cp $WRF_RUN_DIR/* ."} msg ]
	
#	exec ln -sf [file join $EMIS_DIR Xinxin_Emissions wrfchemi*] .
#	exec ln -sf [file join $EMIS_DIR NEI Xinxin_Emissions wrfchemi_00z_d01] .
	set wrfchemi_f [glob -nocomplain [file join $EMIS_DIR NEI Xinxin_Emissions wrfchemi*]]
	foreach x $wrfchemi_f {
		exec ln -sf $x .
	}	
	set wrffire_f [glob -nocomplain [file join $EMIS_DIR TracerGen out wrffire*]]
	foreach x $wrffire_f {
		exec ln -sf $x .
	}	
puts ayyayai
exit

	exec cp namelist.input namelist.input.sed
	set sedcommand [open sedcommand.sed w+]
	puts $sedcommand "/start_year/c\\ start_year								= $syyyy,"
	puts $sedcommand "/start_month/c\\ start_month							= $smm,"
	puts $sedcommand "/start_day/c\\ start_day							= $sdd,"
	puts $sedcommand "/start_hour/c\\ start_hour							= $shh,"
	puts $sedcommand "/end_year/c\\ end_year							= $eyyyy,"
	puts $sedcommand "/end_month/c\\ end_month							= $emm,"
	puts $sedcommand "/end_day/c\\ end_day							= $edd,"
	puts $sedcommand "/end_hour/c\\ end_hour							= $ehh,"
	puts $sedcommand "/io_form_auxinput5/c\\ io_form_auxinput5							= 0,"
	puts $sedcommand "/io_form_auxinput7/c\\ io_form_auxinput7							= 0,"
	puts $sedcommand "/chem_opt/c\\ chem_opt							= 0,"
	puts $sedcommand "/biomass_burn_opt/c\\ biomass_burn_opt							= 0,"
	close $sedcommand
	exec sed -f sedcommand.sed namelist.input.sed > namelist.input
	file delete -force sedcommand.sed namelist.input.sed

	set c [catch { eval "exec mpiexec_mpt ./real.exe" } msg ]
	puts $log $msg
	flush $log

	exec cp namelist.input namelist.input.sed
	set sedcommand [open sedcommand.sed w+]
	puts $sedcommand "/start_year/c\\ start_year								= $syyyy,"
	puts $sedcommand "/start_month/c\\ start_month							= $smm,"
	puts $sedcommand "/start_day/c\\ start_day							= $sdd,"
	puts $sedcommand "/start_hour/c\\ start_hour							= $shh,"
	puts $sedcommand "/end_year/c\\ end_year							= $eyyyy,"
	puts $sedcommand "/end_month/c\\ end_month							= $emm,"
	puts $sedcommand "/end_day/c\\ end_day							= $edd,"
	puts $sedcommand "/end_hour/c\\ end_hour							= $ehh,"
	puts $sedcommand "/io_form_auxinput5/c\\ io_form_auxinput5							= 2,"
	puts $sedcommand "/io_form_auxinput7/c\\ io_form_auxinput7							= 2,"
	puts $sedcommand "/chem_opt/c\\ chem_opt							= 14,"
	puts $sedcommand "/biomass_burn_opt/c\\ biomass_burn_opt							= 1,"
	close $sedcommand
	exec sed -f sedcommand.sed namelist.input.sed > namelist.input
	file delete -force sedcommand.sed namelist.input.sed

	
	set c [catch { eval "exec mpiexec_mpt ./wrf.exe" } msg ]
	puts $log $msg
	flush $log

}


# ###########################################################################
#
# Run WRF without fire
# 
# ###########################################################################
if { $wrfnf == "yes" } {
	
	cd $WRFNF_DIR
	
	exec cp namelist.input namelist.input.sed
	set sedcommand [open sedcommand.sed w+]
	puts $sedcommand "/start_year/c\\ start_year								= $syyyy,"
	puts $sedcommand "/start_month/c\\ start_month							= $smm,"
	puts $sedcommand "/start_day/c\\ start_day							= $sdd,"
	puts $sedcommand "/start_hour/c\\ start_hour							= $shh,"
	puts $sedcommand "/end_year/c\\ end_year							= $eyyyy,"
	puts $sedcommand "/end_month/c\\ end_month							= $emm,"
	puts $sedcommand "/end_day/c\\ end_day							= $edd,"
	puts $sedcommand "/end_hour/c\\ end_hour							= $ehh,"
	puts $sedcommand "/io_form_auxinput5/c\\ io_form_auxinput5							= 0,"
	puts $sedcommand "/io_form_auxinput7/c\\ io_form_auxinput7							= 0,"
	puts $sedcommand "/chem_opt/c\\ chem_opt							= 0,"
	puts $sedcommand "/biomass_burn_opt/c\\ biomass_burn_opt							= 0,"
	close $sedcommand
	exec sed -f sedcommand.sed namelist.input.sed > namelist.input
	file delete -force sedcommand.sed namelist.input.sed

	
	set c [catch { eval "exec mpiexec_mpt ./real.exe" } msg ]
	puts $log $msg
	flush $log


	set c [catch { eval "exec mpiexec_mpt ./wrf.exe" } msg ]
	puts $log $msg
	flush $log




}
# ###########################################################################
#
# Run MAIAC Inversion
# 
# ###########################################################################
if {maiac = "yes"} {
	puts $log "# ---------------------------------------------------------"
	puts $log "# Start MAIAC"
	puts $log "# ---------------------------------------------------------"
	flush $log

	date_aux="${wrf_yyyy}-${wrf_mm}-${wrf_dd} ${wrf_hh}:00:00"
	set off_maiac 24; # MAIAC offset from beginning
	year_i_maiac=$(date -d "$date_aux  ${off_maiac} hours" '+%Y')
    month_i_maiac=$(date -d "$date_aux  ${off_maiac} hours" '+%m')
    day_i_maiac=$(date -d "$date_aux  ${off_maiac} hours" '+%d')
    hour_i_maiac=$(date -d "$date_aux  ${off_maiac} hours" '+%H')
    echo "Date start MAIAC= ${year_i_maiac}-${month_i_maiac}-${day_i_maiac}_${hour_i_maiac}:00:00"

	year_f=$(date -d "$date_aux  ${timestep_tracer} hours" '+%Y')
    month_f=$(date -d "$date_aux  ${timestep_tracer} hours" '+%m')
    day_f=$(date -d "$date_aux  ${timestep_tracer} hours" '+%d')
    hour_f=$(date -d "$date_aux  ${timestep_tracer} hours" '+%H')
    echo "Date end TRACER D01= ${year_f}-${month_f}-${day_f}_${hour_f}:00:00"

	# Write MAIAC to hourly files
	set c [catch { eval "exec /nasa/matlab/2017b/bin/matlab -nodisplay -r /nasa/matlab/2017b/bin/matlab -nodisplay -r \"try;write_maiac_matlab_file_hourly([$year_i_maiac $month_i_maiac $day_i_maiac $hour_i_maiac 0 0],[$year_f $month_f $day_f $hour_f 0 0],'${MAIAC_DATA}/');catch;disp('MATLAB issue');exit;end\" "} msg ]
	puts $log $msg
	flush $log


}
