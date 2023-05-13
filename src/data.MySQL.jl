################
# MySQL        #
################

using MySQL
using DBInterface
using DataFrames

# # those parameters are assigned elsewhere
# host = "127.0.0.1" # do not use 'localhost'
# user = ENV["PV_USER"]
# passwd = ENV["PV_PASSWORD"]
# dbname = ENV["PV_DATABASE"]


function readDataMySQL(dbname::String)
 #   conn = DBInterface.connect(MySQL.Connection, host, user, passwd, db=database)
    conn = DBInterface.connect(MySQL.Connection, host, user, passwd, db=dbname)
    field = ["activity", "child", "knome", "lifetime", "occurrence", "preference", "period", "assigned"]
    query = string.("SELECT * FROM ", "vr_julia_", field)

    df_activity = DBInterface.execute(conn, query[1]) |> DataFrame
    df_child = DBInterface.execute(conn, query[2]) |> DataFrame
    df_knome = DBInterface.execute(conn, query[3]) |> DataFrame
    df_lifetime = DBInterface.execute(conn, query[4]) |> DataFrame
    df_occurrence = DBInterface.execute(conn, query[5]) |> DataFrame
    df_preference = DBInterface.execute(conn, query[6]) |> DataFrame
    df_period = DBInterface.execute(conn, query[7]) |> DataFrame
    df_assigned = DBInterface.execute(conn, query[8]) |> DataFrame
    DBInterface.close!(conn::MySQL.Connection)

    return df_activity, df_child, df_knome, df_lifetime, df_occurrence, df_preference, df_period, df_assigned
end # function readDataMySQL

 function writeSolutionMySQL(dbname::String, s::String, df::DataFrame)
    # avoid problems with empty dataframe
    if nrow(df)==0
        return
    end

    # trick to avoid error with boolean values in the db
    if s=="solution"
        # convert boolean field into Int field
        df[!, :exceed] = convert.(Int, df[:, :exceed])
    end
    if s=="preassigned"
        # convert boolean field into Int field
        df[!, :valid] = convert.(Int, df[:, :valid])
    end

    conn = DBInterface.connect(MySQL.Connection, host, user, passwd, db=dbname)
        query = string.("DROP TABLE IF EXISTS ", s, ";")
        DBInterface.execute(conn, query)
        MySQL.load(df, conn, s)
    DBInterface.close!(conn::MySQL.Connection)
end # function writeSolutionMySQL