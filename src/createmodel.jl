function constraintPartialAssigned!(m::Model, df_partialassigned::DataFrame)
    # get the variable x
    x=m[:x]

    # check if there are any pre-assignment
    if nrow(df_partialassigned) > 0
        # constraint: pre-assignment (force assignment)
        @constraint(
            m,
            assigned[pref in df_partialassigned[:, :idpreference]],
            x[pref] == 1
        )
    end
end # function constraintPartialAssigned!

function constraintInactive!(m::Model, df_preference::DataFrame)
    # get the variable x
    x=m[:x]

    @constraint(
        m,
        inactive,
        sum(
            x[pref]
            for
            pref in
            df_preference[df_preference[:, :inactive].==1, :idpreference]
        ) == 0
    )
end # function constraintInactive!

function constraintIncompatible!(m::Model, 
    df_preference::DataFrame,
    df_occurrence::DataFrame)
    # get the variable x
    x=m[:x]

    # get incompatible preferences
    df_incompatible = getIncompatiblePreference(df_occurrence, df_preference)
    # constraint: avoid time incompatible preferences
    @constraint(
        m,
        incompatible[i in 1:nrow(df_incompatible)],
        x[df_incompatible[i, :idp1]] + x[df_incompatible[i, :idp2]] <= 1
    )
end # function constraintIncompatible!

function constraintAtmostassigned!(m::Model, 
    df_preference::DataFrame,
    df_period::DataFrame)
    # get the variable x
    x=m[:x]

    # get period maximal assignment condition
    df_periodassigned = getPreferencePeriod(df_preference, df_period)
    # get sub dataframe of child and period
    subdf = groupby(df_periodassigned, [:idpasseport, :idperiod])
    # constraint: at most maxassigned activity per child and per period
    @constraint(
        m,
        atmostassigned[group in 1:length(subdf)],
        # only take the first one since all minchild are the same
        sum(x[pref] for pref in subdf[group][:, :idpreference]) <=
        subdf[group][:, :periodmaxassigned][1]
    )
end # function constraintAtmostassigned!

function constraintSimilar!(m::Model, 
    df_preference::DataFrame,
    df_occurrence::DataFrame)
    # get the variable x
    x=m[:x]

    # only consider first occurrence of multi-occurrence activities
    dfm = df_occurrence[
        df_occurrence[:, :idoccurrence].==df_occurrence[:, :previous],
        :idoccurrence,
    ]
    subdf = filter(r -> any(in.(dfm, r.idoccurrence)), df_preference)
    # get sub dataframe of child and similar
    subdf = groupby(subdf, [:idpasseport, :similarity])
    # constraint: at most 1 activity per child and per similar activities
    @constraint(
        m,
        similar2[group in 1:length(subdf)],
        sum(x[pref] for pref in subdf[group][:, :idpreference]) <= 1
    )
end # function constraintSimilar!

function constraintLifetime!(m::Model, df_lifetime::DataFrame)
    # get the variable x
    x=m[:x]

    # constraint: lifetime = no assignment to previously assigned lifetime activities
    if nrow(df_lifetime)!=0
        @constraint(
        m,
        lifetime,
        sum(x[pref] for pref in df_lifetime[:, :idpreference]) == 0
        )
    end # if nrow(df_lifetime)!=0
end # function constraintLifetime!

function constraintAge!(m::Model, 
    df_preference::DataFrame,
    df_occurrence::DataFrame,
    df_activity::DataFrame,
    df_child::DataFrame)
    # get the variable x
    x=m[:x]

    # get age condition
    df_age =
        getAgeCondition(df_child, df_activity, df_occurrence, df_preference)
    # get the idpreference for which children are below the required age
    prefminage = getPrefVector(df_age, "BelowMinAge", "idpreference")
    # constraint: minimum age
    @constraint(m, minage, sum(x[pref] for pref in prefminage) == 0)
    # get the idpreference for which children are above the required age
    prefmaxage = getPrefVector(df_age, "AboveMaxAge", "idpreference")
    # constraint: maximum age
    @constraint(m, maxage, sum(x[pref] for pref in prefmaxage) == 0)
end # function constraintAge!

function constraintKnome!(m::Model, 
    df_preference::DataFrame,
    df_knome::DataFrame)
    # get the variable x
    x=m[:x]

    # get knome preferences
    df_knomedistinct, df_knomepref = getKnome(df_knome, df_preference)
    # constraint: knomedistinct
    @constraint(
        m,
        knomedistinct,
        sum(x[pref] for pref in df_knomedistinct[:, :idpreference]) == 0
    )
    # constraint: knomepref
    @constraint(
        m,
        knomepref[i in 1:nrow(df_knomepref)],
        x[df_knomepref[i, :idp1]] == x[df_knomepref[i, :idp2]]
    )
end # function constraintKnome!

function constraintNumberChildren!(m::Model, 
    df_preference::DataFrame)
    # get the variables
    x=m[:x]
    yOpen=m[:yOpen]

    # group by occurrences
    subdf = groupby(df_preference, [:idoccurrence])
    # constraint: maximum number of children per occurrence
    @constraint(
        m,
        maxnumberofchildren[group in 1:length(subdf)],
        sum(x[pref] for pref in subdf[group][:, :idpreference]) <=
        # only take the first one since all maxchild are the same
        yOpen[group] * subdf[group][:, :maxchild][1]
    )

    # constraint: minimum number of children per occurrence for opening it
    @constraint(
        m,
        minnumberofchildren[group in 1:length(subdf)],
        sum(x[pref] for pref in subdf[group][:, :idpreference]) >=
        # only take the first one since all minchild are the same
        yOpen[group] * subdf[group][:, :minchild][1]
    )
end # function constraintNumberChildren!

function constraintMultiOccurrence!(m::Model, 
    df_preference::DataFrame,
    df_occurrence::DataFrame)
    # get the variable x
    x=m[:x]

    # constraint: activity on multiple occurrences
    df_equal, df_invalid = getMulti(df_preference, df_occurrence)
    # invalid if not all occurrences have been selected by child
    @constraint(
        m,
        invalid,
        sum(x[pref] for pref in df_invalid[:, :idpreference]) == 0
    )
    # valid if all occurrences have been selected by child
    @constraint(
        m,
        multioccurrence[i in 1:nrow(df_equal)],
        x[df_equal[i, :idp1]] == x[df_equal[i, :idp2]]
    )
end # function constraintMultiOccurrence!



function createmodel(
    df_child::DataFrame,
    df_activity::DataFrame,
    df_period::DataFrame,
    df_lifetime::DataFrame,
    df_occurrence::DataFrame,
    df_preference::DataFrame,
    df_knome::DataFrame,
    weightChoice::Float64,
    weightCost::Float64,
    solver = "CBC"
)

if solver == "GUROBI"
    GRB_ENV = Gurobi.Env()
    m = Model(() -> Gurobi.Optimizer(GRB_ENV))
    set_optimizer_attribute(m, "TimeLimit", 300)
    set_optimizer_attribute(m, "MIPGap", 0.01)
elseif solver == "HiGHS"
    m = Model(HiGHS.Optimizer)
    set_optimizer_attribute(m, "time_limit", 300.0)
    set_optimizer_attribute(m, "mip_rel_gap", 0.01)
else
    m = Model(Cbc.Optimizer)
    set_optimizer_attribute(m, "ratioGap", 0.1)
    # set_optimizer_attribute(m, "seconds", 600)
end # if solver

    # set the variables
    @variable(m, x[df_preference[:, :idpreference]], Bin)
    # group by occurrences
    subdf = groupby(df_preference, [:idoccurrence])
    @variable(m, yOpen[group in 1:length(subdf)], Bin)

    # constraintAssigned!(m, df_assigned)
    constraintInactive!(m, df_preference)
    constraintIncompatible!(m, df_preference, df_occurrence)
    constraintAtmostassigned!(m, df_preference, df_period)
    constraintSimilar!(m, df_preference, df_occurrence)
    constraintLifetime!(m, df_lifetime)
    constraintAge!(m, df_preference, df_occurrence, df_activity, df_child)
    constraintKnome!(m, df_preference, df_knome)
    constraintNumberChildren!(m, df_preference)
    constraintMultiOccurrence!(m, df_preference, df_occurrence)

    # create the objective function
    z = zCost(df_preference, weightChoice, weightCost, m)
    # Set objective function and sense
    @objective(m, Max, z)

    return m
end