start transaction;

SET FOREIGN_KEY_CHECKS=0;

-- delete test results
delete from trun;
delete from rep_test;
delete from tfile;
delete from ttest;
delete from tskipall_msg;
delete from tdiag_msg;

SET FOREIGN_KEY_CHECKS=1;

commit;
