
DECLARE @Phones TABLE 
(
	[ROW] INT
	,[PKAROOT] VARCHAR(8)
	,[PHONE] VARCHAR(10)
)
INSERT INTO @Phones
	SELECT 
		ROW_NUMBER() OVER (ORDER BY PHONE) [ROW]
		, PKAROOT
		, PHONE 
	FROM 
		OPENQUERY
			(ADB,
				'
					SELECT 
						PKAROOT
						, PHONE 
					FROM
						 MULTPH 
					WHERE 
						(
							PHTYPE = ''C''
							OR 
							ISCELL = 1
						)
						AND PHONEOK = 0
						AND SOURCE IN 
						(
							''Consumer''
							,''Consumer-Verbal''
							,''Consumer-Written''
							,''Consumer-Written/TLO''
							,''Client Update''
							,''CLIENT''
							,''''
						)
				'	
			)
SELECT 
	[Account Number]
	,'TMPPLLC' [Account Namespace]
	, 'SIGNER' [Account Relationship]
	,[Account Open Date]
	,'2e3cb2e6-bb97-4728-a0a6-036b7313ac88' [brandID]
	,'PRESETTLEMENT' [Product Type]
	,'account' [Product Description]
	,CONVERT(DATE, GETDATE()) [Date Assigned]
	,CONVERT(DATE, GETDATE() + 90) [Expected Retraction Date]
	,[First Name]
	,[Last Name]
	,[Middle Name]
	,'' [Email Address 1]
	,'' [Email Address 2]
	,'' [Email Address 3]
	,(
		Select 
			PHONE 
		FROM 
			@Phones 
		WHERE 
			[Account Root] = PKAROOT
		ORDER BY ROW 
		OFFSET 0 ROWS
		FETCH NEXT 1 ROWS ONLY
	) [Telephone 1]
    , CASE
		WHEN (
			Select 
				PHONE 
			FROM 
				@Phones 
			WHERE 
				[Account Root] = PKAROOT
			ORDER BY ROW 
			OFFSET 0 ROWS
			FETCH NEXT 1 ROWS ONLY
		) IS NOT NULL 
			THEN 'CELL'
		ELSE '' 
	END [Telephone Type 1]
	, CASE
		WHEN (
			Select 
				PHONE 
			FROM 
				@Phones 
			WHERE 
				[Account Root] = PKAROOT
			ORDER BY ROW 
			OFFSET 0 ROWS
			FETCH NEXT 1 ROWS ONLY
		) IS NOT NULL 
			THEN 'YES'
		ELSE 'NO' 
	END [SMS Consent Flag Telephone 1]
	,(
		Select 
			PHONE 
		FROM 
			@Phones 
		WHERE 
			[Account Root] = PKAROOT
		ORDER BY ROW 
		OFFSET 1 ROWS
		FETCH NEXT 1 ROWS ONLY
	) [Telephone 2]
	, CASE
		WHEN (
			Select 
				PHONE 
			FROM 
				@Phones 
			WHERE 
				[Account Root] = PKAROOT
			ORDER BY ROW 
			OFFSET 1 ROWS
			FETCH NEXT 1 ROWS ONLY
		) IS NOT NULL 
			THEN 'CELL'
		ELSE '' 
	END [Telephone Type 2]
	, CASE
		WHEN (
			Select 
				PHONE 
			FROM 
				@Phones 
			WHERE 
				[Account Root] = PKAROOT
			ORDER BY ROW 
			OFFSET 1 ROWS
			FETCH NEXT 1 ROWS ONLY
		) IS NOT NULL 
			THEN 'YES'
		ELSE 'NO' 
	END [SMS Consent Flag Telephone 2]
	,(
		Select 
			PHONE 
		FROM 
			@Phones 
		WHERE 
			[Account Root] = PKAROOT
		ORDER BY ROW 
		OFFSET 2 ROWS
		FETCH NEXT 1 ROWS ONLY
	) [Telephone 3]
	, CASE
		WHEN (
			Select 
				PHONE 
			FROM 
				@Phones 
			WHERE 
				[Account Root] = PKAROOT
			ORDER BY ROW 
			OFFSET 2 ROWS
			FETCH NEXT 1 ROWS ONLY
		) IS NOT NULL 
			THEN 'CELL'
		ELSE '' 
	END [Telephone Type 3]
	, CASE
		WHEN (
			Select 
				PHONE 
			FROM 
				@Phones 
			WHERE 
				[Account Root] = PKAROOT
			ORDER BY ROW 
			OFFSET 2 ROWS
			FETCH NEXT 1 ROWS ONLY
		) IS NOT NULL 
			THEN 'YES'
		ELSE 'NO' 
	END [SMS Consent Flag Telephone 3]
	,[Address Line-1]
	,[Address Line-2]
	,'' [Address Line-3]
	,'HOME' [Address Type]
	,[City]
	,[State]
	,[ZIP / Postal Code]
	,[Total Amount Due]
	,[Current Amount Due]
	,[Current Balance]
	,[Total Delinquent Amount]
	,[Delinquency Date]
	,'-1' [Cycles Delinquent]
	,'' [Campaign ID]
	,'' [Customer Number]
	,[Display Account Number]
	,[Original Creditor]
	,[Current Creditor]
	,[Original Account Number]
FROM OPENQUERY
(ADB,' 
	SELECT  
	TRIM(AROOT.ACCTNUM) [Account Number]
	, CAST(CLAIM.CONTDATE as SQL_CHAR) [Account Open Date]
	, TRIM(DEM.FIRSTNAME) [First Name]
	, TRIM(DEM.LASTNAME) [Last Name]
	, TRIM(DEM.MIDDLENAME) [Middle Name]
	, TRIM(DEM.EMAIL) [Email Address 1]
	, TRIM(DEM.ADDRESS1) [Address Line-1]
	, TRIM(DEM.ADDRESS2) [Address Line-2]
	, TRIM(DEM.CITY) [City]
	, TRIM(DEM.STATE) [State]
	, SUBSTRING(DEM.ZIP, 1, 5) [ZIP / Postal Code]
	, CAST(FNAMEVALUE(ACCTBALS.BALANCES, ''IDPPRJ_O'') as SQL_NUMERIC(12, 2)) [Total Amount Due]
	, CAST(FNAMEVALUE(ACCTBALS.BALANCES, ''IDPPRJ_O'') as SQL_NUMERIC(12, 2)) [Current Amount Due]
	, CAST(FNAMEVALUE(ACCTBALS.BALANCES, ''IDPPRJ_O'') as SQL_NUMERIC(12, 2)) [Current Balance]
	, CAST(FNAMEVALUE(ACCTBALS.BALANCES, ''IDPPRJ_O'') as SQL_NUMERIC(12, 2)) [Total Delinquent Amount]
	, CAST(CLAIM.CHARGEOD as SQL_CHAR) [Delinquency Date]
	, SUBSTRING(CLAIM.REFNUM,LENGTH(CLAIM.REFNUM) -3,4) [Display Account Number]
	, CASE
		WHEN OCRED.ONAME IS NULL THEN TRIM(AROOT.ORIGCRED)
		ELSE TRIM(OCRED.ONAME)
	END [Original Creditor]
	, TRIM(PLA.LASTNAME)
		+ CASE 
			WHEN(TRIM(PLA.NAME2)='''') 
				THEN '''' 
			ELSE '', '' + TRIM(PLA.NAME2) 
		END + 
			CASE  
				WHEN(TRIM(PLA.NAME2) = '''' or TRIM(PLA.MISC) = '''') 
					THEN '''' 
			ELSE '', '' + TRIM(PLA.MISC) 
	END [Current Creditor]
	, SUBSTRING(CLAIM.REFNUM,LENGTH(CLAIM.REFNUM) -3,4) [Original Account Number]
	, AROOT.PKAROOT [Account Root]
	FROM AROOT
	INNER JOIN CLIENT on CLIENT.PKCLIENT = AROOT.PKCLIENT
	INNER JOIN TYPECODE on TYPECODE.PKTYPECODE = AROOT.PKTYPECODE
	INNER JOIN 
		(
			SELECT 
			PKCLIENTGP 
			FROM CLIENTGP 
			WHERE CLIENTGP.CODE = ''I''
		) CCODE on CCODE.PKCLIENTGP = CLIENT.PKCLIENTGP
	INNER JOIN CLAIM on CLAIM.PKAROOT = AROOT.PKAROOT
	INNER JOIN STATCODE on STATCODE.PKSTATCODE = CLAIM.PKSTATCODE
	INNER JOIN 
		(
			SELECT 
			PKAROOT, 
			PKENTITY,
			PKACOMP,
			ORDINAL
			FROM ACOMP 
			WHERE 
			TRIM(ACOMP.ENTRYTYPE) = ''DEB''
			AND ACOMP.ORDINAL = ''001''
		) ACMP ON ACMP.PKAROOT = AROOT.PKAROOT
	INNER JOIN 
		(
			SELECT * 
			FROM DEMOG 
			WHERE 
			DEMOG.EMAIL IS NOT NULL
		) DEM ON DEM.PKDEMOG = ACMP.PKENTITY
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
	LEFT JOIN ACCTBALS on ACCTBALS.FILEID = TRIM(AROOT.ACCTNUM)+''.001''
	LEFT JOIN
		(
			SELECT
			BUSNAME1 as ONAME,
			PKAROOT
			FROM COTITLE
			Where 
			DATATYPE = ''OCRED''
		) as OCRED on OCRED.PKAROOT = AROOT.PKAROOT
	WHERE 
		NOT EXISTS
            (
                SELECT
                    *
                FROM
                    MEMBSRCH
                WHERE
                    MEMBSRCH.PKAROOT = AROOT.PKAROOT
                    AND
                    (
                        ENTRYTYPE = ''DAT''
                        OR ENTRYTYPE = ''MDC''
                    )
            )
        AND
        NOT EXISTS
            (
                SELECT
                    *
                FROM
                    AIQ
                WHERE
                    AIQ.PKAROOT = AROOT.PKAROOT
                    AND
                    (
                        PKACTCODE = ''CP00003X'' 
                        OR PKACTCODE = ''CP000062''
                    )
            )
        AND
        NOT EXISTS
            (
                SELECT
                    *
                FROM
                    DEFATTY
                WHERE
                    DEFATTY.PKACOMP = ACMP.PKACOMP
            )
        AND
            (
                AROOT.DNCALL = 0
                AND 
                AROOT.DNMAIL = 0
                AND 
                AROOT.DNCEASE = 0
                AND
                DEM.EMOPTOUT = 0
                AND 
                AROOT.HOLD = 0
            )
        AND
            (
                AROOT.ACCTMARK <> ''I''
                AND
                AROOT.INVALID <> 1
            )
        AND 
            (
                (
                    CLAIM.PKSTATCODE = ''SC00000U''
                    AND
                    CLAIM.STATDATE <= CAST(CURDATE() - 30 AS SQL_DATE)
                )
                OR
                STATCODE.CODE IN (''315'', ''320'', ''011'', ''120'')
            )
        AND
            (
                TRIM(AROOT.ORIGCRED) IS NOT NULL
                OR
                OCRED.ONAME IS NOT NULL
                OR
                TRIM(CLAIM.FORX) IS NOT NULL
            )
        AND CLAIM.OPENDATE BETWEEN ''2023-02-01'' AND ''2023-08-30''
        AND DEM.STATE = ''NY''
        AND LEFT(CLIENT.ID, 2) NOT IN (''FL'', ''NJ'')
	ORDER BY TRIM(AROOT.ACCTNUM)
	')
	WHERE
	(
		Select 
			PHONE 
		FROM 
			@Phones 
		WHERE 
			[Account Root] = PKAROOT
		ORDER BY ROW 
		OFFSET 0 ROWS
		FETCH NEXT 1 ROWS ONLY
	) IS NOT NULL

