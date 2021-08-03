/*

Cleaning House Data in SQL Server

Data source: Nashville Housing Data.xlsx

*/

-- Quick overview of the data we have
SELECT *
FROM PortfolioProject..NashvilleHousing

--------------------------------------------------------
-- Standardize SaleDate format
SELECT SaleDate, CAST(SaleDate as date)
FROM PortfolioProject..NashvilleHousing

ALTER TABLE NashvilleHousing
ALTER COLUMN SaleDate date


---------------------------------------------------------
-- Populate Property Data Address

SELECT PropertyAddress
FROM PortfolioProject..NashvilleHousing
WHERE PropertyAddress is null

-- There are null values in propertyaddress, which is not common because addres usually keeps the same. Let�s take a look.
-- This query show us that when ParcelID is repeated, the propertyaddress is the same
SELECT *
FROM PortfolioProject..NashvilleHousing
-- WHERE PropertyAddress is null
order by ParcelID

-- Self-join with NashbilleHousing where parcelid is the same but the uniqueid is different. 
-- This will allows us to put b.propertyaddress where a.propertyaddress is null.
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID and
	a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null

-- Having made sure the query works, it is time to update de values where propertyaddress is null
UPDATE a
SET a.PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID and
	a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null 

------------------------------------------------------------------------
-- Splitting data from a column to individual columns, using two methods: SUBSTRING and PARSENAME

-- Breaking out Address into indivual columns (Address, City, State)
SELECT PropertyAddress, SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as Address,
SUBSTRING(PropertyAddress,CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) as State
FROM PortfolioProject..NashvilleHousing

-- Create individual column for the property address
ALTER TABLE PortfolioProject..NashvilleHousing
Add PropertySplitAddress Nvarchar(255)

UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

-- Create individual column for property city
ALTER TABLE PortfolioProject..NashvilleHousing
Add PropertySplitCity Nvarchar(255)

UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress,CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))

SELECT *
FROM PortfolioProject..NashvilleHousing

-- Display OnwneAddress
SELECT OwnerAddress
FROM PortfolioProject..NashvilleHousing

-- Separate owner address
SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) as Address,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) as City,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) as State
FROM PortfolioProject..NashvilleHousing

-- Create individual column for owner address
ALTER TABLE PortfolioProject..NashvilleHousing
Add OwnerSplitAddress Nvarchar(255)

UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

-- Create individual column for owner city
ALTER TABLE PortfolioProject..NashvilleHousing
Add OwnerSplitCity Nvarchar(255)

UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

-- Create individual column for owner state
ALTER TABLE PortfolioProject..NashvilleHousing
Add OwnerSplitState Nvarchar(255)

UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)


SELECT *
FROM PortfolioProject..NashvilleHousing

-------------------------------------------------------------------
-- Change Y and N to Yes and No "SoldAsVacant" field
SELECT distinct(SoldAsVacant), count(SoldAsVacant)
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END
FROM PortfolioProject..NashvilleHousing

UPDATE PortfolioProject..NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
					WHEN SoldAsVacant = 'N' THEN 'No'
					ELSE SoldAsVacant
					END

---------------------------------------------------------------------------
-- Remove duplicates using CTE

WITH RowNumCTE AS (
SELECT *,
	ROW_NUMBER() OVER (
	Partition by 
	ParcelID, 
	PropertyAddress, 
	SalePrice, 
	SaleDate, 
	LegalReference 
	Order by UniqueID) row_num
FROM PortfolioProject..NashvilleHousing
)

SELECT *
FROM RowNumCTE
WHERE row_num > 1


-------------------------------------------------------------------------
-- Delete Unused Columns

SELECT *
FROM PortfolioProject..NashvilleHousing

ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress