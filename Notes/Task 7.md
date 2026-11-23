Task 7

## 7.1

 ## Problem:

The original query uses YEAR() and MONTH() functions on the CreatedAtUtc column. 
This prevents SQL Server from performing an efficient Index Seek.

 ## Original Query:

SELECT Id, Email
FROM identity.Users
WHERE YEAR(CreatedAtUtc) = 2026
AND MONTH(CreatedAtUtc) = 3;

## Optimization:

I replaced the functions with a date range so SQL Server can search directly using the index.

 Optimized Query:


SELECT Id, Email
FROM identity.Users
WHERE CreatedAtUtc >= '2026-03-01'
AND CreatedAtUtc < '2026-04-01';

## Execution Plan Comparison:

- Before: Index Scan on IX_Users_CreatedAtUtc.
- After: Index Seek on  IX_Users_CreatedAtUtc.

 ## Logical Reads Comparison:

- Before: 1011 logical reads.
- After: 14 logical reads.

 ## Results:

Both queries returned 1054 rows. Logical reads decreased by approximately 98.6%
while returning the same results.

## Conclusion:

Using a date range instead of applying functions to the indexed column 
allowed SQL Server to perform an Index Seek and greatly reduced the number of logical reads.

----------------------------------------------------------
## 7.2

 ## Problem
The original query uses DATEDIFF() on the PaidAtUtc column. 
This makes the condition non-SARGable
preventing SQL Server from efficiently using an Index Seek.

 ## Original Query

SELECT Id, InvoiceId, Amount
FROM finance.Payments
WHERE DATEDIFF(DAY, PaidAtUtc, SYSUTCDATETIME()) <= 30;


 ## Optimized Query

SELECT Id, InvoiceId, Amount
FROM finance.Payments
WHERE PaidAtUtc >= DATEADD(DAY, -30, SYSUTCDATETIME())
  AND PaidAtUtc <= SYSUTCDATETIME();


 ## Execution Plan Comparison
- Before: SQL Server used an Index Scan on IX_Payments_PaidAtUtc
- reading 129,502 rows to return 15,548 rows.

- After: SQL Server used an Index Seek on the same index reading only 15,548 rows.

 ## Logical Reads Comparison
- Before: 610 logical reads.
- After: 77 logical reads.

This reduced logical reads by approximately 87.4%.

 ## Results
Both queries returned 15,548 rows on the test data.

The optimized query also excludes future payment dates.

 ## Conclusion
Moving the date calculation away from the column allowed SQL Server to use an Index Seek 
instead of an Index Scan. This significantly reduced the number of logical reads 
  and improved query efficiency.

  ----------------------------------------------------------
  ## 7.3

  ## Problem
The original query uses the LEFT() function on the LastName column. 
This makes the condition non-SARGable and prevents SQL Server from efficiently using an Index Seek.

 ## Original Query

SELECT Id, FirstName, LastName
FROM identity.Users
WHERE LEFT(LastName, 3) = N'Abd';


 ## Optimized Query

SELECT Id, FirstName, LastName
FROM identity.Users
WHERE LastName LIKE N'Abd%';


 ## Execution Plan Comparison
-  Before: SQL Server used an Index Scan on IX_Users_Email, reading 85,403 rows.
-  After: SQL Server used an Index Seek on IX_Users_LastName reading only 839 rows.

 ## Logical Reads Comparison
- Before: 1,275 logical reads.
- After: 20 logical reads.

This reduced logical reads by approximately 98.4%.

 ## Results
Both queries returned 839 rows.

 ## Conclusion
Using LIKE N'Abd%' instead of LEFT() allowed SQL Server to perform an Index Seek 
and significantly reduced the number of logical reads.

  ----------------------------------------------------------
  ## 7.4

  ## Problem:

The original query performs a calculation on the Id column (Id + 1)
 which prevents SQL Server from using an efficient Index Seek.

 ## Original Query:

SELECT *
FROM operations.AuditLogs
WHERE Id + 1 = 50001;


 ## Optimized Query:

SELECT *
FROM operations.AuditLogs
WHERE Id = 50000;

 ## Execution Plan:

Before optimization, SQL Server used an Index Scan on  IX_AuditLogs_Actor
     and examined 12,058,000 rows.

After optimization, SQL Server used a Clustered Index Seek on PK_AuditLogs
    and examined only 1 row.

 ## Performance Comparison:

Both queries returned 1 row.

Before optimization the query used 130,925 logical reads and 7 physical reads.

After optimization it used only 4 logical reads and 0 physical reads.

 ## Conclusion:

Moving the calculation away from the column allowed SQL Server to use a Clustered Index Seek 
   instead of scanning the index. 

Logical reads decreased from 130,925 to 4 while returning the same result.

  ----------------------------------------------------------
  ## 7.5

  ## Problem:

The original query compares a VARCHAR(30) column with an NVARCHAR value.
SQL Server converts the column using CONVERT_IMPLICIT
  which prevents an efficient Index Seek.

 ## Original Query:

SELECT Id, TotalAmount, PaidAmount
FROM finance.Invoices
WHERE InvoiceNumber = N'LAB-INV-2026-000001';


 ## Optimized Query:

SELECT Id, TotalAmount, PaidAmount
FROM finance.Invoices
WHERE InvoiceNumber = 'LAB-INV-2026-000001';


 ## Execution Plan:

Before optimization, SQL Server used an Index Scan on IX_Invoices_Number 
     and examined 146,799 rows. A PlanAffectingConvert warning appeared.

After optimization, SQL Server used an Index Seek on IX_Invoices_Number 
    and examined only 1 row The warning disappeared.

 ## Performance Comparison:

Both queries returned 0 rows.

Before optimization logical reads were 737 and physical reads were 3.

After optimization logical reads decreased to 3 and physical reads became 0.

 ## Conclusion:

Using a value with the same data type as the column removed the implicit conversion 
  and allowed SQL Server to use an Index Seek.

  ----------------------------------------------------------
  ## 7.6

  ## Problem:
The original query used UPPER() on the indexed Email column. 
This prevented SQL Server from performing an efficient Index Seek
     and resulted in an Index Scan.

 ## Optimization:

The database collation is SQL_Latin1_General_CP1_CI_AS. 
Since  CI means Case Insensitive email comparisons do not require UPPER().

The optimized query compares Email directly with the parameter.

 ## Performance Results:

- Before: Index Scan on IX_Users_CreatedAtUtc examining 85,403 rows, with 1,011 logical reads.
- After: Index Seek on IX_Users_Email with 3 logical reads.
- Both queries returned 0 rows for the tested email.

 ## Conclusion:

Removing the unnecessary UPPER(` allowed SQL Server to use the email index efficiently
  reducing logical reads from 1,011 to 3 (approximately 99.7%).


 ----------------------------------------------------------
  ## 7.7

  ## Problem:
The original query used an optional parameter with an OR condition. 
 SQL Server generated a cached plan that used an Index Scan and examined 85,403 rows.

 ## Optimization:

Added OPTION (RECOMPILE) to compile the query using the actual parameter value at execution time.

 ## Performance Results:

- Before: Index Scan on IX_Users_Email 1,275 logical reads.
- After: 20 logical reads.
- Both queries returned 839 rows.

Logical reads decreased from 1,275 to 20, an improvement of approximately 98.4%.

 ## Conclusion:

 OPTION (RECOMPILE) allowed SQL Server to optimize the query for the actual parameter value 
 instead of relying on a general cached plan.


----------------------------------------------------------
  ## 7.8

  ## Problem:
  Using SUBSTRING() on the LastName column in the WHERE clause prevents SQL Server 
     from efficiently searching the index.

 ## Slow Query:

SELECT Id, FirstName, LastName
FROM identity.Users
WHERE SUBSTRING(LastName, 1, 3) = N'Abd';


 ## Execution Plan:

- Index Scan on IX_Users_Email.
- Actual Rows Read: 85,403.
- Logical Reads: 1,275.
- Rows Returned: 839.

## Optimized Query:

SELECT Id, FirstName, LastName
FROM identity.Users
WHERE LastName LIKE N'Abd%';


 ## Execution Plan:
- Index Seek on IX_Users_LastName.
- Actual Rows Read: 839.
- Logical Reads: 20.
- Rows Returned: 839.

## Conclusion:

Replacing SUBSTRING() with a prefix LIKE condition allowed SQL Server to use an Index Seek 
  instead of scanning 85,403 rows. Both queries returned the same 839 rows 
  while logical reads decreased from 1,275 to 20 (approximately 98.4% reduction).

  ----------------------------------------------------------
