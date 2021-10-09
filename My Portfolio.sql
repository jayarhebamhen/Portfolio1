select * from PortfolioProject..CovidDeaths
Where continent is not null
order by 3,4

--select * from PortfolioProject..CovidVaccinations
--order by 3,4

--select the data we are going to be using

select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths
Where continent is not null
order by 1,2

--Looking at Total cases VS Total Deaths; shows the likelihood of dying from covid

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercent
from PortfolioProject..CovidDeaths
--where location like 'Nigeria'
order by 1,2

--Looking at Total cases VS Populaion; shows what percentage of the population has gotten covid

select location, date, total_cases, population, (total_cases/population)*100 as AffectedPercent
from PortfolioProject..CovidDeaths
where location like '%states%' and continent is not null
order by 1,2

--Looking at Countries with highest infection rate compared to population

select location,population, MAX (total_cases) AS HighestInfectionCount,
MAX((total_cases/population))*100 as PercentPopulationInfected
from PortfolioProject..CovidDeaths
Where continent is not null
Group By Location, population
order by PercentPopulationInfected desc


--Showing Countries with Highest Death count per Population

select location, MAX (cast (total_deaths as int)) AS TotaldeathCount
from PortfolioProject..CovidDeaths
Where continent is not null
Group By Location
order by TotaldeathCount desc

--By Continent

select location, MAX (cast (total_deaths as int)) AS TotaldeathCount
from PortfolioProject..CovidDeaths
Where continent is null
Group By location
order by TotaldeathCount desc


select continent, MAX (cast (total_deaths as int)) AS TotaldeathCount
from PortfolioProject..CovidDeaths
Where continent is not null
Group By continent
order by TotaldeathCount desc


--Global Numbers

select date, SUM(new_cases) as TotalNewCases, SUM (cast (new_deaths as int)) as TotalNewDeaths, 
(SUM (cast (new_deaths as int))/SUM(new_cases))*100 As DeathPercent
from PortfolioProject..CovidDeaths
where continent is not null
Group By date
order by 1,2

--used "SUM (cast (new_deaths as int))" to resolve this error response 
--"operand data type nvarchar is invalid for sum operator"

select SUM(new_cases) as TotalNewCases, SUM (cast (new_deaths as int)) as TotalNewDeaths, 
(SUM (cast (new_deaths as int))/SUM(new_cases))*100 As DeathPercent
from PortfolioProject..CovidDeaths
where continent is not null
order by 1,2


--Total Population vs Vaccinations

select dea.continent, dea.location,  dea.date, dea.population, vac.new_vaccinations as VaccinationsperDay
from PortfolioProject..CovidDeaths  dea
Join PortfolioProject..CovidVaccinations vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3

--Total Population vs Vaccinations Rolling count

select dea.continent, dea.location,  dea.date, dea.population, vac.new_vaccinations as VaccinationsperDay,
SUM (vac.new_vaccinations) OVER (PARTITION BY dea.location)
from PortfolioProject..CovidDeaths  dea
Join PortfolioProject..CovidVaccinations vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3

--Operand data type nvarchar is invalid for sum operator. use "SUM (cast (new_deaths as int))" 
--OR "SUM (convert(int,vac.new_vaccinations))"

select dea.continent, dea.location,  dea.date, dea.population, vac.new_vaccinations as VaccinationsperDay,
SUM (convert(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location order by dea.location, dea.date) as RollingCount
from PortfolioProject..CovidDeaths  dea
Join PortfolioProject..CovidVaccinations vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3

--People Vaccinated by Country/Location

select dea.continent, dea.location,  dea.date, dea.population, vac.new_vaccinations as VaccinationsperDay,
SUM (convert(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location order by dea.location, dea.date) as RollingCount,
(RollingCount/Population) * 100
from PortfolioProject..CovidDeaths  dea
Join PortfolioProject..CovidVaccinations vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- Error from Above:Invalid column name 'RollingCount'. We an't use an Alias. so we use CTE.

With PopvsVac(Continent, Location, Date, Population, new_vaccinations, RollingCount) 
AS
(select dea.continent, dea.location,  dea.date, dea.population, vac.new_vaccinations as VaccinationsperDay,
SUM (convert(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location order by dea.location, dea.date) as RollingCount
--(RollingCount/Population) * 100
from PortfolioProject..CovidDeaths  dea
Join PortfolioProject..CovidVaccinations vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)

SELECT * , (RollingCount/Population)*100

FROM PopvsVac



--TEMP TABLE

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar (255),
Location nvarchar (255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingCount numeric
)

INSERT INTO #PercentPopulationVaccinated
select dea.continent, dea.location,  dea.date, dea.population, vac.new_vaccinations as VaccinationsperDay,
SUM (convert(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location order by dea.location, dea.date) as RollingCount
--(RollingCount/Population) * 100
from PortfolioProject..CovidDeaths  dea
Join PortfolioProject..CovidVaccinations vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2,3

SELECT * , (RollingCount/Population)*100 as PercentVaccinatedDaily
FROM #PercentPopulationVaccinated


--CREATING VIEWS

create view TotalCasesvsTotalDeaths as
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercent
from PortfolioProject..CovidDeaths
--where location like 'Nigeria'
--order by 1,2

create view PercentPopulationVaccinated as
select dea.continent, dea.location,  dea.date, dea.population, vac.new_vaccinations as VaccinationsperDay,
SUM (convert(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location order by dea.location, dea.date) as RollingCount
--(RollingCount/Population) * 100
from PortfolioProject..CovidDeaths  dea
Join PortfolioProject..CovidVaccinations vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2,3