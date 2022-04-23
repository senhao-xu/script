#!/bin/bash
#设置颜色

out(){
 echo -e "\033[42m$1\033[0m"
}

read -p "$(echo -e "是否开启远程登录1开启,0不开启:")" longRange
out "===============start install postgresql"
yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
yum install -y postgresql14-server
out "===============end install postgresql"

out "===============start init postgresql"
/usr/pgsql-14/bin/postgresql-14-setup initdb
systemctl enable postgresql-14
systemctl start postgresql-14

out "===============init postgresql password -> postgres"
su - postgres -c "psql -c \"alter user postgres with password 'postgres';\" "
out "===============end init postgresql"

out "===============start longRange postgresql"
if [[ longRange==1 ]]; then
cp -f  ./postgresql.conf  /var/lib/pgsql/14/data/postgresql.conf    
cp -f ./pg_hba.conf /var/lib/pgsql/14/data/pg_hba.conf 
out "===============start open firewall"
firewall-cmd --zone=public --add-port=5432/tcp --permanent
firewall-cmd --reload
out "===============end open firewall"
fi
systemctl restart postgresql-14
out "===============end longRange postgresql"