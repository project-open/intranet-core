# Sample Includelet, to be included as a ]po[ portlet
#

set text "<h1>Hello World</h1>\n"

# The calling page may pass some variables to this
# includelet, let's show them for debugging purposes.

set vars [info vars]
foreach var $vars {
    # Exclude system vars
    if {[regexp {__} $var match]} {continue} 

    # Exclude "text" variable
    if {[regexp {^text$} $var match]} {continue} 

    set cmd "set $var"
    append text "<li>$var = [eval $cmd]"
}

