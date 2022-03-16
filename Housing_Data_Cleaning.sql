/*

Data Cleaning with SQL (MySQL)
[Raw data](https://github.com/n-lydia/SQL-Projects/blob/main/Nashville%20Housing%20Data%20for%20Data%20Cleaning.xlsx)

The goal of this project is to practice and demonstrate data cleaning skills using SQL such as:
Format Standardization | Split column value | Change boolean value | Remove Duplicate | Remove unused columns

*/

-- Raw data to work on

SELECT *
FROM DataCleaning..Housing

/* Rows includes:
UniqueID | ParcelID | LandUse | PropertyAddress | SaleDate | SalePrice | LegalReference | SoldAsVacant | OwnerName | OwnerAddress | Acreage | TaxDistrict | LandValue | BuildingValue | TotalValue | YearBuilt | Bedrooms | FullBath | HalfBath
*/


-- Standardize Date Format of SaleDate

ALTER TABLE DataCleaning..Housing
ADD SaleDateConverted date;

Update Housing
SET SaleDateConverted = CONVERT(Date, SaleDate);

SELECT SaleDateConverted
FROM DataCleaning..Housing;


-- Populate PropertyAddress data using ParcelID as reference

SELECT 
	a.ParcelID,
	a.PropertyAddress,
	b.ParcelID,
	b.PropertyAddress,
	ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM DataCleaning..Housing a
JOIN DataCleaning..Housing b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID 
WHERE a.PropertyAddress IS NULL;

Update a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM DataCleaning..Housing a
JOIN DataCleaning..Housing b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID 
WHERE a.PropertyAddress IS NULL;


-- Split PropertyAddress into detailed columns (Address, City)

SELECT 
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as City
FROM DataCleaning..Housing;


ALTER TABLE DataCleaning..Housing
ADD PropertySplitAddress nvarchar(255);

Update Housing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1);


ALTER TABLE DataCleaning..Housing
ADD PropertyCity nvarchar(255);

Update Housing
SET PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress));


-- Split OwnerAddress into detailed columns (Address, City,State)

SELECT
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) as OwnerAddress,
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) as OwnerCity,
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) as OwnerState
From DataCleaning..Housing;


ALTER TABLE DataCleaning..Housing
ADD OwnerSplitAddress nvarchar(255);

Update Housing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3);


ALTER TABLE DataCleaning..Housing
ADD OwnerCity nvarchar(255);

Update Housing
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2);


ALTER TABLE DataCleaning..Housing
ADD OwnerState nvarchar(255);

Update Housing
SET OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);


-- Standardize boolean value ('Y' & 'N' to 'Yes' & 'No' in SoldAsVacant)

Update Housing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
						END


-- Remove duplicates

WITH RowNum as 
(SELECT *,
	ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
						ORDER BY UniqueID) as row_num
FROM DataCleaning..Housing)

DELETE
FROM RowNum
WHERE row_num > 1


-- Delete unused columns

ALTER TABLE DataCleaning..Housing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate