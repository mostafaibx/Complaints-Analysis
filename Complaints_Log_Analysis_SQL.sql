


------------------------Adding the table to the database in postgradesql------------------------
------------------------------------------------------------------------------------------------

---creating a table in the database to import the csv file

CREATE TABLE Financal_complaints (
		Complaint_ID CHAR (50),
		Date_Sumbited CHAR (50), 
		Product	TEXT,
		Sub_product	TEXT,
		Issue TEXT,
		Sub_issue	TEXT,
		Company_public_response TEXT,
		Company	TEXT,
		State	TEXT,
		ZIP_code TEXT,
		Tags TEXT,
		Consumer_consent_provided TEXT,
		Submitted_via	TEXT,
		Date_received	CHAR (50),
		Company_response_to_consumer TEXT,
		Timely_response	TEXT,
		Consumer_disputed TEXT
                                   );
                                   
                                   
---Inserting data from CSV file

 copy public.financal_complaints (
               Complaint_ID,
	 	Date_Sumbited,	Product,
	 	Sub_product,
	 	Issue,
	 	Sub_issue,
	 	Company_public_response,
	 	Company,  State,
	 	ZIP_code,
	 	Tags,	
	 	Consumer_consent_provided,
	 	Submitted_via,
	 	Date_Received,
	 	Company_response_to_consumer,
	 	Timely_response,
	 	Consumer_disputed
) FROM 'D:/Financial Consumer Complaints.csv' DELIMITER ',' CSV  HEADER QUOTE '\' ESCAPE ';


---casting the correct data types for columns

ALTER TABLE financal_complaints ALTER COLUMN complaint_id TYPE INT USING CAST(complaint_id AS INT)

ALTER TABLE financal_complaints ALTER COLUMN date_sumbited TYPE DATE USING date_sumbited::date
--------ERROR:  date/time field value out of range: "8-20-20


--- checking the rows in the date_submitted to understand the date formates 

SELECT date_sumbited FROM financal_complaints

--- I found that we have 2 diffrent date formates (MM/DD/YY & YYYY-MM-DD)


--- in order to change them accordingly I nested a case expression in TO_DATE function

ALTER TABLE financal_complaints ALTER COLUMN date_sumbited TYPE DATE USING  TO_DATE(
         date_sumbited,
         CASE
           WHEN date_sumbited LIKE '%-%-%' THEN 'YYYY-MM-DD'
           WHEN date_sumbited LIKE '%/%/%' THEN 'MM/DD/YY'
         END
       )
       
ALTER TABLE financal_complaints ALTER COLUMN date_received TYPE DATE USING  TO_DATE(
         date_received,
         CASE
           WHEN date_received LIKE '%-%-%' THEN 'YYYY-MM-DD'
           WHEN date_received LIKE '%/%/%' THEN 'MM/DD/YY'
         END
       )
       
       
------------------------now we need to explore more in the data to clean it------------------------
---------------------------------------------------------------------------------------------------
 
SELECT DISTINCT product FROM financal_complaints
SELECT DISTINCT sub_product FROM financal_complaints

-----we have 8 values for products and 46 sub_products


-----select distinct rows to find any errors

SELECT product, sub_product 
FROM financal_complaints
GROUP BY 1,2
ORDER BY 1


-----updating samilar values with diffrent names and misspellings 

UPDATE financal_complaints
SET sub_product = 'Credit card'
WHERE sub_product = 'Credit card debt';

UPDATE financal_complaints
SET sub_product = 'credit loan' 
WHERE Sub_product = '""""""';

UPDATE financal_complaints
SET sub_product = 'Private student loan'
WHERE sub_product = 'Non-federal student loan' OR Sub_product = 'Private student loan debt';

...........

---checking values in issue and sub_issue

SELECT DISTINCT issue 
FROM financal_complaints 

-----we can see that there is repatative values with diffrent name 

----updating values

UPDATE financal_complaints
SET issue = 'Advertising and marketing'
WHERE issue ='Advertising';

UPDATE financal_complaints
SET issue = 'Closing an account'
WHERE issue ='Closing your account';

UPDATE financal_complaints
SET issue = 'Closing an account'
WHERE issue ='Closing your account' OR issue = 'Closing/Cancelling account';

.......

---we have 48178 NULL values in company_public_response

SELECT company_public_response 
FROM financal_complaints
WHERE company_public_response IS NULL


---we have 2 distinct responses only 

SELECT DISTINCT company_public_response 
FROM financal_complaints

----OUTPUT
"NULL"
"Company chooses not to provide a public response"
"Company has responded to the consumer and the CFPB and chooses not to provide a public response"


--- for each distinct issue we have one response 

SELECT issue, company_public_response
FROM financal_complaints
WHERE company_public_response IS NOT NULL
GROUP BY 1,2


------IMPUTATION
----therefore I replaced nulls for each issue with its response

WITH t2 AS (SELECT DISTINCT issue, company_public_response AS cpm FROM financal_complaints
WHERE company_public_response IS NOT NULL )

UPDATE financal_complaints
SET company_public_response = COALESCE (company_public_response, t2.cpm)
FROM t2
WHERE financal_complaints.issue = t2.issue AND financal_complaints.company_public_response IS NULL



------------------------Aggregation------------------------
-----------------------------------------------------------

--Multivariate Non-graphical:

---checking the percentages of values of one column according to another

SELECT issue, COUNT (*),
     ROUND (CAST (SUM (case when consumer_disputed = 'N/A' 
				  then 1 else 0 end) AS numeric) / CAST (COUNT (*) AS numeric)  *100,2) AS NA_perc,
     ROUND (CAST (SUM (case when consumer_disputed = 'Yes' 
				  then 1 else 0 end) AS numeric) / CAST (COUNT (*) AS numeric) *100,2) AS Yes_perc, 
	 ROUND (CAST (SUM (case when consumer_disputed = 'No' 
				  then 1 else 0 end) AS numeric) / CAST (COUNT (*) AS numeric) *100,2) AS no_perc
FROM financal_complaints
GROUP BY 1


SELECT submitted_via, COUNT (*),
     ROUND (CAST (SUM (case when timely_response = 'Yes' 
				  then 1 else 0 end) AS numeric) / CAST (COUNT (*) AS numeric) *100,2) AS Yes_perc, 
	 ROUND (CAST (SUM (case when timely_response = 'No' 
				  then 1 else 0 end) AS numeric) / CAST (COUNT (*) AS numeric) *100,2) AS no_perc
FROM financal_complaints
GROUP BY 1
 
..........

---Checking number of products caused issues per year

SELECT date_trunc('year', date_sumbited) AS date, product, COUNT (*)
FROM financal_complaints
GROUP BY 1,2
ORDER BY 1



 
