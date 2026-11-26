# Task 6 – Execution Plan and Performance Analysis

## 1. Query

This query is used by the collections screen to retrieve the 15 invoices with the highest remaining amounts.

SELECT TOP (15)
    i.InvoiceNumber,
    sp.StudentNumber,
    i.TotalAmount - i.PaidAmount AS Remaining,
    CASE
        WHEN i.DueAtUtc < DATEADD(DAY, -60, SYSUTCDATETIME())
        THEN 'Urgent'
        ELSE 'Normal'
    END AS Urgency
FROM finance.Invoices AS i
INNER JOIN identity.StudentProfiles AS sp
    ON sp.Id = i.StudentId
WHERE i.PaidAmount < i.TotalAmount
  AND i.DueAtUtc < SYSUTCDATETIME()
ORDER BY Remaining DESC;


## 2. Expected Execution Plan

Before executing the query I expected the following operators:

1. Clustered Index Scan – Invoices: I expected SQL Server to scan the Invoices table 
                          because there is no suitable index for the filtering conditions 
                          on DueAtUtc and PaidAmount < TotalAmount.

2. Compute Scalar: To calculate the remaining amount using TotalAmount - PaidAmount.

3. Hash Match – Inner Join: I expected Hash Match because the query joins two tables 
                             and Invoices contains a large number of rows.

4. Clustered Index Scan – StudentProfiles: I expected SQL Server might scan this table 
                         to build the hash table for the join.

5. Sort: To sort the results by Remaining DESC.

6. Top: To return only the first 15 rows.

7. Compute Scalar: To calculate the urgency using the CASE expression.

## 3. Actual Execution Plan

After executing the query with the Actual Execution Plan enabled SQL Server used the following operators.

The execution plan used parallel processing with a Degree of Parallelism (DOP) of 12.

### 1. Clustered Index Scan – Invoices (Node 7)

SQL Server scanned the clustered index of Invoices to evaluate the filtering conditions.

 Properties:

- Estimated Rows: 43,531.4
- Actual Rows: 50,427
- Estimated Rows Read: 146,799
- Actual Rows Read: 146,799
- EstimateCPU: 0.0269393
- EstimateIO: 1.87572
- EstimatedTotalSubtreeCost: 1.90266
- AvgRowSize: 65
- Ordered: False
- TableCardinality: 146,799
- Storage: RowStore

 Why SQL Server choose it:

There is no suitable index supporting the filtering conditions. 
The existing indexes do not directly support filtering by DueAtUtc
     and comparing PaidAmount with TotalAmount.

Therefore SQL Server scanned the clustered index to evaluate the conditions.

### 2. Compute Scalar – Remaining (Node 6)

This operator calculates the remaining amount:

 TotalAmount - PaidAmount

 Properties:

- Estimated Rows: 43,531.4
- Actual Rows: 50,427
- EstimateCPU: 0.00244665
- EstimateIO: 0
- EstimatedTotalSubtreeCost: 1.9051
- AvgRowSize: 74

 Why SQL Server choose it:

The query needs to calculate the Remaining value for each qualifying invoice.
 This value is also used by the ORDER BY clause.

### 3. Sort (Node 5)

This operator sorts the invoices by Remaining in descending order.

 Properties:

- Estimated Rows: 15
- EstimateRowsWithoutRowGoal: 43,531.4
- Actual Rows: The per-thread output counters sum to approximately 151 across parallel workers.
- EstimateCPU: 0.513186
- EstimateIO: 0.00187688
- EstimatedTotalSubtreeCost: 2.4417
- AvgRowSize: 56
- Distinct: False
- Ascending: False

 Why SQL Server choose it:

The query uses ORDER BY Remaining DESC so the rows must be sorted.

Since Remaining is a calculated expression and there is no suitable index providing this order SQL Server used a Sort operator.

The estimated row count of 15 is affected by the Row Goal introduced by TOP (15). 
The per-thread actual counters are not the final number of rows returned by the query.

### 4. Nested Loops – Inner Join (Node 3)

SQL Server used Nested Loops to perform the INNER JOIN between Invoices and StudentProfiles.

 Properties:

- Estimated Rows: 15
- EstimateRowsWithoutRowGoal: 43,531.4
- Actual Rows: The per-thread output counters sum to approximately 147 across parallel workers.
- EstimateCPU: 0.0303269
- EstimateIO: 0
- EstimatedTotalSubtreeCost: 2.49385
- Optimized: False
- WithOrderedPrefetch: True

 Why SQL Server choose it:

Nested Loops uses the sorted invoice rows as its outer input and searches for the matching student profile using the inner input.

SQL Server chose this operator because the inner table has an index on the join key, allowing efficient lookups.

### 5. Clustered Index Seek – StudentProfiles (Node 8)

SQL Server searches for the matching student profile using:

 StudentProfiles.Id = Invoices.StudentId

 Properties:

- Estimated Rows: 1 per lookup
- Estimated Rows Read: 1 per lookup
- Actual Executions: Approximately 151 across parallel workers
- EstimateCPU: 0.0001581
- EstimateIO: 0.003125
- EstimatedTotalSubtreeCost: 0.0521452
- TableCardinality: 85,000
- Ordered: True
- ScanDirection: FORWARD
- Storage: RowStore

 Why SQL Server choose it:

 StudentProfiles.Id is the clustered primary key. 
 Therefore, SQL Server can use a Clustered Index Seek to find the matching student row efficiently 
  instead of scanning the whole table.

This Seek is the inner input of the Nested Loops operator.

### 6. Gather Streams – Parallelism (Node 2)

This operator combines the results produced by parallel threads into one output stream.

 Properties:

- Estimated Rows: 15
- Actual Rows: 15
- EstimateRowsWithoutRowGoal: 43,531.4
- EstimateCPU: 0.0286097
- EstimateIO: 0
- EstimatedTotalSubtreeCost: 2.52246
- Degree of Parallelism: 12

 Why SQL Server choose it:

The query was executed using 12 parallel threads. 
Gather Streams combines the results from these threads into one stream 
  and preserves the required order.

### 7. Top (Node 1)

This operator returns only the first 15 rows.

**Properties:**

- Estimated Rows: 15
- Actual Rows: 15
- TopExpression: 15
- RowCount: False
- IsPercent: False
- WithTies: False

  Why SQL Server choose it:

The query uses TOP (15) so SQL Server uses the Top operator to limit the final result to 15 rows.

### 8. Compute Scalar – Urgency (Node 0)

This operator calculates the Urgency column using the CASE expression.

 Properties:

- Estimated Rows: 15
- Actual Rows: 15
- EstimateCPU: 0.0000015
- EstimateIO: 0

  Why SQL Server choose it:

It evaluates whether each returned invoice is more than 60 days overdue:

- Urgent: If DueAtUtc is earlier than 60 days ago.
- Normal: Otherwise.

This calculation is performed for the final 15 rows.

## 4. Estimated Rows vs Actual Rows

For the Invoices Clustered Index Scan:

- Estimated Rows: 43,531.4
- Actual Rows: 50,427

SQL Server underestimated the qualifying rows by approximately 6,896 rows.

The difference between estimated and actual rows may affect the optimizer's decisions.

The Row Goal introduced by TOP (15) also affects the estimated row counts of several operators.

 Note: The actual counters for some operators are distributed across the 12 parallel workers. 
       Their per-thread totals should not be confused with the final number of rows returned. 
       The final result contains 15 rows.

### 5. Performance Measurement

To measure the query's work and execution time, I enabled:

SET STATISTICS IO ON;
SET STATISTICS TIME ON;


## A. STATISTICS IO

The second execution reported:

Invoices:

Scan Count: 13

Logical Reads: 2,674

Physical Reads: 2

Read-Ahead Reads: 2,525

StudentProfiles:

Scan Count: 0

Logical Reads: 449

Physical Reads: 17

Explanation:

Scan Count: The number of scan or seek operations reported by SQL Server. 
With parallel execution this value does not necessarily represent the number of complete table scans.

Logical Reads: The number of 8 KB data pages accessed in memory.

Physical Reads: The number of pages read from disk.

Read-Ahead Reads: Pages SQL Server read ahead of time to improve performance.

Invoices had more logical reads because SQL Server performed a Clustered Index Scan.

## B. STATISTICS TIME

The second execution reported:

Compile CPU Time: 0 ms

Compile Elapsed Time: 31 ms

Execution CPU Time: 15 ms

Execution Elapsed Time: 117 ms

Explanation:

CPU Time: The time spent processing the query on the CPU.

Elapsed Time: The total time taken by the operation, including time spent waiting.

CPU time and elapsed time can differ because of parallel execution and other waits.

The measurements may vary between executions because of caching and system conditions.

## 6. Memory Grant

The execution plan reported the following memory grant information:

SerialRequiredMemory: 512 KB

SerialDesiredMemory: 7,320 KB

RequiredMemory: 7,296 KB

DesiredMemory: 14,112 KB

RequestedMemory: 14,112 KB

GrantedMemory: 14,112 KB

MaxUsedMemory: 5,912 KB

GrantWaitTime: 0 ms

MaxQueryMemory: 1,542,648 KB

SQL Server requested and received 14,112 KB and used a maximum of 5,912 KB.

The GrantWaitTime was 0 ms, which means the query did not wait for its memory grant.

## 7. Missing Index Recommendation

The execution plan suggested a missing index on:

finance.Invoices (DueAtUtc)

With the following included columns:

InvoiceNumber, StudentId, TotalAmount, PaidAmount

The estimated impact was 62.5707%.

This recommendation suggests that an index on DueAtUtc may help reduce the work required to filter invoices.

However, the impact value is an optimizer estimate, not a guaranteed performance improvement.
The index should be tested by comparing the query before and after creating it.

## 8. Statistics and Waits

Some statistics on the Invoices table had a high Modification Count
which may affect estimation accuracy.

Examples include:

Invoices statistics on PK_Invoices: Modification Count = 9,520.

Invoices statistics on IX_Invoices_StudentStatus: Modification Count = 9,520.

StudentProfiles statistics on PK_StudentProfiles: Modification Count = 0.

The recorded waits included:

LATCH_EX

LATCH_SH

CXPACKET

CXSYNC_PORT

PAGEIOLATCH_SH

These waits show that the query experienced different types of synchronization and resource waits. Their presence alone does not prove that there is a performance problem.

## 9. Where My Guess Was Wrong

My main incorrect prediction was expecting a Hash Match instead of Nested Loops for the INNER JOIN.

I also expected SQL Server might scan StudentProfiles to build a hash table. However, 
SQL Server used a Clustered Index Seek on StudentProfiles.Id because it is the clustered primary key.

Another difference was the order of operations. I expected the Sort to happen after the JOIN, but the actual plan sorted the invoice rows before performing the Nested Loops join.

## 10. Conclusion

The actual execution plan differed from some of my expectations.

SQL Server used Nested Loops with a Clustered Index Seek instead of Hash Match. 
It also performed the Sort before the JOIN.

The Invoices Clustered Index Scan was the main source of logical reads 
because SQL Server had to evaluate the filtering conditions without a suitable index.

The missing index recommendation on DueAtUtc may improve performance, 
but it needs to be tested before implementation.

