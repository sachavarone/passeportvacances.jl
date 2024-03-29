##################################
# subsequent parameters          #
##################################
# csvseparator = ","
weightChoice = 4.0
weightCost = 1.0
mincv = 0.4
zvalue = 2.8
agecategorylimit = [today()] # by default, no category "2020-09-01"
# solvername = "CBC"
# solvername = "HiGHS"
# solvername = "NEOS" # Cplex will be used

##################################
# MySQL parameters               #
##################################
host = "127.0.0.1" # do not use 'localhost'
user = ENV["PV_USER"]
passwd = ENV["PV_PASSWORD"]
@info "Parameters 'user', 'passwd' and 'database' read from environment variables"

##################################
# Email for commercial solvers   #
# only needed if NEOS is used    #
##################################
myemail = ENV["PV_EMAIL"]