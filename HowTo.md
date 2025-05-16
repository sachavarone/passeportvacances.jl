# Instructions

## Ubuntu on WSL2
* install from windows store Ubuntu last version
* launch Ubuntu and update it
```bash
sudo apt update && sudo apt upgrade
```

## Julia on Ubuntu
* install Julia from juliaup
 cf https://github.com/JuliaLang/juliaup
```bash
curl -fsSL https://install.julialang.org | sh
```

## Project
* clone the project
```bash
git clone https://github.com/sachavarone/passeportvacances.jl.git
```
* lauch VScode
```bash
code .
```

## MySQL
* install MySQL
```bash
sudo apt install mysql-server
```
* check that it MySQL is launched
```bash
service mysql status
```
* if needed, start the service 
(cf  https://stackoverflow.com/questions/62987154/mysql-wont-start-error-su-warning-cannot-change-directory-to-nonexistent)
```bash
sudo service mysql stop
sudo usermod -d /var/lib/mysql/ mysql
sudo service mysql start
```
Note: in case of problem, "mysql -uroot -p" make it possible to login
* Secure mysql
```bash
sudo mysql_secure_installation
```
* trick to be able to connect using root user
```bash
sudo mysql
```

## Login credential preparation in .bashrc
```bash
export PV_USER='username'
export PV_PASSWORD='password'
export PV_DATABASE='databasename'
export PV_EMAIL='myemail@myhost.ext'
```

## Database
* Copy db passeport vacances from a windows folder to the current wsl folder
```bash
cp /mnt/c/Users/datapath_where_the_db_is/database_name.sql .
```
* create the database
```bash
mysql -u root -p
mysql> CREATE DATABASE <database_name;
mysql> USE <database_name;

# Creata a user
mysql> CREATE USER '<user_name>'@'localhost' IDENTIFIED BY '<mot_de_passe_complexe>';

# Create access rights
mysql> GRANT SELECT, SHOW VIEW ON <database_name>.* TO '<user_name>'@'localhost';
mysql> GRANT CREATE, INSERT, DROP ON <database_name>.solution TO '<user_name>'@'localhost';
mysql> GRANT CREATE, INSERT, DROP ON <database_name>.remainder TO '<user_name>'@'localhost';
mysql> GRANT CREATE, INSERT, DROP ON <database_name>.preassigned TO '<user_name>'@'localhost';
mysql> FLUSH PRIVILEGES;
mysql> \q
```