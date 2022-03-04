--From Datetime to date
ALTER TABLE PortfolioProject..CovidDeaths
ALTER COLUMN date Date;


-- Data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;


-- CASE FATALITY RATE (CFR)
-- It is the ratio between confirmed deaths and confirmed cases. Note that it is "confirmed" cases, not total cases.
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS CFR
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;


-- CRUDE MORTALITY RATE, or CRUDE DEATH RATE
-- It is the number of deaths from COVID-19 divided by the total population of a geographic area
SELECT location, date, population, total_deaths, (total_deaths/population)*100 AS CrudeMortalityRate
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;


-- INFECTION RATE
SELECT location, date, population, new_cases, total_cases, (new_cases/population)*100 AS DailyInfectionRate, (total_cases/population)*100 AS CumulativeInfectionRate
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;


-- Countries order by highest infection rate (cumulative)
SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount, (MAX(total_cases)/population)*100 AS HighestInfectionRate
FROM PortfolioProject..CovidDeaths
WHERE total_cases IS NOT NULL 
AND population IS NOT NULL 
AND continent IS NOT NULL
GROUP BY Location, population
ORDER BY HighestInfectionRate DESC;


-- Countries order by highest death count 
SELECT Location, MAX(CAST(total_deaths AS BIGINT)) AS HighestDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY HighestDeathCount DESC;


-- Continents order by highest death count
SELECT continent, MAX(CAST(total_deaths AS BIGINT)) AS HighestDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY HighestDeathCount DESC;


-- Global Numbers
SELECT date, SUM(new_cases) AS GlobalCases, SUM(CAST(new_deaths AS INT)) AS GlobalDeaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS GlobalCFR -- CFR: Case Fatality Rate
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1;
-- TOTAL
SELECT SUM(new_cases) AS GlobalCases, SUM(CAST(new_deaths AS INT)) AS GlobalDeaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS GlobalCFR -- CFR: Case Fatality Rate
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL;


-- Share of people that has received (at least) one dose of COVID-19 vaccine (by country)
SELECT D.continent, D.location, D.date, population, V.new_vaccinations,
SUM(CONVERT(BIGINT, V.new_vaccinations)) OVER (PARTITION BY D.location ORDER BY D.location, D.date) AS CumulativePeopleVaccinated
FROM PortfolioProject..CovidDeaths D
JOIN PortfolioProject..CovidVaccinations V
     ON D.location = V.location
     AND D.date = V.date
WHERE D.continent IS NOT NULL
ORDER BY D.location, D.date;


-- Percentage of population that has received (at least) one dose of COVID-19 vaccine (by country)
-- Using CTE (Common Table Expression):
WITH PopVac (continent, location, date, population, new_vaccinations, CumulativePeopleVaccinated)
AS 
(
SELECT D.continent, D.location, D.date, population, V.new_vaccinations,
SUM(CONVERT(BIGINT, V.new_vaccinations)) OVER (PARTITION BY D.location ORDER BY D.location, D.date) AS CumulativePeopleVaccinated
FROM PortfolioProject..CovidDeaths D
JOIN PortfolioProject..CovidVaccinations V
     ON D.location = V.location
     AND D.date = V.date
WHERE D.continent IS NOT NULL
)
SELECT *, (CumulativePeopleVaccinated/population)*100 AS Percentage
FROM PopVac
ORDER BY location, date;


-- Using Temp Table:
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date date,
Population numeric,
new_vaccinations numeric,
CumulativePeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT D.continent, D.location, D.date, population, V.new_vaccinations,
SUM(CONVERT(BIGINT, V.new_vaccinations)) OVER (PARTITION BY D.location ORDER BY D.location, D.date) AS CumulativePeopleVaccinated
FROM PortfolioProject..CovidDeaths D
JOIN PortfolioProject..CovidVaccinations V
     ON D.location = V.location
     AND D.date = V.date
WHERE D.continent IS NOT NULL

SELECT *, (CumulativePeopleVaccinated/population)*100 AS Percentage
FROM #PercentPopulationVaccinated
ORDER BY location, date;


-- Creating View to store data for visualizations 
CREATE VIEW dbo.PercentPopulationVaccinated AS 
(
SELECT D.continent, D.location, D.date, population, V.new_vaccinations,
SUM(CONVERT(BIGINT, V.new_vaccinations)) OVER (PARTITION BY D.location ORDER BY D.location, D.date) AS CumulativePeopleVaccinated
FROM PortfolioProject..CovidDeaths D
JOIN PortfolioProject..CovidVaccinations V
     ON D.location = V.location
     AND D.date = V.date
WHERE D.continent IS NOT NULL
);

--DROP VIEW PercentPopulationVaccinated
