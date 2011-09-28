#!/usr/bin/perl

# --------------------------------------------------------
#
# import-oracle-users.perl
#
# Import users from an Oracle oracle database into ]po[
# (c) 2011 ]project-open[, frank.bergmann@project-open.com
# All rights reserved.
#
# The import uses the SQLPLUS Oracle client to select out
# a number of fields about every users and uses PostgreSQL
# SQL statements in order to create the user on the ]po[
# side.
# --------------------------------------------------------


my $debug = 1;

# Oracle connection parameters
my $ora_user = "<project_open_user>\@<oracle_instance>";
my $ora_pwd = "<project_open_password>";

# PostgreSQL connection parameters
my $pg_pwd = "";
my $pg_datasource = "dbi:Pg:dbname=projop";
my $pg_username = "projop";


# --------------------------------------------------------
# Load libraries
#
use strict;
use FindBin;
use lib $FindBin::Bin;
use IPC::Open2;
use DBI;


# --------------------------------------------------------
# Establish the database connection and
# extract some constants.
#
my $dbh = DBI->connect($pg_datasource, $pg_username, $pg_pwd) ||
    die "Error: import-oracle-users.perl: 1: Unable to connect to database.\n";

my $registered_users_group_id = -2;


my $sth = $dbh->prepare("SELECT group_id from groups where group_name = 'Customers'");
$sth->execute() || die "Error: import-oracle-users.perl: 2: Unable to execute SQL statement.\n";
my $row = $sth->fetchrow_hashref;
my $customer_group_id = $row->{group_id};




# --------------------------------------------------------
# Execute the sqlplus client and return the list of records.
# Oracle needs these variables:
#	export LD_LIBRARY_PATH=.
#	export ORACLE_HOME=.
#	export TNS_ADMIN=.

local (*Reader, *Writer);
my $pid = open2(\*Reader, \*Writer, "/usr/lib/oracle/11.2/client/bin/sqlplus -s '$ora_user/$ora_pwd'");

# Tell Oracle to output clean text without formatting.
print Writer "set colsep ','\n";
print Writer "set sqlprompt ''\n";
print Writer "set echo off\n";
print Writer "set feedback off\n";
print Writer "set pagesize 0\n";
print Writer "set trimspool on\n";
print Writer "set headsep off\n";
print Writer "set linesize 1000\n";
print Writer "set pagesize 0\n";

# The Oracle SQL Statemente. Please replace with
# your equivalente column names. We separate columns
# with "\t" (tab) characters, which are easy to parse.
print Writer "
	SELECT 	trim(USER_NR) || '\t' || 
		FIRST_NAMES || '\t' || 
		LAST_NAME || '\t' || 
		TELEPHONE || '\t' || 
		MOBILE_PHONE || '\t' || 
		EMAIL || '\t' || 
		COMPANY || '\t' || 
		to_char(DISABLE_DATE, 'YYYY-MM-DD')
	FROM	USERS_VIEW_PO;
";

print Writer "exit\n";

# We have to close the writer before we start reading
close Writer;


# --------------------------------------------------------
# Loop through Oracle results and insert into ]po[

my $line;
my $ctr = 0;
while ($line = <Reader>){ 
    
    # --------------------------------------------------------
    # Decompose the line into several variables
    chomp($line);
    (my $user_nr, my $user_first_names, my $user_last_name, my $user_tel, my $user_mobile, my $user_email, my $user_company, my $user_disable_date) = split(/\t/, $line);
    print "Notice: import-oracle-users.perl: ctr=$ctr: user_nr=$user_nr, first_names=$user_first_names, last_name=$user_last_name, email=$user_email, tel=$user_tel, mobile=$user_mobile, company=$user_company, disable_date=$user_disable_date\n" if $debug;


    # --------------------------------------------------------
    # Check completeness
    #
    if ("" eq $user_first_names) {
	print "Warning: import-oracle-users.perl: User '$user_first_names' '$user_last_name' ($user_nr) has empty first_names, skipping\n";
	next;
    }
    if ("" eq $user_last_name) {
	print "Warning: import-oracle-users.perl: User '$user_first_names' '$user_last_name' ($user_nr) has empty last_name, skipping\n";
	next;
    }
    if ("" eq $user_nr) {
	print "Warning: import-oracle-users.perl: User '$user_first_names' '$user_last_name' ($user_nr) has no user_nr, skipping\n";
	next;
    }

    # --------------------------------------------------------
    # Complete missing fields
    #
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

    # --------------------------------------------------------
    # Create a new user if necessary
    #

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

	# Add the original email to a DynField in table "persons"
	$sth = $dbh->prepare("UPDATE persons SET sisla_email = '$user_email' where person_id = $user_id");
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

    $ctr = $ctr + 1;
}

exit 0;

