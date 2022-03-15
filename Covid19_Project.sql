/*
Covid-19 Data Exploration with SQL (MySQL)
Data collected from [Our World in Data](https://ourworldindata.org/covid-deaths)
Data updated in: 2022-03-14

The goal of this project is to practice and demonstrate personal usage of SQL as skills included:
Aggregate Functions | Converting Data Types | Joins | CTE | Windows Functions | Temp Table | Creating Views 

Note: After downloading, data is splitted into 2 tables for data manipulation demonstrations.
*/

-- OVERVIEW OF COVID-19 SITUATION WORLDWIDE

-- Total Cases, Total Deaths & Death Percentage by Covid-19 Worldwide until date (Round the percentage value to 4 decimal places)

SELECT
	SUM(new_cases) as w_total_cases,
	SUM(CAST(new_deaths as bigint)) as w_total_deaths,
	ROUND(SUM(CAST(new_deaths as bigint)) / SUM(new_cases) * 100, 4) as w_death_percentage
FROM Covid19_Project..Deaths
WHERE location = 'World';


-- Highest Covid-19 Death Count by Continent

SELECT
	continent,
	MAX(CAST(total_deaths AS bigint)) AS total_death_count
FROM Covid19_Project..Deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC;


-- Total Cases vs. Total Deaths per Country
-- The likelihood of dying among those infected with Covid-19 by Country by Date (Round the percentage value to 2 decimal places)

SELECT
	location,
	date,
	ROUND((total_deaths / total_cases) * 100, 2) AS death_percentage
FROM Covid19_Project..Deaths
WHERE total_deaths IS NOT NULL
AND continent IS NOT NULL
ORDER BY 1, 2;


-- Total Cases vs. Population by Country
-- The percentage of population infected with Covid-19 by Country by Date (Round the percentage value to 4 decimal places)

SELECT
	location,
	date,
	ROUND((total_cases / population) * 100, 4) AS infected_percentage
FROM Covid19_Project..Deaths
WHERE continent IS NOT NULL
ORDER BY 1,2;


-- Highest Covid-19 Infections Rate per capita by country (Round the percentage value to 2 decimal places)

SELECT
	location,
	population,
	MAX(total_cases) AS highest_infection_count,
	MAX(ROUND((total_cases / population) * 100, 2)) AS latest_infection_percentage
FROM Covid19_Project..Deaths
WHERE continent IS NOT NULL
AND population IS NOT NULL
GROUP BY location, population
ORDER BY latest_infection_percentage DESC;


-- Highest Covid-19 Death Count by country until date

SELECT
	location,
	MAX(CAST(total_deaths AS bigint)) AS total_death_count
FROM Covid19_Project..Deaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC;



-- COVID-19 VACCINATION OVERVIEW

-- Total Vaccination vs. Total Population
-- The percentage of population that had received at least 1 Covid-19 vaccine
-- Using CTE and Window Function

With RollingVac as
(SELECT
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	SUM(CONVERT(bigint,v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) as rolling_vaccination_count
FROM Covid19_Project..Deaths as d
JOIN Covid19_Project..Vaccinations as v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL) 

SELECT *,
	ROUND((rolling_vaccination_count / population) * 100, 4) as vaccination_percentage
FROM RollingVac
WHERE rolling_vaccination_count IS NOT NULL
ORDER BY location, date;


-- Using Temp Table

DROP TABLE IF EXISTS #VaccinationPercentage
CREATE TABLE #VaccinationPercentage
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_vaccination_count numeric
)

INSERT INTO #VaccinationPercentage
SELECT
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	SUM(CONVERT(bigint,v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) as rolling_vaccination_count
FROM Covid19_Project..Deaths as d
JOIN Covid19_Project..Vaccinations as v
	ON d.location = v.location
	AND d.date = v.date

SELECT *,
	(rolling_vaccination_count / population ) * 100
FROM #VaccinationPercentage;
	

-- Create View to store data for later visualization

CREATE VIEW VaccinationPercentage as
SELECT
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	SUM(CONVERT(bigint,v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) as rolling_vaccination_count
FROM Covid19_Project..Deaths as d
JOIN Covid19_Project..Vaccinations as v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL


