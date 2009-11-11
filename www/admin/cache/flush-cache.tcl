ad_page_contract {
    Flush one or more values from util_memoize's cache
} {
    {suffix "util_memoize"}
    {return_url "."}
}

foreach name [ns_cache names $suffix] {
    ns_cache flush $suffix $name
}

ad_returnredirect $return_url
