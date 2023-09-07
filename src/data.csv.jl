# export data as csv
function exportDataCSV(pathtodata::String, fieldname::String)
    # check if directory exists
    if !isdir(pathtodata)
        # create subdirectory
        mkdir(pathtodata)
    end # if !isdir(string(pathtodata, "solution/")
    # filename for remainder
    filename = string(pathtodata, fieldname, ".csv")
    # write solution to a file
    CSV.write(filename, eval(Meta.parse(string("df_",fieldname))); delim=',');
  end # function exportDataCSV

# export LPmodel as txt
# usage: exportLPModelTxt("./data/model.txt", m)
function exportLPModelTxt(filename::String, LPmodel::Model)
  open(filename, "w") do f
    print(f, LPmodel)
  end
end # function exportLPModelTxt


####################################################################################
# For compatibility with old CSV version                                           #
# Not revised                                                                      #
####################################################################################
#
# # load the csv files containing the data of the problem to solve
# function datacsv(pathtodata, filenameParameter, filenameChild, filenameKnome,
#     filenameActivity, filenameLifetime, filenameoccurrence, filenamePreference,
#     filenamePeriod, filenameSolution, filenameAssigned, csvseparator)

#     # create a directory "solution" if it does not exist
#     if (isdir(pathtodata) & !isdir(string(pathtodata, "solution")))
#         mkdir(string(pathtodata, "solution"))
#     end

#     # read the child data file
#     df_child = DataFrame(CSV.File(filenameChild,header=true, delim=csvseparator)) #readtable(filenameChild, separator = csvseparator);
#     # read the activity data file
#     df_activity = DataFrame(CSV.File(filenameActivity, header=true, delim=csvseparator)) #readtable(filenameActivity, separator = csvseparator);
#     # read the period data file
#     df_period = DataFrame(CSV.File(filenamePeriod, header=true, delim=csvseparator))#readtable(filenamePeriod, separator = csvseparator);
#     # read the lifetime data file
#     df_lifetime = DataFrame(CSV.File(filenameLifetime, header=true, delim=csvseparator))#readtable(filenameLifetime, separator = csvseparator);
#     # read the occurrence data file
#     df_occurrence =  DataFrame(CSV.File(filenameoccurrence, header=true, delim=csvseparator))#readtable(filenameoccurrence, separator = csvseparator);#CSV.read(filenameoccurrence, types=Dict(3=>String, 4=>String, 5=>String, 7=>Int64, 8=>Int64));#readtable(filenameoccurrence, separator = csvseparator);#CSV.read(filenameoccurrence, types=Dict(7=>Int64, 8=>Int64));#readtable(filenameoccurrence, separator = csvseparator);#CSV.read(filenameoccurrence, nullable=true)#

#     # read the preference data file
#     df_preference = DataFrame(CSV.File(filenamePreference, header=true, delim=csvseparator));#readtable(filenamePreference, separator = csvseparator);#CSV.read(filenamePreference, header=true)#
#     # read the knome data file
#     df_knome = DataFrame(CSV.File(filenameKnome, header=true, delim=csvseparator))#readtable(filenameKnome, separator = csvseparator);
#     # test if filenameAssiged exists
#     if isfile(filenameAssigned)
#     	# read the assigned data file
#     	df_assigned = DataFrame(CSV.File(filenameAssigned, header=true, delim=csvseparator));
#     else
#     	# define an empty data frame
#     	df_assigned=DataFrame(idpasseport = Int64[], idoccurrence = Int64[])
#     end # if isfile
# 
# 
#     return df_child, df_activity, df_period, df_lifetime, df_occurrence, df_preference, df_knome, df_assigned
# end

# #function to load and store the parameter given by the user
# function getParamcsv(filename)
#     csvseparator = ","
#     weightChoice = 4.0
#     weightCost = 1.0
#     mincv = 0.4
#     zvalue = 2.8
#     agecategorylimit = [today()] # by default, no category "2020-09-01"
# 
#     # Due to a bug in the last Julia version, isfile returns an error
#     # if isfile(filename)
#     #     param = DataFrame(CSV.File(filename, header=false))
# 
#     #     csvseparator = param[1,2]
#     #     weightChoice = parse(Float64, param[2,2])
#     #     weightCost = parse(Float64, param[3,2])
#     #     mincv = parse(Float64, param[4,2])
#     #     zvalue = parse(Float64, param[5,2])
#     #     agecategorylimit = sort(Date.(param[6:end,2]))
#     # end
# 
#     return csvseparator, weightChoice, weightCost, mincv, zvalue, agecategorylimit
# end
# 
# # get data from csv and clean it
# function getdatacsv(pathtodata::String)
#     #get the path to each data file
#     filenameParameter,
#     filenameChild,
#     filenameKnome,
#     filenameActivity,
#     filenameLifetime,
#     filenameoccurrence,
#     filenamePreference,
#     filenamePeriod,
#     filenameSolution,
#     filenameRemainder,
#     filenameAssigned = openFiles(pathtodata)
# 
#     #get the different parameter given by the user
#     csvseparator, weightChoice, weightCost, mincv, zvalue, agecategorylimit =
#         getParamcsv(filenameParameter)
# 
#     #read all the csv files and load into dataframes
#     df_child,
#     df_activity,
#     df_period,
#     df_lifetime,
#     df_occurrence,
#     df_preference,
#     df_knome,
#     df_assigned = datacsv( pathtodata,
#         filenameParameter,
#         filenameChild,
#         filenameKnome,
#         filenameActivity,
#         filenameLifetime,
#         filenameoccurrence,
#         filenamePreference,
#         filenamePeriod,
#         filenameSolution,
#         filenameAssigned,
#         csvseparator,
#     )
#     #convert and correct the data
#     df_child, df_period, df_lifetime, df_occurrence, df_preference = dataconvertcsv(df_child,
#     df_period,
#     df_lifetime,
#     df_occurrence,
#     df_preference)
# 
#     return df_child, df_activity, df_period, df_lifetime, df_occurrence, df_preference, df_knome, df_assigned
# end