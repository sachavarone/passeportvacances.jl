
function run(dbname::String)
# get the data
df_activity, 
df_child ,
df_knome, 
df_lifetime, 
df_occurrence, 
df_preference, 
df_period, 
df_assigned = readDataMySQL(dbname)

# # export as csv files
# field = ["activity", "child", "knome", "lifetime", "occurrence", "preference", "period", "assigned"]
# pathtodata = "data/"
# # export all files
# for i in 1:length(field)
#     exportDataCSV(pathtodata, field[i])
#  end

# enhance the data
 df_lifetime = enhancelifetime(df_lifetime, df_preference, df_occurrence)
 df_preference = enhancepreference(df_preference, df_occurrence, df_activity)
 df_assigned = enhanceassigned(df_assigned, df_preference)
 # compute choice score
 df_preference[!, :zpref] = computeChoiceScore(df_preference, df_occurrence)
 
 @info "Data acquired."

# create the model
m = createmodel(
    df_child,
    df_activity,
    df_period,
    df_lifetime,
    df_occurrence,
    df_preference,
    df_knome,
    df_assigned,
    weightChoice,
    weightCost,
    solvername
)
@info "Model built."

# disable printing output from the solver
set_silent(m)
# # enable printing output from the solver
# unset_silent(m)
# solve the problem
optimize!(m)
@info "Model solved."

# get the status of the resolution
status = termination_status(m)
# # summrise the solution
# solution_summary(m)

# get the solution and analyse it
solution, df_analysis = getsolution(
    status,
    df_preference,
    df_occurrence,
    df_child,
    zvalue,
    m,
    agecategorylimit
)
# compute the remaining available place for each occurrences
remainder = getremainder(solution, df_occurrence, df_activity)

@info "Solution from optimisation."

# write table solution into the database
writeSolutionMySQL("solution", solution)
# write table remainder into the database
writeSolutionMySQL("remainder", remainder)

@info "Tables 'solution' and 'remainder' written in the database."

# # write LP model, for debugging purpose
# exportLPModelTxt("./data/model.txt", m)

end # function run