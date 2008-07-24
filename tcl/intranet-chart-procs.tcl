# /packages/intranet-core/tcl/intranet-user-procs.tcl
#
# Copyright (C) 2004 ]project-open[
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

# @author alwin.egger@gmx.net

ad_proc -public im_get_chart { x_axis y_axis data { default_dim "" } } {
    Returns HTML Code representing a chart with the values transfered. <br />
    Parameters:<br />
    x_axis [list start_val end_val display_interval unit [scale]]<br />
    y_axis [list start_val end_val display_interval unit [scale]]<br />
    data [list [list x_val y_val size info link (image)]*]<br />
    default_dim [list margin_left margin_top width height arrows_p] (default "")<br />
    REMARK: Other scales the linear ones are not yet supported
} {

# check the parameters and set defaults
    if { [llength $x_axis] < 4 || [llength $x_axis] > 5 } {
	return "im_get_chart needs as first parameter the following list: [list start_val end_val display_interval unit [scale]]"
    } elseif { [llength $x_axis] == 4 } {
	lappend x_axis "lin"
    }

    if { [llength $y_axis] < 4 || [llength $y_axis] > 5 } {
        return "im_get_chart needs as second parameter the following list: [list start_val end_val display_intvrval unit [scale]]"
    } elseif { [llength $y_axis] == 4 } {
        lappend y_axis "lin"
    }


# set some defaults
    if { $default_dim == "" || [llength $default_dim] != 5} {
	set margin_left 0
	set margin_top 30
	set width 500
	set height 200
	set arrows "t"
    } else {
	set margin_left [lindex $default_dim 0]
        set margin_top [lindex $default_dim 1]
        set width [lindex $default_dim 2]
        set height [lindex $default_dim 3]
        set arrows [lindex $default_dim 4]

    }

    set html ""
# add styles used
    append html "<style type=\"text/css\">
<!--
.xAxis {
    position:absolute;
    margin-top:[expr $margin_top + $height + 1]px;
    height:40;
    width:100;
    vertical-align:top;
    text-align:center;
    padding:0px;
}

.yAxis {
    position:absolute;
    margin-left:[expr $margin_left + -49]px;
    height:20;
    width:100;
    vertical-align:top;
    text-align:right;
    padding:0px;
}

.data {
    position:absolute;
    height:50;
    width:50;
    vertical-align:center;
    text-align:center;
    padding:0px;
}
-->
</style>"


# add lines, arrow and all other fix elements of the chart
    append html "<div>
<!-- the axis -->
<div style=\"position:absolute;margin-top:[expr $margin_top + $height]px;margin-left:[expr $margin_left + 50]px;\"><img src=\"images/black.gif\" height=\"1\" width=\"$width\"/></div>
<div style=\"position:absolute;margin-left:[expr $margin_left + 50]px;margin-top:$margin_top\"><img src=\"images/black.gif\" height=\"$height\" width=\"1\"/></div>\n"
    if { $arrows == "t" } {
        append html "<!-- the arrows -->
<div style=\"position:absolute;margin-left:[expr $margin_left + 44]px;margin-top:[expr $margin_top + -8]px\"><img src=\"images/arrow-up.gif\" height=\"15\" width=\"13\"/></div>
<div style=\"position:absolute;margin-top:[expr $margin_top + $height - 6]px;margin-left:[expr $margin_left + 45 + $width]px;\"><img src=\"images/arrow-right.gif\" height=\"13\" width=\"15\"/></div>"
    }
# add x scale
    set x_steps [expr [expr [lindex $x_axis 1] - [lindex $x_axis 0]] / [lindex $x_axis 2]]
    for { set x_values 0 } { $x_values < $x_steps } { incr x_values } {
	set curr_margin_left [expr 1 + $margin_left + [expr $x_values * [expr $width / $x_steps]]]
	set curr_scale [expr [lindex $x_axis 0] + $x_values * [lindex $x_axis 2]]
        append html "<div class=\"xAxis\" style=\"margin-left:[expr $curr_margin_left]px;\"><img src=\"images/black.gif\" height=\"10\" width=\"1\" align=\"top\"/><br/>$curr_scale</div>\n"
    }
append html "<div class=\"xAxis\" style=\"margin-left:[expr $margin_left + $width]px;\"><img src=\"images/clear.gif\" height=\"10\" width=\"1\" align=\"top\"/><br/>[lindex $x_axis 3]</div>\n"
   
# add y scale
    set y_steps [expr [expr [lindex $y_axis 1] - [lindex $y_axis 0]] / [lindex $y_axis 2]]
    for { set y_values 0 } { $y_values < $y_steps } { incr y_values } {
        set curr_margin_top [expr -6 + $margin_top + $height - [expr $y_values * [expr $height / $y_steps]]]
        set curr_scale [expr [lindex $y_axis 0] + $y_values * [lindex $y_axis 2]]
	append html "<div class=\"yAxis\" style=\"margin-top:[expr $curr_margin_top]px;\">$curr_scale <img src=\"images/black.gif\" height=\"1\" width=\"10\" align=\"middle\"/></div>\n"
    }
append html "<div class=\"yAxis\" style=\"margin-top:[expr $margin_top + -10]px;\">[lindex $y_axis 3] <img src=\"images/clear.gif\" height=\"1\" width=\"10\" align=\"middle\"/></div>\n"

# add values received
    for {set data_count 0 } { $data_count < [llength $data] } { incr data_count } {
	set curr_data [lindex $data $data_count]
        set curr_margin_left [expr abs([expr [expr [lindex $curr_data 0] * $width] / [expr [lindex $x_axis 1] - [lindex $x_axis 0]]] + $margin_left + 26)]
        set curr_margin_top [expr abs(($height - [expr [expr [lindex $curr_data 1] * $height] / [expr [lindex $y_axis 1] - [lindex $y_axis 0]]]) + $margin_top - [expr [lindex $curr_data 2] / 2] + 1)]
        if { [llength $curr_data] == 6 } {
             set curr_image [lindex $curr_data 5]
        } else { 
             set curr_image "images/bullet-red.gif"
        }
	append html "<div class=\"data\" style=\"margin-top:[expr $curr_margin_top]px;margin-left:[expr $curr_margin_left]px\"><a href=\"[lindex $curr_data 4]\"><img src=\"$curr_image\" width=\"[lindex $curr_data 2]\" height=\"[lindex $curr_data 2]\" alt=\"[lindex $curr_data 3]\" title=\"[lindex $curr_data 3]\" border=\"0\"/></a></div>\n"
    }

# close div section
    append html "</div>"
    append html "<div><img src=\"images/clear.gif\" width=\"1\" height=\"[expr $height + 100]\" /></div>"
    return $html
}

ad_proc -public im_get_axis { max_value steps } {
    Returns the steps to display on a axis in order to make it look nice
} {
    set dirty_step [expr $max_value / $steps]
    if { $dirty_step < 0.1 } {
	return 0.01
    } elseif { $dirty_step < 1 } {
	return 0.1
    } elseif { $dirty_step < 10 } {
	return 1
    } elseif { $dirty_step < 100 } {
	return 10
    } elseif { $dirty_step < 1000 } {
	return 100
    } elseif { $dirty_step < 10000 } {
	return 1000
    } elseif { $dirty_step < 100000 } {
	return 10000
    } elseif { $dirty_step < 1000000 } {
	return 100000
    } else {
	return 1000000
    }
}