# /pvt/portrait/upload-2.tcl

ad_page_contract {
    adds (or replaces) a user's portrait
 
    @author by philg@mit.edu
    @creation-date September 26, 1999
    @cvs-id upload-2.tcl,v 1.1.2.3 2000/10/25 18:19:02 kevin Exp
} {
    user_id:naturalnum
    upload_file:trim,notnull
    upload_file.tmpfile:tmpfile,optional
    {portrait_comment ""}
    {return_url ""}
}

set upload_user_id [ad_maybe_redirect_for_registration]

if { [empty_string_p $portrait_comment] } {
    set complete_portrait_comment [db_null]
} else {
    set complete_portrait_comment $portrait_comment
}

# determine if add or update
set add_p [db_0or1row update_or_add {
   select portrait_id
     from general_portraits
    where on_what_id = :user_id
      and upper(on_which_table) = 'USERS' 
      and approved_p = 't'
      and portrait_primary_p = 't'
}]

set exception_text ""
set exception_count 0

# this stuff only makes sense to do if we know the file exists
set tmpfile    ${upload_file.tmpfile}
set file_extension [string tolower [file extension $upload_file]]

# remove the first . from the file extension
regsub "\." $file_extension "" file_extension

set guessed_file_type [ns_guesstype $upload_file]

set n_bytes [file size $tmpfile]

# check to see if this is one of the favored MIME types,
# e.g., image/gif or image/jpeg
if { ![empty_string_p [ad_parameter AcceptablePortraitMIMETypes "general-portraits"]] && [lsearch [ad_parameter AcceptablePortraitMIMETypes "general-portraits"] $guessed_file_type] == -1 } {
    incr exception_count
    append exception_text "<li>Your image wasn't one of the acceptable MIME types:   [ad_parameter AcceptablePortraitMIMETypes "general-portraits"]"
}

# strip off the C:\directories... crud and just get the file name
if ![regexp {([^/\\]+)$} $upload_file match client_filename] {
    # couldn't find a match
    set client_filename $upload_file
}

if { ![empty_string_p [ad_parameter MaxPortraitBytes "general-portraits"]] && $n_bytes > [ad_parameter MaxPortraitBytes "general-portraits"] } {
    append exception_text "<li>Your file is too large.  The publisher of [ad_system_name] has chosen to limit portraits to [util_commify_number [ad_parameter MaxPortraitBytes "general-portraits"]] bytes.  You can use PhotoShop or the GIMP (free) to shrink your image.\n"
    incr exception_count
}



if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}
# if an add a portrait 
if { $add_p == 0 } {
   set portrait_id [db_string portrait_unique_key "select general_portraits_id_seq.nextval from dual"]
}

set what_aolserver_told_us ""
if { $file_extension == "jpeg" || $file_extension == "jpg" } {
    catch { set what_aolserver_told_us [ns_jpegsize $tmpfile] }
} elseif { $file_extension == "gif" } {
    catch { set what_aolserver_told_us [ns_gifsize $tmpfile] }
}

# the AOLserver jpegsize command has some bugs where the height comes 
# through as 1 or 2 
# for original picture
if { ![empty_string_p $what_aolserver_told_us] && [lindex $what_aolserver_told_us 0] > 10 && [lindex $what_aolserver_told_us 1] > 10 } {
    set portrait_original_width [lindex $what_aolserver_told_us 0]
    set portrait_original_height [lindex $what_aolserver_told_us 1]
} else {
    set portrait_original_width ""
    set portrait_original_height ""
}

# retrieve the parameters for module general-portraits
set thumbnail_width [ad_parameter ThumbnailWidth "general-portraits" 0]
set thumbnail_height [ad_parameter ThumbnailHeight "general-portraits" 0]
set convert_bin [ad_parameter ConvertBinary "general-portraits"]
set produce_thumbnail_p [ad_parameter ProduceThumbnailsAutomaticallyP "general-portraits" 0]
set approved_p [util_decode [ad_parameter DefaultUploadApprovalPolicy] "open" "t" "f"]

# if the original is smaller than the specific thumbnail size, then why thumbnail
if { ![empty_string_p $portrait_original_width] && \
	![empty_string_p $portrait_original_height] && \
	($portrait_original_width < $thumbnail_width && \
	$portrait_original_height < $thumbnail_height)} {
   set thumbnail_pic $tmpfile
   set portrait_thumbnail_width $portrait_original_width
   set portrait_thumbnail_height $portrait_original_height
} elseif { !$produce_thumbnail_p } {
   set thumbnail_pic $tmpfile
   set portrait_thumbnail_width $thumbnail_width
   set portrait_thumbnail_height $thumbnail_height
} else {
   set thumbnail_pic ${tmpfile}_thumb 

   ns_log Notice "convert cmd: '$convert_bin -geometry ${thumbnail_width}x${thumbnail_height} $tmpfile $thumbnail_pic'"

   if [catch {exec $convert_bin -geometry "${thumbnail_width}x${thumbnail_height}" $tmpfile $thumbnail_pic} errmsg ] {
        ad_return_complaint 1 "You don't have the necessary .so files to do image thumbnail creation.  
                               Please either don't upload a picture or find the correct .so files. <li> $errmsg"
        return
   }
   set what_aolserver_told_us_thumbnail ""
   if { $file_extension == "jpeg" || $file_extension == "jpg" } {
       catch { set what_aolserver_told_us_thumbnail [ns_jpegsize $thumbnail_pic] }
   } elseif { $file_extension == "gif" } {
       catch { set what_aolserver_told_us_thumbnail [ns_gifsize $thumbnail_pic] }
   }

   # the AOLserver jpegsize command has some bugs where the height comes
   # through as 1 or 2
   if { ![empty_string_p $what_aolserver_told_us_thumbnail] && [lindex $what_aolserver_told_us_thumbnail 0] > 10
         && [lindex $what_aolserver_told_us_thumbnail 1] > 10 } {
       set portrait_thumbnail_width [lindex $what_aolserver_told_us_thumbnail 0]
    set portrait_thumbnail_height [lindex $what_aolserver_told_us_thumbnail 1]
   } else {
       set portrait_thumbnail_width ""
       set portrait_thumbnail_height ""
   }

   # convert -geometry maintain the aspect ratio of the image, but if the image is like 100x1000000, then it needs to be reduce
   # to the exact size of the thumbnail
   if { ![empty_string_p $portrait_thumbnail_width] && ![empty_string_p $portrait_thumbnail_height] &&
         ([expr $portrait_thumbnail_width / $thumbnail_width] > 2 || [expr $portrait_thumbnail_height / $thumbnail_height] > 2) } {
      if [catch {exec ${convert_bin}! -geometry "${thumbnail_width}x${thumbnail_height}" $tmpfile $thumbnail_pic} errmsg ] {
         ad_return_complaint 1 "You don't have the necessary .so files to do image thumbnail creation.
                               Please either don't upload a picture or find the correct .so files. <li> $errmsg"
         return
      }
      set portrait_thumbnail_width $thumbnail_width
      set portrait_thumbnail_height $thumbnail_height 
   }
}
ns_log Notice "File: $upload_file, tmp: $tmpfile"


db_dml erase_portrait {
   delete from general_portraits
    where on_what_id = :user_id
      and upper(on_which_table) = 'USERS'
}


if { $add_p == 0 } {
   db_dml insert_pet_portrait "
   insert into general_portraits
      (portrait_id, on_which_table, on_what_id, upload_user_id, portrait_comment, portrait_upload_date, portrait,
       portrait_client_file_name, portrait_file_type, portrait_file_extension, 
       portrait_original_width, portrait_original_height, approved_p, portrait_primary_p,
       portrait_thumbnail, portrait_thumbnail_width, portrait_thumbnail_height)
   values
      (:portrait_id, 'USERS', :user_id, :upload_user_id, :complete_portrait_comment, sysdate, empty_blob(),
       :client_filename, :guessed_file_type, 
       :file_extension, :portrait_original_width, :portrait_original_height, :approved_p, 't',  empty_blob(), 
       :portrait_thumbnail_width, :portrait_thumbnail_height) returning portrait, portrait_thumbnail into :1, :2" -blob_files [list $tmpfile $thumbnail_pic]

} else {

   db_dml pvt_portrait_upload_2_upload {
       update general_portraits
       set portrait = empty_blob(),
	   portrait_comment = :complete_portrait_comment,
	   portrait_client_file_name = :client_filename,
	   portrait_file_type = :guessed_file_type,
	   portrait_file_extension = :file_extension,
	   portrait_original_width = :portrait_original_width,
	   portrait_original_height = :portrait_original_height,
	   portrait_upload_date = sysdate,
	   portrait_thumbnail = empty_blob(),
	   portrait_thumbnail_width = :portrait_thumbnail_width,
	   portrait_thumbnail_height = :portrait_thumbnail_height
       where portrait_id = :portrait_id
       returning portrait, portrait_thumbnail into :1, :2
   } -blob_files [list $tmpfile $thumbnail_pic]
}

db_release_unused_handles

if { [exists_and_not_null return_url] } {
    ad_returnredirect $return_url
} else {
    ad_returnredirect "/intranet/users/view?user_id=$user_id"
}

