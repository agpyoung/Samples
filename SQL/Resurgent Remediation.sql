SELECT * FROM OPENQUERY
(ADB,
    '
        SELECT 
        TRIM(AROOT.ACCTNUM) [Account Number]
        , CLAIM.OPENDATE [Open Date]
        , STATCODE.CODE + '' - '' + STATCODE.DESCRIPT [Status]
        , CASE 
			WHEN 
			FNAMEVALUE(VARVALUE.VARS, ''STOL'') IS NOT NULL 
			AND FNAMEVALUE(VARVALUE.VARS, ''STOL'') <> ''''
				THEN CAST(FNAMEVALUE(VARVALUE.VARS, ''STOL'') as SQL_DATE) 
			ELSE NULL
		END [SOL DATE]
        , TRIM(PLA.LASTNAME)+ 
            CASE 
                WHEN(TRIM(PLA.NAME2)='''') 
                    THEN '''' 
                ELSE '', ''+TRIM(PLA.NAME2) 
            END + 
            CASE  
                WHEN(TRIM(PLA.NAME2) = '''' or TRIM(PLA.MISC) = '''') 
                    THEN '''' 
                ELSE '', ''+TRIM(PLA.MISC) 
            END [Plaintiff]
        , TRIM(DEM.FIRSTNAME) + '' '' + TRIM(DEM.LASTNAME) [Defendant]
        , FILING.FILINGDATE [Filing Date]
        , HEAR.COMMENTS [Hearing Notes]
        FROM AROOT
        JOIN CLAIM on CLAIM.PKAROOT = AROOT.PKAROOT
        JOIN STATCODE on STATCODE.PKSTATCODE = CLAIM.PKSTATCODE
        JOIN 
		(
			SELECT 
			ACOMP.PKAROOT,
			ACOMP.PKENTITY
			FROM
			ACOMP
			WHERE 
			TRIM(ACOMP.ENTRYTYPE) = ''DEB''
		) AC ON AC.PKAROOT = AROOT.PKAROOT
	    JOIN 
		(
			SELECT 
			DEMOG.FIRSTNAME,
			DEMOG.MIDDLENAME,
			DEMOG.LASTNAME,
            DEMOG.STATE,
			DEMOG.PKDEMOG
			FROM
			DEMOG
		) DEM ON DEM.PKDEMOG = AC.PKENTITY
        JOIN CLIENT ON CLIENT.PKCLIENT = AROOT.PKCLIENT
        JOIN CLIENTGP ON CLIENTGP.PKCLIENTGP = CLIENT.PKCLIENTGP AND CLIENTGP.CODE = ''I''
        LEFT JOIN VARVALUE on VARVALUE.PKPRIME = AROOT.PKAROOT 
        LEFT JOIN FILING on FILING.PKAROOT = AROOT.PKAROOT
        LEFT JOIN 
        (
            SELECT 
            PKAROOT, 
            PKENTITY,
            PKACOMP,
            ORDINAL
            FROM ACOMP 
            WHERE 
            TRIM(ACOMP.ENTRYTYPE) = ''PLA''
        ) PACMP ON PACMP.PKAROOT = AROOT.PKAROOT
        LEFT JOIN 
            (
                SELECT 
                LASTNAME,
                NAME2,
                MISC,
                PKDEMOG
                FROM DEMOG 
            ) PLA ON PLA.PKDEMOG = PACMP.PKENTITY
        LEFT JOIN 
        (
            SELECT
                * 
            FROM HEARING
            WHERE
            COMMENTS IS NOT NULL
        ) HEAR ON HEAR.PKAROOT = AROOT.PKAROOT
        WHERE
        STATCODE.CODE < ''500''
        AND LEFT(CLIENT.ID, 2) = ''FL'' 
        AND CLAIM.OPENDATE >= ''02/01/2023''
        ORDER BY 
        STATCODE.CODE
    '
)
