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

set ANLS_DIR [file join $MAIN_DIR]
set EMIS_DIR [file join $MAIN_DIR Emissions]
set REF_DIR [file join $MAIN_DIR Reference]
set WPS_DIR [file join $MAIN_DIR wps]
set WRF_DIR [file join $MAIN_DIR WRF]
set OUT_DIR [file join $MAIN_DIR Output]

# On/off Options
set wps "yes"



# Initialize log
set log_name [file join $REF_DIR run_[clock format [clock seconds] -format "%Y-%m-%d_%H:%M:%S" ]\.log]
set log [open $log_name w+]

# ###########################################################################
#
# Define Dates
# 
# ###########################################################################


# Define start date and time UTC
# set start_date_str "20130820"; # Start Date
# set shh 12
# set start_hr_MT 12; # Simulation start hour in Mountain time

# if { $start_date_str > 0} {
#	set start_date [string range $start_date_str 0 3] ;# Year
#	lappend start_date [string range $start_date_str 4 5] ;# Month
#	lappend start_date [string range $start_date_str 6 7] ;# Day
#	lappend start_date $shh; # Hour
# 
#	} else {
#	set secondi [clock seconds]
#	# Convert MDT to UTC: +6 hours  
#	set secondi [expr $secondi + 3600*6]; 
#	set start_date [split [clock format $secondi -format %Y:%m:%d:%H] ":"] ;
#}

#puts start_date
#puts $start_date

#set syyyy [lindex $start_date 0] ;# Year
#set smm   [lindex $start_date 1] ;# Month
#set sdd   [lindex $start_date 2] ;# Day
#set sdate $syyyy$smm$sdd
#puts sdate
#puts $sdate

# set shh [lindex $start_date 3]; # Hour
#set sdatetime $sdate$shh
#puts sdatetime
#puts $sdatetime
#set sss [clock scan $sdate]
#set ttt [clock format $sss -format %Y-%m-%d_%H:%M:%S]
#set vvv [clock add $sss 6 hours]
#set zzz [clock format $vvv -format %Y-%m-%d_%H:%M:%S]
#######################################################
set syyyy 2013
set smm 08
set sdd 20
set shh 12
set sdate $syyyy$smm$sdd

# set sdate $syyyy-$smm-$sdd\_$shh:00:00

set start_datetime [clock add [clock scan $sdate] $shh hours]

# Define simulation length in hours
set time_step 12

# Set end date
set end_datetime [clock add $start_datetime $time_step hours]
set eyyyy [clock format $end_datetime -format %Y]
set emm   [clock format $end_datetime -format %m]
set edd   [clock format $end_datetime -format %d]
set ehh   [clock format $end_datetime -format %H]


# ###########################################################################
#
# Download necessary data
# 
# ###########################################################################


# ###########################################################################
#
# Run WPS
# 
# ###########################################################################
if { $wps == "yes" } {
#	puts $log "# ---------------------------------------------------------"
#	puts $log "# Start wps!"
#	puts $log "# ---------------------------------------------------------"
#	flush $log
	
	cd $WPS_DIR
	
	# Clean up leftover files: SST, FILE, GRIB, met_em, gfs, gdas, nam
	if {[llength [glob -nocomplain [file join SST*]]] > 0} {eval "file delete -force [glob -nocomplain [file join SST*]]"}
	if {[llength [glob -nocomplain [file join  FILE:*]]] > 0} {eval "file delete -force [glob -nocomplain [file join FILE:*]]"}
	if {[llength [glob -nocomplain [file join  GRIBFILE*]]] > 0} {eval "file delete -force [glob -nocomplain [file join GRIBFILE*]]"}
	if {[llength [glob -nocomplain [file join met_em.d*]]] > 0} {eval "file delete -force [glob -nocomplain [file join met_em.d*]]"}
	if {[llength [glob -nocomplain [file join gfs*]]] > 0} {eval "file delete -force [glob -nocomplain [file join gfs*]]"}
	if {[llength [glob -nocomplain [file join gdas*]]] > 0} {eval "file delete -force [glob -nocomplain [file join gdas*]]"}

	# Link NAM data and VTable
	eval "exec ./link_grib.csh [file join $DATA_DIR NAM $sdate]"
	if {[llength [glob -nocomplain VTable]] > 0 } {eval "file delete -force VTable" }
	exec ln -sf ungrib/Variable_Tables/Vtable.NAM Vtable

	# Create sedcommand.sed file and fill it with commands
	exec cp namelist.wps namelist.wps.sed
	set sedcommand [open sedcommand.sed w+]
#	exec sed -i "/start_date/c\start_date		=";#$wrf_yyyy\-$wrf_mm\-$wrf_dd\_$wrf_hh:00:00' namelist.wps
#	puts $sedcommand "-i /start_date/c\start_date		= 1234"
#	puts $sedcommand "s,_START_,$wrf_yyyy\-$wrf_mm\-$wrf_dd\_$wrf_hh:00:00,g"
#	puts $sedcommand "s,_END_,$eyyyy\-$emm\-$edd\_$ehh\:00:00,g"
	puts $sedcommand "/start_date/c\\ start_date			= '$syyyy\-$smm\-$sdd\_$shh:00:00,'"
	puts $sedcommand "/end_date/c\\ end_date			= '$eyyyy\-$emm\-$edd\_$ehh:00:00,'"
	close $sedcommand
	exec sed -f sedcommand.sed namelist.wps.sed > namelist.wps
	file delete -force sedcommand.sed namelist.wps.sed


	# Run ungrib.exe
#	puts $log "# ---------------------------------------------------------"
#	puts $log "# Run ungrib.exe!"
#	puts $log "# ---------------------------------------------------------"
#	exec "./ungrib.exe"

	# Run metgrid.exe
#	puts $log "# ---------------------------------------------------------"
#	puts $log "# Run metgrid.exe!"
#	puts $log "# ---------------------------------------------------------"
#	exec "./metgrid.exe"	

	# Run geogrid.exe	
#	puts $log "# ---------------------------------------------------------"
#	puts $log "# Run geogrid.exe!" 
#	puts $log "# ---------------------------------------------------------"
#	exec "./geogrid.exe"
	
#	puts $log "# ---------------------------------------------------------"
#	puts $log "# End WPS!"
#	puts $log "# ---------------------------------------------------------"
#	flush $log
}

# ###########################################################################
#
# Run a real.exe for 24 hours for input files
# 
# ###########################################################################




# ###########################################################################
#
# Generate Emissions: Biomass Burning
# 
# ###########################################################################



# ###########################################################################
#
# Generate Emissions: Anthropogenic
# 
# ###########################################################################




# ###########################################################################
#
# Generate Emissions: Tracers
# 
# ###########################################################################




# ###########################################################################
#
# Run WRF
# 
# ###########################################################################





