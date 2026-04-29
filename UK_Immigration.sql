--1. STANDARDISE DATA TYPES--
--1.1 CLEAN APPLICATIONS COLUMN (REMOVE COMMAS)--

-- STUDY (NATIONALITY)
UPDATE Study_Applications_By_Nationality
SET Applications = REPLACE(Applications, ',', '');

-- STUDY (INSTITUTION)
UPDATE Study_Applications_By_Institution
SET Applications = REPLACE(Applications, ',', '');

-- WORK (NATIONALITY)
UPDATE Work_Applications_By_Nationality
SET Applications = REPLACE(Applications, ',', '');

-- WORK (INDUSTRY)
UPDATE Work_Applications_By_Industry
SET Applications = REPLACE(Applications, ',', '');

-- 1.2 ENSURE CORRECT DATA TYPES--

-- STUDY (NATIONALITY)
ALTER TABLE Study_Applications_By_Nationality 
    ALTER COLUMN Year SMALLINT;
ALTER TABLE Study_Applications_By_Nationality 
    ALTER COLUMN Quarter NVARCHAR(20);
ALTER TABLE Study_Applications_By_Nationality 
    ALTER COLUMN Applications INT;

-- STUDY (INSTITUTION)
ALTER TABLE Study_Applications_By_Institution 
    ALTER COLUMN Year SMALLINT;
ALTER TABLE Study_Applications_By_Institution 
    ALTER COLUMN Quarter NVARCHAR(20);
ALTER TABLE Study_Applications_By_Institution 
    ALTER COLUMN Applications INT;

-- WORK (NATIONALITY)
ALTER TABLE Work_Applications_By_Nationality 
    ALTER COLUMN Year SMALLINT;
ALTER TABLE Work_Applications_By_Nationality 
    ALTER COLUMN Quarter NVARCHAR(20);
ALTER TABLE Work_Applications_By_Nationality 
    ALTER COLUMN Applications INT;

-- WORK (INDUSTRY)
ALTER TABLE Work_Applications_By_Industry 
    ALTER COLUMN Year SMALLINT;
ALTER TABLE Work_Applications_By_Industry 
    ALTER COLUMN Quarter NVARCHAR(20);
ALTER TABLE Work_Applications_By_Industry 
    ALTER COLUMN Applications INT;


--2.FIX MISSING OR INCONSISTENT VALUES--
--2.1 TRIM TEXT AND FIX EMPTY STRINGS--

UPDATE Study_Applications_By_Nationality
SET Applicant_Nationality = NULLIF(LTRIM(RTRIM(Applicant_Nationality)), '');

UPDATE Study_Applications_By_Institution
SET Institution_type = NULLIF(LTRIM(RTRIM(Institution_type)), '');

UPDATE Work_Applications_By_Nationality
SET Applicant_Nationality = NULLIF(LTRIM(RTRIM(Applicant_Nationality)), '');

UPDATE Work_Applications_By_Industry
SET Industry_Type = NULLIF(LTRIM(RTRIM(Industry_Type)), '');


--2.2 REPLACE NULL TEXT WITH 'Unknown'--

UPDATE Study_Applications_By_Nationality
SET Applicant_Nationality = 'Unknown'
WHERE Applicant_Nationality IS NULL;

UPDATE Work_Applications_By_Nationality
SET Applicant_Nationality = 'Unknown'
WHERE Applicant_Nationality IS NULL;

UPDATE Study_Applications_By_Institution
SET Institution_type = 'Unknown'
WHERE Institution_type IS NULL;

UPDATE Work_Applications_By_Industry
SET Industry_Type = 'Unknown'
WHERE Industry_Type IS NULL;

--2.3 FIX APPLICATIONS COLUMN--

UPDATE Study_Applications_By_Nationality
SET Applications = 0
WHERE Applications IS NULL OR Applications < 0;

UPDATE Study_Applications_By_Institution
SET Applications = 0
WHERE Applications IS NULL OR Applications < 0;

UPDATE Work_Applications_By_Nationality
SET Applications = 0
WHERE Applications IS NULL OR Applications < 0;

UPDATE Work_Applications_By_Industry
SET Applications = 0
WHERE Applications IS NULL OR Applications < 0;


--3 STANDARDISE QUARTER FORMAT ('2010 Q1' → 'Q1')--

UPDATE Study_Applications_By_Nationality
SET Quarter = 'Q' + RIGHT(Quarter,1)
WHERE Quarter LIKE '%Q%';

UPDATE Study_Applications_By_Institution
SET Quarter = 'Q' + RIGHT(Quarter,1)
WHERE Quarter LIKE '%Q%';

UPDATE Work_Applications_By_Nationality
SET Quarter = 'Q' + RIGHT(Quarter,1)
WHERE Quarter LIKE '%Q%';

UPDATE Work_Applications_By_Industry
SET Quarter = 'Q' + RIGHT(Quarter,1)
WHERE Quarter LIKE '%Q%';

--4 RENAME COLUMNS FOR READABILITY--

-- STUDY (NATIONALITY)
EXEC sp_rename 'Study_Applications_By_Nationality.Type_of_application', 'Application_Type', 'COLUMN';
EXEC sp_rename 'Study_Applications_By_Nationality.Institution_type_group', 'Institution_Group', 'COLUMN';
EXEC sp_rename 'Study_Applications_By_Nationality.Geographical_region', 'Geographical_Region', 'COLUMN';
EXEC sp_rename 'Study_Applications_By_Nationality.Nationality', 'Applicant_Nationality', 'COLUMN';

-- STUDY (INSTITUTION)
EXEC sp_rename 'Study_Applications_By_Institution.Type_of_application', 'Application_Type', 'COLUMN';
EXEC sp_rename 'Study_Applications_By_Institution.Institution_type_group', 'Institution_Group', 'COLUMN';
EXEC sp_rename 'Study_Applications_By_Institution.Institution_type', 'Institution_Type', 'COLUMN';

-- WORK (NATIONALITY)
EXEC sp_rename 'Work_Applications_By_Nationality.Type_of_application', 'Application_Type', 'COLUMN';
EXEC sp_rename 'Work_Applications_By_Nationality.Category_of_leave', 'Leave_Category', 'COLUMN';
EXEC sp_rename 'Work_Applications_By_Nationality.Geographical_region', 'Geographical_Region', 'COLUMN';
EXEC sp_rename 'Work_Applications_By_Nationality.Nationality', 'Applicant_Nationality', 'COLUMN';

-- WORK (INDUSTRY)
EXEC sp_rename 'Work_Applications_By_Industry.Type_of_application', 'Application_Type', 'COLUMN';
EXEC sp_rename 'Work_Applications_By_Industry.Category_of_leave', 'Leave_Category', 'COLUMN';
EXEC sp_rename 'Work_Applications_By_Industry.Industry', 'Industry_Type', 'COLUMN';


--5.CREATE POWER BI-FRIENDLY AGGREGATED VIEWS--
--5.1 AGGREGATE STUDY DATA BY YEAR/QUARTER/NATIONALITY--

CREATE VIEW vw_Study_Aggregated AS
SELECT 
    Year,
    Quarter,
    Applicant_Nationality,
    Institution_Group,
    SUM(Applications) AS Total_Applications
FROM Study_Applications_By_Nationality
GROUP BY 
    Year, Quarter, Applicant_Nationality, Institution_Group;

--5.2 AGGREGATE WORK DATA (BY NATIONALITY)--

CREATE VIEW vw_Work_Aggregated AS
SELECT 
    Year,
    Quarter,
    Applicant_Nationality,
    Leave_Category,
    SUM(Applications) AS Total_Applications
FROM Work_Applications_By_Nationality
GROUP BY 
    Year, Quarter, Applicant_Nationality, Leave_Category;

--5.3 FILTER LAST 5 YEARS FOR FASTER POWER BI PERFORMANCE--

IF OBJECT_ID('vw_AllApps_Last5Years', 'V') IS NOT NULL
    DROP VIEW vw_AllApps_Last5Years;
GO

CREATE VIEW vw_AllApps_Last5Years AS
SELECT 
      Year,
    Quarter,
	Application_Type,
    Applicant_Nationality,
    Applications,
	Geographical_region,
    'Study' AS App_Type
FROM Study_Applications_By_Nationality
WHERE Year >= YEAR(GETDATE()) - 5

UNION ALL

SELECT 
    Year,
    Quarter,
	Application_Type,
    Applicant_Nationality,
    Applications,
	Geographical_region,
    'Work' AS App_Type
FROM Work_Applications_By_Nationality
WHERE Year >= YEAR(GETDATE()) - 5;


