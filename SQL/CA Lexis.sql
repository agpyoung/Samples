select dl.debtor_id AS incoming_custacct,
    REPLACE(dl.fname, ',', ' ') AS incoming_fname,
    REPLACE(dl.middle, ',', ' ') AS incoming_mname,
    REPLACE(dl.lname, ',', ' ') AS incoming_lname,
    people_suffix_id AS incoming_suffix,
    dl.ssn AS incoming_ssn,
    dl.addr1 AS incoming_address,
    dl.city AS incoming_ccity,
    dl.state AS incoming_sstate,
    dl.zip AS incoming_zip,
    fl.client_id AS incoming_client,
    CASE WHEN(cl.create_dt<curdate()) THEN DATE_FORMAT(cl.create_dt, '%m/%d/%Y') ELSE NULL END AS incoming_agreedate,
    '02' AS Incoming_prodcode
FROM
    debtor_lst dl
        LEFT JOIN
    file_debtor fd ON fd.debtor_id = dl.debtor_id
        LEFT JOIN
    file_lst fl ON fl.file_id = fd.file_id
        LEFT JOIN
    file_case fc ON fc.file_id = fl.file_id
        LEFT JOIN
    case_lst cl ON cl.case_id = fc.case_id
WHERE
    dl.fname <> 'UNKNOWN'
        AND dl.fname IS NOT NULL
        AND dl.lname NOT LIKE '%Deceased%'
        AND dl.dod IS NULL
        AND dl.co_name IS NULL
        AND dl.ssn IS NOT NULL
        AND cl.cur_case_stat_id IN (1,2,4)
        AND fd.debtor_class_id IN(1,2,4,6,13,20,22,25,30,33,38,42)
GROUP BY dl.ssn
ORDER BY dl.state
