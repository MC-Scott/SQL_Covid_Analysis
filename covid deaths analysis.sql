select *
From [dbo].[CovidDeaths]
--Where continent is not null
order by 3, 4

select *
From [dbo].['Covid Vaccinations']
order by 3, 4

select location, date, population, total_cases, total_deaths, new_cases
From [dbo].[CovidDeaths]
Where continent is not null
order by location, date -- ('order by 1,2' - but apparently this is bad practice because you should name the columns instead of assisgning numbers)

--Looking at total cases vs total deaths percentage
--Shows the likelihood of dying if you contract COVID in your country

select location, date, population, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_Percentage
From [dbo].[CovidDeaths]
Where location like '%kingdom%'
and continent is not null
order by location, date, Death_Percentage;

--Look at total cases vs population as percentage
--Shows what percentage of population has got covid

select location, date, population, total_cases, total_deaths, (total_cases/population)*100 as PercentPopInfected
From [dbo].[CovidDeaths]
Where location like '%kingdom%'
and continent is not null
order by location, date

--Look at countries with max infection count compared to population

select location, population, MAX(total_cases) as HighestInfectionCount, (MAX(total_cases/population))*100 as PercentPopInfected
From [dbo].[CovidDeaths]
Where continent is not null
Group by location, population
order by PercentPopInfected desc

--Countries with highest death rate per population

select location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From [dbo].[CovidDeaths]
Where continent is not null
Group by location
order by TotalDeathCount desc

--Breaking things down by continent (in data exploration we determined that where continent was null, the location column showed more in-depth metrics than the continent column itself- hence
--we select 'location' where 'continent' is null to display this data).

select location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From [dbo].[CovidDeaths]
Where continent is null
Group by location
order by TotalDeathCount desc

--Another way to get this data (which we have decided isn't as accurate but will facilitate the Tableau data visualisaitondwon the line)...

select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From [dbo].[CovidDeaths]
Where continent is not null
Group by continent
order by TotalDeathCount desc

--(My own code below) Showing the highest daily deaths as a percentage of Pop. 

--select location, date, new_deaths as DailyDeaths, (new_deaths/population)*100 as PercentPopDailyDeaths
--From [dbo].[CovidDeaths]
--Where continent is not null
--order by date desc 

--Total cases across the world (because SUM(total_cases) adds up all the total cases and we're grouping by 'date'

SELECT date AS 'Date', SUM(new_cases) AS 'Total Cases', SUM(cast(new_deaths AS int)) AS 'Total Deaths', SUM(cast(new_deaths AS int))/SUM(new_cases)*100 AS 'Death Percentage'
FROM [dbo].[CovidDeaths]
WHERE continent is not null
GROUP BY date
ORDER BY date,'Total Cases';

--Total cases, deaths and death percentage in the world

SELECT SUM(new_cases) AS 'Total Cases', SUM(cast(new_deaths AS int)) AS 'Total Deaths', SUM(cast(new_deaths AS int))/SUM(new_cases)*100 AS 'Death Percentage'
FROM [dbo].[CovidDeaths]
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2;

--Joining the two tables by their common columns; 'location' and 'date'

SELECT *
FROM [dbo].[CovidDeaths] dea
JOIN [dbo].['Covid Vaccinations'] vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY dea.location, dea.date;

--Looking at total pop that have been vaccinated

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM [dbo].[CovidDeaths] dea
JOIN [dbo].['Covid Vaccinations'] vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2, 3;

--Rolling count of vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations AS 'New Vaccinations'
, SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS 'Rolling Pop Vaccinated'
FROM [dbo].[CovidDeaths] dea
JOIN [dbo].['Covid Vaccinations'] vac
	ON dea.date = vac.date
	AND dea.location = vac.location
WHERE dea.continent is not null
ORDER BY 2, 3;

--Creating a CTE for column rolling pop vac in order to do the calculations required to create the column percentage vacc.

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPopVaccinated)
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations AS 'New Vaccinations'
, SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPopVaccinated
--, (RollingPopVaccinated/population)*100
FROM [dbo].[CovidDeaths] dea
JOIN [dbo].['Covid Vaccinations'] vac
	ON dea.date = vac.date
	AND dea.location = vac.location
WHERE dea.continent is not null
--ORDER BY 2, 3
)
SELECT *, (RollingPopVaccinated/population)*100 AS PercentagePopVaccinated
FROM PopvsVac

--A quick look at the code to create a temp table

CREATE TABLE #PercentagePopVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPopVaccinated numeric,
)

--DROP TABLE if exists #PercentagePopVaccinated
INSERT INTO #PercentagePopVaccinated

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations AS 'New Vaccinations'
, SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPopVaccinated
--, (RollingPopVaccinated/population)*100
FROM [dbo].[CovidDeaths] dea
JOIN [dbo].['Covid Vaccinations'] vac
	ON dea.date = vac.date
	AND dea.location = vac.location
WHERE dea.continent is not null
--ORDER BY 2, 3

SELECT *, (RollingPopVaccinated/population)*100
FROM #PercentagePopVaccinated

--Creating view to store data for leter visualisations

CREATE VIEW RollingPopVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations AS 'New Vaccinations'
, SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPopVaccinated
--, (RollingPopVaccinated/population)*100
FROM [dbo].[CovidDeaths] dea
JOIN [dbo].['Covid Vaccinations'] vac
	ON dea.date = vac.date
	AND dea.location = vac.location
WHERE dea.continent is not null
--ORDER BY 2, 3

--Another view

