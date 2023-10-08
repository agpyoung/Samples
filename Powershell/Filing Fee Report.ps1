#Requires -RunAsAdministrator
Import-Module SQLServer

Function Send-AlertEmail
{
    $EmailSettings = @{
        SMTP = # Input SMTP Address
        From = # Input Desired Outbound Address
		To = # Input Recipient
        Subject = $Subject
        Body = $Body
        Port = "25"
    }

    Send-MailMessage `
    -SmtpServer $EmailSettings.SMTP `
    -To $EmailSettings.To `
    -From $EmailSettings.From `
    -Subject $EmailSettings.Subject `
    -BodyAsHtml $EmailSettings.Body `
    -Priority High `
    -Port $EmailSettings.Port
}

$Day = Get-Date -f dddd
If($Day -eq 'Monday')
{
    $DaysToSubtract = '3'
}
Else
{
    $DaysToSubtract = '1'
}
$connectionString = # Input SQL Connection String
$Query = 
"
SELECT * FROM OPENQUERY(ADB,'
	select 
	trim(aroot.acctnum) [AccountNumber], 
	TRIM(revarch.Status) [Status], 
	cast((substring(dttime,1,4) + ''-'' + substring(dttime,5,2) + ''-'' + substring(dttime,7,2)) as sql_date) [CompletedDate], 
	TRIM(dttime),
	case 
		when substring(Client.ID,1,2) not in (''FL'', ''NJ'')
			then ''NY''
		else substring(Client.ID,1,2)
	end as State,
	TRIM(Clientgp.Descript) [Client],
	CAST
	(
		CASE
			WHEN ((jmt.jmtdate is null or jmt.jmtdate = ''1899-12-30'') and (curintdate = ''1899-12-30'' or curintdate is null)) 
				THEN
					cast(fnamevalue(acctbals.balances, ''IDPPRJ'') as sql_numeric(12,2)) +
					cast(fnamevalue(acctbals.balances, ''IDIPRJ'') as sql_numeric(12,2)) +
					cast(fnamevalue(acctbals.balances, ''IDFPRJ'') as sql_numeric(12,2)) +
					cast(fnamevalue(acctbals.balances, ''IDCPRJ'') as sql_numeric(12,2)) +
					cast(fnamevalue(acctbals.balances, ''IDOPRJ'') as sql_numeric(12,2)) +
					cast(fnamevalue(acctbals.balances, ''ITAC_OVRPMTS'') as sql_numeric(12,2))
			WHEN (jmt.jmtdate is null or jmt.jmtdate = ''1899-12-30'') 
				THEN (curdate() - curintdate)*(cast(fnamevalue(acctbals.balances,''IDPPRJ'') as sql_numeric) * cast(claim.intonprin as SQL_INTEGER) * claim.prejint/36500) +
					cast(fnamevalue(acctbals.balances,''IDPPRJ'') as sql_numeric(12,2)) +
					cast(fnamevalue(acctbals.balances, ''IDIPRJ'') as sql_numeric(12,2)) +
					cast(fnamevalue(acctbals.balances, ''IDFPRJ'') as sql_numeric(12,2)) +
					cast(fnamevalue(acctbals.balances, ''IDCPRJ'') as sql_numeric(12,2)) +
					cast(fnamevalue(acctbals.balances, ''IDOPRJ'') as sql_numeric(12,2)) +
					cast(fnamevalue(acctbals.balances, ''ITAC_OVRPMTS'') as sql_numeric(12,2))
			WHEN (jmt.jmtdate is not null and jmt.jmtdate <> ''1899-12-30'' and (curintdate = ''1899-12-30'' or curintdate is null)) 
				THEN
					cast(fnamevalue(acctbals.balances,''IDPPOJ'') as sql_numeric(12,2)) +
					cast(fnamevalue(acctbals.balances, ''IDIPOJ'') as sql_numeric(12,2)) +
					cast(fnamevalue(acctbals.balances, ''IDFPOJ'') as sql_numeric(12,2)) +
					cast(fnamevalue(acctbals.balances, ''IDCPOJ'') as sql_numeric(12,2)) +
					cast(fnamevalue(acctbals.balances, ''IDOPOJ'') as sql_numeric(12,2)) +
					cast(fnamevalue(acctbals.balances, ''ITAC_OVRPMTS'') as sql_numeric(12,2))
			WHEN (jmt.jmtdate is not null and jmt.jmtdate <> ''1899-12-30'' and jmtdate>=curintdate) 
				THEN (curdate() - jmtdate)*(cast(fnamevalue(acctbals.balances,''IDPPOJ'') as sql_numeric) * cast(claim.intonprin as SQL_INTEGER) * claim.postjint/36500) +
					cast(fnamevalue(acctbals.balances,''IDPPOJ'') as sql_numeric(12,2)) +
					cast(fnamevalue(acctbals.balances, ''IDIPOJ'') as sql_numeric(12,2)) +
					cast(fnamevalue(acctbals.balances, ''IDFPOJ'') as sql_numeric(12,2)) +
					cast(fnamevalue(acctbals.balances, ''IDCPOJ'') as sql_numeric(12,2)) +
					cast(fnamevalue(acctbals.balances, ''IDOPOJ'') as sql_numeric(12,2)) +
					cast(fnamevalue(acctbals.balances, ''ITAC_OVRPMTS'') as sql_numeric(12,2))
			WHEN (jmt.jmtdate is not null and jmt.jmtdate <> ''1899-12-30'' and jmtdate<curintdate) 
				THEN (curdate() - curintdate)*(cast(fnamevalue(acctbals.balances,''IDPPOJ'') as sql_numeric) * cast(claim.intonprin as SQL_INTEGER) * claim.postjint/36500) +
					cast(fnamevalue(acctbals.balances,''IDPPOJ'') as sql_numeric(12,2)) +
					cast(fnamevalue(acctbals.balances, ''IDIPOJ'') as sql_numeric(12,2)) +
					cast(fnamevalue(acctbals.balances, ''IDFPOJ'') as sql_numeric(12,2)) +
					cast(fnamevalue(acctbals.balances, ''IDCPOJ'') as sql_numeric(12,2)) +
					cast(fnamevalue(acctbals.balances, ''IDOPOJ'') as sql_numeric(12,2)) +
					cast(fnamevalue(acctbals.balances, ''ITAC_OVRPMTS'') as sql_numeric(12,2))
		END as SQL_NUMERIC(12,2)
	) as Balance
	from revarch
		inner join aroot on aroot.pkaroot = revarch.pkaroot
		inner join revdef on revarch.pkrevdef = revdef.pkrevdef
		inner join client on Aroot.pkclient = client.pkclient
		inner join clientgp on Client.pkclientgp = Clientgp.pkclientgp
		inner join claim on claim.pkaroot = aroot.pkaroot
		INNER JOIN acctbals on acctbals.fileid = trim(aroot.acctnum)+''.001''
		LEFT JOIN (select judgment.jmtdate, judgment.pkaroot from judgment inner join legalact on legalact.pkmaster = judgment.pkjudgment where isprimary=1)jmt on jmt.pkaroot = aroot.pkaroot
	where 
        dttime >= SUBSTRING(REPLACE(Replace(REPLACE(CAST(TIMESTAMPADD(SQL_TSI_DAY, -$($DaysToSubtract), CURRENT_TIMESTAMP()) as SQL_CHAR),''-'',''''),'':'',''''),'' '',''''),1,14)
		and LEFT(CLIENT.ID,2) in (''NJ'',''FL'')
		and STATUS = ''P''
		and revdef.code in (''E_ARSSUT'', ''E_ARSSUIT'')
	'
)
"
$Results = Invoke-Sqlcmd -ConnectionString $connectionString -Query $Query

$Clients = @{}
foreach($Client in $Results | select Client -Unique)
{
    $Clients.Add($Client.Client, 0)
}
$FLTotal = 0
Foreach($Result in $Results)
{
    $Fee = $null
    If($Result.State -eq 'FL')
    {
        Switch($Result.Balance)
        {
            {$_ -lt "501"} {$Fee = "0"}
            {$_ -ge "501" -and $_ -lt "2501"} {$Fee = "175"}
            {$_ -ge "2501" -and $_ -lt "15001"} {$Fee = "300"}
            {$_ -ge "15001" -and $_ -lt "30001"} {$Fee = "400"}
            {$_ -gt "30001"} {$Fee = "401"}
        }
        $FLTotal += $Fee
        $Clients.($Result.Client) += $Fee
    }
}

$Report = `
Foreach($Client in $Clients.Keys)
{
    "<tr><td>$($Client)</td><td>$('$' + $Clients.$Client)</td><td>0</td><td>0</td></tr>"
}
$Notice = '<Font Color = "Red"><b> This is an Automated Message. Do not reply.</b></Font>'
$Body = @"
            <head>
            <title>E-Filing Report</title>
            </head>
            <body>
            <div class="content">
            <table>
            <colgroup><col/><col/><col/><col/></colgroup>
            <tr><th>Client</th><th>FL Filing</th><th>NJ Filing</th><th>NJ Service</th></tr>
            $Report
            </table>
            </br>
            FL Total $('$' + $FLTotal)
            </br>
            </br>
            $Notice
            </body></html>
"@
        $Subject = "E-Filing Fee Report $(Get-Date -f MM/dd/yyyy)."
        Send-AlertEmail