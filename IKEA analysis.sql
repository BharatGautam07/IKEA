-- CHECK ROW COUNTS AFTER IMPORT
select * from dbo.[year 2009-2010]
SELECT COUNT(*) AS Rows_2009_2010 FROM dbo.[Year 2009-2010];
SELECT COUNT(*) AS Rows_2010_2011 FROM dbo.[Year 2010-2011];

-- COMBINE BOTH YEAR AND CONVERT TYPES SAFELY
SELECT 
	invoice, StockCode, Description, Quantity,
	COALESCE(
			TRY_CONVERT(datetime2, InvoiceDate, 120),
			TRY_CONVERT(datetime2, InvoiceDate, 105)
	) AS InvoiceDate,
	TRY_CONVERT(decimal(10,2), Price) AS Price,
	Customer_ID, Country, '2009-2010' AS SourceSheet
INTO dbo.RetailCombined
FROM dbo.[Year 2009-2010]

UNION ALL

SELECT 
	invoice, StockCode, Description, Quantity,
	COALESCE(
			TRY_CONVERT(datetime2, InvoiceDate, 120),
			TRY_CONVERT(datetime2, InvoiceDate, 105)
	) AS InvoiceDate,
	TRY_CONVERT(decimal(10,2), Price) AS Price,
	Customer_ID, Country, '2010-2011' AS SourceSheet
FROM dbo.[Year 2010-2011];

-- CONFIRM THE CONVERSION WORKED CLEANLY
SELECT COUNT(*) AS Total_Rows FROM dbo.RetailCombined;
SELECT COUNT(*) AS Failed_Dates FROM dbo.RetailCombined WHERE InvoiceDate IS NULL;
SELECT COUNT(*) AS Failed_Price FROM dbo.RetailCombined WHERE Price IS NULL;

-- CHECK 1 - MISSING CUSTOMER ID 
SELECT COUNT(*) AS Missing_Customer_ID
FROM dbo.RetailCombined
WHERE Customer_ID IS NULL;

-- CHECK 2 - NEGITIVE AND ZERO QUANTITY
SELECT COUNT(*) AS Negitive_Qty
FROM dbo.RetailCombined
WHERE Quantity <= 0;

-- CHECK 3 - MISSING DESCRIPTION
SELECT COUNT(*) AS Missing_Description
FROM dbo.RetailCombined
WHERE Description IS NULL;

-- CHECK 4 - EXACT DUPLICATE ROWS
SELECT invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer_ID, Country,
		COUNT(*) AS ExactDupeCount
FROM dbo.RetailCombined
GROUP BY invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer_ID, Country
HAVING COUNT(*) > 1;

-- DEDUPLICATE AND PRODUCE THE FINAL CLEAND TABLE
WITH deduped AS(
	SELECT *,
			ROW_NUMBER() OVER(
				PARTITION BY invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer_ID, Country
				ORDER BY (SELECT NULL)
			) AS RowNum
	FROM dbo.RetailCombined
)
SELECT invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer_ID, Country, SourceSheet
INTO dbo.RetailCleaned
FROM deduped
WHERE RowNum = 1;

SELECT * FROM dbo.RetailCleaned;