# passeportvacances

"Passeport Vacances": an assignment of activities to children

A mathematical model and its algorithm in the Julia language for an assignment of children to activities problem, known as the

    Passeport Vacances

It includes, in its original version,

    data requests from a MySQL database
    a modelisation as a Mixed Integer Programming model (MIP)
    a query to a MIP solver, by default Cbc
    a solution written to a MySQL database

It does not include
    a database
    views as requests in the database
so that this project is usefull only if you have your own data.

Usage: passeporvacances.run(database_name)
