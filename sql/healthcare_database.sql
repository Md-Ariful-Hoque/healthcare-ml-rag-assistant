create database healthcare_project;
use healthcare_project;

/* create patients tables */

CREATE TABLE patients (
    Id VARCHAR(36) PRIMARY KEY,
    BIRTHDATE DATE,
    DEATHDATE DATE NULL,
    SSN VARCHAR(20),
    DRIVERS VARCHAR(20),
    PASSPORT VARCHAR(20),
    PREFIX VARCHAR(20),
    FIRST VARCHAR(100),
    LAST VARCHAR(100),
    SUFFIX VARCHAR(20),
    MAIDEN VARCHAR(100),
    MARITAL VARCHAR(10),
    RACE VARCHAR(50),
    ETHNICITY VARCHAR(50),
    GENDER VARCHAR(10),
    BIRTHPLACE VARCHAR(200),
    ADDRESS VARCHAR(200),
    CITY VARCHAR(100),
    STATE VARCHAR(100),
    COUNTY VARCHAR(100),
    ZIP VARCHAR(20),
    LAT DOUBLE,
    LON DOUBLE,
    HEALTHCARE_EXPENSES DOUBLE,
    HEALTHCARE_COVERAGE DOUBLE
) CHARACTER SET utf8mb4;

/* lead patients data */

LOAD DATA LOCAL INFILE 'csv/patients.csv'
INTO TABLE patients
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    Id,
    BIRTHDATE,
    @DEATHDATE,
    SSN,
    DRIVERS,
    PASSPORT,
    PREFIX,
    FIRST,
    LAST,
    SUFFIX,
    MAIDEN,
    MARITAL,
    RACE,
    ETHNICITY,
    GENDER,
    BIRTHPLACE,
    ADDRESS,
    CITY,
    STATE,
    COUNTY,
    ZIP,
    LAT,
    LON,
    HEALTHCARE_EXPENSES,
    HEALTHCARE_COVERAGE
)
SET DEATHDATE = NULLIF(@DEATHDATE, '');

select count(*) as total_patients
from patients;

/* create encounters table */

CREATE TABLE encounters (
    Id VARCHAR(36) PRIMARY KEY,
    START DATETIME,
    STOP DATETIME,
    PATIENT VARCHAR(36),
    ORGANIZATION VARCHAR(36),
    PROVIDER VARCHAR(36),
    PAYER VARCHAR(36),
    ENCOUNTERCLASS VARCHAR(50),
    CODE BIGINT,
    DESCRIPTION VARCHAR(255),
    BASE_ENCOUNTER_COST DOUBLE,
    TOTAL_CLAIM_COST DOUBLE,
    PAYER_COVERAGE DOUBLE,
    REASONCODE BIGINT NULL,
    REASONDESCRIPTION VARCHAR(255) NULL
) CHARACTER SET utf8mb4;

/* load encounters data*/

LOAD DATA LOCAL INFILE 'csv/encounters.csv'
INTO TABLE encounters
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    Id,
    @START,
    @STOP,
    PATIENT,
    ORGANIZATION,
    PROVIDER,
    PAYER,
    ENCOUNTERCLASS,
    CODE,
    DESCRIPTION,
    BASE_ENCOUNTER_COST,
    TOTAL_CLAIM_COST,
    PAYER_COVERAGE,
    @REASONCODE,
    @REASONDESCRIPTION
)
SET
    START = STR_TO_DATE(@START, '%Y-%m-%dT%H:%i:%sZ'),
    STOP = STR_TO_DATE(@STOP, '%Y-%m-%dT%H:%i:%sZ'),
    REASONCODE = NULLIF(@REASONCODE, ''),
    REASONDESCRIPTION = NULLIF(TRIM(TRAILING '\r' FROM @REASONDESCRIPTION), '');

SELECT COUNT(*) AS total_encounters
FROM encounters;

/* create condition table */

CREATE TABLE conditions (
    START DATE,
    STOP DATE NULL,
    PATIENT VARCHAR(36),
    ENCOUNTER VARCHAR(36),
    CODE BIGINT,
    DESCRIPTION VARCHAR(255)
) CHARACTER SET utf8mb4;

/* load condition data */
LOAD DATA LOCAL INFILE 'csv/conditions.csv'
INTO TABLE conditions
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    @START,
    @STOP,
    PATIENT,
    ENCOUNTER,
    CODE,
    @DESCRIPTION
)
SET
    START = STR_TO_DATE(@START, '%Y-%m-%d'),
    STOP = STR_TO_DATE(NULLIF(@STOP, ''), '%Y-%m-%d'),
    DESCRIPTION = TRIM(TRAILING '\r' FROM @DESCRIPTION);

SELECT COUNT(*) AS total_conditions
FROM conditions;

/* verify the relationships */

select
e.patient,
p.FIRST,
p.LAST,
e.ENCOUNTERCLASS,
e.DESCRIPTION
from encounters e
left join patients p
on e.PATIENT = p.Id
limit 10;

/* check encounter types */

select
ENCOUNTERCLASS,
count(*) as number_of_encounters
from encounters
group by ENCOUNTERCLASS
order by number_of_encounters desc;

/* patient-level encounter counts */

select
PATIENT,
count(*) as total_encounters
from encounters
group by PATIENT
order by total_encounters desc
limit 10;

/* add patient names*/

select
p.id,
p.first,
p.last,
count(e.id) as total_encounters
from patients p
left join encounters e
on p.id = e.patient
group by
p.id,
p.first,
p.last
ORDER BY total_encounters DESC
limit 10;

/* count emergency encounters per patient */
SELECT
    p.Id,
    p.FIRST,
    p.LAST,
    COUNT(e.Id) AS emergency_encounters
FROM patients p
LEFT JOIN encounters e
    ON p.Id = e.PATIENT
    AND e.ENCOUNTERCLASS = 'emergency'
GROUP BY
    p.Id,
    p.FIRST,
    p.LAST
ORDER BY emergency_encounters DESC
LIMIT 10;

/* inpatient encounters */
SELECT
    p.Id,
    p.FIRST,
    p.LAST,
    COUNT(e.Id) AS inpatient_encounters
FROM patients p
LEFT JOIN encounters e
    ON p.Id = e.PATIENT
    AND e.ENCOUNTERCLASS = 'inpatient'
GROUP BY
    p.Id,
    p.FIRST,
    p.LAST
ORDER BY inpatient_encounters DESC
LIMIT 10;

select
DESCRIPTION,
count(*) as condition_count
from conditions
group by
DESCRIPTION
order by condition_count desc
limit 10;

/* unique patients per condition */

select
DESCRIPTION,
count(DISTINCT patient) as unique_patients
from conditions
group by DESCRIPTION
order by unique_patients desc
limit 10;

/* combine conditions with patient demographics*/
select
p.GENDER,
count(DISTINCT c.patient) as unique_patients
from conditions c
left join patients p
on c.patient = p.id
where c.DESCRIPTION = 'Hypertension'
group by
p.GENDER
order by unique_patients desc;

/* hypertension percentage by gender */
select
p.GENDER,
count(DISTINCT c.patient) as unique_patients,
round(
count(DISTINCT c.patient) /
     (
     select
     count(DISTINCT PATIENT)
     from conditions c
     where c.DESCRIPTION = 'Hypertension'
     )*100, 2
) as percentage
from conditions c
left join patients p
on c.patient = p.id
where c.DESCRIPTION = 'Hypertension'
group by
p.GENDER
order by unique_patients desc;

/* compare hypertension prevalence by gender */

select
p.GENDER,
count(DISTINCT c.patient) as unique_patients,
round(
count(DISTINCT c.patient) /
     (
     select
     count(*)
     from patients p2
     where p2.GENDER = p.GENDER
     )*100, 2
) as hypertension_prevalence_percent
from conditions c
left join patients p
on c.patient = p.id
where c.DESCRIPTION = 'Hypertension'
group by
p.GENDER
order by unique_patients desc;


/* calculate age */
select
id,
first,
last,
gender,
BIRTHDATE,
TIMESTAMPDIFF(YEAR, BIRTHDATE, CURDATE()) as age
from patients
limit 10;

/* summarize age */
select
round(avg(TIMESTAMPDIFF(YEAR, BIRTHDATE, CURDATE())),2) as average_age,
min(TIMESTAMPDIFF(YEAR, BIRTHDATE, CURDATE())) as minimum_age,
max(TIMESTAMPDIFF(YEAR, BIRTHDATE, CURDATE())) as maximum_age
from patients;

/* create age groups */
select
id,
TIMESTAMPDIFF(YEAR, BIRTHDATE, CURDATE()) as age,
case
    when  TIMESTAMPDIFF(YEAR, BIRTHDATE, CURDATE())  <= 17 then 'child'
    when  TIMESTAMPDIFF(YEAR, BIRTHDATE, CURDATE())  <= 39 then 'Young Adult'
    when  TIMESTAMPDIFF(YEAR, BIRTHDATE, CURDATE())  <= 64 then 'Middle Aged'
    else 'Older Adult'
end    as age_group
from patients
limit 10;

select
case
    when  TIMESTAMPDIFF(YEAR, BIRTHDATE, CURDATE())  <= 17 then 'child'
    when  TIMESTAMPDIFF(YEAR, BIRTHDATE, CURDATE())  <= 39 then 'Young Adult'
    when  TIMESTAMPDIFF(YEAR, BIRTHDATE, CURDATE())  <= 64 then 'Middle Aged'
    else 'Older Adult'
end    as age_group,
count(*) as patient_count
from patients
GROUP BY age_group
order by patient_count desc
limit 10;

SELECT
    c.PATIENT,
    TIMESTAMPDIFF(YEAR, p.BIRTHDATE, CURDATE()) AS age,
    CASE
        WHEN TIMESTAMPDIFF(YEAR, p.BIRTHDATE, CURDATE()) <= 17 THEN 'Child'
        WHEN TIMESTAMPDIFF(YEAR, p.BIRTHDATE, CURDATE()) <= 39 THEN 'Young Adult'
        WHEN TIMESTAMPDIFF(YEAR, p.BIRTHDATE, CURDATE()) <= 64 THEN 'Middle Aged'
        ELSE 'Older Adult'
    END AS age_group
FROM conditions c
JOIN patients p
    ON c.PATIENT = p.Id
WHERE c.DESCRIPTION = 'Hypertension'
limit 10;

SELECT
    age_group,
    COUNT(DISTINCT PATIENT) AS hypertension_patients
FROM (
    SELECT
        c.PATIENT,
        CASE
            WHEN TIMESTAMPDIFF(YEAR, p.BIRTHDATE, CURDATE()) <= 17 THEN 'Child'
            WHEN TIMESTAMPDIFF(YEAR, p.BIRTHDATE, CURDATE()) <= 39 THEN 'Young Adult'
            WHEN TIMESTAMPDIFF(YEAR, p.BIRTHDATE, CURDATE()) <= 64 THEN 'Middle Aged'
            ELSE 'Older Adult'
        END AS age_group
    FROM conditions c
    JOIN patients p
        ON c.PATIENT = p.Id
    WHERE c.DESCRIPTION = 'Hypertension'
) AS hypertension_data
GROUP BY age_group
ORDER BY hypertension_patients DESC;

SELECT
    age_group,
    COUNT(*) AS total_patients,
    SUM(has_hypertension) AS hypertension_patients,
    ROUND(
        SUM(has_hypertension) / COUNT(*) * 100,
        2
    ) AS hypertension_prevalence_percent
FROM (
    SELECT
        p.Id,
        CASE
            WHEN TIMESTAMPDIFF(YEAR, p.BIRTHDATE, CURDATE()) <= 17 THEN 'Child'
            WHEN TIMESTAMPDIFF(YEAR, p.BIRTHDATE, CURDATE()) <= 39 THEN 'Young Adult'
            WHEN TIMESTAMPDIFF(YEAR, p.BIRTHDATE, CURDATE()) <= 64 THEN 'Middle Aged'
            ELSE 'Older Adult'
        END AS age_group,

        CASE
            WHEN EXISTS (
                SELECT 1
                FROM conditions c
                WHERE c.PATIENT = p.Id
                  AND c.DESCRIPTION = 'Hypertension'
            )
            THEN 1
            ELSE 0
        END AS has_hypertension

    FROM patients p
) AS patient_data

GROUP BY age_group
ORDER BY hypertension_prevalence_percent DESC;

SELECT COUNT(DISTINCT PATIENT) AS patients_with_conditions
FROM conditions;

SELECT
    COUNT(DISTINCT PATIENT) AS patients_with_encounters
FROM encounters;

/* start building the ML dataset */

SELECT
    p.Id AS patient_id,
    COUNT(e.Id) AS total_encounters,
    SUM(CASE WHEN e.ENCOUNTERCLASS = 'emergency' THEN 1 ELSE 0 END)
        AS emergency_encounters,
    SUM(CASE WHEN e.ENCOUNTERCLASS = 'inpatient' THEN 1 ELSE 0 END)
        AS inpatient_encounters,
    SUM(CASE WHEN e.ENCOUNTERCLASS = 'urgentcare' THEN 1 ELSE 0 END)
        AS urgentcare_encounters
FROM patients p
LEFT JOIN encounters e
    ON p.Id = e.PATIENT
GROUP BY p.Id
ORDER BY total_encounters DESC
LIMIT 10;
