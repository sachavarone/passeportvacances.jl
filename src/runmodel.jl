##################################
# No more used                   #
# Backup from reading csv files  #
# Beware:                        #
# probably some updates needed   #
##################################

# Function to solve different problems with only one compilation
# pathtodata => path to the csv files containing all the data needed to solve the problem
function createandsolve(pathtodata::String; solvername::String = "Cbc")
    # filename for parameters
    filenameParameter = string(pathtodata, "userparam.csv")

    # get the different parameter given by the user
    csvseparator, weightChoice, weightCost, mincv, zvalue, agecategorylimit =
        getParamcsv(filenameParameter)

    df_child,
    df_activity,
    df_period,
    df_lifetime,
    df_occurrence,
    df_preference,
    df_knome,
    df_assigned = getdatacsv(pathtodata)

    #join data
    df_lifetime = enhancelifetime(df_lifetime, df_preference, df_occurrence)
    df_preference = enhancepreference(df_preference, df_occurrence, df_activity)
    df_assigned = enhanceassigned(df_assigned, df_preference)
    # compute choice score
    df_preference[!, :zpref] = computeChoiceScore(df_preference, df_occurrence)

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
    # solve the problem
    optimize!(m)
    status = termination_status(m)

    #get the solution and store int csv file
    solution, df_analysis = getsolution(
        status,
        df_preference,
        df_occurrence,
        df_child,
        zvalue,
        m,
        agecategorylimit,
    )
    remainder = getremainder(solution, df_occurrence, df_activity)

    # return the solution
    return solution, remainder, df_analysis
end # function createandsolve
