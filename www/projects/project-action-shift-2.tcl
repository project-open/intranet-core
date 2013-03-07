# /packages/intranet-core/www/projects/project-action-shift-2.tcl
#
# Copyright (C) 2003-2013 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.


ad_page_contract {
    Shift the project forward or backward in time
    @param return_url the url to return to
    @param shift_period +<number>[w]

    @author frank.bergmann@project-open.com
} {
    select_project_id
    shift_period
    return_url
}


ad_proc -public im_project_shift {
    -project_id:required
    -shift_days:required
} {
    Moves an entire project forward or backward in time
    taking into account weekends and global bank holidays
} {
    ns_log Notice "im_project_shift: project_id=$project_id, shift_days=$shift_days"
    set shift_epoch [expr $shift_days * 3600 * 24]

    # -----------------------------------------------------------
    # Pull out the start- and end dates 
    #
    set sub_projects_sql "
	select	p.project_id as sub_project_id,
		p.start_date,
		p.end_date
	from	im_projects main_p,
		im_projects p
	where	main_p.project_id = :project_id and
		p.tree_sortkey between main_p.tree_sortkey and tree_right(main_p.tree_sortkey)
	order by p.tree_sortkey
    "
    db_foreach sub_projects $sub_projects_sql {
	set project_start_hash($sub_project_id) [im_date_ansi_to_epoch $start_date]
	set project_end_hash($sub_project_id) [im_date_ansi_to_epoch $end_date]
    }


    # -----------------------------------------------------------
    # Shift the dates
    #
    foreach pid [array names project_start_hash] {
	set project_start_hash($pid) [expr $project_start_hash($pid) + $shift_epoch]
	set project_end_hash($pid) [expr $project_end_hash($pid) + $shift_epoch]
    }



    # -----------------------------------------------------------
    # Write results to projects
    #
    foreach pid [array names project_start_hash] {
	db_dml update_sub_project "
		update im_projects set
			start_date = '[im_epoch_to_ansii $project_start_hash($pid)]',
			end_date = '[im_epoch_to_ansii $project_end_hash($pid)]'
		where	project_id = :pid
	"
    }
}




set user_id [ad_maybe_redirect_for_registration]
set shift_period [string tolower $shift_period]

if {![regexp {^([\+\-])([0-9]+)([wd]*)$} $shift_period match direction number unit]} {
    ad_return_complaint 1 "<b>Invalid shift period</b>:<br>We expect something like '+10' or '-2w', found: '$shift_period'."
}

if {"" == $unit} { set unit "d" }
if {"-" == $direction} { set number [expr -1 * $number] }
if {"w" == $unit} { set number [expr $number * 7] }

# !!! Shift project
# ad_return_complaint 1 "$shift_period - $return_url - $select_project_id - '$number' - '$unit' - [llength $select_project_id]"


foreach pid $select_project_id {

    if {[db_0or1row project_info "
	select	start_date,
		end_date
	from	im_projects
	where	project_id = :pid
    "]} {
	# Found project information
	im_project_shift -project_id $pid -shift_days $number
    }
}




ad_returnredirect $return_url
