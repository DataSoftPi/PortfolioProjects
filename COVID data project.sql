--Data source: ourworldindata.org
--I downloaded a spreadsheet with all the data and using Excel, I created two separate sheets out of it - 
--'coviddeaths' that will track the data about the number of Covid induced deaths and 'covidvaccinations' that is going to include the vaccination information. 

--Creating tables
DROP TABLE IF EXISTS coviddeaths;

CREATE TABLE coviddeaths ( 
iso_code varchar(10),    
continent varchar(30),    
location varchar(100),
date date,
population float4,    
total_cases float4,    
new_cases float4, 
new_cases_smoothed float4,
total_deaths float4, 
new_deaths float4,
new_deaths_smoothed float4,
total_cases_per_million float4,    
new_cases_per_million float4,
new_cases_smoothed_per_million float4,    
total_deaths_per_million float4,
new_deaths_per_million float4,    
new_deaths_smoothed_per_million float4,    
reproduction_rate float4,    
icu_patients float4,
icu_patients_per_million float4,
hosp_patients float4,
hosp_patients_per_million float4,
weekly_icu_admissions float4, 
weekly_icu_admissions_per_million float4,
weekly_hosp_admissions float4,
weekly_hosp_admissions_per_million float4) ;

DROP TABLE IF EXISTS covidvaccinations;

CREATE TABLE covidvaccinations (
iso_code varchar(10),
continent varchar(30),
location varchar(100),
date date,
new_tests bigint,
total_tests_per_thousand float4,
new_tests_per_thousand float4,
new_tests_smoothed float4,
new_tests_smoothed_per_thousand float4,
positive_rate float4,
tests_per_case float4,
tests_units varchar(100),
total_vaccinations bigint,
people_vaccinated bigint,
people_fully_vaccinated bigint,
total_boosters bigint,
new_vaccinations bigint,
new_vaccinations_smoothed bigint,
total_vaccinations_per_hundred float4,
people_vaccinated_per_hundred float4,
people_fully_vaccinated_per_hundred float4,
total_boosters_per_hundred float4,
new_vaccinations_smoothed_per_million bigint,
new_people_vaccinated_smoothed bigint,
new_people_vaccinated_smoothed_per_hundred float4,
stringency_index float4,
population_density float4,
median_age float4,
aged_65_older float4,
aged_70_older float4,
gdp_per_capita float4,
extreme_poverty float4,
cardiovasc_death_rate float4,
diabetes_prevalence float4,
female_smokers float4,
male_smokers float4,
handwashing_facilities float4,
hospital_beds_per_thousand float4,
life_expectancy float4,
human_development_index float4,
excess_mortality_cumulative_absolute float4,
excess_mortality_cumulative float4,
excess_mortality float4,
excess_mortality_cumulative_per_million float4) ;

--Importing CSV files 

COPY coviddeaths
FROM '/Library/PostgreSQL/14/bin/Database/CovidDeaths.csv' DELIMITER ',' CSV HEADER;

COPY covidvaccinations
FROM '/Library/PostgreSQL/14/bin/Database/CovidVaccinations.csv' DELIMITER ',' CSV HEADER;

--Looking at Total Cases vs Total Deaths for each country
 
SELECT location,  date, population, total_cases, new_cases, total_deaths
FROM coviddeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2  

--Looking at total cases vs total deaths with the probability of dying if you contract covid in your country

SELECT continent, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage 
FROM coviddeaths
WHERE continent IS NOT NULL
order by 1, 2

--Looking at Total Cases vs Population
--Shows what percentage of population contracted Covid

SELECT location, date, total_cases, population, (total_cases/population)*100 as percent_population_infected 
FROM coviddeaths
WHERE continent IS NOT NULL
order by 1, 2

--Looking at countries with the highest infection rate compared to population

SELECT location, population, MAX(total_cases) as highest_infection_count,
Max((total_cases/population))*100 as percent_population_infected 
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY population, location
order by percent_population_infected DESC

--Showing countries with the highest death count per population

SELECT location, CAST(MAX(total_deaths) as int) as total_death_count
FROM coviddeaths
WHERE continent IS NULL
GROUP BY location
order by total_death_count DESC

--Breaking down death count per continent

SELECT continent, CAST(MAX(total_deaths) as int) as total_death_count
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY continent
order by total_death_count DESC

--Global numbers

SELECT date, CAST(SUM(new_cases) as int), CAST(SUM(new_deaths) as int), (SUM(new_deaths)/SUM(new_cases)*100) as DeathPercentage
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY date
order by 1, 2

--Looking at total population vs vaccination

WITH PopvsVac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated) 

as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER BY dea.location, dea.date) 
as rolling_people_vaccinated

FROM coviddeaths dea JOIN covidvaccinations vac
ON vac.location = dea.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3
	)
	
SELECT *, (rolling_people_vaccinated/population)*100 as rolling_vac_percentage
FROM PopvsVac


--Creating view to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated as

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER BY dea.location, dea.date) 
as rolling_people_vaccinated

FROM coviddeaths dea JOIN covidvaccinations vac
ON vac.location = dea.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL





