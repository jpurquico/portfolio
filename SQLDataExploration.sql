-- Data: ourworldindata.org/covid-deaths

Select *
From PortfolioProject..CovidDeaths
Where continent is not null
Order by 3, 4

-- Select Data that we will be using

Select location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Where continent is not null
Order by 1, 2

-- Total Cases vs Total Deaths
-- Shows likelihood of dying from COVID-19 in a specific country
Select location, date, total_cases, total_deaths, round((total_deaths/total_cases)*100, 2) as DeathPercentage
From PortfolioProject..CovidDeaths
Where location like 'Canada'
Order by 1, 2 Desc

-- Total Cases vs Population
-- Shows percentage of population that got infected with COVID-19 in a specific country
Select location, date, population, total_cases, round((total_cases/population)*100, 2) as InfectionRate
From PortfolioProject..CovidDeaths
Where location like 'Canada'
Order by 1, 2

-- Countries with the highest Infection Rate compared to Population
Select location, population, Max(total_cases) as HighestInfectionCount, Max(round((total_cases/population)*100, 2)) as InfectionRate
From PortfolioProject..CovidDeaths
Where continent is not null
Group by location, population
Order by InfectionRate desc

-- Countries with highest Death Rate compared to Population
Select location, Max(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null
Group by location
Order by TotalDeathCount desc

-- Infection Rate per continent
Select location, population, Max(total_cases) as HighestInfectionCount, Max(round((total_cases/population)*100, 2)) as InfectionRate
From PortfolioProject..CovidDeaths
Where continent is null 
	and location not like '%income%' --remove income locations
Group by location, population
Order by InfectionRate desc

-- Total Deaths per continent
Select location, Max(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is null 
	and location not like '%income%' --remove income locations
Group by location
Order by TotalDeathCount desc

-- Global numbers
Select date, 
	Sum(new_cases) as TotalCases, 
	Sum(cast(new_deaths as int)) as TotalDeaths, 
	Sum(cast(new_deaths as int))/Sum(new_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null
Group by date
Order by 1, 2

-- Join CovidDeaths and CovidVaccinations tables
Select death.continent, 
	death.location, 
	death.date, 
	death.population, 
	vacc.new_vaccinations,
	SUM(convert(bigint, vacc.new_vaccinations)) 
		OVER (Partition by death.location 
			Order by death.location, death.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths death
Join PortfolioProject..CovidVaccinations vacc
	On death.location = vacc.location
	and death.date = vacc.date
Where death.continent is not null
Order by 2, 3

-- Use CTE
With PopVacc (Continent, Location, date, population, new_vaccinatios, RollingPeopleVaccinated)
as (
Select death.continent, 
	death.location, 
	death.date, 
	death.population, 
	vacc.new_vaccinations,
	SUM(convert(bigint, vacc.new_vaccinations)) 
		OVER (Partition by death.location 
			Order by death.location, death.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths death
Join PortfolioProject..CovidVaccinations vacc
	On death.location = vacc.location
	and death.date = vacc.date
Where death.continent is not null
)
Select *, (RollingPeopleVaccinated/Population)*100 as RollingPopVaccPercentage
From PopVacc

-- Temp Table
Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccination numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select death.continent, 
	death.location, 
	death.date, 
	death.population, 
	vacc.new_vaccinations,
	SUM(convert(bigint, vacc.new_vaccinations)) 
		OVER (Partition by death.location 
			Order by death.location, death.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths death
Join PortfolioProject..CovidVaccinations vacc
	On death.location = vacc.location
	and death.date = vacc.date
Where death.continent is not null

Select *, (RollingPeopleVaccinated/Population)*100 as RollingPopVaccPercentage
From #PercentPopulationVaccinated

-- Create View for data viz

Create View PercentPopulationVaccinated as
Select death.continent, 
	death.location, 
	death.date, 
	death.population, 
	vacc.new_vaccinations,
	SUM(convert(bigint, vacc.new_vaccinations)) 
		OVER (Partition by death.location 
			Order by death.location, death.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths death
Join PortfolioProject..CovidVaccinations vacc
	On death.location = vacc.location
	and death.date = vacc.date
Where death.continent is not null

Select *
From PercentPopulationVaccinated