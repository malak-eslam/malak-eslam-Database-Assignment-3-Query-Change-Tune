-- Task 1
-- 1.1
SELECT InvoiceNumber,
     (
        SELECT CONCAT(u.FirstName, ' ', u.LastName)
        FROM [identity].[Users] AS u
        WHERE u.Id = (
            SELECT sp.UserId
            FROM [identity].[StudentProfiles] AS sp
            WHERE sp.Id = i.StudentId
        )
    ) AS StudentName,

       i.TotalAmount,
	   i.PaidAmount,
	   i.DueAtUtc,
	   i.TotalAmount - i.PaidAmount As RemainingAmount,
	   DATEDIFF(Day, i.DueAtUtc , GETUTCDATE())  As DaysLate
	  
INTO #OverdueInvoices

FROM finance.Invoices As i

WHERE 
     i.DueAtUtc < SYSUTCDATETIME()
      AND
	 i.PaidAmount < i.TotalAmount ;


-- 1.2
SELECT 
      *,
	  CASE
	      WHEN DueAtUtc < DATEADD(MONTH, -2, SYSUTCDATETIME())
		      OR 
			  RemainingAmount > 10000
		   THEN 'Urgent'

		   WHEN DueAtUtc < DATEADD(MONTH, -1, SYSUTCDATETIME())
            THEN 'Medium'

        ELSE 'Low'
    END AS Priority
      
FROM #OverdueInvoices

ORDER BY
    CASE
        WHEN DueAtUtc < DATEADD(MONTH, -2, SYSUTCDATETIME())
             OR RemainingAmount > 10000 THEN 1

        WHEN DueAtUtc < DATEADD(MONTH, -1, SYSUTCDATETIME()) THEN 2

        ELSE 3
    END,
    RemainingAmount DESC;


