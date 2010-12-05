-- branch io_rewiring for ttcopy

INSERT INTO job ( job_id, client_min_rev, priority, name, `desc` )
VALUES (
    3, 257, 3, 'Parrot test (branch io_rewiring)', NULL
);

INSERT INTO jobp ( jobp_id, job_id, rep_path_id, `order`, name, `desc`, max_age, depends_on_id, extends )
VALUES (
    3, 3, 438, 3, 'sole', NULL,    7*24,  NULL, 0
);

INSERT INTO jobp_cmd ( jobp_cmd_id, jobp_id, `order`, cmd_id )
VALUES (
    11, 3, 1, 1 ), (
    12, 3, 2, 2 ), (
    13, 3, 3, 4 ), (
    14, 3, 4, 5 ), (
    15, 3, 5, 6
);


INSERT INTO machine_job_conf ( machine_job_conf_id, machine_id, rep_id, rep_path_id, job_id, priority )
VALUES (
    13, 7, NULL, NULL, 3,    3
);


INSERT INTO fspath_select ( fspath_select_id, fsfile_type_id, rep_path_id, fspath_id )
VALUES (
    4, 1, 438, 3  ), (   -- or 3 -> 1 for stable
    5, 2, 438, 3         -- or 3 -> 1 for stable
);
