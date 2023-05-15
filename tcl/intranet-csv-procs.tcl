# /packages/intranet-core/tcl/intranet-csv-procs.tcl
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
    CSV Handling

    @author unknown@arsdigita.com
    @author frank.bergmann@project-open.com
}

# ------------------------------------------------------------------
# CSV File Parser
# ------------------------------------------------------------------

ad_proc im_csv_parse_file {
    {-debug 0}
    line
    {separator ","}
} {
    Splits a CVS file into a list of lists. 
    Deals with:
    <ul>
    <li>Fields enclosed by double quotes
    <li>Komma or Semicolon separators
    <li>Quoted field contents
    </ul>
    The state machine can be in one of three states:
    <ul>
    <li>"before_field": Starting reading a field, either starting
        with a quote character (double quote, single quote) or
        with a non-quote character. 
        A separator indicates an empty field.
        A \n indicates the end of the line
    <li>"field": Reading a field, either quoted or not quoted
        The variable "quote" contains the quote character with reading
        the field content.
    <li>"separator": Reading a separator, either a "," or a ";"
    </ul>

} {
    set result_list [list];	# A list of lines
    set line_fields [list];	# A single line that consists of multiple fields
    set pos 0;	   		# The current "cursor" position in the file
    set len [string length $line]
    set quote ""
    set state "before_field"
    set field ""
    set cnt 0

    while {$pos <= $len} {
	set char [string index $line $pos]
	set next_char [string index $line $pos+1]
	if {$debug} {ns_log notice "im_csv_split: pos=$pos, char=$char, state=$state"}

	switch $state {
	    "before_field" {
		# We're before a field. Next char may be a quote or not. Skip white spaces. \n means new line.
		if {"\n" eq $char} {
		    if {$debug} {ns_log notice "im_csv_split: before_field: found end of line: line=$line_fields"}
		    lappend result_list $line_fields
		    set line_fields [list]
		    incr pos
		} elseif {[string is space $char] && $char != $separator} {
		    if {$debug} {ns_log notice "im_csv_split: before_field: found a space: '$char'"}
		    incr pos
		} else {
		    # Skip the char if it was a quote
		    set quote_pos [string first $char "\"'"]
		    if {$quote_pos >= 0} {
			if {$debug} {ns_log notice "im_csv_split: before_field: found quote=$char"};
			set quote $char; 	# Remember the quote char
			incr pos;			# skip the char
		    } else {
			if {$debug} {ns_log notice "im_csv_split: before_field: unquoted field"}
			set quote ""
		    }
		    set field ""; 		    # Initialize the field value for the "field" state
		    set state "field";		    # "Switch" to reading the field content
		}
	    }
	    "field" {
		# We are reading the content of a field until we
		# reach the end, either marked by a matching quote
		# or by the "separator" if the field was not quoted.

		# Check for a duplicated quote when in quoted mode.
		if {"" != $quote && $char eq $quote && $next_char eq $quote} {
		    append field $char
		    incr pos
		    incr pos    
		} else {
		    # Check if we have reached the end of the field
		    # either with the matching quote of with the separator:
		    if {"" != $quote && $char eq $quote || "" == $quote && $char eq $separator} {
			if {$debug} {ns_log notice "im_csv_split: field: found quote or term: $char"}
			# Skip the character if it was a quote
			if {"" != $quote} { incr pos }
			# Trim the field if it was not quoted
			if {"" == $quote} { set field [string trim $field] }
			lappend line_fields $field
			set state "separator"
		    } else {
			if {$debug} {ns_log notice "im_csv_split: field: found a field char: $char"}
			append field $char
			incr pos
		    }
		}
	    }
	    "separator" {
		# We got here after finding the end of a "field".
		# Now we expect a separator or we have to throw an
		# error otherwise. Skip whitespaces, unless the whitespace is the separator...

		if {"\n" eq $char} {
		    if {$debug} {ns_log notice "im_csv_split: separator: found end of line: line=$line_fields"}
		    lappend result_list $line_fields
		    set line_fields [list]
		    incr pos
		} elseif {$separator eq $char} { 
		    set state "before_field";		    # don't inc pos!
		}

		if {[string is space $char]} {
		    if {$debug} {ns_log notice "im_csv_split: separator: found a space: '$char'"}
		    incr pos
		} else {
		    if {$char eq $separator} {
			if {$debug} {ns_log notice "im_csv_split: separator: found separator: '$char'"}
			incr pos
			set state "before_field"
		    } else {
			if {$debug} {ns_log error "im_csv_split: separator: didn't find separator: '$char'"}
			set state "before_field"
		    }
		}
	    }
	    # Switch, while and proc ending
	}

	if {$debug} {
	    incr cnt
	    if {$cnt > 10000} { ad_return_complaint 1 "<pre>overflow:\ncnt=$cnt\npos=$pos\nline_fields=$line_fields\nresult_list=$result_list</pre>" }
	}
    }

    # Add the field to the result if we reach the end of the line
    # in state "field".
    if {"field" == $state} { lappend line_fields $field }
    if {"" ne $line_fields} { lappend result_list $line_fields }

    return $result_list
}


# ------------------------------------------------------------------
# CSV File Parser
# ------------------------------------------------------------------

ad_proc im_count_chars_in_str { str char } {
    Counts the occurrences of char in str
} {
    return [expr [string length $str] - [string length [string map [list $char {}] $str]]]
}


ad_proc im_csv_get_values { file_content {separator ","}} {
    Get the values from a CSV (Comma Separated Values) file
    and generate an list of list of values. Deals with:
    <ul>
    <li>Fields enclosed by double quotes
    <li>Komma or Semicolon separators
    <li>Quoted field contents
    </ul>
    The state machine can be in one of two states:
    <ul>
    <li>"field_start": Starting reading a field, either starting
        with a quote character (double quote, single quote) or
        with a non-quote character.
    <li>"field": Reading a field, either quoted or not quoted
        The variable "quote" contains the quote character with reading
        the field content.
    <li>"separator": Reading a separator, either a "," or a ";"
    </ul>

} {
    set debug 1

    set csv_files [split $file_content "\n"]
    set csv_files_len [llength $csv_files]
    set result_list_of_lists [list]
	
    # get start with 1 because we use the function im_csv_split to get the header
    set line_num 1
    while {$line_num < $csv_files_len} {

	set line [lindex $csv_files $line_num]
	set line [string trimright $line];   # remove trailing ^M
	incr line_num
	# ns_log Notice "im_csv_get_values: Before while: line_num=$line_num, line=$line"

	set quote_count [im_count_chars_in_str $line "\""]
	# ns_log Notice "im_csv_get_values: Before while: line_num=$line_num, quote_count=$quote_count, even=[expr $quote_count % 2]"
	while {$line_num < $csv_files_len && [expr $quote_count % 2]} {
	    # ns_log Notice "im_csv_get_values: In While: line_num=$line_num, quote_count=$quote_count, even=[expr $quote_count % 2]"
	    # We found an uneven number of double quotes in the string.
	    # So there is a long quote-delimited string that continues
	    # in the next line.
	    append line " [lindex $csv_files $line_num]"
	    incr line_num
	    set quote_count [im_count_chars_in_str $line "\""]
	}	

	# Skip compeletely empty lines
	if {$line eq ""} {
	    continue
	}

	# deal with leading "-" in line, which leads to an error later
	if {[regexp {^\-(.*)} $line match rest_of_line]} { set line $rest_of_line }


	if {$debug} {ns_log notice "im_csv_get_values: After While: line_num=$line_num, line=$line"}
	set result_list [im_csv_split $line $separator]
	lappend result_list_of_lists $result_list
    }
    return $result_list_of_lists
}


# ------------------------------------------------------------------
# CSV Line Parser
# ------------------------------------------------------------------

ad_proc im_csv_split { 
    {-debug 0}
    line 
    {separator ","}
} {
    Splits a line from a CSV (Comma Separated Values) file
    into an array of values. Deals with:
    <ul>
    <li>Fields enclosed by double quotes
    <li>Komma or Semicolon separators
    <li>Quoted field contents
    </ul>
    The state machine can be in one of two states:
    <ul>
    <li>"field_start": Starting reading a field, either starting
        with a quote character (double quote, single quote) or
        with a non-quote character.
    <li>"field": Reading a field, either quoted or not quoted
        The variable "quote" contains the quote character with reading
        the field content.
    <li>"separator": Reading a separator, either a "," or a ";"
    </ul>

} {
    set result_list [list]
    set pos 0
    set len [string length $line]
    set quote ""
    set state "field_start"
    set field ""
    set cnt 0

    while {$pos <= $len} {
	set char [string index $line $pos]
	set next_char [string index $line $pos+1]
	if {$debug} {ns_log notice "im_csv_split: pos=$pos, char=$char, state=$state"}

	switch $state {
	    "field_start" {
		# We're before a field. Next char may be a quote
		# or not. Skip white spaces.
		if {[string is space $char] && $char != $separator} {
		    if {$debug} {ns_log notice "im_csv_split: field_start: found a space: '$char'"}
		    incr pos
		} else {
		    # Skip the char if it was a quote
		    set quote_pos [string first $char "\"'"]
		    if {$quote_pos >= 0} {
			if {$debug} {ns_log notice "im_csv_split: field_start: found quote=$char"}
			# Remember the quote char
			set quote $char
			# skip the char
			incr pos
		    } else {
			if {$debug} {ns_log notice "im_csv_split: field_start: unquoted field"}
			set quote ""
		    }
		    # Initialize the field value for the "field" state
		    set field ""
		    # "Switch" to reading the field content
		    set state "field"
		}
	    }
	    "field" {
		# We are reading the content of a field until we
		# reach the end, either marked by a matching quote
		# or by the "separator" if the field was not quoted.

		# Check for a duplicated quote when in quoted mode.
		if {"" != $quote && $char eq $quote && $next_char eq $quote} {
		    append field $char
		    incr pos
		    incr pos    
		} else {
		    # Check if we have reached the end of the field
		    # either with the matching quote of with the separator:
		    if {"" != $quote && $char eq $quote || "" == $quote && $char eq $separator} {
			if {$debug} {ns_log notice "im_csv_split: field: found quote or term: $char"}
			# Skip the character if it was a quote
			if {"" != $quote} { incr pos }
			# Trim the field if it was not quoted
			if {"" == $quote} { set field [string trim $field] }
			lappend result_list $field
			set state "separator"
		    } else {
			if {$debug} {ns_log notice "im_csv_split: field: found a field char: $char"}
			append field $char
			incr pos
		    }
		}
	    }
	    "separator" {
		# We got here after finding the end of a "field".
		# Now we expect a separator or we have to throw an
		# error otherwise. Skip whitespaces, unless the whitespace is the separator...
		if {$char == $separator} { 
		    # don't inc pos!
		    set state "field_start"
		}

		if {[string is space $char]} {
		    if {$debug} {ns_log notice "im_csv_split: separator: found a space: '$char'"}
		    incr pos
		} else {
		    if {$char eq $separator} {
			if {$debug} {ns_log notice "im_csv_split: separator: found separator: '$char'"}
			incr pos
			set state "field_start"
		    } else {
			if {$debug} {ns_log error "im_csv_split: separator: didn't find separator: '$char'"}
			set state "field_start"
		    }
		}
	    }
	    # Switch, while and proc ending
	}

	if {$debug} {
	    incr cnt
	    if {$cnt > 10000} { ad_return_complaint 1 "overflow" }
	}
    }

    # Add the field to the result if we reach the end of the line
    # in state "field".
    if {"field" == $state} {
	lappend result_list $field	
    }

    return $result_list
}


# ---------------------------------------------------------------

ad_proc im_csv_duplicate_double_quotes {arg} {
    This proc duplicates double quotes so that the resulting
    string becomes suitable to be written to a CSV file
    according to the Microsoft Excel CSV conventions
    @see ad_quotehtml
} {
    regsub -all {"} $arg {""} result
    return $result
}


# ---------------------------------------------------------------
# "
# ------------------------------------------------------------------

ad_proc im_csv_guess_separator { file } {
    Returns the separator of the comma separated file
    by determining the character frequency in the file
} {
    foreach char [split $file ""] {
	# The the numeric character code for the character
        scan $char "%c" code
	if {[lsearch {";" "," "|" "\t"} $char] != -1} {
	    # Increment the respective counter
	    set count 0
	    if {[info exists hash($code)]} { set count $hash($code) }
	    set hash($code) [expr {$count+1}]
	}
    }
    
    set max_code ""
    set max_count 0
    foreach key [array names hash] {
	if {$hash($key) > $max_count} {
            set max_code $key
            set max_count $hash($key)
	}
    }
    
    if {[catch {
	set result [format "%c" $max_code]
    } err_msg]} {
	ad_return_complaint 1 "<b>im_csv_guess_separator: Didn't find separator</b>:<br>
	Input:<br><pre>$file</pre>"
	ad_script_abort
    }
    return $result
}





# ------------------------------------------------------------------
# CSV output helpers
# ------------------------------------------------------------------

ad_proc im_cvs_output_findoc_clean_cell {
    -value:required
} {
    Removes HTML tags from cells in order to return the alphanumeric
    value suitable for a CSV (Excel) format
} {
    ns_log Notice "im_cvs_output_findoc_clean_cell: in: val='$value'"
    regsub -all {[\n\t\r]} $value " " value
    set value [string trim $value]
    ns_log Notice "im_cvs_output_findoc_clean_cell: whitespace: val='$value'"

    # Empty value => empty value
    if {"" eq $value} { return $value }
    ns_log Notice "im_cvs_output_findoc_clean_cell: work: val='$value'"

    # Remove enclosing tags (always in <tag ...>xxx</tag> structure)
    set new_value ""
    while {$value ne $new_value} {
	set new_value $value
	set value [im_cvs_output_strip_outer_tag -value $new_value]
    }
    ns_log Notice "im_cvs_output_findoc_clean_cell: nowrap: val='$value'"

    # Single tag? Replace with tag...
    if {[regexp {^\<(\w+)[^\>]*\>$} $value match tag]} {
	ns_log Notice "im_cvs_output_findoc_clean_cell: single tag: tag=$tag, val='$value'"
	set value $tag
    }

    # <option ...>value</option> list? Return the "selected" option.
    set value [im_csv_output_strip_option_list -value $value]

    set value [string trim $value]
    ns_log Notice "im_cvs_output_findoc_clean_cell: out: val='$value'"
    return $value
}


ad_proc im_cvs_output_strip_outer_tag {
    -value:required
} {
    ns_log Notice "im_cvs_output_strip_outer_tag: value=$value"
    
    if {[regexp {^\<(\w+)[^\>]*\>(.*)$} $value match start_tag rest]} {
	# Found a starting tag
	ns_log Notice "im_cvs_output_strip_outer_tag: value=$value, start_tag=$start_tag, rest=$rest"
	if {[regexp {^(.*)\</(\w+)\>$} $rest match content end_tag ]} {
	    # Found an end tag
	    ns_log Notice "im_cvs_output_strip_outer_tag: value=$value, start_tag=$start_tag, end_tag=$end_tag content=$content"
	    if {[string tolower $start_tag] eq [string tolower $end_tag]} {
		ns_log Notice "im_cvs_output_strip_outer_tag: return=$content"
		return $content
	    }
	}
    }
    return $value; # unchanged
}



ad_proc im_csv_output_strip_option_list {
    -value:required
} {
    set org_value [string trim $value]
    # Skip if not starting with <option...>
    if {![regexp -nocase {^\<option[^\>]*\>} $org_value]} {
	return $org_value
    }

    ns_log Notice "im_cvs_output_strip_option_list: in: value=$value"
    regsub -all -nocase {\<\/option\>} $value "\n" value
    ns_log Notice "im_cvs_output_strip_option_list: subs: value=$value"

    set option_list [split $value "\n"]
    ns_log Notice "im_cvs_output_strip_option_list: option_list=$option_list"

    # Search for "<option selected>..."
    set result ""
    foreach option $option_list {
	set option [string trim $option]
	ns_log Notice "im_cvs_output_strip_option_list: option=$option"
	if {[regexp {\<option[^\>]*selected[^\>]*\>(.*)$} $option match result]} {
	    return $result
	}
    }

    return $org_value
}


