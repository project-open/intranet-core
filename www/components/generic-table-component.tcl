# -------------------------------------------------------------
# /packages/intranet-confdb/www/generic-table.tcl
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
# return_url


if {![info exists table_name]} {
    ad_page_contract {
	@author frank.bergmann@project-open.com
    } {
	table_name
	select_column
	select_value
	{ order_by "" }
	return_url
    }
}


if {![info exists return_url] || "" == $return_url} { set return_url [im_url_with_query] }
set user_id [ad_maybe_redirect_for_registration]


# ------------------------------------------------------------------
# 
# ------------------------------------------------------------------

list::create \
    -name generic \
    -multirow generic_rows \
    -key $select_column \
    -elements {
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

