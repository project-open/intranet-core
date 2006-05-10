#!/usr/bin/perl

# --------------------------------------------------------
# ]project-open[ ERP/Project Management System
# (c) 2006 ]project-open[, frank.bergmann@project-open.com
# All rights reserved.
#
# common_constants.pm - Common constants for all user exits
#
# --------------------------------------------------------


# --------------------------------------------------------
# Where to write debugging messages?
$logfile = "/web/projop/log/user_exits.log";


# --------------------------------------------------------
# Define the date format for debugging messages
$date = `/bin/date +"%Y%m%d.%H%M"` || 
	die "common_constants: Unable to get date\n";
chomp($date);


# --------------------------------------------------------
# Database Connection Parameters

$db_pwd = "";
$db_datasource = "dbi:Pg:dbname=projop";
$db_username = "projop";



# --------------------------------------------------------
# You don't know the "datasource"? Try run this code to
# extract user information from ]po[
#
# Probe DBI for the installed drivers
# my @drivers = DBI->available_drivers();
# die "No drivers found!\n" unless @drivers; # should never happen
# 
# Iterate through the drivers and list the data sources for each one
# foreach my $driver ( @drivers ) {
#     print "Driver: $driver\n";
#     my @dataSources = DBI->data_sources( $driver );
#     foreach my $dataSource ( @dataSources ) {
#         print "\tData Source is $dataSource\n";
#     }
#     print "\n";
# }

