select * from PortfolioProject..CovidDeaths
Where continent is not null
order by 3,4

select * from PortfolioProject..CovidVaccinations
Where continent is not null
order by 3,4

-- Select Data to be using

select Location, date, total_cases, new_cases,total_deaths, population
from PortfolioProject..CovidDeaths
Where continent is not null
order by 1,2

-- Looking at Total cases vs Total Deaths
-- Likelyhood of dying if you contract Covid19

select Location, date, total_cases,total_deaths, total_deaths/total_cases*100 as FatalityRate_pc
from PortfolioProject..CovidDeaths
--where location like  'ita%'
Where continent is not null
order by 1,2 desc

-- Looking at TotalCases vs Population
-- Shows what percentage of the population had covid



select Location, date, population, total_cases, total_cases/population*100 as IncidenceRate
from PortfolioProject..CovidDeaths
Where continent is not null
--where location like  '%states%'
order by 1,2 desc


-- Looking at the highest Indicence rate

select Location, population, max (total_cases) HighestInfectionCount,
max((total_cases/population))*100 as IncidenceRate
from PortfolioProject..CovidDeaths
--where location like 'fra%' or location like 'ita%'
Where continent is not null
group by location, population
Order by  IncidenceRate desc

-- Looking at the highest mortality rate

select Location, population, max (total_deaths) HighestDeathsCount,
max((total_deaths/population))*100 as MortalityRate
from PortfolioProject..CovidDeaths
--where location like 'fra%' or location like 'ita%'
Where continent is not null
group by location, population
Order by  MortalityRate desc


select Location,  max(cast (total_deaths as int)) tot
from PortfolioProject..CovidDeaths
Where continent is not null
group by location
order by tot desc

-- Let's break things down by Continent
-- Showing continents with highest deaths count


select location,  max (total_deaths) TotalDeathCount
from PortfolioProject..CovidDeaths
where continent is null
and location not like '%income%' 
and location not like '%union%'
and location <> 'World'
and location <> 'International'
group by location
order by TotalDeathCount desc

--GLOBAL NUMBERS

-- Total number of cases, deaths, death percentage per day accross the world

select date, sum(new_cases) World_Total_Cases, SUM(cast(new_deaths as int)) World_Total_Deaths, SUM(cast(new_deaths as int))/sum(new_cases)*100 DeathPercent
from PortfolioProject..CovidDeaths
--where location like  'ita%'
Where continent is not null
Group by date
order by 1,2

-- Total number of cases, deaths, death percentage accross the world


select sum(new_cases) World_Total_Cases, SUM(cast(new_deaths as int)) World_Total_Deaths, SUM(cast(new_deaths as int))/sum(new_cases)*100 DeathPercent
from PortfolioProject..CovidDeaths
--where location like  'ita%'
Where continent is not null
--Group by date
--order by 1,2

--Looking Popolation vs Vaccinations

select Deaths.continent,Deaths.location,Deaths.date, Deaths.population, new_vaccinations,
SUM(CONVERT(BIGINT, new_vaccinations)) over (partition by Deaths.location Order by deaths.location, deaths.date) as RollingNumberOfDoses
from PortfolioProject..CovidDeaths Deaths
join PortfolioProject..CovidVaccinations Vaccines	
on Deaths.location=Vaccines.location and Deaths.date=Vaccines.date
Where Deaths.continent is not null
and deaths.location = 'Canada'
order by 2,3

--USE CTE TO GET VACCINATED POPULATION PERCENTAGE WITH DOUBLE DOSE

With PopVsVac_CTE AS
(select Deaths.continent,Deaths.location,Deaths.date, Deaths.population, new_vaccinations,
SUM(CONVERT(BIGINT, new_vaccinations)) over (partition by Deaths.location Order by deaths.location, deaths.date) as RollingNumberOfDoses
from PortfolioProject..CovidDeaths Deaths
join PortfolioProject..CovidVaccinations Vaccines	
on Deaths.location=Vaccines.location and Deaths.date=Vaccines.date
Where Deaths.continent is not null)
--order by 2,3)
Select *,
(RollingNumberOfDoses/2)/population*100 as PercentageOfVaccinatedPopulation
from PopVsVac_CTE
--where location='Canada'
order by 2,3

-- USE TEMP TABLE TO GET VACCINATED POPULATION PERCENTAGE WITH DOUBLE DOSE


DROP TABLE IF EXISTS #PopVsVac_Temp
CREATE TABLE #PopVsVac_Temp
(continent NVarCHAR (255), location NVarCHAR (255), date datetime, population numeric, new_vaccinations numeric, RollingNumberOfDoses numeric)
INSERT INTO #PopVsVac_Temp
select Deaths.continent,Deaths.location,Deaths.date, Deaths.population, new_vaccinations,
SUM(CONVERT(BIGINT, new_vaccinations)) over (partition by Deaths.location Order by deaths.location, deaths.date) as RollingNumberOfDoses
from PortfolioProject..CovidDeaths Deaths
join PortfolioProject..CovidVaccinations Vaccines	
on Deaths.location=Vaccines.location and Deaths.date=Vaccines.date
Where Deaths.continent is not null


select *,
(RollingNumberOfDoses/2)/population*100 as PercentageOfVaccinatedPopulation
from #PopVsVac_Temp
--where location = 'Italy'
---order by PercentageOfVaccinatedPopulation desc


-- CREATE VIEWS TO STORE DATA FOR LATER VISUALIZATION

-- 1st VIEW: DosesVsPopoulation

CREATE VIEW DosesVSpPopulation AS
select Deaths.continent,Deaths.location,Deaths.date, Deaths.population, new_vaccinations,
SUM(CONVERT(BIGINT, new_vaccinations)) over (partition by Deaths.location Order by deaths.location, deaths.date) as RollingNumberOfDoses
from PortfolioProject..CovidDeaths Deaths
join PortfolioProject..CovidVaccinations Vaccines	
on Deaths.location=Vaccines.location and Deaths.date=Vaccines.date
Where Deaths.continent is not null

--2nd View: GlobalNumbers

CREATE VIEW GlobalNumbers AS
select sum(new_cases) World_Total_Cases, SUM(cast(new_deaths as int)) World_Total_Deaths, SUM(cast(new_deaths as int))/sum(new_cases)*100 DeathPercent
from PortfolioProject..CovidDeaths
--where location like  'ita%'
Where continent is not null
--Group by date
--order by 1,2

--3rd View: PercentageOfVaccinatedPopulation

CREATE VIEW VaccinatedPopulationPerLocationPerDay as
With PopVsVac_CTE AS
(select Deaths.continent,Deaths.location,Deaths.date, Deaths.population, new_vaccinations,
SUM(CONVERT(BIGINT, new_vaccinations)) over (partition by Deaths.location Order by deaths.location, deaths.date) as RollingNumberOfDoses
from PortfolioProject..CovidDeaths Deaths
join PortfolioProject..CovidVaccinations Vaccines	
on Deaths.location=Vaccines.location and Deaths.date=Vaccines.date
Where Deaths.continent is not null)
--and deaths.location = 'Canada')
--order by 2,3)
Select *,
(RollingNumberOfDoses/2)/population*100 as PercentageOfVaccinatedPopulation
from PopVsVac_CTE

--4th View: Fatality Rate per Location per Date

CREATE VIEW FatalityRatePerLocationPerDate AS
select Location, date, total_cases,total_deaths, total_deaths/total_cases*100 as FatalityRate_pc
from PortfolioProject..CovidDeaths
--where location like  'ita%'
Where continent is not null
--order by 1,2 desc