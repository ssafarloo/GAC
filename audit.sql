

-- https://www.red-gate.com/simple-talk/sql/database-administration/sql-server-security-audit-basics/ -- security audit
--//

SELECT event_time, statement,
   CAST(additional_information AS XML).value('declare namespace z="http://schemas.microsoft.com/sqlserver/2008/sqlaudit_data"; 
      (//z:address)[1]', 'nvarchar(300)')  
FROM sys.fn_get_audit_file('E:\MSSQL11.MSSQLSERVER\MSSQL\Log\Audit-20180213-154103*',Null, Null)
-- WHERE action_id = 'LGIS' 
ORDER BY event_time DESC
 

select * from sys.dm_audit_actions 

--//

EXECUTE AS LOGIN = N'GAMCUSTOM\assatouj';
-- revert;
SELECT name, HAS_DBACCESS(name) , *
  FROM sys.databases;
  GO

  --//


--\\ email notification for Audit events

DECLARE @TempTime datetime2;
DECLARE @Counter int;
DECLARE @MailQuery NVARCHAR(MAX);
SET @Counter = 0
SET @TempTime = (SELECT TOP 1 LastEventTime FROM dbo.TempAuditTime)
SET @Counter= (SELECT COUNT (event_time) 
 FROM sys.fn_get_audit_file('C:\SqlAudits\*.sqlaudit', default, default)
 WHERE DATEADD(hh, DATEDIFF(hh, GETUTCDATE(), CURRENT_TIMESTAMP), event_time ) > @TempTime)
 PRINT @Counter
 IF @Counter > 0 

 	BEGIN
	SET @MailQuery = CAST ((SELECT td = DATEADD(hh, DATEDIFF(hh, GETUTCDATE(), CURRENT_TIMESTAMP), event_time), '', 
							td =statement, ''
					FROM sys.fn_get_audit_file('C:\SqlAudits\*.sqlaudit', default, default)
					WHERE DATEADD(hh, DATEDIFF(hh, GETUTCDATE(), CURRENT_TIMESTAMP), event_time ) > @TempTime FOR XML PATH('tr'), TYPE
					) AS NVARCHAR(MAX))

DECLARE @tableHTML  NVARCHAR(MAX) ;

SET @tableHTML =
    N'<H1>Security Event Report</H1>' +
    N'<table border="1">' +
    N'<tr><th>Event time</th><th>Statement</th>'+
	N'</tr>' +
    @MailQuery +
    N'</table>';
	
 PRINT @tableHTML

 -- Update temp table event time
USE master

	UPDATE dbo.TempAuditTime
   SET [LastEventTime] = SYSDATETIME ()

-- Send Email
EXEC msdb.dbo.sp_send_dbmail
        @profile_name = 'SecurityEvent', 
		@recipients = 'nikola.dimitrijevic@apexsql.com',
		@body = @tableHTML,
		@body_format = 'HTML',
		@subject = 'Security Event Occured';
		
    	END; 


--\\ END --\\ email notification for Audit events


EXEC master.dbo.sp_configure 'show advanced options', 0;

Exec sp_configure 'default trace enabled'

RECONFIGURE WITH OVERRIDE;



select * from  sys.trace_events

SELECT * FROM fn_trace_geteventinfo(1)evi

SELECT DISTINCT
       e.name AS EventName
  FROM
       fn_trace_geteventinfo(1)evi
       JOIN sys.trace_events e
       ON
       evi.eventid
       =
       e.trace_event_id;
