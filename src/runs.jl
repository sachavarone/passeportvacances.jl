function setValidPreAssignement!(m::Model, df_assigned::DataFrame)
    # do nothing else if there is no entries as pre-assignement
    if nrow(df_assigned)==0
        # for coherence and avoid trouble later in writing as a table
        df_assigned[!,:valid] .= true
        return df_assigned
    end

    # trying to optimize with all pre-assignements
    constraintPartialAssigned!(m, df_assigned)
    optimize!(m)
    status = termination_status(m)

    if status == MOI.OPTIMAL
        # add a valid column set to true
        df_assigned[!,:valid] .= true
        @info "Complete model with all pre-assignements solved"
        return df_assigned
    else
        # delete constraints
        delete.(m, m[:assigned])
        unregister(m, :assigned)
        @info "Entering pre-assignments validation phase ..."
    end
    
     # add a valid column set to false by default
     df_assigned[!,:valid] .= false
     # comment 
     sInfoPrefix = "     Preassigned "
     # check all pre-assignment constraints one by one
    for i in 1:nrow(df_assigned)
        sinfo = string(sInfoPrefix, i)
        df_assigned[i,:valid] = true
        df_partialassigned = df_assigned[df_assigned[:,:valid].==true,:]
    
        constraintPartialAssigned!(m, df_partialassigned)
        optimize!(m)
        status = termination_status(m)
    
        if status != MOI.OPTIMAL
            df_assigned[i,:valid] = false
            sinfo = string(sinfo, " failed")
        else
            sinfo = string(sinfo, " passed")
        end

        delete.(m, m[:assigned])
        unregister(m, :assigned)

        @info sinfo
    end
    validAssignement = string("Preassigned: ", sum(df_assigned[:,:valid]), " valid over ", nrow(df_assigned))
    @info validAssignement

    return df_assigned
end

function runValidPreAssignment!(previousStatus::MOI.TerminationStatusCode, m::Model, df_assigned::DataFrame)
    status = previousStatus
    # check if existintg preassignments
    if nrow(df_assigned)>0
        # find valid pre-assignments
        df_assigned = setValidPreAssignement!(m, df_assigned)

        if sum(df_assigned[:,:valid]) < nrow(df_assigned)
            # set the valid pre-assigned constraints
            df_partialassigned = df_assigned[df_assigned[:,:valid].==true,:]
            constraintPartialAssigned!(m, df_partialassigned)
            optimize!(m)
            status = termination_status(m)
            @info "Model with pre-assignment solved"
        end
    end # if nrow(df_assigned)>0
    return status
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
    return
end

status = runValidPreAssignment!(status, m, df_assigned)

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

    @info "Solution retrieved."

    # write table solution into the database
    writeSolutionMySQL(dbname, "solution", solution)
    # write table remainder into the database
    writeSolutionMySQL(dbname, "remainder", remainder)
    @info "Tables 'solution' and 'remainder' written in the database."
    if nrow(df_assigned)>0
        # write table preassigned into the database
        writeSolutionMySQL(dbname, "preassigned", df_assigned)
        @info "Table 'preassigned' written in the database"
    end

else
    @warn status
end

# # write LP model, for debugging purpose
# exportLPModelTxt("./data/model.txt", m)

end # function run