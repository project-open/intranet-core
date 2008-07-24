# /packages/intranet-filestorage/www/last-backup-file.tcl
#
# Copyright (C) 2003-2004 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.

ad_page_contract {
    Shows the last ".pgp" backup file in the backup
    directory in the filestorage.

    The idea is to publicly display ".pgp" encrypted files 
    so that they can be downloaded by a backup server.

    @author frank.bergmann@project-open.com
    @creation-date Oct 2005
} {
}

# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

set user_id [ad_get_user_id]
set return_url "/intranet-filestorage/"

set find_cmd [parameter::get -package_id [im_package_core_id] -parameter "FindCmd" -default "/bin/find"]

set backup_path [parameter::get -package_id [im_package_core_id] -parameter "BackupBasePathUnix" -default "/tmp"]


# ------------------------------------------------------
# Get the list of backup sets for restore
# ------------------------------------------------------

# Get the list of all backup sets under backup_path
set file_list [exec $find_cmd $backup_path -name {*.pgp} ]
set file_list [lsort -decreasing $file_list]

set file [lindex $file_list 0]

if [file readable $file] {

    set type [ns_guesstype $file]
    set type "application/pgp"
    ns_returnfile 200 $type $file

} else {
    doc_return 500 text/html "[_ intranet-filestorage.lt_Did_not_find_the_spec]"
}
