# /www/intranet/preferences-reset.tcl

ad_page_contract { 
    Resets the user's preferences for status reports to default

    @author Michael Pih (pihman@arsdigita.com)
    @creation-date 1 August 2000
    @cvs-id preferences-reset.tcl,v 1.1.2.1 2000/08/16 21:28:43 mbryzek Exp

} {}

# make sure the user is logged in
set user_id [ad_maybe_redirect_for_registration]

# delete any of the user's existing status report preferences
db_dml reset_status_report_preferences \
	"delete from im_status_report_preferences
         where user_id = :user_id"

db_release_unused_handles

ad_returnredirect preferences-edit
