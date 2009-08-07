ad_library {
    Initialization for intranet-core
    
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date 16 August, 2007
    @cvs-id $Id$
}

# Create a global cache for im_profile entries.
# The cache is bound by global timeout of 1 hour currently.
ns_cache create im_profile -timeout [ad_parameter -package_id [im_package_core_id] CacheTimeoutProfiles "" 3600]


# Create a global cache for im_company entries.
# The cache is bound by global timeout of 1 hour currently.
ns_cache create im_company -timeout [ad_parameter -package_id [im_package_core_id] CacheTimeoutCompanies "" 3600]


