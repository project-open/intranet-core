# /www/intranet/users/skill-update.tcl

ad_page_contract {
    Accepts "Update", "Del" and "Add" buttons from skill-edit.
    @author Guillermo Belcic
    @creation-date October 07, 2003
} {
    user_id:integer,optional,notnull
    user_id_from_search:integer,optional,notnull
    skill_type_id:integer,notnull
    claimed:array,optional
    confirmed:array,optional
    skill_deleted:array,optional
    add_skill_id:integer,optional
    { submit "" }
    { return_url "" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set user_is_employee_p [im_user_is_employee_p $current_user_id]
set user_is_wheel_p [ad_user_group_member [im_wheel_group_id] $current_user_id]
set user_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
set user_admin_p [|| $user_admin_p $user_is_wheel_p]

set todays_date [lindex [split [ns_localsqltimestamp] " "] 0]

if { !$user_admin_p && $user_id != $current_user_id } {
    ad_return_complaint "Insufficient Privileges" "<li>You have insufficient privileges to modify this user."
}

if {[string equal "" $return_url]} {
    set return_url "/intranet/users/view?user_id=$user_id"
}

# ---------------------------------------------------------------
# Deal with Update, Del and Add commands
# ---------------------------------------------------------------

switch $submit {

    "Update" {
	set return_url "/intranet/users/view?user_id=$user_id"
	
	# ------------------- Update Claimed Experience ------------
	set claimed_list [array names claimed]
	foreach claimed_skill_id $claimed_list {
	    if {"" == $claimed_skill_id} { continue }
	    if {"" == $claimed($claimed_skill_id)} { continue }

	    set sqlclaimed "
	update
		im_freelance_skills
	set
		claimed_experience_id=$claimed($claimed_skill_id)
	where
		user_id=:user_id
		and skill_id=:claimed_skill_id
		and skill_type_id=:skill_type_id"

	    if [catch {db_dml update_experience $sqlclaimed} errmsg] {
		ad_return_complaint "DB Error" "
                <li>Error updating experience: $errmsg"
	    }
	}

	# ------------------- Update Confirmed Experience ------------
	set confirmed_list [array names confirmed]
	foreach confirmed_skill_id $confirmed_list {
	    if {"" == $confirmed_skill_id} { continue }
	    if {"" == $confirmed($confirmed_skill_id)} { continue }

	    set sqlconfirmed "
        update
                im_freelance_skills
        set
                confirmed_experience_id=$confirmed($confirmed_skill_id),
		confirmation_user_id=$current_user_id,
		confirmation_date=to_date('$todays_date','YYYY-MM-DD')
        where
                user_id=:user_id
                and skill_id=:confirmed_skill_id
                and skill_type_id=:skill_type_id"

	    if [catch {db_dml update_experience $sqlconfirmed} errmsg] {
		ad_return_complaint "DB Error" "
                <li>Error updating experience: $errmsg"
	    }
	}
    }
    
    "Del" {
	# ------------------- Delete selected Skills ------------
	set delete_list [array names skill_deleted]
	foreach delete_skill $delete_list {
	    set sqldelete "
		delete
		from
			im_freelance_skills
		where
			user_id=:user_id
			and skill_id=:delete_skill
			and skill_type_id=:skill_type_id
"
	    if [catch {db_dml delete_skill $sqldelete} errmsg] {
		ad_return_complaint "DB Error" "
               <li>Error updating experience: $errmsg"
	    }
	}
    }

    "Add" {
	# ------------------- Add a new skill to the list ------------

	if {![info exists add_skill_id]} {
	    ad_return_complaint "Error" "
               <li>You need to specify add_skill_id."
	}

	set unconfirmed_experience [db_string unconfirmed_experience "select category_id from categories where category_type='Intranet Experience Level' and category='Unconfirmed'"]

	set sql "
insert into im_freelance_skills 
(user_id, skill_id, skill_type_id, confirmed_experience_id) values
(:user_id, :add_skill_id, :skill_type_id, :unconfirmed_experience)"

       if [catch { db_dml insert_freelance_skills $sql } errmsg] {
    ad_return_complaint "DB-Error" "<li>The database choked on our insert:
    <blockquote>$errmsg</blockquote>"
        }
    }
}


db_release_unused_handles
ad_returnredirect $return_url
