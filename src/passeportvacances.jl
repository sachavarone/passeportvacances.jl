# SPDX-License-Identifier: MIT

module passeportvacances

export run
# run: passeportvacances.run("farfadet_chalais")
# run: passeportvacances.run("farfadet_chalais", "GUROBI")
# run: passeportvacances.run("farfadet_chalais", "NEOS")

# install and call the packages
include("packages.jl")
# constraint functions
include("func_constraint.jl")
# create the MIP model
include("createmodel.jl");
# constraint functions
include("func_balance.jl")
# get and write the solution
include("solution.jl")
 
# get data from database
include("data.MySQL.jl")
# enhance data
include("data.enhance.jl")

# get additional parameters
include("parameters.jl")
# create, solve, analyse model
include("runs.jl")

 end # module passeportvacances