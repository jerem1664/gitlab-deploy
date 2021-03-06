#!/usr/bin/env bash

GITPASS=`/usr/bin/tr -cd '[:alnum:]' < /dev/urandom | /usr/bin/fold -w16 | /usr/bin/head -n1`
GITURL="http://$HOSTNAME.one.ippon-hosting.net"

GITUSER="$3"
GITUSERMAIL=`echo $4 | /bin/sed 's/_AT_/@/'`
GITGROUP="$1"
GITPROJECT="$2"

# prerequires
/usr/bin/apt-get update
/usr/bin/apt-get remove apt-listchanges -y
/usr/bin/apt-get install curl openssh-server ca-certificates git -y


# DL
/usr/bin/curl -LJO https://packages.gitlab.com/gitlab/gitlab-ce/packages/ubuntu/xenial/gitlab-ce_9.1.3-ce.0_amd64.deb/download

# Install
/usr/bin/dpkg -i gitlab-ce_9.1.3-ce.0_amd64.deb


# wget gilab.rb or/and sed /etc/gitlab/gitlab.rb with VARS
/usr/bin/wget http://jerem.unvrai.info/share/gitlab.rb -O /etc/gitlab/gitlab.rb
#/bin/sed -i '13s/^#\ //' /etc/gitlab/gitlab.rb
#/bin/sed -i '43,47s/^#\ //' /etc/gitlab/gitlab.rb
#/bin/sed -i '314s/^#\ //' /etc/gitlab/gitlab.rb

/bin/sed -i "s,GITURL,"$GITURL"," /etc/gitlab/gitlab.rb
/bin/sed -i "s,GITPASS,"$GITPASS"," /etc/gitlab/gitlab.rb
/bin/sed -i "s,GITUSERMAIL,"$GITUSERMAIL",g" /etc/gitlab/gitlab.rb
/bin/sed -i "s,GITUSER,"$GITUSER"," /etc/gitlab/gitlab.rb
/bin/sed -i "s,GITPROJECT,"$GITPROJECT"," /etc/gitlab/gitlab.rb


# Launch conf
/usr/bin/gitlab-ctl reconfigure
if [ $? == 0 ] ; then
    GITSTATE="Install OK"
else
    GITSTATE="Something goes wrong"
fi



# Conf
GITLAB_TOKEN=`/usr/bin/curl http://localhost/api/v3/session --data "login=root&password=$GITPASS" | awk -F '"' '{print $(NF-1)}'`

/usr/bin/curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --data "email=$GITUSERMAIL&password=$GITPASS&username=$GITUSER&name=$GITUSER&confirm=false" "http://localhost/api/v3/users"

/usr/bin/curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --data "name=$GITGROUP&path=$GITGROUP" "http://localhost/api/v3/groups"

/usr/bin/curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --data "user_id=2&access_level=50" "http://localhost/api/v3/groups/3/members"

/usr/bin/curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --data "name=$GITPROJECT&owned=$GITGROUP&namespace_id=3" "http://localhost/api/v3/projects"


# Send info to ActiveMQ

/usr/bin/curl -XPOST -d "body={HOST:'$HOSTNAME',SERVICE:'Gitlab',GITLABSTATE:'$GITSTATE',GITURL:'$GITURL',TOKEN:'$GITLAB_TOKEN',GITROOTPASS:'$GITPASS',CLIENT:'$GITGROUP',PROJECT:'$GITPROJECT',ADMIN:'$GITUSER',EMAIL:'$GITUSERMAIL'}" http://admin:admin@10.0.45.30:8161/api/message?destination=queue://SO.FACT


# Clean
# rm -f /etc/gitlab/gitlab.rb
