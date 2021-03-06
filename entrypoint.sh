#!/usr/bin/env bash


run(){
	set -x
	service apache2 start
	snort -u snort -g snort -c /etc/snort/snort.conf -D -i eno3 &
        barnyard2 -D -c /etc/snort/barnyard2.conf -d /var/log/snort -f snort.u2 -w /var/log/snort/barnyard2.waldo -g snort -u snort
	exit 0

}

error_msg(){
      echo "There is no environment variable to config mysql" > /dev/stderr
      rm /etc/snort/config.lock
}



if [ -e /etc/snort/configured ]; then
	echo "Configuration has been compeleted before this time..."
	run
fi

if [ ! -e /etc/snort/config.lock ]; then
   touch /etc/snort/config.lock
   if [ -z $mysql_host ]; then
	echo "MySQL Host Address is undefined" > /dev/stderr
	error_msg
   elif [ -z $mysql_user ]; then
	echo "MySQL Username is undefined" > /dev/stderr
	error_msg
   elif [ -z $mysql_password ]; then
	echo "MySQL password is undefined" > /dev/stderr
	error_msg
   elif [ -z $mysql_db ]; then
	echo "MySQL DatabaseName is undefined" > /dev/stderr
	error_msg
   elif [ -z $sensor_name ]; then
	echo "Sensor Name is undefined" > /dev/stderr
	error_msg
   else
        cd /var/www/html/snorby
	echo $mysql_host
	echo $mysql_user
	echo $mysql_password
	echo $mysql_db
	echo $sensor_name

	mysql -h$mysql_host -u$mysql_user -p$mysql_password $mysql_db -e exit
	if [ $? -ne 0 ]; then
		echo "Database is not ready"
	else
		sed -e 's/username.*/username: '"$mysql_user"'/' -e 's/password.*/password: '"$mysql_password"'/' -e 's/host.*/host: '"$mysql_host"'/' config/database.yml
		sed -i -e 's/username.*/username: '"$mysql_user"'/' -e 's/password.*/password: '"$mysql_password"'/' -e 's/host.*/host: '"$mysql_host"'/' config/database.yml
		RAILS_ENV=production bundle exec rake secret
		RAILS_ENV=production bundle exec rake db:autoupgrade
		RAILS_ENV=production bundle exec rake db:seed
		mysql --host=$mysql_host -u$mysql_user -p$mysql_password $mysql_db -e "source /opt/snort_src/barnyard2-master/schemas/create_mysql;"
		echo "output database: log, mysql, user=$mysql_user password=$mysql_password dbname=$mysql_db host=$mysql_host sensor name=$sensor_name" | tee -a /etc/snort/barnyard2.conf
		touch /etc/snort/configured 
		run
	fi
   fi
fi

exit 1
