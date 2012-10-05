# /packages/intranet-core/www/report-bug-on-page.tcl
#
# Copyright (C) 1998-2004 various parties
# The code is based on ArsDigita ACS 3.4

ad_page_contract { 
    Prepare to send out an error report
    @author frank.bergmann@project-open.com
} {
    page_url
}

# ---------------------------------------------------------------
# Security & Defaults
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set page_title "[lang::message::lookup "" intranet-core.Report_but_on_page "Report a Bug or Misbehaviour"]"
set context_bar [im_context_bar $page_title]

# ---------------------------------------------------------------
# Other variables
# ---------------------------------------------------------------

set tell_us_what_is_wrong_msg [lang::message::lookup "" intranet-core.Tell_us_what_is_wrong "Tell us what is wrong with this page"]
set tell_us_what_should_be_right_msg [lang::message::lookup "" intranet-core.Tell_us_what_should_be_right "Tell us what should be in the page instead"]


