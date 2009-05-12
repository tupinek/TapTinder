start transaction;

SET FOREIGN_KEY_CHECKS=0;

-- delete test results
truncate table trun;
truncate table rep_test;
truncate table tfile;
truncate table ttest;
truncate table tskipall_msg;
truncate table tdiag_msg;

SET FOREIGN_KEY_CHECKS=1;

commit;
