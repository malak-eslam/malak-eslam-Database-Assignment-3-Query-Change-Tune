# Task 9 – DISTINCT

### 1. Non-Indexed Column

SELECT DISTINCT Payload
FROM dbo.SortSpillDemo;

- Clustered Index Scan: Reads 150,000 rows.
- Hash Match (Aggregate): Removes duplicates.
- Result: 2 distinct values.

### 2. Cheaper Alternative: Stream Aggregate
- Removes duplicates from already sorted data.
- Can be used efficiently when an index provides ordering on the distinct column.

### 3. Unique Column

SELECT DISTINCT Id
FROM dbo.SortSpillDemo;

- Index Scan:Reads 150,000 rows.
- No Aggregate operator because Id is already unique (Primary Key).
- SQL Server eliminates the unnecessary DISTINCT.