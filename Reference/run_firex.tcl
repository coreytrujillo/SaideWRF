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


# Define start date and time
set start_date_str "20130820"; # Start Date
set shh 06; # Simulation start hour in Mountain time

if { $start_date_str > 0} {
	set start_date [string range $start_date_str 0 3] ;# Year
	lappend start_date [string range $start_date_str 4 5] ;# Month
	lappend start_date [string range $start_date_str 6 7] ;# Day
	
	} else {
	set secondi [clock seconds]
	# Convert MDT to UTC: +6 hours  
	set secondi [expr $secondi + 3600*6]; 
	set start_date [split [clock format $secondi -format %Y:%m:%d] ":"] ;
}

set syyyy [lindex $start_date 0] ;# Year
set smm   [lindex $start_date 1] ;# Month
set sdd   [lindex $start_date 2] ;# Day
set sdate $syyyy$smm$sdd

# Define simulation length in hours
set time_step 12

# Set final date variables based on simulation lengths
append end_date [lindex $start_date 0] [lindex $start_date 1] [lindex $start_date 2]
set end_date [expr [clock scan $end_date]+[expr $time_step*3600]]
set eyyyy [clock format $end_date -format %Y]
set emm   [clock format $end_date -format %m]
set edd   [clock format $end_date -format %d]
set ehh   [clock format $end_date -format %H]


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
	if {[llength [glob -nocomplain [file join *nam*]]] > 0} {eval "file delete -force [glob -nocomplain [file join *nam*]]"}

	# Link NAM data
	set c [catch { eval "exec ./link_grib.csh [file join $DATA_DIR NAM $sdate]" } msg]
	if{[llength [glob -noclompain VTable]] > 0 } {eval "file delete -force VTable" }
	exec ln -sf ungrib/Variable_Tables/Vtable.NAM Vtable
	
	
	
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





