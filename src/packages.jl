using Pkg

# get packages dependencies
deps = Pkg.dependencies()
# find installed packages
installs = Dict{String, VersionNumber}()
for (uuid, dep) in deps
    dep.is_direct_dep || continue
    dep.version === nothing && continue
    installs[dep.name] = dep.version
end

if ! in("CSV",keys(installs))
	Pkg.add("CSV")
end
using CSV

if ! in("DataFrames",keys(installs))
	Pkg.add("DataFrames")
end
using DataFrames

if ! in("Cbc",keys(installs))
	Pkg.add("Cbc")
end
using Cbc

if ! in("HiGHS",keys(installs))
	Pkg.add("HiGHS")
end
using HiGHS

# if ! in("Gurobi",keys(installs))
# 	Pkg.add("Gurobi")
# end
# using Gurobi

if ! in("JuMP",keys(installs))
	Pkg.add("JuMP")
end
using JuMP

if ! in("Dates",keys(installs))
	Pkg.add("Dates")
end
using Dates

if ! in("Statistics",keys(installs))
	Pkg.add("Statistics")
end
using Statistics

if ! in("ODBC",keys(installs))
	Pkg.add("ODBC")
end
using ODBC

if ! in("DBInterface",keys(installs))
	Pkg.add("DBInterface")
end
using DBInterface

if ! in("MySQL",keys(installs))
	Pkg.add("MySQL")
end
using MySQL