function setValidPreAssignement!(m::Model, df_assigned::DataFrame)
    # add a valid column set to false by default
    df_assigned[!,:valid] .= false

    # do nothing else if there is no entries as pre-assignement
    if nrow(df_assigned)==0
        return
    end

    for i in 1:nrow(df_assigned)
        df_assigned[i,:valid] = true
        df_partialassigned = df_assigned[df_assigned[:,:valid].==true,:]
    
        constraintPartialAssigned!(m, df_partialassigned)
        optimize!(m)
        status = termination_status(m)
    
        if status != MOI.OPTIMAL
            df_assigned[i,:valid] = false
        end
    
        delete.(m, m[:assigned])
        unregister(m, :assigned)
    end
end

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
@info "Data acquired."

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
 @info "Data joint."
 
# create the model
m = createmodel(
    df_child,
    df_activity,
    df_period,
    df_lifetime,
    df_occurrence,
    df_preference,
    df_knome,
    weightChoice,
    weightCost,
    solvername
)
@info "Primary model built."

# disable printing output from the solver
set_silent(m)
# # enable printing output from the solver
# unset_silent(m)
# solve the problem
optimize!(m)
# get the status of the resolution
status = termination_status(m)
# # summrise the solution
# solution_summary(m)
if status == MOI.OPTIMAL
    @info "Primary model solved."
else
    @warn status
end

# find valid pre-assignments
setValidPreAssignement!(m, df_assigned)
# set the valid pre-assigned constraints
df_partialassigned = df_assigned[df_assigned[:,:valid].==true,:]
constraintPartialAssigned!(m, df_partialassigned)
optimize!(m)
status = termination_status(m)
validAssignement = string("Preassigned: ", sum(df_assigned[:,:valid]), " valid over ", nrow(df_assigned))
@info validAssignement

# status of the optimisation should be "Optimal"
if status == MOI.OPTIMAL

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
else
    @warn status
end

# # write LP model, for debugging purpose
# exportLPModelTxt("./data/model.txt", m)

end # function run