#!/usr/bin/perl

# --------------------------------------------------------
#
# import-oracle-users.perl
#
# Import users from an Oracle into ]po[
# (c) 2006 ]project-open[, frank.bergmann@project-open.com
# All rights reserved.
#
# --------------------------------------------------------


my $debug = 1;

# Oracle connection parameters
my $ora_user = "<user>@<instance>";
my $ora_pwd = "<passwd>";

# PostgreSQL connection parameters
my $pg_pwd = "";
my $pg_datasource = "dbi:Pg:dbname=projop";
my $pg_username = "projop";

my $logfile = "/var/log/import-oracle-users.log";


# --------------------------------------------------------
# Load libraries
#
use strict;
use FindBin;
use lib $FindBin::Bin;
use IPC::Open2;
use DBI;



# --------------------------------------------------------
# Create a log file for the Oracle output
open(L, ">> $logfile") || die "import-oracle-users.perl: Couldn't open $logfile";
print L "import-oracle-users.perl: Starting Import\n";


# --------------------------------------------------------
# Establish the database connection and
# extract some constants.
#
my $dbh = DBI->connect($pg_datasource, $pg_username, $pg_pwd) ||
    die "Error: import-oracle-users.perl: 1: Unable to connect to database.\n";

my $registered_users_group_id = -2;


# --------------------------------------------------------
# Get the ID of the group "Customers"
#
my $sth = $dbh->prepare("SELECT group_id from groups where group_name = 'Customers'");
$sth->execute() || die "Error: import-oracle-users.perl: 2: Unable to execute SQL statement.\n";
my $row = $sth->fetchrow_hashref;
my $customer_group_id = $row->{group_id};


# --------------------------------------------------------
# Get the company_id of a specific customer
#
my $sth = $dbh->prepare("SELECT company_id from im_companies where company_path = '<company_path>'");
$sth->execute() || die "Error: import-oracle-users.perl: 2a: Unable to execute SQL statement.\n";
my $row = $sth->fetchrow_hashref;
my $customer_id = $row->{company_id};


# --------------------------------------------------------
# Execute the sqlplus client and
# return the list of records
#

# Oracle needs these variables
# export LD_LIBRARY_PATH=.
# export ORACLE_HOME=.
# export TNS_ADMIN=.

local (*Reader, *Writer);
my $pid = open2(\*Reader, \*Writer, "/usr/lib/oracle/11.2/client/bin/sqlplus -s '$ora_user/$ora_pwd'");

print Writer "set colsep ','\n";
print Writer "set sqlprompt ''\n";
print Writer "set echo off\n";
print Writer "set feedback off\n";
print Writer "set pagesize 0\n";
print Writer "set trimspool on\n";
print Writer "set headsep off\n";
print Writer "set linesize 1000\n";
print Writer "set pagesize 0\n";

print Writer "
	SELECT 	trim(USUARIO) || '\t' || 
		NOMBRE || '\t' || 
		APELLIDOS || '\t' || 
		TELEFONO || '\t' || 
		MOVIL || '\t' || 
		EMAIL || '\t' || 
		COOPERATIVA || '\t' || 
		to_char(FEC_BAJA, 'YYYY-MM-DD')
	FROM	SGEN_V_USUARIOS_PO;
";

print Writer "exit\n";

# We have to close the Writer before reading
close Writer;


# --------------------------------------------------------
# Loop through Oracle results and
# insert into ]po[

my $line;
my $ctr = 0;
while ($line = <Reader>){ 

    # Write Oracle output to logfile
    print L $line;
    
    # --------------------------------------------------------
    # Decompose the line into several variables
    chomp($line);
    (my $user_nr, my $user_first_names, my $user_last_name, my $user_tel, my $user_mobile, my $user_email, my $user_company, my $user_disable_date) = split(/\t/, $line);
    print "Notice: import-oracle-users.perl: ctr=$ctr: user_nr=$user_nr, first_names=$user_first_names, last_name=$user_last_name, email=$user_email, tel=$user_tel, mobile=$user_mobile, company=$user_company, disable_date=$user_disable_date\n" if $debug;


    # --------------------------------------------------------
    # Check completeness
    #
    if ("" eq $user_first_names) {
	print "Error: import-oracle-users.perl: User '$user_first_names' '$user_last_name' ($user_nr) has empty first_names, skipping\n";
	next;
    }
    if ("" eq $user_last_name) {
	print "Error: import-oracle-users.perl: User '$user_first_names' '$user_last_name' ($user_nr) has empty last_name, skipping\n";
	next;
    }
    if ("" eq $user_nr) {
	print "Error: import-oracle-users.perl: User '$user_first_names' '$user_last_name' ($user_nr) has no user_nr, skipping\n";
	next;
    }

    # --------------------------------------------------------
    # Complete missing fields
    #
    
    # Save the original email for reference
    my $sisla_email = $user_email;

    if ("" eq $user_email) {
	print "Warning: import-oracle-users.perl: User '$user_first_names' '$user_last_name' ($user_nr) has no email, creating dummy email\n";
	$user_email = "$user_first_names.$user_last_name\@lagunaro.es";
    }

    # --------------------------------------------------------
    # Check if the user already exists
    #
    my $sth = $dbh->prepare("SELECT user_id from users where username = '$user_nr'");
    $sth->execute() || die "Error: import-oracle-users.perl: 3: Unable to execute SQL statement.\n";
    my $row = $sth->fetchrow_hashref;
    my $user_id = $row->{user_id};

    if ("" == $user_id) {
	print "Notice: import-oracle-users.perl: Creating new user\n" if $debug;
	$sth = $dbh->prepare("
                SELECT acs__add_user(
                        null, 'user', now(), 0, '0.0.0.0',
                        null, '$user_nr', '$user_email.$user_nr', null,
                        '$user_first_names', '$user_last_name',
                        'hashed_password', 'salt',
                        '$user_nr', 't', 'approved'
                ) as user_id
        ");
	$sth->execute() || die "Error: import-oracle-users.perl: 4: Unable to execute SQL statement.\n";
        my $row = $sth->fetchrow_hashref;
        my $user_id = $row->{user_id};

	# Insert rows in users_contact and im_employees
	$sth = $dbh->prepare("INSERT INTO users_contact (user_id) VALUES ($user_id)");
	$sth->execute() || die "Error: import-oracle-users.perl: 5: Unable to execute SQL statement.\n";
	$sth = $dbh->prepare("INSERT INTO im_employees (employee_id) VALUES ($user_id)");
	$sth->execute() || die "Error: import-oracle-users.perl: 6: Unable to execute SQL statement.\n";

	# make the user an approved member of "registered_users"
	my $sth = $dbh->prepare("SELECT count(*) as exists_p from acs_rels where object_id_one = $registered_users_group_id and object_id_two = $user_id and rel_type = 'membership_rel'");
	$sth->execute() || die "Error: import-oracle-users.perl: 7a: Unable to execute SQL statement.\n";
	my $row = $sth->fetchrow_hashref;
	my $exists_p = $row->{exists_p};
	if (!$exists_p) {
	    $sth = $dbh->prepare("SELECT membership_rel__new($registered_users_group_id, $user_id)");
	    $sth->execute() || die "Error: import-oracle-users.perl: 7b: Unable to execute SQL statement.\n";
	}
    }

    # Add the original email to a DynField in table "persons"
    $sth = $dbh->prepare("UPDATE persons SET sisla_email = '$sisla_email' where person_id = $user_id");
    $sth->execute() || die "Error: import-oracle-users.perl: 6: Unable to execute SQL statement.\n";


    if ("" eq $user_id) {
	print "Error: import-oracle-users.perl: Found empty user_id for user_nr=$user_nr.\n";
	next;
    }


    # --------------------------------------------------------
    # Check if the user is member of group "customers" and make him a member otherwise.
    #
    my $sth = $dbh->prepare("
	SELECT	count(*) as exists_p 
	from	acs_rels 
	where	object_id_one = $customer_group_id and 
		object_id_two = $user_id and 
		rel_type = 'membership_rel'
    ");
    $sth->execute() || die "Error: import-oracle-users.perl: 8: Unable to execute SQL statement.\n";
    my $row = $sth->fetchrow_hashref;
    my $exists_p = $row->{exists_p};
    print "Notice: import-oracle-users.perl: Customer group membership exists_p=$exists_p\n" if $debug;
    if (!$exists_p) {
	$sth = $dbh->prepare("SELECT membership_rel__new($customer_group_id, $user_id)");
	$sth->execute() || die "Error: import-oracle-users.perl: 9: Unable to execute SQL statement.\n";
    }


    # --------------------------------------------------------
    # Check if the user is member of his company already and make hima member otherwise
    #
    my $sth = $dbh->prepare("
	SELECT	count(*) as exists_p 
	from	acs_rels r,
		im_biz_object_members bom
	where	r.rel_id = bom.rel_id and
		r.object_id_one = $customer_id and 
		r.object_id_two = $user_id and 
		rel_type = 'membership_rel'
    ");
    $sth->execute() || die "Error: import-oracle-users.perl: 9: Unable to execute SQL statement.\n";
    my $row = $sth->fetchrow_hashref;
    my $exists_p = $row->{exists_p};
    print "Notice: import-oracle-users.perl: Customer membership exists_p=$exists_p\n" if $debug;
    if (!$exists_p) {
	$sth = $dbh->prepare("SELECT im_biz_object_member__new(null, 'im_biz_object_member', $customer_id, $user_id, 1300, 624, '0.0.0.0')");
	$sth->execute() || die "Error: import-oracle-users.perl: 9a: Unable to execute SQL statement.\n";
    }


    # --------------------------------------------------------
    # Update user information
    print "Notice: import-oracle-users.perl: Updating users_contact for user_id=$user_id.\n";
    $sth = $dbh->prepare("
	UPDATE users_contact SET
		work_phone = '$user_tel',
		cell_phone = '$user_mobile'
	WHERE user_id = $user_id
    ");
    $sth->execute() || die "Error: import-oracle-users.perl: 10: Unable to execute SQL statement.\n";

    print "Notice: import-oracle-users.perl: End of processing user_id=$user_id\n" if $debug;



    # --------------------------------------------------------
    # User status = "deleted" if the $user_disable_date is set
    # -2 represents the "Registered Users" magic object
    #
    my $member_state = "approved";
    if ("" ne $user_disable_date) {
	$member_state = "banned";
    }

    print "Notice: import-oracle-users.perl: Updating user_status\n";
    $sth = $dbh->prepare("
	UPDATE membership_rels 
	SET member_state = '$member_state'
	WHERE rel_id in (
			select	rel_id
			from	acs_rels r
			where	object_id_one = -2 and
				object_id_two = $user_id and
				rel_type = 'membership_rel'
		)
    ");
    $sth->execute() || die "Error: import-oracle-users.perl: 10: Unable to execute SQL statement.\n";

    $ctr = $ctr + 1;
}

# Close Logfile
close(L);

exit 0;

