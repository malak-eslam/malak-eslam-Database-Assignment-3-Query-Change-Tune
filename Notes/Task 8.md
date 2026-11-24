# Task 8 – Sort Spill

### Before Fixing
- Estimated Rows: 15,000
- Actual Rows: 105,000
- Spill Level: 1
- Memory Used: 19,776 KB
- Writes to tempdb: 6,796 pages
- Reads from tempdb: 6,796 pages

SQL Server underestimated the number of rows because the statistics were outdated. The Sort operator did not have enough memory, so it used **tempdb** to complete sorting. This is called a **Sort Spill** and causes extra read/write operations.

### Fix
Updated the statistics using:

UPDATE STATISTICS dbo.SortSpillDemo IX_SortSpillDemo_Category


### After Fixing
- Estimated Rows: 105,000
- Actual Rows: 105,000
- Memory Grant: 102,240 KB
- No Sort Spill warning.

### Conclusion
Updating statistics improved row estimation and eliminated the Sort Spill warning.