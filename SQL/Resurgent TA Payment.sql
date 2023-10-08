USE [TrueAccord]
DECLARE @sFrag TABLE
(
    [Account Number] INT,
    [Account Namespace] CHAR(8),
    [Payment Method] NVARCHAR(MAX),
    [Payment Amount] NUMERIC(12,2),
    [Transaction Date] DATE,
    [Category Code] CHAR(8)
);

WITH RESULTS
(
    [Account Number],
    [Account Namespace],
    [Payment Method],
    [Payment Amount],
    [Transaction Date],
    [Category Code]
)
AS
(
    SELECT 
        [Account Number],
        [Account Namespace],
        [Payment Method],
        [Payment Amount],
        [Transaction Date],
        [Category Code]
    FROM OPENQUERY
    (
        adb,
        '
            SELECT 
                TRIM(AROOT.ACCTNUM) as [Account Number], 
                ''TMPPLLC'' as [Account Namespace], 
                TRIM(Fragstr) [Payment Method],
                CAST(FNAMEVALUE(ACCTBALS.BALANCES, ''TrxLastPmtAmt'') as SQL_NUMERIC(12,2)) as [Payment Amount], 
                TRIM(CAST(FNAMEVALUE(ACCTBALS.BALANCES, ''TrxLastPmtDate'') as SQL_CHAR)) as [Transaction Date], 
                ''PAYMENT'' as [Category Code] 
            FROM AROOT 
                INNER JOIN CLAIM on CLAIM.PKAROOT = AROOT.PKAROOT 
                INNER JOIN STATCODE on STATCODE.PKSTATCODE = CLAIM.PKSTATCODE 
                INNER JOIN journal on journal.pkaroot = aroot.pkaroot 
                INNER JOIN history on history.pkhistory = journal.pkhistory 
                INNER JOIN 
                (
                    SELECT 
                    FRAGSTR, 
                    PKHISTORY 
                    FROM HISTFRAG2
                ) FRAG on FRAG.PkHistory = history.pkhistory 
                LEFT JOIN ACCTBALS on ACCTBALS.FILEID = TRIM(AROOT.ACCTNUM)+''.001'' 
            WHERE 
                --STATCODE.CODE < ''500'' 
                TRANSCLASS = ''P''
                AND CLAIM.LASTPMNT >= ''2023-04-03''
                AND EFFECTDATE >= ''2023-04-03''
                ORDER BY TRIM(AROOT.ACCTNUM) 
        '
    ) 
)

INSERT INTO @sFrag 
    SELECT
        [RESULTS].[Account Number],
        [RESULTS].[Account Namespace],
        STUFF
        (
            (
                SELECT 
                    '' + R.[Payment Method]
                FROM Results R 
                WHERE R.[Account Number] = [RESULTS].[Account Number] 
                ORDER BY R.[Account Number] 
                    FOR XML PATH('')
            ),1,2,''
        ) [Payment Method],
        [RESULTS].[Payment Amount],
        [RESULTS].[Transaction Date],
        [RESULTS].[Category Code]
    FROM RESULTS
    LEFT JOIN 
    (
        SELECT 
        [Account Number]
        FROM SettlementPlacedDatas
        WHERE [Product Type] = 'PRESETTLEMENT'
    ) SD on SD.[Account Number] = RESULTS.[Account Number]
    LEFT JOIN 
    (
        SELECT 
        [Account Number]
        FROM RetractionDatas
    ) RD on RD.[Account Number] = RESULTS.[Account Number]
    WHERE
    (
            RD.[Account Number] IS NOT NULL
        OR
            SD.[Account Number] IS NOT NULL
    )
    

SELECT
    [@sFrag].[Account Number],
    [@sFrag].[Account Namespace],
    REPLACE
    (
        SUBSTRING
        (
            [@sFrag].[Payment Method],
            CHARINDEX
            (
                'TrxMethod',
                [@sFrag].[Payment Method]
            ),
            CHARINDEX
            (
                '&',
                [@sFrag].[Payment Method], 
                CHARINDEX
                (
                    'TrxMethod',
                    [@sFrag].[Payment Method]
                )
            ) 
            - CHARINDEX
            (
                'TrxMethod',
                [@sFrag].[Payment Method]
            )
        ),'TrxMethod=', ''
    ) [Payment Method],
    [@sFrag].[Payment Amount],
    [@sFrag].[Transaction Date],
    [@sFrag].[Category Code]
FROM @sFrag
GROUP BY 
    [Account Number], 
    [Account Namespace],
    [Payment Method],
    [Payment Amount],
    [Transaction Date],
    [Category Code]