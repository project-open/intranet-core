# -------------------------------------------------------------
# /packages/intranet-core/www/components/generic-table-component.tcl
#
# Copyright (c) 2007 ]project-open[
# All rights reserved.
#
# Author: frank.bergmann@project-open.com
#

# -------------------------------------------------------------
# Variables:
# table_name
# select_column
# select_value
# order_by
# exclude_columns
# return_url


if {![info exists table_name]} {
    ad_page_contract {
	@author frank.bergmann@project-open.com
    } {
	table_name
	select_column
	select_value
	{ order_by "" }
	{ exclude_columns "" }
	return_url
    }
}

if {![info exists exclude_columns]} { set exclude_columns "" }
if {![info exists return_url] || "" == $return_url} { set return_url [im_url_with_query] }

set user_id [ad_maybe_redirect_for_registration]


# ------------------------------------------------------------------
# 
# ------------------------------------------------------------------

# Get the columns of that table
set elements [list]
set column_sql "
	select	lower(column_name) as column_name
	from	user_tab_columns
	where	upper(table_name) = upper(:table_name)
"
db_foreach cols $column_sql {

    if {[lsearch $exclude_columns $column_name] >= 0} { continue }

    lappend elements $column_name
    set col_name_l10n [lang::message::lookup "" intranet-core.Generic_Table_${table_name}_$column_name $column_name]
    lappend elements [list label $col_name_l10n]
}


list::create \
    -name generic \
    -multirow generic_rows \
    -key $select_column \
    -elements $elements

set ttt {
        name {
            label "name"
        }
        description {
            label "Description"
        }
    }

db_multirow -extend { ttt } generic_rows generic_rows_sql "
	select	*
	from	$table_name
	where	$select_column = :select_value
" {
    set ttt 0
}

