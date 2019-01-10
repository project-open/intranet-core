# /packages/intranet-core/tcl/intranet-groups-permissions.tcl
#
# Copyright (C) 1998-2004 various parties
# The code is based on ArsDigita ACS 3.4
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.

ad_library {
    Compatibility library for a fast port of ]project-open[
    (ACS 3.4 Intranet) to OpenACS

    @author unknown@arsdigita.com
    @author Frank Bergmann (frank.bergmann@project-open.com)
}



ad_proc -public cr_filename_to_mime_type { 
    -create:boolean
    filename
} { 
    given a filename, returns the mime type.  If the -create flag is
    given the mime type will be created; this assumes there is some
    other way such as ns_guesstype to find the filename

    @param create flag whether to create the mime type the routine picks for filename
    @param filename the filename to try to guess a mime type for (the file need not 
           exist, the routine does not attempt to access the file in any way)

    @return mimetype (or */* of unknown)

    @author Jeff Davis (davis@xarg.net)
} { 
    set extension [string tolower [string trimleft [file extension $filename] "."]]
    
    if {$extension eq ""} { 
        return "*/*"
    } 
    
    if {[db_0or1row lookup_mimetype { select mime_type from cr_extension_mime_type_map where extension = :extension }]} { 
        return $mime_type
    } else { 
        set mime_type [string tolower [ns_guesstype $filename]]
        ns_log Debug "guessed mime \"$mime_type\" create_p $create_p" 
        if {(!$create_p) || $mime_type eq "*/*" || $mime_type eq ""} {
            # we don't have anything meaningful for this mimetype 
            # so just */* it.

            return "*/*"
        } 

        # We guessed a type but there was no mapping
        # create it and map it.  We know the extension 
        cr_create_mime_type -extension $extension -mime_type $mime_type -description {}
        
        return $mime_type
    }
}




ad_proc -public cr_import_content {
    {-storage_type "file"}
    -creation_user
    -creation_ip
    -image_only:boolean
    {-image_type "image"}
    {-other_type "content_revision"}
    {-title ""}
    {-description ""}
    {-package_id ""}
    -item_id
    parent_id
    tmp_filename
    tmp_size
    mime_type
    object_name
} {

    Import an uploaded file into the content repository.

    @param storage_type Where to store the content (lob or file), defaults to "file" (later
           a system-wide parameter)
    @param creation_user The creating user (defaults to current user)
    @param creation_ip The creating ip (defaults to peeraddr)
    @param image_only Only allow images
    @param image_type The type of content item to create if the file contains an image
    @param other_type The type of content item to create for a non-image file
    @param title The title given the new revision
    @param description The description of the new revision
    @param package_id Package Id of the package that created the item
    @param item_id If present, make a new revision of this item, otherwise, make a new
           item
    @param parent_id The parent of the content item we create
    @param tmp_filename The name of the temporary file holding the uploaded content
    @param tmp_size The size of tmp_file
    @param mime_type The uploaded file's mime type
    @param object_name The name to give the result content item and revision

    This procedure handles all mime_type details, creating a new item of the appropriate
    type and stuffing the content into either the file system or the database depending
    on "storage_type".  The new revision is set live, and its item_id is returned to the
    caller.

    image_type and other_type should be supplied when the client package
    has extended the image and content_revision types to hold package-specific 
    information.   Checking is done to ensure that image_type has been inherited from
    image, and that other_type has been inherited from content_revision.

    It up to the caller to do any checking on size limitations, etc.

} {

    if { ![info exists creation_user] } {
        set creation_user [ad_conn user_id]
    }

    if { ![info exists creation_ip] } {
        set creation_ip [ad_conn peeraddr]
    }

    # DRB: Eventually we should allow for text storage ... (CLOB for Oracle)

    if { $storage_type ne "file" && $storage_type ne "lob" } {
        return -code error "Imported content must be stored in the file system or as a large object"
    }

    if {$mime_type eq "*/*"} {
        set mime_type "application/octet-stream"
    }

    if {$package_id eq ""} {
	set package_id [ad_conn package_id]
    }

    set old_item_p [info exists item_id]
    if { !$old_item_p } {
        set item_id [db_nextval acs_object_id_seq]
    }

    # use content_type of existing item 
    if {$old_item_p} {
	set content_type [db_string get_content_type ""]
    } else {
        # all we really need to know is if the mime type is mapped to image, we
        # actually use the passed in image_type or other_type to create the object
        if {[db_string image_type_p "" -default 0]} {
            set content_type image
        } else {
            set content_type content_revision
        }
    }
    set revision_id [db_nextval acs_object_id_seq]

    db_transaction {

        if { [db_string is_registered "" -default ""] eq "" } {
            db_dml mime_type_insert ""
            db_exec_plsql mime_type_register ""
        }

        switch $content_type {
            image {

                if { [db_string image_subclass ""] == "f" } {
                    error "Image file must be stored in an image object"
                }
    
                set what_aolserver_told_us ""
                if {$mime_type eq "image/jpeg"} {
                    catch { set what_aolserver_told_us [ns_jpegsize $tmp_filename] }
                } elseif {$mime_type eq "image/gif"} {
                    catch { set what_aolserver_told_us [ns_gifsize $tmp_filename] }
                } elseif {$mime_type eq "image/png"} { 
		    # we don't have built in png size detection
		    # but we want to allow upload of png images
		} else {
                    error "Unknown image type"
                }

                # the AOLserver jpegsize command has some bugs where the height comes 
                # through as 1 or 2 
                if { $what_aolserver_told_us ne "" 
		     && [lindex $what_aolserver_told_us 0] > 10
		     && [lindex $what_aolserver_told_us 1] > 10 
		 } {
                    set original_width [lindex $what_aolserver_told_us 0]
                    set original_height [lindex $what_aolserver_told_us 1]
                } else {
                    set original_width ""
                    set original_height ""
                }

                if { !$old_item_p } {
                    db_exec_plsql image_new ""
                } else {
                    db_exec_plsql image_revision_new ""
                }

            }

            default {

                if { $image_only_p } {
                    error "The file you uploaded was not an image (.gif, .jpg or .jpeg) file"
                }

                if { [db_string content_revision_subclass ""] == "f" } {
                    error "Content must be stored in a content revision object"
                }

                if { !$old_item_p } {
                    db_exec_plsql content_item_new ""
                }
                db_exec_plsql content_revision_new ""

            }
        }

        # insert the attatchment into the database

        switch $storage_type {
            file {
                set filename [cr_create_content_file $item_id $revision_id $tmp_filename]
                db_dml set_file_content ""
            }
            lob {
                db_dml set_lob_content "" -blob_files [list $tmp_filename]
                db_dml set_lob_size ""
            }
        }

    }

    return $revision_id

}



ad_proc -public ad_partner_upvar { var {levels 2} } {
    incr levels
    set return_value ""
    for { set i 1 } { $i <= $levels } { incr i } {
        catch {
            upvar $i $var value
            if { $value ne "" } {
                set return_value $value
                return $return_value
            }
        } err_msg
    }
    return $return_value
}


ad_proc -public im_new_object_id { } {
    Create a new project and and setup a new administration group
} {
    db_nextval "acs_object_id_seq"
}


ad_proc -public im_state_widget { 
    {default ""} 
    {select_name "usps_abbrev"}
} {
    Returns a state selection box
} {
    set widget_value "<select name=\"$select_name\">\n"
    if { $default eq "" } {
        append widget_value "<option value=\"\" selected=\"selected\">[_ intranet-core.Choose_a_State]</option>\n"
    }

    db_foreach all_states {
	select state_name, abbrev from us_states order by state_name
    } {
        if { $default == $abbrev } {
            append widget_value "<option value=\"$abbrev\" selected=\"selected\">$state_name</option>\n" 
        } else {            
            append widget_value "<option value=\"$abbrev\">$state_name</option>\n"
        }
    }
    append widget_value "</select>\n"
    return $widget_value
}

ad_proc -public im_country_widget { 
    {default ""} 
    {select_name "country_code"} 
    {size_subtag ""}
} {
    Returns a country selection box
} {
    set widget_value "<select name=\"$select_name\" $size_subtag>\n"
    if { $default eq "" } {
	append widget_value "<option value=\"\" selected=\"selected\">[_ intranet-core.Choose_a_Country]</option>\n"
    }
    db_foreach all_countries {
	select country_name, iso from country_codes order by country_name 
    } {
        if { $default == $iso } {
            append widget_value "<option value=\"$iso\" selected=\"selected\">$country_name</option>\n" 
        } else {            
            append widget_value "<option value=\"$iso\">$country_name</option>\n"
        }
    }
    append widget_value "</select>\n"
    return $widget_value
}

