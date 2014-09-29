# /packages/intranet-core/www/admin/benchmarks/tcl-loop-benchmark.tcl
#
# Copyright (C) 2004-2014 ]project-open[
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.

ad_page_contract {
  Benchmark inserting rows into a temporary table
  @author frank.bergmann@project-open.com
} {
    { num 10000 }
}


set page_title "TCL Loop Benchmark"


set clicks0 [clock clicks]

for {set i 0} {$i < $num} {incr i} {
    set j $i
}

set clicks1 [clock clicks]

set tcl_loops_per_second [expr round($num / (($clicks1 - $clicks0) / 1000000.0)) ]


# db_dml store_result "insert into benchmark_results ('tcl_loop_benchmark', now(), $inserts_per_second)"

