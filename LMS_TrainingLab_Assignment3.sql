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


