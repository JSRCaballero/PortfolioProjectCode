
--Queries to pull up the original data tables for reference

Select *
From CovidPortfolioProject..CovidDeaths
Order By location, date 

Select *
From CovidPortfolioProject..CovidVaccinations
Order By location, date


-- Showing recent data from the United States

Select *
From CovidPortfolioProject..CovidDeaths
Where location = 'United States'
Order By date DESC


-- Showing current data for total cases and total deaths for all countries in alphabetical order

Select location, population, 
	MAX(total_cases) as Current_Total_Cases, 
	MAX(CAST(total_deaths as int)) as Current_Total_Deaths
	--Changing the data type of total_deaths to allow window functions. nvarchar -> int
From CovidPortfolioProject..CovidDeaths
Where continent is NOT NULL
Group By location, population
Order By location


--Alternative way to solve the data type problem above using Alter

Alter Table CovidDeaths
Alter Column total_deaths int;

Select location, population, MAX(total_deaths) as Current_Total_Deaths
From CovidPortfolioProject..CovidDeaths
Where continent is NOT NULL
Group By location, population
Order By location


--Adding information from another table using Join

Select dea.location, dea.population, 
	MAX(dea.total_cases) as Current_Total_Cases, 
	MAX(dea.total_deaths) as Current_Total_Deaths, 
	MAX(Cast(vac.total_tests as int)) as Current_Total_Tests,
	MAX(Cast(vac.total_vaccinations as int)) as Current_Total_Vaccinations
From CovidPortfolioProject..CovidDeaths dea
Join CovidPortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = dea.date
where dea.continent is NOT NULL
Group By dea.location, dea.population
Order By dea.location




--Rolling infection count using Partition By per country by date


Select dea.location, dea.date, dea.new_cases, 
	SUM(dea.new_cases) OVER (Partition By dea.location Order By dea.location, dea.date) as Rolling_New_Cases_Total
From CovidPortfolioProject..CovidDeaths dea
Join CovidPortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is NOT NULL
Group By dea.location, dea.date, dea.new_cases
Order By dea.location

-- Cases, Deaths, and Vaccinations

Alter Table CovidVaccinations
Alter Column total_vaccinations int;

Alter Table CovidDeaths
Alter Column total_deaths int;

Select dea.location, dea.population, 
	MAX(dea.total_cases) as TotalCases, 
	MAX(dea.total_deaths) as TotalDeaths, 
	MAX(vac.total_vaccinations) as TotalVaccinations
From CovidPortfolioProject..CovidDeaths dea
Join CovidPortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is NOT NULL
Group By dea.location, dea.population
Order By dea.location



--Using a Temp Table to query percentage statistics
--Creating Temp Table

Drop Table If Exists #CountryTotals
Create Table #CountryTotals (
Location nvarchar(255) NULL,
Population float NULL,
Total_Cases int NULL,
Total_Deaths int NULL,
Total_Vaccinations int NULL
) 
--Inserting data into Temp Table
Insert Into #CountryTotals
Select dea.location, dea.population, 
	MAX(dea.total_cases) as TotalCases, 
	MAX(dea.total_deaths) as TotalDeaths, 
	MAX(vac.total_vaccinations) as TotalVaccinations
From CovidPortfolioProject..CovidDeaths dea
Join CovidPortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is NOT NULL
Group By dea.location, dea.population
Order By dea.location

--Querying off of Temp Table to determine percentages (the casting here limits the decimal accuracy to reduce visual clutter)

Select location, population, Total_Cases, Cast((Total_Cases/population)*100 as numeric (16,4)) as PercentagePopulationInfected, 
	Total_Deaths, Cast((Total_Deaths/population)*100 as numeric (16,4)) as PercentagePopulationDeceased, 
	Total_Vaccinations, Cast((Total_Vaccinations/population)*100 as numeric (16,4)) as PercentagePopulationVaccinated
From #CountryTotals
Order By location


-- Fatality Rates. Infections vs deaths per continent to determine chances of recovery.

Select location, population, MAX(total_cases) as TotalCases, MAX(total_deaths) as TotalDeaths, 
	Cast((MAX(total_deaths)/MAX(total_cases))*100 as numeric (16,4)) as FatalityRate
From CovidPortfolioProject..CovidDeaths
Where continent is NULL
Group By location, population
Order By location


--Vaccinations by continent

Select Continent, MAX(total_vaccinations) as TotalVaccinations
From CovidPortfolioProject..CovidVaccinations
where continent IS NOT NULL
Group By continent
Order By continent


--Population Percentage Infected By Country (for a heat map in tableau)

Select location, MAX((total_cases/population))*100 as PercentPopulationInfected
From CovidPortfolioProject..CovidDeaths
Group By location, population
Order By PercentPopulationInfected desc

--World wide infection count by date

Select location, date, 
	SUM(new_cases) OVER (Partition By location Order By location, date) as WorldInfectionCount
From CovidPortfolioProject..CovidDeaths 
Where location = 'world'


--Rolling death count and rolling vaccination count for countries by date

Select dea.location, dea.date, 
	SUM(dea.new_deaths) OVER (Partition By dea.location Order By dea.location, dea.date) as DeathCount,
	SUM(vac.new_vaccinations) OVER (Partition By vac.location Order By vac.location, vac.date) as VaxCount
From CovidPortfolioProject..CovidDeaths dea
Join CovidPortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is NOT NULL