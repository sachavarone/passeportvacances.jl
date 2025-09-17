## to be run from the root of the project :
##   julia --project=. -e 'using Pkg; Pkg.instantiate()'
##julia --project=. examples/run_dbname.jl

# charge le module depuis le dossier du projet puis appelle run
# Utilise @__DIR__ pour résoudre le chemin quel que soit le répertoire courant
include(joinpath(@__DIR__, "..", "src", "passeportvacances.jl"))
using .passeportvacances

passeportvacances.run("dbname")