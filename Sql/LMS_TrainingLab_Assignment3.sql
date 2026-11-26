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


-- Task 2

-- 2.1

INSERT INTO [academic].[Departments]
    (Code, Name)
VALUES
    ('DSAI', 'Data Science & Artificial Intelligence');


SELECT *
FROM [academic].[Departments]
WHERE Code = 'DSAI';


--2.2

INSERT INTO [academic].[Courses]
           (DepartmentId, Title, Code, CreditHours, PassingScore)
VALUES (
         ( SELECT Id
		   FROM [academic].[Departments]
		   WHERE Code = 'DSAI' ),

        'Introduction to Data Analysis' , 
		'DSAI-101' ,
		 3 , 
		 60
		 )


SELECT *
FROM [academic].[Departments]
WHERE Code = 'DSAI';

SELECT *
FROM [academic].[Courses]
WHERE Code = 'DSAI-101';

--3.2
INSERT INTO [delivery].[AcademicTerms]
(
    AcademicYear,
    TermCode,
    Name,
    StartDate,
    EndDate,
    RegistrationStartDate,
    RegistrationEndDate,
    Status
)
VALUES
(
    2027,
    'Summer',
    'Summer 2027',
    '2027-06-15',
    '2027-08-31',
    '2027-05-01',
    '2027-06-10',
    4
);

SELECT *
FROM [delivery].[AcademicTerms]
WHERE TermCode = 'Summer';

--4.2
INSERT INTO [communication].[Announcements]
(
    SectionId,
    Title,
    Body,
    PublishedAtUtc,
    CreatedByUserId,
    Status
)
VALUES
(
    NULL,
    'Summer 2027 Registration',
    'Registration for Summer 2027 opens on May 1, 2027.',
    '2027-05-01',
    6,
    1
);

--5.2
INSERT INTO [identity].[Roles]
(
    Code,
    Name,
    Description,
    IsDeleted,
    IsSystem
)
VALUES
(
    'TA',
    'Teaching Assistant',
    'Role for Teaching Assistants',
    0,
    0
);


--Task 3

--3.1

IF NOT EXISTS
(
    SELECT 1
    FROM sys.sequences
    WHERE name = 'InvoiceNumberSequence'
      AND SCHEMA_NAME(schema_id) = 'finance'
)
BEGIN
    CREATE SEQUENCE finance.InvoiceNumberSequence
    START WITH 1
    INCREMENT BY 1;
END;

--3.2
DECLARE @Number BIGINT;

SET @Number = NEXT VALUE FOR finance.InvoiceNumberSequence;

SELECT CONCAT(
              'LAB-INV-2026-',
               FORMAT(@Number, '000000')
             ) AS InvoiceNumber;


--3.3
------------------------
SELECT TOP 5 Id, UserId
FROM [identity].[StudentProfiles];

SELECT Id, Name, AcademicYear, TermCode
FROM [delivery].[AcademicTerms];

SELECT Id, Name
FROM [delivery].[AcademicTerms]
WHERE Name = 'Fall 2027';

-------------------------
GO
DECLARE @Number BIGINT;

DECLARE @InvoiceNumber VARCHAR(30);

BEGIN TRANSACTION;

SET @Number = NEXT VALUE FOR finance.InvoiceNumberSequence;

SET @InvoiceNumber = CONCAT(
    'LAB-INV-2026-',
    FORMAT(@Number, '000000')
);


INSERT INTO finance.Invoices
(
    InvoiceNumber,
    StudentId,
    TermId,
    CurrencyCode,
    DueAtUtc,
    IssuedAtUtc,
    TotalAmount,
    PaidAmount,
    CreatedAtUtc,
    Status
)
VALUES
(
    @InvoiceNumber,
    304,
    12,
    'EGP',
    DATEADD(DAY, 30, SYSUTCDATETIME()),
    SYSUTCDATETIME(),
    4500,
    0,
    SYSUTCDATETIME(),
    1
);

SELECT * FROM finance.Invoices
WHERE InvoiceNumber = @InvoiceNumber;


ROLLBACK TRANSACTION;


SELECT CONCAT(
              'LAB-INV-2026-',
               FORMAT(NEXT VALUE FOR finance.InvoiceNumberSequence, '000000')
              ) AS NextInvoiceNumber;


GO


-- Task 4
INSERT INTO delivery.Sections
(
    CourseId,
    TermId,
    SectionCode,
    Capacity,
    Location,
    CreatedAtUtc
)

SELECT
    CourseId,
    13,
    SectionCode,
    Capacity,
    Location,
    SYSUTCDATETIME()
FROM delivery.Sections
WHERE TermId = 12;

SELECT *
FROM delivery.Sections
WHERE TermId = 13;


-- Task 5

-- 5.1
SELECT
    Code AS [Course Code],
    Title AS [Course Title],
    CreditHours AS [Credits]
FROM academic.Courses
ORDER BY
    CreditHours DESC,
    Title ASC;

-- 5.2 
SELECT TOP 5 *
FROM [identity].[StudentProfiles]
ORDER BY NEWID();


--5.3
SELECT *
FROM [identity].[Users]
WHERE DATALENGTH(Email) <> DATALENGTH(LTRIM(RTRIM(Email)));


--5.4
SELECT *
FROM [identity].[Users]
WHERE Email <> LOWER(Email);

--5.5
SELECT *
FROM [identity].[Users]
WHERE Email NOT LIKE '%@%'
   OR Email LIKE '@%'
   OR Email NOT LIKE '%@%.%';


--5.6
SELECT DISTINCT
    SUBSTRING(
              Email,
              CHARINDEX('@', Email) + 1,
              LEN(Email)
            ) AS EmailProvider
FROM [identity].[Users]
WHERE Email LIKE '%@%'
ORDER BY EmailProvider;


SELECT DISTINCT
          RIGHT(Email, LEN(Email) - CHARINDEX('@', Email)) AS EmailProvider
FROM [identity].[Users]
WHERE Email LIKE '%@%'
ORDER BY EmailProvider;

--5.7
SELECT *
FROM [identity].[Users]
ORDER BY
    LastLoginAtUtc DESC;


--5.8
SELECT *
FROM [finance].[Payments]
WHERE PaidAtUtc >= '2026-10-01'
  AND PaidAtUtc < '2026-11-01';


--5.9
SELECT
    *,
      PaidAtUtc AT TIME ZONE 'UTC'
                AT TIME ZONE 'Egypt Standard Time' AS CairoPaymentTime
FROM [finance].[Payments]
WHERE CAST(
    PaidAtUtc AT TIME ZONE 'UTC'
              AT TIME ZONE 'Egypt Standard Time'
    AS TIME
) >= '00:00:00'
AND CAST(
    PaidAtUtc AT TIME ZONE 'UTC'
              AT TIME ZONE 'Egypt Standard Time'
    AS TIME
) < '05:00:00';


--5.10
SELECT *
FROM [attendance].[AttendanceSessions]
WHERE DATENAME(WEEKDAY, SessionDate) = 'Friday';


--5.11
SELECT *
FROM [identity].[Users]
WHERE PhoneNumber LIKE '010%'
   OR PhoneNumber LIKE '011%'
   OR PhoneNumber LIKE '012%'
   OR PhoneNumber LIKE '015%';


--5.12
SELECT
    PhoneNumber,
    CONCAT(
        LEFT(PhoneNumber, 3),
        REPLICATE('*', LEN(PhoneNumber) - 5),
        RIGHT(PhoneNumber, 2)
    ) AS MaskedPhone
FROM [identity].[Users];

--5.13
SELECT
    InvoiceNumber,
    TRY_CAST(
        RIGHT(
            InvoiceNumber,
            CHARINDEX('-', REVERSE(InvoiceNumber)) - 1
        ) AS INT
    ) AS RunningNumber
FROM [finance].[Invoices]
WHERE TRY_CAST(
    RIGHT(
        InvoiceNumber,
        CHARINDEX('-', REVERSE(InvoiceNumber)) - 1
    ) AS INT
) IS NOT NULL
ORDER BY RunningNumber;


--5.14
SELECT
    Title,
    CASE
        WHEN EstimatedMinutes IS NULL THEN 'Not set'
        ELSE CONCAT(
            EstimatedMinutes / 60, ' h ',
            EstimatedMinutes % 60, ' min'
        )
    END AS LessonLength
FROM [content].[Lessons];



--5.15
SELECT *
FROM [communication].[Announcements]
WHERE Body LIKE '%[%]%';


--5.16
SELECT TOP 5 WITH TIES
    InvoiceNumber,
    TotalAmount
FROM [finance].[Invoices]
ORDER BY TotalAmount DESC;


--5.17
SELECT TOP 10 PERCENT
    Id,
    Amount,
    PaidAtUtc
FROM [finance].[Payments]
ORDER BY Amount DESC;

--5.18
SELECT *
FROM [delivery].[Sections]
WHERE Location <> 'Hall A'
   OR Location IS NULL;


--5.19
SELECT
    InvoiceNumber,
    TotalAmount,
    PaidAmount,
    TotalAmount - PaidAmount AS RemainingAmount,

    CASE
        WHEN PaidAmount = 0 THEN 'Not Paid'
        ELSE 'Partially Paid'
    END AS PaymentStatus,

    CASE
        WHEN DueAtUtc < SYSUTCDATETIME() THEN 'Overdue'
        ELSE 'Not Overdue'
    END AS OverdueStatus,

    CAST(
        PaidAmount * 100.0 / NULLIF(TotalAmount, 0)
        AS DECIMAL(5,1)
    ) AS PaidPercentage

FROM [finance].[Invoices]

WHERE PaidAmount < TotalAmount

ORDER BY RemainingAmount DESC;


--5.20
SELECT *
FROM [identity].[Users]
ORDER BY CreatedAtUtc DESC
OFFSET 40 ROWS
FETCH NEXT 20 ROWS ONLY;

--5.21
DECLARE @LastSeenId BIGINT = 500000;

SELECT TOP (50) *
FROM [operations].[AuditLogs]
WHERE Id > @LastSeenId
ORDER BY Id ASC;


--5.22
SELECT TOP 10 *
FROM [finance].[Payments];

-- The first query does not guarantee the latest 10 payments because it has no ORDER BY
-- the corrected query uses PaidAtUtc DESC.

SELECT TOP 10 *
FROM [finance].[Payments]
ORDER BY PaidAtUtc DESC;


--5.23
SELECT TOP 10
    UPPER(LTRIM(RTRIM(Title))) AS LessonTitle,

    LEN(LTRIM(RTRIM(Title))) AS TitleLength,

    EstimatedMinutes,

    CASE
        WHEN EstimatedMinutes IS NULL THEN 'Not set'
        WHEN EstimatedMinutes <= 15 THEN 'Quick'
        WHEN EstimatedMinutes <= 45 THEN 'Standard'
        ELSE 'Long'
    END AS DurationCategory

FROM [content].[Lessons]

WHERE IsPublished = 1
  AND LEN(LTRIM(RTRIM(Title))) > 40

ORDER BY TitleLength DESC;


--5.24
SELECT DISTINCT TOP 12
    FORMAT(DueAtUtc, 'yyyy-MM') AS DueMonth,
    CurrencyCode,

    CASE
        WHEN PaidAmount = 0 THEN 'Not Paid'
        ELSE 'Partially Paid'
    END AS PaymentState

FROM [finance].[Invoices]

WHERE DueAtUtc < SYSUTCDATETIME()
  AND PaidAmount < TotalAmount

ORDER BY DueMonth DESC;


-- Task 6

EXEC sp_helpindex 'finance.Invoices';

EXEC sp_helpindex 'identity.StudentProfiles';

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

INNER JOIN [identity].StudentProfiles AS sp
    ON sp.Id = i.StudentId

WHERE i.PaidAmount < i.TotalAmount
  AND i.DueAtUtc < SYSUTCDATETIME()

ORDER BY Remaining DESC;

-- Task 7

CREATE INDEX IX_Users_Email
ON [identity].[Users] (Email)
INCLUDE (FirstName, LastName);

CREATE INDEX IX_Users_LastName
ON [identity].[Users] (LastName)
INCLUDE (FirstName, Email);

CREATE INDEX IX_Users_CreatedAtUtc
ON [identity].[Users] (CreatedAtUtc)
INCLUDE (Email);

CREATE INDEX IX_Payments_PaidAtUtc
ON finance.Payments (PaidAtUtc)
INCLUDE (InvoiceId, Amount);

CREATE INDEX IX_Invoices_Number
ON finance.Invoices (InvoiceNumber);


--7.1
SET STATISTICS IO ON;

SELECT Id, Email
FROM [identity].[Users]
WHERE YEAR(CreatedAtUtc) = 2026
AND MONTH(CreatedAtUtc) = 3;

SELECT Id, Email
FROM [identity].[Users]
WHERE CreatedAtUtc >= '2026-03-01'
AND CreatedAtUtc < '2026-04-01';


--7.2

SELECT Id, InvoiceId, Amount
FROM finance.Payments
WHERE DATEDIFF(DAY, PaidAtUtc, SYSUTCDATETIME()) <= 30;


SELECT Id, InvoiceId, Amount
FROM finance.Payments
WHERE PaidAtUtc >= DATEADD(DAY, -30, SYSUTCDATETIME())
  AND PaidAtUtc <= SYSUTCDATETIME();


--7.3
SELECT Id, FirstName, LastName
FROM [identity].[Users]
WHERE LEFT(LastName, 3) = N'Abd';


SELECT Id, FirstName, LastName
FROM [identity].[Users]
WHERE LastName LIKE N'Abd%';

--7.4
SELECT *
FROM operations.AuditLogs
WHERE Id + 1 = 50001;

SELECT *
FROM operations.AuditLogs
WHERE Id = 50000;

--7.5
SELECT Id, TotalAmount, PaidAmount
FROM finance.Invoices
WHERE InvoiceNumber = N'LAB-INV-2026-000001';


SELECT Id, TotalAmount, PaidAmount
FROM finance.Invoices
WHERE InvoiceNumber = 'LAB-INV-2026-000001';

--7.6
SELECT DATABASEPROPERTYEX(DB_NAME(), 'Collation')
                                       AS DatabaseCollation;


DECLARE @Email NVARCHAR(320) = N'...';

SELECT Id, FirstName, LastName
FROM [identity].[Users]
WHERE UPPER(Email) = UPPER(@Email);

GO

DECLARE @Email NVARCHAR(320) = N'...';

SELECT Id, FirstName, LastName
FROM [identity].[Users]
WHERE Email = @Email;

GO

--7.7
DECLARE @LastName NVARCHAR(100) = N'Hassan';
SELECT Id, FirstName, Email
FROM [identity].[Users]
WHERE (@LastName IS NULL
OR LastName = @LastName);

GO

DECLARE @LastName NVARCHAR(100) = N'Hassan';

SELECT Id, FirstName, Email
FROM [identity].[Users]
WHERE (@LastName IS NULL
       OR LastName = @LastName)
OPTION (RECOMPILE);

GO

--7.8
SELECT Id, FirstName, LastName
FROM [identity].[Users]
WHERE SUBSTRING(LastName, 1, 3) = N'Abd';


SELECT Id, FirstName, LastName
FROM [identity].[Users]
WHERE LastName LIKE N'Abd%';


-- Task 8
CREATE TABLE dbo.SortSpillDemo
(
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Category INT,
    SortValue VARCHAR(200),
    Payload VARCHAR(1000)
);

 ;WITH Numbers AS
(
    SELECT TOP (50000)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Num
    FROM sys.all_objects A
    CROSS JOIN sys.all_objects B
)
INSERT INTO dbo.SortSpillDemo (Category, SortValue, Payload)
SELECT
    Num % 10,
    CONCAT('Value-', Num),
    REPLICATE('X', 500)
FROM Numbers;

SELECT COUNT(*) AS TotalRows
FROM dbo.SortSpillDemo;


SELECT *
FROM dbo.SortSpillDemo;

CREATE NONCLUSTERED INDEX IX_SortSpillDemo_Category
ON dbo.SortSpillDemo(Category);



SELECT Category, COUNT(*) AS RowsCount
FROM dbo.SortSpillDemo
GROUP BY Category
ORDER BY Category;


SELECT COUNT(*) AS AvailableRows
FROM sys.all_objects A
CROSS JOIN sys.all_objects B;

;WITH Numbers AS
(
    SELECT TOP (100000)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Num
    FROM sys.all_objects A
    CROSS JOIN sys.all_objects B
)
INSERT INTO dbo.SortSpillDemo (Category, SortValue, Payload)
SELECT
    1,
    CONCAT('Extra-', Num),
    REPLICATE('Y', 500)
FROM Numbers;

SELECT COUNT(*) AS TotalRows
FROM dbo.SortSpillDemo;

DBCC SHOW_STATISTICS
(
    'dbo.SortSpillDemo',
    'IX_SortSpillDemo_Category'
)
WITH HISTOGRAM;

SELECT *
FROM dbo.SortSpillDemo
WHERE Category = 1
ORDER BY SortValue DESC;

DELETE FROM dbo.SortSpillDemo
WHERE SortValue LIKE 'Extra-%';

SELECT COUNT(*) AS TotalRows
FROM dbo.SortSpillDemo;

UPDATE STATISTICS dbo.SortSpillDemo
IX_SortSpillDemo_Category WITH FULLSCAN;

;WITH Numbers AS
(
    SELECT TOP (100000)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Num
    FROM sys.all_objects A
    CROSS JOIN sys.all_objects B
)
INSERT INTO dbo.SortSpillDemo (Category, SortValue, Payload)
SELECT
    1,
    CONCAT('Extra-', Num),
    REPLICATE('Y', 500)
FROM Numbers;

ALTER DATABASE LmsTrainingLab
SET AUTO_UPDATE_STATISTICS OFF;

SELECT *
FROM dbo.SortSpillDemo
WHERE Category = 1
ORDER BY SortValue DESC;

UPDATE STATISTICS dbo.SortSpillDemo
IX_SortSpillDemo_Category WITH FULLSCAN;

SELECT *
FROM dbo.SortSpillDemo
WHERE Category = 1
ORDER BY SortValue DESC;

--Task 9
SELECT DISTINCT Payload
FROM dbo.SortSpillDemo;

SELECT DISTINCT Id
FROM dbo.SortSpillDemo;

-- Task 11

--11.1
UPDATE c
SET PassingScore = 65
FROM academic.Courses AS c
INNER JOIN academic.Departments AS d
ON c.DepartmentId = d.Id
WHERE d.Code = 'DSAI' ;

--11.2
UPDATE e
SET FinalGrade =
       CASE 
	       WHEN FinalScore >= 90 THEN 'A'
	       WHEN FinalScore >= 80 THEN 'B'
	       WHEN FinalScore >= 70 THEN 'C'
	       WHEN FinalScore >= 60 THEN 'D'
		   ELSE 'F'
	  END  
FROM delivery.Enrollments AS e
WHERE CompletedAtUtc <> NULL
  AND FinalScore <> NULL;

--11.3

DELETE FROM [identity].[UserRoles]
WHERE RoleId = 7;

DELETE FROM [identity].[Roles]
WHERE Id = 7;

--11.4

SELECT TOP (0)
    InvoiceId,
    PaymentMethodId,
    Amount,
    CurrencyCode,
    ExternalReference,
    PaidAtUtc,
    CreatedByUserId,
    CreatedAtUtc,
    Kind,
    Status
INTO finance.PaymentStaging
FROM finance.Payments;

INSERT INTO finance.PaymentStaging
SELECT TOP (3)
    InvoiceId,
    PaymentMethodId,
    Amount,
    CurrencyCode,
    ExternalReference,
    PaidAtUtc,
    CreatedByUserId,
    CreatedAtUtc,
    Kind,
    Status
FROM finance.Payments;

TRUNCATE TABLE finance.PaymentStaging;

--11.5
DROP TABLE dbo.SortSpillDemo


--Task 12

--12.1
CREATE TABLE CoursePassingMarkHistory
(
    CourseId INT,
    OldPassingScore DECIMAL(5,2),
    NewPassingScore DECIMAL(5,2),
    ChangedAt DATETIME2,
    ChangedBy NVARCHAR(128)
);

UPDATE c
SET PassingScore = 60
OUTPUT 
     INSERTED.Id,
    DELETED.PassingScore,
    INSERTED.PassingScore,
    SYSUTCDATETIME(),
    SUSER_SNAME()
INTO dbo.CoursePassingMarkHistory
(
    CourseId,
    OldPassingScore,
    NewPassingScore,
    ChangedAt,
    ChangedBy
)
FROM academic.Courses AS c
INNER JOIN academic.Departments AS d
    ON c.DepartmentId = d.Id
WHERE d.Code = 'DSAI';

--12.2
SELECT TOP (0) *
INTO communication.AnnouncementsArchive
FROM communication.Announcements;

SET IDENTITY_INSERT communication.AnnouncementsArchive ON;

DELETE FROM communication.Announcements
OUTPUT
    DELETED.Id,
    DELETED.SectionId,
    DELETED.Title,
    DELETED.Body,
    DELETED.PublishedAtUtc,
    DELETED.ExpiresAtUtc,
    DELETED.CreatedByUserId,
    DELETED.CreatedAtUtc,
    DELETED.UpdatedAtUtc,
    DELETED.Status
INTO communication.AnnouncementsArchive
(
    Id,
    SectionId,
    Title,
    Body,
    PublishedAtUtc,
    ExpiresAtUtc,
    CreatedByUserId,
    CreatedAtUtc,
    UpdatedAtUtc,
    Status
)
WHERE ExpiresAtUtc < DATEADD(MONTH, -6, SYSUTCDATETIME());

SET IDENTITY_INSERT communication.AnnouncementsArchive OFF;

-- Task 13
CREATE TABLE WebsiteCatalog
(
    CourseId INT PRIMARY KEY,
    Code VARCHAR(30) NOT NULL,
    Title NVARCHAR(200) NOT NULL,
    CreditHours DECIMAL(4,2) NOT NULL,
    IsVisible BIT NOT NULL
);

INSERT INTO WebsiteCatalog (CourseId, Code, Title, CreditHours, IsVisible)
SELECT Id, Code, Title, CreditHours, 1
FROM academic.Courses
WHERE IsActive = 1;

MERGE WebsiteCatalog AS Target
USING academic.Courses AS Source
ON Target.CourseId = Source.Id

WHEN MATCHED AND
(
    Target.Code <> Source.Code
    OR Target.Title <> Source.Title
    OR Target.CreditHours <> Source.CreditHours
)
THEN
    UPDATE SET
        Target.Code = Source.Code,
        Target.Title = Source.Title,
        Target.CreditHours = Source.CreditHours,
        Target.IsVisible = Source.IsActive

WHEN NOT MATCHED BY TARGET AND Source.IsActive = 1
THEN
    INSERT (CourseId, Code, Title, CreditHours, IsVisible)
    VALUES (Source.Id, Source.Code, Source.Title,
            Source.CreditHours, 1)

WHEN MATCHED AND Source.IsActive = 0 AND Target.IsVisible = 1
THEN
    UPDATE SET Target.IsVisible = 0

OUTPUT
    $action ,
    COALESCE(INSERTED.CourseId, DELETED.CourseId) AS CourseId,
    DELETED.Title AS OldTitle,
    INSERTED.Title AS NewTitle;