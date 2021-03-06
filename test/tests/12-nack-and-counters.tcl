source "../tests/includes/init-tests.tcl"
source "../tests/includes/job-utils.tcl"

test "NACK immediately re-enqueue the job" {
    set qname [randomQueue]
    set id [R 0 addjob $qname myjob 5000 replicate 3 retry 3]
    set job [R 0 show $id]
    assert {$id ne {}}
    R 0 getjob from $qname

    assert {[count_job_copies $job queued] == 0}
    R 0 NACK $id
    assert {[count_job_copies $job queued] >= 0}
}

test "GET WITHCOUNTERS can retrieve NACKs count" {
    set qname [randomQueue]
    set id [R 0 addjob $qname myjob 5000 replicate 3 retry 3]
    set job [R 0 show $id]
    assert {$id ne {}}
    set myjob [lindex [R 0 getjob from $qname] 0]

    R 0 NACK $id
    set myjob [lindex [R 0 getjob withcounters from $qname] 0]
    assert {[lindex $myjob 4] > 0}
}

test "GET WITHCOUNTERS can retrieve additional deliveries count" {
    set qname [randomQueue]
    set id [R 0 addjob $qname myjob 5000 replicate 3 retry 3]
    set job [R 0 show $id]
    assert {$id ne {}}
    set myjob [lindex [R 0 getjob from $qname] 0]

    wait_for_condition 1000 50 {
        [count_job_copies $job queued] >= 1
    } else {
        fail "Job never rescheduled while it should"
    }
    set myjob [lindex [R 0 getjob withcounters from $qname] 0]
    assert {[lindex $myjob 6] > 0}
}
