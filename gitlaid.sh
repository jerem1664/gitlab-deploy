#!/usr/bin/env bash

GITPASS=`/usr/bin/openssl rand -base64 12`
GITURL="http://$HOSTNAME-$VMID.one.ippon-hosting.net"
GITUSER="geebay"
GITUSERMAIL="jbarron@ippon.fr"
GITGROUP="mygroup"
GITPROJECT="myproject"

# prerequires
/usr/bin/apt-get update
/usr/bin/apt-get remove apt-listchanges -y
/usr/bin/apt-get install curl openssh-server ca-certificates git -y


# DL
/usr/bin/curl -LJO https://packages.gitlab.com/gitlab/gitlab-ce/packages/ubuntu/xenial/gitlab-ce_9.1.3-ce.0_amd64.deb/download

# Install
/usr/bin/dpkg -i gitlab-ce_9.1.3-ce.0_amd64.deb


# wget gilab.rb and sed /etc/gitlab/gitlab.rb with VARS
/usr/bin/wget http://jerem.unvrai.info/share/gitlab.rb -O /etc/gitlab/gitlab.rb
/bin/sed -i "s,GITURL,"$GITURL"," /etc/gitlab/gitlab.rb
/bin/sed -i "s,GITPASS,"$GITPASS"," /etc/gitlab/gitlab.rb


# Launch conf
/usr/bin/gitlab-ctl reconfigure
if [ $? == 0 ] ; then
    echo "Done"
else
    echo "Something goes wrong"
fi



# Conf
GITLAB_TOKEN=`/usr/bin/curl http://localhost/api/v3/session --data "login=root&password=$GITPASS" | awk -F '"' '{print $(NF-1)}'`

/usr/bin/curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --data "email=$GITUSERMAIL&password=$GITPASS&username=$GITUSER&name=$GITUSER&confirm=false" "http://localhost/api/v3/users"

/usr/bin/curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --data "name=$GITGROUP&path=$GITGROUP" "http://localhost/api/v3/groups"

/usr/bin/curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --data "user_id=2&access_level=50" "http://localhost/api/v3/groups/3/members"

/usr/bin/curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --data "name=$GITPROJECT&owned=$GITGROUP&namespace_id=3" "http://localhost/api/v3/projects"


# Send Token to ActiveMQ

/usr/bin/curl -XPOST -d "body=TOKEN=$GITLAB_TOKEN,gitlabstate=Install_OK" http://admin:admin@10.0.45.30:8161/api/message?destination=queue://SO.FACT
