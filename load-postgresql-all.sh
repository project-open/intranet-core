#!/bin/bash

#
# load-postgresql-all.sh
# V1.0, 2004-09-24
#
# (Re-) loads the PostgreSQL SQL models of all modules
#


psql projop -f intranet-big-brother/sql/postgresql/intranet-big-brother-create.sql
psql projop -f intranet-core/sql/postgresql/intranet-core-create.sql
psql projop -f intranet-cost/sql/postgresql/intranet-cost-create.sql
psql projop -f intranet-filestorage/sql/postgresql/intranet-filestorage-create.sql
psql projop -f intranet-forum/sql/postgresql/intranet-forum-create.sql
psql projop -f intranet-freelance/sql/postgresql/intranet-freelance-create.sql
psql projop -f intranet-hr/sql/postgresql/intranet-hr-create.sql
psql projop -f intranet-invoices/sql/postgresql/intranet-invoices-create.sql
psql projop -f intranet-payments/sql/postgresql/intranet-payments-create.sql
psql projop -f intranet-timesheet/sql/postgresql/intranet-timesheet.sql
psql projop -f intranet-trans-invoices/sql/postgresql/intranet-trans-invoices-create.sql
psql projop -f intranet-translation/sql/postgresql/intranet-translation-create.sql

