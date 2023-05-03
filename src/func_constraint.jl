# test if occurrence o1 is incompatible with occurrence o2
function isIncompatible(df::DataFrame, o1::Int64,o2::Int64)
  v1 = df[o1,:occurrenceend]<=df[o2,:occurrencebegin]
  v2 = df[o2,:occurrenceend]<=df[o1,:occurrencebegin]
  return !(v1 || v2)
#  return !(v1.value || v2.value ) # if nullable=false is missing in the query
end # function isCompatible

# return incompatible occurrences dataframe
# df = dataframe of occurrences
function getIncompatible(df::DataFrame)
  # get the number of occurrences
  nboccurrence = nrow(df)
  # initialize incompatibility matrix
  dfi = DataFrame(ido1 = [], ido2 = [])
  for o1 in 1:nboccurrence
    for o2 in (o1+1):nboccurrence
      # incompatible[o1,o2] = isIncompatible(df, o1,o2)
      # incompatible[o2,o1] = incompatible[o1,o2]
      if isIncompatible(df, o1,o2)
        # get the correct id of the occurrences
        v1 = df[o1,:idoccurrence]
        v2 = df[o2,:idoccurrence]
        # create new incompatibility
        newinc = DataFrame(ido1 = [v1], ido2 = [v2])
        # merge incommpatibility dataframes
        dfi = [dfi; newinc]
      end # if isIncompatible
    end # for o2
  end # for o1

  return dfi
end # function getIncompatible

# return incompatible preferences dataframe
# dfo = dataframe of occurrences
# dfp = dataframe of preferences
function getIncompatiblePreference(dfo::DataFrame, dfp::DataFrame)
# create empty dataframe of resulting incompatible preferences
dfipref = DataFrame(idp1 = [], idp2 = [])
# get dataframe of incompatible occurrences
dfio = getIncompatible(dfo)
# group by child the preference dataframe
subdf = groupby(dfp[:,[:idpasseport, :idoccurrence, :idpreference]], :idpasseport) ;
# apply on each child
for dfchild in subdf
	# iterate through each incompatible binome of occurrences
	for rowinc in eachrow(dfio)
		# get the index in which incompatible occurrences appear within df_preference
		o = indexin([rowinc[:ido1], rowinc[:ido2]], dfchild[:,:idoccurrence])
		# test if the index exists, i.e. different from 0
		if (o[1]!=nothing) & (o[2]!=nothing)
			# update the incompatible binome of idpreferences
			dfipref = [dfipref; DataFrame(idp1 = dfchild[o[1], :idpreference], idp2 = dfchild[o[2], :idpreference])]
		end # if
	end # for rowinc
end # for dfchild

  return dfipref
end # function getIncompatiblePreference

# dfo = dataframe for occurrence
# dfp = dataframe of preference
# dfc = dataframe of child
# dfa = dataframe of activity
function getAgeCondition(dfc::DataFrame, dfa::DataFrame, dfo::DataFrame, dfp::DataFrame)

  # only take a useful subset
  subdf = dfc[:,[:idpasseport, :birthdate]]
  # add column birthdate to dfp
  df = leftjoin(dfp, subdf, on = :idpasseport)
  # only take a useful subset
  subdf = dfa[:,[:idactivity, :minage, :maxage]]
  # add column activity to dfp
  df = leftjoin(df, subdf, on = :idactivity)

  firstOccurrence=DateTime(minimum(dfo[:,:occurrencebegin]))
  # add boolean column for min age
  df[!,:BelowMinAge] = map((x,y) -> Date(x)-Year(1) > Date(firstOccurrence)-Dates.Year(y), df[:,:birthdate], df[:,:minage])
  # add boolean column for max age
  df[!,:AboveMaxAge] = map((x,y) -> Date(x)+Year(1) < Date(firstOccurrence)-Dates.Year(y) , df[:,:birthdate], df[:,:maxage])

  return df
end # function getAgeCondition

# get the vector of idpreference(=colnamevalue) depending on boolean condition (=colnamecond)
function getPrefVector(df::DataFrame,colnamecond::String, colnamevalue::String)
  pref = Int64[]
  for i in 1:nrow(df)
    if df[i,Symbol(colnamecond)] == true
      append!( pref, df[i,Symbol(colnamevalue)])
    end # if
  end # for i
  return pref
end # function getPrefVector

# compute max score preference
# dfp = data frame preferences
function maxScorePreference(dfp::DataFrame)
  temp = sum(dfp[:,:zpref])
  return temp
end # function maxScorePreference

# compute max score cost
# dfp = data frame preferences
function maxScorePrice(dfp::DataFrame)
  temp = sum(dfp[:,:pricechild]) + sum(dfp[:,:pricefixed])
  return temp
end # function maxScorePrice

# compute cost assignement
# dfp = data frame preferences
function zCost4(dfp::DataFrame, weightChoice::Float64 , weightCost::Float64, m)
    x=m[:x]
    yOpen=m[:yOpen]

  # compute the objectives
  zPref = sum(x[dfp[numpref,:idpreference]]*dfp[numpref,:zpref]
              for numpref in 1:nrow(dfp))

  # group by occurrences
  subdf = groupby(dfp, [:idoccurrence]);
  zPriceChild = sum(x[dfp[numpref,:idpreference]]*dfp[numpref,:pricechild]
             for numpref in 1:nrow(dfp));
  zPriceFixed = sum(yOpen[group]*subdf[group][1,:pricefixed]
              for group in 1:length(subdf));
  Price = zPriceChild + zPriceFixed;

  Nchild=length(subdf)
  meanPrice=Price/Nchild

  #group by passseport
  subdf=groupby(dfp, [:idpasseport]);

  #add variables and constraintes to linearise the abs value
  @variable(m, cplus[1:length(subdf)]);
  @variable(m, cmoins[1:length(subdf)]);

  @constraint(m, absvalue[group in 1:length(subdf)], (sum(
	x[subdf[group][pref, :idpreference]]*subdf[group][pref, :pricechild]+x[subdf[group][pref, :idpreference]]*subdf[group][pref, :pricefixed]/subdf[group][pref, :minchild]
	for pref in 1:nrow(subdf[group]))
	-meanPrice*1.2)==cplus[group]-cmoins[group])
  @constraint(m, bornesplus[j in 1:length(subdf)], cplus[j]>=0)
  @constraint(m, bornesmoins[j in 1:length(subdf)], cmoins[j]>=0)

  zPrice=sum(cplus); # minimise only the one who are too expensive

  # compute maximal values for each objectives
  zprefmax = maxScorePreference(dfp);
  zpricemax = maxScorePrice(dfp);
  # set the weights between objectives
  wPref = weightChoice / zprefmax
  wPrice = weightCost / zpricemax
  # compute the objective
  z = wPref * zPref - wPrice * zPrice
  return z
end # function zCost4

# compute cost assignement
# dfp = data frame preferences
function zCost(dfp::DataFrame, weightChoice::Float64 , weightCost::Float64, m)
  x=m[:x]
  yOpen=m[:yOpen]

# compute the objectives
zPref = sum(x[dfp[numpref,:idpreference]]*dfp[numpref,:zpref]
            for numpref in 1:nrow(dfp))

# group by occurrences
subdf = groupby(dfp, [:idoccurrence]);
zPriceChild = sum(x[dfp[numpref,:idpreference]]*dfp[numpref,:pricechild]
           for numpref in 1:nrow(dfp));
zPriceFixed = sum(yOpen[group]*subdf[group][1,:pricefixed]
            for group in 1:length(subdf));
   
Price = zPriceChild + zPriceFixed;

Nchild=length(subdf)
meanPrice=Price/Nchild

#group by passseport
subdf=groupby(dfp, [:idpasseport]);

# add variables and constraintes to linearise the abs value
@variable(m, cplus[1:length(subdf)]);
@variable(m, cmoins[1:length(subdf)]);

@constraint(m, absvalue[group in 1:length(subdf)], (sum(
x[subdf[group][pref, :idpreference]]*subdf[group][pref, :pricechild]+x[subdf[group][pref, :idpreference]]*subdf[group][pref, :pricefixed]/subdf[group][pref, :minchild]
for pref in 1:nrow(subdf[group]))
-meanPrice*1.2)==cplus[group]-cmoins[group])
@constraint(m, bornesplus[j in 1:length(subdf)], cplus[j]>=0)
@constraint(m, bornesmoins[j in 1:length(subdf)], cmoins[j]>=0)

# cplus = @variable(m, [group in eachindex(subdf)], lower_bound=0)
# cmoins = @variable(m, [group in eachindex(subdf)], lower_bound=0)
# @constraint(m, [group in eachindex(subdf)], sum(x[pref,:idpreference] * (subdf[group][pref,:pricechild] + subdf[group][pref,:pricefixed] / subdf[group][pref,:minchild])
#      for pref in 1:size(subdf[group],1)) / size(subdf[group],1) + 0.2 * meanPrice <= cplus[group] - cmoins[group])


zPrice=sum(cplus); # minimise only the one who are too expensive

# compute maximal values for each objectives
zprefmax = maxScorePreference(dfp);
zpricemax = maxScorePrice(dfp);
# set the weights between objectives
wPref = weightChoice / zprefmax
wPrice = weightCost / zpricemax
# compute the objective
z = wPref * zPref - wPrice * zPrice
return z
end # function zCost


# build a dataframe which contains period specific idpreference and child
function getPreferenceInPeriod(df_preference::DataFrame, df_period::DataFrame, idperiod::Int64)
    # set the beginning of the considered period
    pbegin = df_period[df_period[:,:idperiod].==idperiod,:periodbegin]
    # set the end of the considered period
    pend = df_period[df_period[:,:idperiod].==idperiod,:periodend]
    # set the condition to be between beginning and enhanced
    pcondbegin = df_preference[:,:occurrencebegin] .>= pbegin
    pcondend = df_preference[:,:occurrencebegin] .<= pend
    pcondition = pcondbegin .& pcondend


  # select preferenceid from the beginning of the period
  df = df_preference[df_preference[:,:occurrencebegin] .>= df_period[df_period[:,:idperiod].==idperiod,:periodbegin],[:idpreference,:idpasseport,:occurrencebegin]];
  # select preferenceid until the end of the period
  df = df[df[:,:occurrencebegin] .<= df_period[df_period[:,:idperiod].==idperiod,:periodend][1],:];
  # add the maximal assignement
  df[!,:periodmaxassigned] .= df_period[df_period[:,:idperiod].==idperiod,:periodmaxassigned][1]
  # add the identification of the period
  df[!,:idperiod] .= df_period[df_period[:,:idperiod].==idperiod,:idperiod][1]

  return df
end # function getPreferenceInPeriod

# build a dataframe which contains idpreference, idpasseport, periodmaxassigned and idperiod
function getPreferencePeriod(df_preference::DataFrame, df_period::DataFrame)
  df = DataFrame(idpreference = Int64[], idpasseport = Int64[], occurrencebegin= DateTime[], periodmaxassigned = Int64[], idperiod = Int64[])
  if nrow(df_period)>0
      for i in df_period[:,:idperiod]
    	df = vcat(df, getPreferenceInPeriod(df_preference, df_period, Int64(i)))
      end # for i
  end # if nrow(df_period)>0
  return df
end # function getPreferencePeriod

# get the initial occurrence from a list of successive occurrences within a single activity
# dfo = df_occurrence
function getInitialMultioccurrence(dfo::DataFrame)
	# those for which there exists a next occurrence but no previous one
	df = dfo[(dfo[:,:next].!=dfo[:,:idoccurrence]) .& (dfo[:,:previous].==dfo[:,:idoccurrence]), :idoccurrence]
	df = DataFrame(idoccurrence=df)
end # function getInitialMultioccurrence

# get the list of occurrences from initial occurrence in multiple occurrences
# oInit = initial occurrence
# dfo  = df_occurrence
function getListoccurrenceFromInitial(oInit::Int64, dfo::DataFrame)
  # create the list with the initial occurrence
  df = DataFrame(idoccurrence = [oInit])
  # get the index
  index = findall(dfo[:,:idoccurrence].==oInit)#findin(dfo[:,:idoccurrence],oInit)
  # add successive occurrences
  while dfo[index,:next]!=dfo[index,:idoccurrence]
	push!(df, dfo[index,:next])
	nextoccurrence = dfo[index,:next]
	index = findall(dfo[:,:idoccurrence] .== nextoccurrence)#findin(dfo[:,:idoccurrence],nextoccurrence)
  end # while
  # compute the number of members in the list
  nbmember = nrow(df)
  # specify the group id as the initial occurrence
  df[!,:group] = [oInit for i in 1:nbmember]
  # specify the number of members in the list
  df[!,:cardinality] = [nbmember for i in 1:nbmember]
  return df
end # function getListoccurrenceFromInitial

# get the list of multiple occurrences
# dfo  = df_occurrence
function getMultioccurrence(dfo::DataFrame)
  # create empty dataframe
  df = DataFrame(idoccurrence=Int64[], group=Int64[], cardinality=Int64[])
  # get the initial muli-occurrences
  df_init = getInitialMultioccurrence(dfo::DataFrame)
  # loop for each initial occurrence
  for oInit in df_init[:,:idoccurrence]
	append!(df, getListoccurrenceFromInitial(oInit, dfo))
  end # for oInit
  return df
end # function getMultioccurrence

# get the dataframe prepared for constraint creation for consecutive occurrences
# dfp = df_preference
# dfo  = df_occurrence
function getMultiPrepared(dfp::DataFrame, dfo::DataFrame)
  df = getMultioccurrence(dfo)
  df = innerjoin(dfp, df, on = :idoccurrence)
  df = df[:,[:idpasseport, :idpreference, :group , :cardinality]]
  return df
end # function getMultiPrepared

# get the pairs of preferences that must be equality
# dfp = df_preference
# dfo  = df_occurrence
function getMulti(dfp::DataFrame, dfo::DataFrame)
  df_multiple = getMultiPrepared(dfp, dfo)
  # create empty dataframe
  df_equal = DataFrame(idp1 = Int64[], idp2 = Int64[], group = Int64[])
  df_invalid = DataFrame(idpreference = Int64[])
  # create groups
  subdf = groupby(df_multiple, [:idpasseport, :group]);
  for group in 1:length(subdf)
    # only those for which each occurrences have been selected
    if subdf[group][1,:cardinality]==nrow(subdf[group])
      for i in 1:(nrow(subdf[group])-1)
        p1value = subdf[group][i,:idpreference]
        p2value = subdf[group][i+1,:idpreference]
        push!(df_equal, [p1value p2value subdf[group][1,:group]])
      end # for i
    else
      for i in 1:nrow(subdf[group])
        push!(df_invalid, [subdf[group][i,:idpreference]])
      end # for i
    end # if subdf
  end # for group

  return df_equal, df_invalid
end # function getMulti

# get binome equality preferences
# idc1 = idchild1
# idc2 = idchild2
# dfp  = df_preference
function getBinome(idc1::Int64, idc2::Int64, dfp::DataFrame)
  # get preferences related to selected binome
  df1 = dfp[dfp[:,:idpasseport].==idc1,[:idoccurrence, :idpreference, :idpasseport]];
  df2 = dfp[dfp[:,:idpasseport].==idc2,[:idoccurrence, :idpreference, :idpasseport]];
  # get both preferences
  df = [df1;df2];

  # create empty data frame
  df_distinct = DataFrame(idpreference = []);
  df_knomepref = DataFrame(idp1 = [], idp2 = []);
  # group by occurrences
  subdf = groupby(df, [:idoccurrence]);
  for group in 1:length(subdf)
	# check if single choice of occurrence
    if nrow(subdf[group])==1
	  push!(df_distinct, [subdf[group][1,:idpreference]]);
	else
	  # same occurrence for the binome
	  push!(df_knomepref, [subdf[group][1,:idpreference], subdf[group][2,:idpreference]]);
	end # if
  end # for group
  return df_distinct, df_knomepref
end # function getBinome

# get knome equality preferences
# dfk = df_knome
# dfp  = df_preference
function getKnome(dfk::DataFrame, dfp::DataFrame)
  # create empty data frame
  df_distinct = DataFrame(idpreference = [])
  df_knomepref = DataFrame(idp1 = [], idp2 = [])

  for i in 1:nrow(dfk)
    idc1 = convert(Int64, dfk[i,:idpasseport1])
	  idc2 = convert(Int64, dfk[i,:idpasseport2])


	  distinct, knomepref = getBinome(idc1, idc2, dfp)
	  append!(df_distinct, distinct);
	  append!(df_knomepref, knomepref)
  end # for i

  return df_distinct, df_knomepref
end # function getKnome
