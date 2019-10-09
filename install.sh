#!/bin/bash
echo "";

echo "################################################";
echo "##  Welcom To Bayu Dwiyan Satria Installation ##";
echo "################################################";

echo "";

echo "Use of code or any part of it is strictly prohibited.";
echo "File protected by copyright law and provided under license.";
echo "To Use any part of this code you need to get a writen approval from the code owner: bayudwiyansatria@gmail.com.";

echo "";

# User Access
if [ $(id -u) -eq 0 ]; then

    echo "################################################";
    echo "##        Checking System Compability         ##";
    echo "################################################";

    echo "";
    echo "Please wait! Checking System Compability";
    echo "";

    # Operation System Information
    if type lsb_release >/dev/null 2>&1 ; then
        os=$(lsb_release -i -s);
    elif [ -e /etc/os-release ] ; then
        os=$(awk -F= '$1 == "ID" {print $2}' /etc/os-release);
    elif [ -e /etc/os-release ] ; then
        os=$(awk -F= '$1 == "ID" {print $3}' /etc/os-release);
    else
        exit 1;
    fi

    os=$(printf '%s\n' "$os" | LC_ALL=C tr '[:upper:]' '[:lower:]' | sed 's/"//g');

    # Update OS Current Distribution
    read -p "Update Distro (y/n) [ENTER] (y)(Recommended): " update;
    update=$(printf '%s\n' "$update" | LC_ALL=C tr '[:upper:]' '[:lower:]' | sed 's/"//g');

    if [ "$update" == "y" ] ; then 
        if [ "$os" == "ubuntu" ] || [ "$os" == "debian" ] ; then
            apt-get -y update && apt-get -y upgrade;
        elif [ "$os" == "centos" ] || [ "$os" == "rhel" ] || [ "$os" == "fedora" ] ; then
            yum -y update && yum -y upgrade;
        else
            exit 1;
        fi
    fi

    # Required Packages
    if [ "$os" == "ubuntu" ] || [ "$os" == "debian" ] ; then
        apt-get -y install git && apt-get -y install wget && apt-get -y install ipcalc;
    elif [ "$os" == "centos" ] || [ "$os" == "rhel" ] || [ "$os" == "fedora" ]; then
        yum -y install git && yum -y install wget && yum -y install ipcalc;
    else
        exit 1;
    fi

    echo "################################################";
    echo "##          Check Kafka Environment          ##";
    echo "################################################";
    echo "";

    echo "We checking Kafka is running on your system";

    KAFKA_HOME="/usr/local/kafka";
    
    if [ -e "$KAFKA_HOME/config" ]; then
        echo "";
        echo "Kafka is already installed on your machines.";
        echo "";
        exit 1;
    else
        echo "Preparing install Kafka";
        echo "";
    fi

    if [ "$1" ] ; then
        version=$1;
        distribution="2.3.0";
        packages="$version";
    else
        read -p "Enter kafka distribution version, (NULL FOR STABLE) [ENTER] : "  version;
        version=$(printf '%s\n' "$version" | LC_ALL=C tr '[:upper:]' '[:lower:]' | sed 's/"//g');

        if [ -z "$version" ] ; then 
            echo "kafka version is not specified! Installing kafka with lastest stable version";
            distribution="2.3.0";
            version="$distribution";
            packages="kafka_2.12-$version";
        else
            version=$version;
            distribution="$version";
            packages="kafka_2.12-$distribution";
        fi
    fi

    echo "################################################";
    echo "##         Collect Kafka Distribution        ##";
    echo "################################################";
    echo "";

    # Packages Available
    if [ "$2" ] ; then
        mirror="$2";
    else
        mirror=https://www.apache.org/dist/kafka;
    fi

    url=$mirror/$distribution/$packages.tgz;
    echo "Checking availablility kafka $version";
    if curl --output /dev/null --silent --head --fail "$url"; then
        echo "Kafka version is available: $url";
    else
        echo "Kafka version isn't available: $url";
        exit 1;
    fi

    echo "";
    echo "Kafka version $version install is in progress, Please keep your computer power on";

    wget $mirror/$distribution/$packages.tgz -O /tmp/$packages.tgz;

    echo "";
    echo "################################################";
    echo "##             Kafka Installation            ##";
    echo "################################################";
    echo "";

    echo "Installing Kafka Version  $distribution";
    echo "";

    # Extraction Packages
    tar -xvf /tmp/$packages.tgz;
    mv $packages $KAFKA_HOME;

    # User Generator
    read -p "Do you want to create user for kafka administrator? (y/N) [ENTER] (y) " createuser;
    createuser=$(printf '%s\n' "$createuser" | LC_ALL=C tr '[:upper:]' '[:lower:]' | sed 's/"//g');

    if [ -n createuser ] ; then
        if [ "$createuser" == "y" ] ; then
            read -p "Enter username : " username;
            read -s -p "Enter password : " password;
            egrep "^$username" /etc/passwd >/dev/null;
            if [ $? -eq 0 ]; then
                echo "$username exists!"
            else
                pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
                useradd -m -p $pass $username
                [ $? -eq 0 ] && echo "User has been added to system!" || echo "Failed to add a user!"
            fi
            usermod -aG $username $password;
        else
            read -p "Do you want to use exisiting user for kafka administrator? (y/N) [ENTER] (y) " existinguser;
            if [ "$existinguser" == "y" ] ; then
                read -p "Enter username : " username;
                egrep "^$username" /etc/passwd >/dev/null;
                if [ $? -eq 0 ]; then
                    echo "$username | OK" ;
                else
                    echo "Username isn't exist we use root instead";
                    username=$(whoami);
                fi 
            else 
                username=$(whoami);
            fi
        fi
    else
        read -p "Enter username : " username;
        read -s -p "Enter password : " password;
        egrep "^$username" /etc/passwd >/dev/null;
        if [ $? -eq 0 ]; then
            echo "$username exists!"
        else
            pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
            useradd -m -p $pass $username
            [ $? -eq 0 ] && echo "User has been added to system!" || echo "Failed to add a user!"
            usermod -aG $username $password;
            echo "User $username created successfully";
            echo "";
        fi
    fi

    echo "";
    echo "################################################";
    echo "##             Kafka Configuration           ##";
    echo "################################################";
    echo "";

    echo "Generate configuration file";

    mkdir -p $KAFKA_HOME/logs;
    mkdir -p $KAFKA_HOME/works;

    # Configuration Variable
    files=(zookeeper.properties server.properties producer.properties consumer.properties);
    for configuration in "${files[@]}" ; do 
        wget https://raw.githubusercontent.com/bayudwiyansatria/Apache-Kafka-Environment/master/kafka-$distribution/config/$configuration -O /tmp/$configuration;
        rm $KAFKA_HOME/config/$configuration;
        chmod 674 /tmp/$configuration;
        mv /tmp/$configuration $KAFKA_HOME/config;
    done
    
    # Network Configuration

    interface=$(ip route | awk '/^default/ { print $5 }');
    ipaddr=$(ip -o -4 addr list "$interface" | awk '{print $4}' | cut -d/ -f1);
    gateway=$(ip route | awk '/^default/ { print $3 }');
    subnet=$(ip addr show "$interface" | grep "inet" | awk -F'[: ]+' '{ print $3 }' | head -1);
    network=$(ipcalc -n "$subnet" | cut -f2 -d= );
    prefix=$(ipcalc -p "$subnet" | cut -f2 -d= );
    hostname=$(echo "$HOSTNAME");

    broker=1;
    cp $KAFKA_HOME/config/server.properties $KAFKA_HOME/config/server-$broker.properties;
    echo -e 'broker.id='$broker'' >> KAFKA_HOME/config/server-$broker.properties;
    sed -i 's/#listeners=PLAINTEXT://:9093//logs#g' $KAFKA_HOME/config/server-$broker.properties;
    echo -e 'listeners=PLAINTEXT://:9093' >> $KAFKA_HOME/config/server-$broker.properties;
    sed -i 's#/tmp/kafka-logs#/usr/local/kafka/logs#g' $KAFKA_HOME/config/server-$broker.properties;
    sed -i 's#localhost#'$ipaddr's#g' $KAFKA_HOME/config/server-$broker.properties;

    chown $username:$username -R $KAFKA_HOME;
    chmod g+rwx -R $KAFKA_HOME;

    echo "";
    echo "################################################";
    echo "##             Java Virtual Machine           ##";
    echo "################################################";
    echo "";

    echo "Checking Java virtual machine is running on your machine";
    profile="/etc/profile.d/bayudwiyansatria.sh";
    env=$(echo "$PATH");
    if [ -e "$profile" ] ; then
        echo "Environment already setup";
    else
        touch $profile;
        echo -e 'export LOCAL_PATH="'$env'"' >> $profile;
    fi

    java=$(echo "$JAVA_HOME");

    if [ -z "$java" ] ; then
        if [ "$os" == "ubuntu" ] || [ "$os" == "debian" ] ; then
            apt-get -y install openjdk-8-jdk;
        elif [ "$os" == "centos" ] || [ "$os" == "rhel" ] || [ "$os" == "fedora" ]; then
            yum -y install java-1.8.0-openjdk;  
        else 
            exit 1;  
        fi
    fi

    java=$(dirname $(readlink -f $(which java))|sed 's^/bin^^');
    echo -e 'export JAVA_HOME="'$java'"' >> $profile;
    echo -e '# Apache Kafka Environment' >> $profile;
    echo -e 'export KAFKA_HOME="'$KAFKA_HOME'"' >> $profile;
    echo -e 'export KAFKA_CONF_DIR=${KAFKA_HOME}/config' >> $profile;
    echo -e 'export KAFKA_INSTALL=${KAFKA_HOME}' >> $profile;
    echo -e 'export KAFKA=${KAFKA_HOME}/bin:${KAFKA_HOME}/sbin' >> $profile;
    
    zookeeper=$(echo "$ZOOKEEPER");
    if [ -z "$ZOOKEEPER"] ; then
        echo -e 'export PATH=${LOCAL_PATH}:${KAFKA}' >> $profile;
    else
        echo -e 'export PATH=${LOCAL_PATH}:${KAFKA}:${ZOOKEEPER}' >> $profile;
    fi

    echo "Successfully Checking";

    echo "";
    echo "################################################";
    echo "##             Authorization                  ##";
    echo "################################################";
    echo "";

    echo "Setting up cluster authorization";
    echo "";

    if [[ -f "/home/$username/.ssh/id_rsa" && -f "/home/$username/.ssh/id_rsa.pub" ]]; then
        echo "SSH already setup";
        echo "";
    else
        echo "SSH setup";
        echo "";
        sudo -H -u $username bash -c 'ssh-keygen';
        echo "Generate SSH Success";
    fi

    if [ -e "/home/$username/.ssh/authorized_keys" ] ; then
        echo "Authorization already setup";
        echo "";
    else
        echo "Configuration authentication";
        echo "";
        sudo -H -u $username bash -c 'touch /home/'$username'/.ssh/authorized_keys';
        echo "Authentication Compelete";
        echo "";
    fi
    
    sudo -H -u $username bash -c 'cat /home/'$username'/.ssh/id_rsa.pub >> /home/'$username'/.ssh/authorized_keys';
    chown -R $username:$username "/home/$username/.ssh/";
    sudo -H -u $username bash -c 'chmod 600 /home/'$username'/.ssh/authorized_keys';

    # Firewall
    echo "################################################";
    echo "##            Firewall Configuration          ##";
    echo "################################################";
    echo "";

    echo "Documentation firewall rule for Kafka https://kafka.apache.org/";

    if [ "$os" == "ubuntu" ] || [ "$os" == "debian" ] ; then
        echo "Enable Firewall Services";
        echo "";
        systemctl start ufw;
        systemctl enable ufw;

        echo "Adding common firewall rule for kafka security";
        ufw allow 9092:9099/tcp;
        
        echo "Allowing DNS Services";
        ufw allow dns;
        echo "";

        echo "Reload Firewall Services";
        systemctl stop ufw;
        systemctl start ufw;
        echo "";

        echo "";
        echo "Success Adding Firewall Rule";
        echo "";

    elif [ "$os" == "centos" ] || [ "$os" == "rhel" ] || [ "$os" == "fedora" ] ; then 
        echo "Enable Firewall Services";
        echo "";
        systemctl start firewalld;
        systemctl enable firewalld;

        echo "Adding common firewall rule for kafka security";
        firewall=$(firewall-cmd --get-default-zone);
        firewall-cmd --zone="$firewall" --permanent --add-port=9092-9099/tcp;
        
        echo "Allowing DNS Services";
        firewall-cmd --zone="$firewall" --permanent --add-service=dns;
        echo "";

        echo "Reload Firewall Services";
        firewall-cmd --reload;
        echo "";

        echo "";
        echo "Success Adding Firewall Rule";
        echo "";
    else
        exit 1;
    fi
    
    if [ "$master" == "n" ] ; then 
        echo "Your worker already setup";
    else
        echo "";
        echo "############################################";
        echo "##        Adding Worker Nodes             ##";
        echo "############################################";
        echo "";

        read -p "Do you want to setup worker? (y/N) [ENTER] (n) " workeraccept;
        workeraccept=$(printf '%s\n' "$workeraccept" | LC_ALL=C tr '[:upper:]' '[:lower:]' | sed 's/"//g');

        if [ -n "$workeraccept" ] ; then 
            if [ "$workeraccept" == "y" ] ; then
                while [ "$workeraccept" == "y" ] ; do 
                    read -p "Please enter worker IP Address [ENTER] " worker;
                    echo -e  ''$worker' # Worker' >> $KAFKA_HOME/config/worker;
                    if [[ -f "~/.ssh/id_rsa" && -f "~/.ssh/id_rsa.pub" ]]; then 
                        echo "SSH already setup";
                        echo "";
                    else
                        echo "SSH setup";
                        echo "";
                        ssh-keygen;
                        echo "Generate SSH Success";
                    fi

                    if [ -e "~/.ssh/authorized_keys" ] ; then 
                        echo "Authorization already setup";
                        echo "";
                    else
                        echo "Configuration authentication";
                        echo "";
                        touch ~/.ssh/authorized_keys;
                        echo "Authentication Compelete";
                        echo "";
                    fi
                    ssh-copy-id -i ~/.ssh/id_rsa.pub "$username@$ipaddr"
                    ssh-copy-id -i ~/.ssh/id_rsa.pub "$worker"
                
                    ssh $worker "wget https://raw.githubusercontent.com/bayudwiyansatria/Apache-Kafka-Environment/master/express-install.sh";
                    ssh $worker "chmod 777 express-install.sh";
                    ssh $worker "./express-install.sh" $version "$mirror" "$username" "$password" "$ipaddr";
                    scp /home/$username/.ssh/authorized_keys /home/$username/.ssh/id_rsa /home/$username/.ssh/id_rsa.pub $username@$worker:/home/$username/.ssh/
                    ssh $worker "chown -R $username:$username /home/$username/.ssh/";
                    scp $KAFKA_HOME/config/server-$broker.properties $username@$worker:$KAFKA_HOME/config
                    broker=$(( $broker + 1 ));
                    cp $KAFKA_HOME/config/server.properties $KAFKA_HOME/config/server-$broker.properties;
                    echo -e 'broker.id='$broker'' >> KAFKA_HOME/config/server-$broker.properties
                    echo -e 'listeners=PLAINTEXT://:9093' >> $KAFKA_HOME/config/server-$broker.properties;
                    echo -e 'log.dirs='$KAFKA_HOME'/logs-'$broker'' >> $KAFKA_HOME/config/server-$broker.properties;
                    scp $KAFKA_HOME/config/server-$broker.properties $username@$worker:$KAFKA_HOME/config;
                    read -p "Do you want to add more worker? (y/N) [ENTER] (n) " workeraccept;
                    workeraccept=$(printf '%s\n' "$workeraccept" | LC_ALL=C tr '[:upper:]' '[:lower:]' | sed 's/"//g');
                done
            fi
        fi

        echo "Worker added";
    fi

    echo "";
    echo "################################################";
    echo "##             Kafka Initialize               ##";
    echo "################################################";
    echo "";

    echo "";

    echo "Initialize Complete";

    echo "";
    echo "############################################";
    echo "##                Cleaning                ##";
    echo "############################################";
    echo "";

    echo "Cleaning Installation Packages";
    echo "";

    rm -rf /tmp/$packages.tgz;
    rm -rf install.sh;

    echo "Success Installation Packages";
    echo "";

    echo "";
    echo "############################################";
    echo "## Thank You For Using Bayu Dwiyan Satria ##";
    echo "############################################";
    echo "";
    
    echo "Installing Kafka $version Successfully";
    echo "Installed Directory $KAFKA_HOME";
    echo "";

    echo "User $username";
    echo "Pass $password";
    echo "";

    echo "Author    : Bayu Dwiyan Satria";
    echo "Email     : bayudwiyansatria@gmail.com";
    echo "Feel free to contact us";
    echo "";

    read -p "Do you want to reboot? (y/N) [ENTER] [n] : "  reboot;
    if [ -n "$reboot" ] ; then
        if [ "$reboot" == "y" ]; then
            reboot;
        else
            echo "We highly recomended to reboot your system";
        fi
    else
        echo "We highly recomended to reboot your system";
    fi

else
    echo "Only root may can install to the system";
    exit 1;
fi