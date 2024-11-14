SELECT *
FROM [Portfolio Project]..CovidDeath$
WHERE continent is not null
ORDER BY 3,4

SELECT *
FROM [Portfolio Project]..CovidVax$
ORDER BY 3,4

SELECT 
	location,
	date,
	total_cases,
	new_cases,
	total_deaths,
	population
FROM [Portfolio Project]..CovidDeath$
ORDER BY 1,2

-- Total Case vs Total Death
-- Seberapa besar angka kematian akibat COVID (%)
SELECT 
	location,
	date,
	total_cases,
	total_deaths,
	(total_deaths/total_cases)*100 AS DeathPercentage
FROM [Portfolio Project]..CovidDeath$
WHERE
	total_cases > 0 AND
	location = 'Indonesia'
ORDER BY 1,2

-- Total Case VS Population

SELECT 
	location,
	date,
	total_cases,
	population,
	(total_cases/population)*100 AS CasePercentage
FROM [Portfolio Project]..CovidDeath$
WHERE
	location = 'Indonesia'
ORDER BY 1,2

--  Infeksi Populasi Tertinggi (Negara)

SELECT 
	location,
	MAX(total_cases) AS HighestIfection,
	population,
	MAX((total_cases/population)*100) AS PopulationInfection
FROM [Portfolio Project]..CovidDeath$
GROUP BY location, population
ORDER BY 4 DESC

-- Kematian Tertinggi (Negara)

SELECT 
	location,
	MAX(total_deaths) AS TotalDeath,
	population
FROM [Portfolio Project]..CovidDeath$
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 2 DESC

-- Kematian Tertinggi (Benua)

SELECT 
	location,
	MAX(total_deaths) AS TotalDeath
FROM [Portfolio Project]..CovidDeath$
WHERE continent IS NULL
GROUP BY location
ORDER BY 2 DESC

-- Kematian Tertinggi vs Populasi (Benua)

SELECT continent, MAX(Total_deaths) as TotalDeathCount 
FROM [Portfolio Project]..CovidDeath$
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- GLOBAL NUMBERS

SELECT 
--	date,
	SUM(new_cases) AS NewCases,
	SUM(new_deaths) AS NewDeath,
	SUM(new_deaths)/SUM(new_cases) * 100 AS DeathPercentage
FROM [Portfolio Project]..CovidDeath$
WHERE
	continent IS NOT NULL AND
	new_cases > 0
--	location = 'Indonesia'
--GROUP BY date
ORDER BY 1,2

-- Total Population vs Vaxed

SELECT 
	ded.continent,
	population,
	ded.location,
	ded.date,
	vax.new_vaccinations,
	SUM(CONVERT(BIGINT,new_vaccinations)) OVER (PARTITION BY ded.location ORDER BY ded.location, ded.date) AS OveralVaccinated
FROM [Portfolio Project]..CovidVax$ as vax
JOIN [Portfolio Project]..CovidDeath$ ded
	ON vax.location = ded.location AND ded.date = vax.date
WHERE ded.continent IS NOT NULL
ORDER BY 3,2

-- CTE

WITH OverallVax (continent, location, date, population, new_vaccinations, overallVaccinated)
AS ( 
SELECT 
	ded.continent,
	ded.location,
	ded.date,
	population,
	vax.new_vaccinations,
	SUM(CONVERT(BIGINT,new_vaccinations)) OVER (PARTITION BY ded.location ORDER BY ded.location, ded.date) AS OverallVaccinated
FROM [Portfolio Project]..CovidVax$ as vax
JOIN [Portfolio Project]..CovidDeath$ ded
	ON vax.location = ded.location AND ded.date = vax.date
WHERE ded.continent IS NOT NULL
--ORDER BY 3,2
)
SELECT *, (overallVaccinated/population)*100 
FROM OverallVax

-- TEMP TABLE

DROP TABLE IF EXISTS #PercentPopulationVaxed
CREATE TABLE #PercentPopulationVaxed
(
    continent nvarchar(255),
    location nvarchar(255),
    date datetime,
    population numeric,
    new_vaccinations numeric,
    RollingPeopleVaccinated numeric
);

INSERT INTO #PercentPopulationVaxed
SELECT 
    ded.continent,
    ded.location,
    ded.date,
    population,
    vax.new_vaccinations,
    SUM(CONVERT(BIGINT, new_vaccinations)) OVER (PARTITION BY ded.location ORDER BY ded.location, ded.date) AS RollingPeopleVaccinated
FROM [Portfolio Project]..CovidVax$ as vax
JOIN [Portfolio Project]..CovidDeath$ ded
    ON vax.location = ded.location AND ded.date = vax.date
WHERE ded.continent IS NOT NULL
ORDER BY 2,3
SELECT *, (RollingPeopleVaccinated / population) * 100 AS PercentPopulationVaccinated
FROM #PercentPopulationVaxed

-- CREATING VIEW

CREATE VIEW PercentPopulationVaxed AS
SELECT 
    ded.continent,
    ded.location,
    ded.date,
    population,
    vax.new_vaccinations,
    SUM(CONVERT(BIGINT, new_vaccinations)) OVER (PARTITION BY ded.location ORDER BY ded.location, ded.date) AS RollingPeopleVaccinated
FROM [Portfolio Project]..CovidVax$ as vax
JOIN [Portfolio Project]..CovidDeath$ ded
    ON vax.location = ded.location AND ded.date = vax.date
WHERE ded.continent IS NOT NULL
--ORDER BY 2,3

SELECT *
FROM PercentPopulationVaxed