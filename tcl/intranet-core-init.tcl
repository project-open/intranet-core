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




# ---------------------------------------------------------------
# Callbacks
#
# Generically create callbacks for all "core" object types
# ---------------------------------------------------------------

db_foreach otype_callbacks "select object_type from acs_object_types" {
    
    ad_proc -public -callback ${object_type}_before_create {
	{-object_id:required}
	{-status_id ""}
	{-type_id ""}
    } {
	This callback allows you to execute action before and after every
	important change of object. Examples:
	- Copy preset values into the object
	- Integrate with external applications via Web services etc.
	
	@param object_id ID of the $object_type 
	@param status_id Optional status_id category. 
		   This value is optional. You need to retrieve the status
		   from the DB if the value is empty (which should rarely be the case)
		   This field allows for quick filtering if the callback 
		   implementation is to be executed only on certain object types.
	@param type_id Optional type_id of category.
		   This value is optional. You need to retrieve the status
		   from the DB if the value is empty (which should rarely be the case)
		   This field allows for quick filtering if the callback 
		   implementation is to be executed only on certain object states.
    } -
    
    ad_proc -public -callback ${object_type}_after_create {
	{-object_id:required}
	{-status_id ""}
	{-type_id ""}
    } {
	This callback allows you to execute action before and after every
	important change of object. Examples:
	- Copy preset values into the object
	- Integrate with external applications via Web services etc.
	
	@param object_id ID of the $object_type 
	@param status_id Optional status_id category. 
		   This value is optional. You need to retrieve the status
		   from the DB if the value is empty (which should rarely be the case)
		   This field allows for quick filtering if the callback 
		   implementation is to be executed only on certain object types.
	@param type_id Optional type_id of category.
		   This value is optional. You need to retrieve the status
		   from the DB if the value is empty (which should rarely be the case)
		   This field allows for quick filtering if the callback 
		   implementation is to be executed only on certain object states.
    } -


    
    ad_proc -public -callback ${object_type}_before_update {
	{-object_id:required}
	{-status_id ""}
	{-type_id ""}
    } {
	This callback allows you to execute action before and after every
	important change of object. Examples:
	- Copy preset values into the object
	- Integrate with external applications via Web services etc.
	
	@param object_id ID of the $object_type 
	@param status_id Optional status_id category. 
		   This value is optional. You need to retrieve the status
		   from the DB if the value is empty (which should rarely be the case)
		   This field allows for quick filtering if the callback 
		   implementation is to be executed only on certain object types.
	@param type_id Optional type_id of category.
		   This value is optional. You need to retrieve the status
		   from the DB if the value is empty (which should rarely be the case)
		   This field allows for quick filtering if the callback 
		   implementation is to be executed only on certain object states.
    } -
    
    ad_proc -public -callback ${object_type}_after_update {
	{-object_id:required}
	{-status_id ""}
	{-type_id ""}
    } {
	This callback allows you to execute action before and after every
	important change of object. Examples:
	- Copy preset values into the object
	- Integrate with external applications via Web services etc.
	
	@param object_id ID of the $object_type 
	@param status_id Optional status_id category. 
		   This value is optional. You need to retrieve the status
		   from the DB if the value is empty (which should rarely be the case)
		   This field allows for quick filtering if the callback 
		   implementation is to be executed only on certain object types.
	@param type_id Optional type_id of category.
		   This value is optional. You need to retrieve the status
		   from the DB if the value is empty (which should rarely be the case)
		   This field allows for quick filtering if the callback 
		   implementation is to be executed only on certain object states.
    } -


    
    ad_proc -public -callback ${object_type}_before_delete {
	{-object_id:required}
	{-status_id ""}
	{-type_id ""}
    } {
	This callback allows you to execute action before and after every
	important change of object. Examples:
	- Copy preset values into the object
	- Integrate with external applications via Web services etc.
	
	@param object_id ID of the $object_type 
	@param status_id Optional status_id category. 
		   This value is optional. You need to retrieve the status
		   from the DB if the value is empty (which should rarely be the case)
		   This field allows for quick filtering if the callback 
		   implementation is to be executed only on certain object types.
	@param type_id Optional type_id of category.
		   This value is optional. You need to retrieve the status
		   from the DB if the value is empty (which should rarely be the case)
		   This field allows for quick filtering if the callback 
		   implementation is to be executed only on certain object states.
    } -
    
    ad_proc -public -callback ${object_type}_after_delete {
	{-object_id:required}
	{-status_id ""}
	{-type_id ""}
    } {
	This callback allows you to execute action before and after every
	important change of object. Examples:
	- Copy preset values into the object
	- Integrate with external applications via Web services etc.
	
	@param object_id ID of the $object_type 
	@param status_id Optional status_id category. 
		   This value is optional. You need to retrieve the status
		   from the DB if the value is empty (which should rarely be the case)
		   This field allows for quick filtering if the callback 
		   implementation is to be executed only on certain object types.
	@param type_id Optional type_id of category.
		   This value is optional. You need to retrieve the status
		   from the DB if the value is empty (which should rarely be the case)
		   This field allows for quick filtering if the callback 
		   implementation is to be executed only on certain object states.
    } -

    ad_proc -public -callback ${object_type}_view {
	{-object_id:required}
	{-status_id ""}
	{-type_id ""}
    } {
	This callback tracks acess to the object's main page.
	
	@param object_id ID of the $object_type 
	@param status_id Optional status_id category. 
		   This value is optional. You need to retrieve the status
		   from the DB if the value is empty (which should rarely be the case)
		   This field allows for quick filtering if the callback 
		   implementation is to be executed only on certain object types.
	@param type_id Optional type_id of category.
		   This value is optional. You need to retrieve the status
		   from the DB if the value is empty (which should rarely be the case)
		   This field allows for quick filtering if the callback 
		   implementation is to be executed only on certain object states.
    } -



}
