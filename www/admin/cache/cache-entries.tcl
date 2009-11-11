ad_page_contract {
    Lists memoized data and gives options to view data or flush data
} {
    {pattern_type "contain"}
    {cache_name "util_memoize"}
    {pattern ""}
    {full "f"}
}

set page_title "Search"
set context [list [list "../developer" "Developer's Administration"] [list "." "Cache Control"] $page_title]

set cached_names [ns_cache names $cache_name]

template::multirow create matches key value value_size full_key date raw_date

foreach name $cached_names {
    if {"" == $pattern || [regexp -nocase -- $pattern $name match]} {
	set key [ad_quotehtml $name]
	set safe_key [ad_quotehtml $name]
	if {[catch {set value [ns_cache get $cache_name $name]} errmsg]} {
	    continue
	}
	set raw_date ""
	set date ""
	set value_size [string length $value]
	template::multirow append matches $key $value $value_size $safe_key $date $raw_date
    }
}

