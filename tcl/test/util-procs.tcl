ad_library {
    Automated tests for intranet-util-procs

    @author Chirstof Damian <christof.damian@project-open.com>
}


#
# unlist
#

aa_register_case -cats { api } util_procs_unlist {
    Test the small unlist proc
} {    
    aa_log "util_procs_unlist"


    set a "a_not_set"
    set d "d_not_set"
    unlist { a_set b_set c_set } a b c d
    
    aa_equals "variable overwritten" $a "a_set"

    aa_true "all variables set" [expr {$a=="a_set" && $b=="b_set" && $c=="c_set"}]
    
    aa_equals "additional variable cleared" $d ""
    
}

#
# multirow_sort_tree
# 


aa_register_case -cats { api } util_procs_multirow_sort_tree {
    Test multirow_sort_tree
} {
    # 
    # template::multirow sort seems to be broken in test scripts. I guess
    # it expects a certain stack to do its upvar magic for the adp pages.
    # thats why I have to use the multirow_sort_tree -nosort option in the
    # tests
    #

    template::multirow create test id parent text number e1 e2  
    template::multirow append test 1  0      a    2      1  2
    template::multirow append test 2  1      b    3      2  5 
    template::multirow append test 3  1      c    4      3  6
    template::multirow append test 4  1      d    5      6  9
    template::multirow append test 5  3      e    1      4  7
    template::multirow append test 6  3      f    2      5  8
    template::multirow append test 7  1      g    1      7  3
    template::multirow append test 8  1      h    2      8  4
    template::multirow append test 9  0      i    1      9  1

    # sorting messes up in aa_ scripts
    aa_log "multirow_sort_tree -nosort test id parent text"
    multirow_sort_tree -nosort test id parent text

    template::multirow foreach test {
	aa_equals "expected $id at $e1 and it is at $tree_order" $e1 $tree_order
    }

    aa_log "multirow_sort_tree -nosort -integer test id parent number"
    multirow_sort_tree -nosort -integer test id parent number

    template::multirow foreach test {
	aa_equals "expected $id at $e2 and it is at $tree_order" $e2 $tree_order
    }

}



