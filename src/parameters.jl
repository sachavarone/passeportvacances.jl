##################################
# subsequent parameters          #
##################################
# csvseparator = ","
weightChoice = 4.0
weightCost = 1.0
mincv = 0.4
zvalue = 2.8
agecategorylimit = [today()] # by default, no category "2020-09-01"
solvername = "CBC"
# solvername = "HiGHS"

##################################
# MySQL parameters               #
##################################
host = "127.0.0.1" # do not use 'localhost'
user = ENV["PV_USER"]
passwd = ENV["PV_PASSWORD"]
database = ENV["PV_DATABASE"]
@info "Parameters 'user', 'passwd' and 'database' read from MySQL"
