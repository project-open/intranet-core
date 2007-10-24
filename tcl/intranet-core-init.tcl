ad_library {
    Initialization for intranet-core
    
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date 16 August, 2007
    @cvs-id $Id$
}

# Initialize the search "semaphore" to 0.
# There should be only one thread indexing files at a time...
nsv_set intranet_core audit_sweep_semaphore 0


# Schedule the audit function (creates a copy of all active main projects...) every few hours
#
set interval_hours [parameter::get_from_package_key -package_key intranet-core -parameter AuditProjectProgressIntervalHours -default 0]
if {0 != $interval_hours} {
    ad_schedule_proc -thread t 10 im_core_audit_sweeper
}

