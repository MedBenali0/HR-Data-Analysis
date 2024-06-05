DESCRIBE rh; /*information about the structure of the table 'rh' */

ALTER TABLE rh CHANGE COLUMN ï»¿id emp_id VARCHAR(20) NULL; /*Rename id column to emp_id*/

SET sql_safe_updates=0;     /*to allow update data values*/
UPDATE rh
SET birthdate = CASE
	WHEN birthdate LIKE "%/%" THEN date_format(str_to_date(birthdate,"%m/%d/%Y"),"%Y-%m-%d")
    WHEN birthdate LIKE "%-%" THEN date_format(str_to_date(birthdate,"%m-%d-%Y"),"%Y-%m-%d")
    ELSE null
END; /*converting 'birthdate' column into the YYYY-MM-DD format*/
SELECT birthdate FROM rh;
ALTER TABLE rh MODIFY COLUMN birthdate DATE; /*modify 'birthdate' column datatype*/

UPDATE rh
SET hire_date = CASE
	WHEN hire_date LIKE "%/%" THEN date_format(str_to_date(hire_date,"%m/%d/%Y"),"%Y-%m-%d")
    WHEN hire_date LIKE "%-%" THEN date_format(str_to_date(hire_date,"%m-%d-%Y"),"%Y-%m-%d")
    ELSE null
END; /*converting 'birthdate' column into the YYYY-MM-DD format*/
SELECT hire_date FROM rh;
ALTER TABLE rh MODIFY COLUMN hire_date DATE; /*modify 'hire_date' column datatype*/

UPDATE rh
SET termdate = date(str_to_date(termdate,"%Y-%m-%d %H:%i:%s UTC"))
WHERE termdate IS NOT NULL AND termdate != ""; /*converting the date and time format YYYY-MM-DD HH:MM:SS UTC for the 'termdate' column to a date format YYYY-MM-DD*/

SET SESSION sql_mode = 'ALLOW_INVALID_DATES';   /*to allow the string 0000-00-00 be a date value and convert it to date*/
UPDATE rh
SET termdate = IF(termdate = '', '0000-00-00', termdate)
WHERE termdate = ''; /*replacing empty string values for the 'termdate' column with '0000-00-00' */

ALTER TABLE rh MODIFY COLUMN termdate DATE; /*modify 'termdate' column datatype*/
SELECT termdate FROM rh;

ALTER TABLE rh ADD COLUMN age INT; /*add age column to the table */
UPDATE rh 
SET age = timestampdiff(YEAR,birthdate,CURDATE()); /*calculating the age based on the birthdate column and the current date*/
SELECT birthdate,age FROM rh;
SELECT min(age) as MINUMUM_AGE, max(age) as MAXIMUM_AGE FROM rh;
SELECT count(age) FROM rh WHERE age<18;


/* QUESTIONS TO ANSWER FOR THE COMPANY */
/* 1- WHAT'S THE GENDER BREAKDOWN OF EMPLOYEES IN THE COMPANY ? */
SELECT gender,count(*) AS number_of_emp
FROM rh
WHERE age >= 18 AND termdate = "0000-00-00"
GROUP BY gender;

/* 2- WHAT'S THE RACE/ETHNICITY BREAKDOWN OF EMPLOYEES IN THE COMPANY ? */
SELECT race,count(*) AS number_of_emp
FROM rh
WHERE age >= 18 AND termdate = "0000-00-00"
GROUP BY race
ORDER BY number_of_emp DESC;

/* 3- WHAT'S THE AGE DISTRIBUTION OF EMPLOYEES IN THE COMPANY ? */
SELECT 
	CASE
		WHEN age>=18 AND age<=24 THEN "18-24"
		WHEN age>=25 AND age<=34 THEN "25-34"
		WHEN age>=35 AND age<=44 THEN "35-44"
		WHEN age>=45 AND age<=54 THEN "45-54"
		WHEN age>=55 AND age<=64 THEN "55-64"
        ELSE "+65"
	END AS age_group, count(*) AS number_of_emp
FROM rh
WHERE age >= 18 AND termdate = "0000-00-00"
GROUP BY age_group
ORDER BY age_group;

SELECT 
	CASE
		WHEN age>=18 AND age<=24 THEN "18-24"
		WHEN age>=25 AND age<=34 THEN "25-34"
		WHEN age>=35 AND age<=44 THEN "35-44"
		WHEN age>=45 AND age<=54 THEN "45-54"
		WHEN age>=55 AND age<=64 THEN "55-64"
        ELSE "+65"
	END AS age_group,gender, count(*) AS number_of_emp
FROM rh
WHERE age >= 18 AND termdate = "0000-00-00"
GROUP BY age_group,gender
ORDER BY age_group,gender;

/* 4- HOW MANY EMPLOYEES WORK AT HEADQUARTERS VS REMOTE LOCATIONS ? */
SELECT location,count(*) AS number_of_emp
FROM rh
WHERE age>=18 AND termdate="0000-00-00"
GROUP BY location;

/* 5- WHAT'S THE AVERAGE LENGHT OF EMPLOYEMENT FOR EMPLOYEES WHO HAVE BEEN TEMINATED ? */
SELECT round(avg(timestampdiff(year,hire_date,termdate))) as AVERAGE_LENGHT_OF_EMPLOYEMENT
FROM rh
WHERE age>=18 AND termdate !="0000-00-00" AND termdate <= CURDATE();

/* 6- HOW DOES THE GENDER DISTRIBUTION VARY ACROSS DEPARTMENTS ? */
SELECT department,gender,count(*) AS number_of_emp
FROM rh
WHERE age>=18 AND termdate ="0000-00-00"
GROUP BY department,gender
ORDER BY department;

/* 7- WHAT'S THE DISTRIBUTION OF JOB TITLES ACROSS DEPARTMENTS ? */
SELECT jobtitle, count(*) AS number_of_emp
FROM rh
WHERE age>=18 AND termdate ="0000-00-00"
GROUP BY jobtitle
ORDER BY number_of_emp DESC;

/* 8- WHICH DEPARTMENT HAS THE HIGHEST TURNOVER RATE ? */
SELECT department, total_emp, terminated_count, terminated_count/total_emp AS termination_rate
FROM ( 
	SELECT department,
		   count(*) AS total_emp, 
           SUM(CASE WHEN termdate != "0000-00-00" AND termdate <= CURDATE() THEN 1 ELSE 0 END) AS terminated_count
	FROM rh
    WHERE age>=18
    GROUP BY department
) AS subquery
ORDER BY termination_rate DESC;
 
 /* 9- WHAT'S THE DISTRIBUTION OF EMPLOYEES BY CITY AND STATE ? */
 SELECT location_state,count(*) AS number_of_emp
 FROM rh
 WHERE age>=18 AND termdate ="0000-00-00"
 GROUP BY location_state
 ORDER BY number_of_emp DESC;
 
 SELECT location_city,count(*) AS number_of_emp
 FROM rh
 WHERE age>=18 AND termdate ="0000-00-00"
 GROUP BY location_city
 ORDER BY number_of_emp DESC;
 
/* 10- HOW HAS THE COMPANY'S EMPLOYEE COUNT CHANGED OVER TIME BASED ON HIRE AND TERMINATION DATES ? */
SELECT year, hires, terminations, hires-terminations as net_change , round(((hires-terminations)/hires)*100,2) AS net_change_percentage
FROM (
	 SELECT YEAR(hire_date) AS year,
			count(*) AS hires,
            SUM(CASE WHEN termdate != "0000-00-00" AND termdate<= CURDATE() THEN 1 ELSE 0 END) AS terminations
	FROM rh
	WHERE age>=18
    GROUP BY year
) AS subquery
ORDER BY year ASC;

/* 11- WHAT'S THE TENURE DISTIBUTION OF EACH DEPARTMENT ? */
SELECT department, round(avg(datediff(termdate,hire_date)/365),0) AS avg_tenure
FROM rh
WHERE age>=18 AND termdate != "0000-00-00" AND termdate <= CURDATE()
GROUP BY department;
