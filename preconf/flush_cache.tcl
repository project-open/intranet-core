ad_page_contract {} { user_id:integer,notnull }
ad_user_login $user_id
ns_cache_flush util_memoize
ns_cache_flush im_profile 
ns_return 200 text/html ""
