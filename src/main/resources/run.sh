#!/bin/bash
platform='unknown'
unamestr=`uname`
if [[ "$unamestr" == 'Linux' ]]; then
   platform='linux'
elif [[ "$unamestr" == 'Darwin' ]]; then
   platform='osx'
   echo "osx"
fi
fullpath=`readlink -f $0`
basedir=`dirname "${fullpath}"`
export APP_BASE=$basedir
# prints all the paramater $@. script name $0, first parameter $1 and so on
equinoxjar="org.eclipse.osgi-3.13.200.jar"
startdaemon=0
stopdaemon=0
consolestart=1
statusdaemon=0
unknown_option=0
while true ; do
    case "$1" in
        -verbose:*) consolestart=0; echo "immmm thinking......... :)"; shift;;
        -start) startdaemon=1; consolestart=0; stopdaemon=0; shift;;
        -stop) stopdaemon=1; startdaemon=0; consolestart=0; shift ;;
        -status) consolestart=0;statusdaemon=1; shift ;;
        -console) consolestart=1; startdaemon=0; stopdaemon=0; shift ;;
        "") break ;;
        *) unknown_option=1; shift ;;
    esac
done

usage() {
 echo "usage:"
 echo "  -start  -to start the application as daemon"
 echo "  -stop   -to stop the application"
 echo "  -status -to check the status of the application"
 echo "   empty to start the application in console mode"
}

if [ "${unknown_option}" -eq 1 ]; then
   echo "Unknown option"
   usage;
   exit 1;
fi

version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
if [ -z "$version" ]; then 
 echo "Java is required"
 exit 1;
fi

isApplicationRunning(){
   local  __resultvar=$1
   local running=0;
   while read line
   do
     processName=$(echo "$line" | awk '{print $8}')
     if [[ "$processName" == "java" ]]; then
        running=$(echo "$line" | awk '{print $2}');
        break
     fi
   done <<< "$(ps -ef | grep "$basedir/lib/$equinoxjar")"
   echo "$running"
}

retval=$(isApplicationRunning)
# Starting the application
if [ "${startdaemon}" -eq 1 ]; then
   retval=$(isApplicationRunning)
   if [ "$retval" -ne 0 ]; then
      echo "Application is already running !! PID:" $retval
   else
      java  -Dosgi.install.area=${basedir} \
            -Dosgi.configuration.area="${basedir}/configuration" \
            -Dosgi.logfile="${basedir}/logs/osgi.log" \
            -Dlogback.configurationFile="$basedir/configuration/logback.xml" \
            -Djetty.home="$basedir/configuration/osgi-jetty-home" \
            -Dfelix.fileinstall.dir="${basedir}/plugins" \
            -jar "${basedir}/lib/$equinoxjar" > /dev/null 2>&1 &
     retval=$(isApplicationRunning)
     if [ "$retval" == 0 ]; then
        echo "Application is not started !!"
     else
        echo "Started the application as deamon PID:" $retval
     fi
   fi
fi
#Stopping the application
if [ "${stopdaemon}" -eq 1 ]; then
   retval=$(isApplicationRunning)
   if [ "$retval" == 0 ]; then
      echo "Application is not running !!"
   else
      echo "Stopping the application with PID:" $retval
      kill "$retval" > /dev/null 2>&1
      sleep .5
      retval=$(isApplicationRunning)
      if [ "$retval" == 0 ]; then
         echo "Application is stopped !!"
      else
         echo "Application stop failed:" $retval
      fi
   fi
fi
#Checking the application status
if [ "${statusdaemon}" -eq 1 ]; then
   retval=$(isApplicationRunning)
   if [ "$retval" == 0 ]; then
     echo "Application is not running !!"
   else 
     echo "Application is running !! PID:" $retval
   fi
fi
# Starting the application in the console mode
if [ "${consolestart}" -eq 1 ]; then
   retval=$(isApplicationRunning)
   if [ "$retval" -ne 0 ]; then
      echo "Application is already running !! PID:" $retval
   else
      echo "Starting the application in console mode"
      java  -Dosgi.install.area=${basedir} \
            -Djava.naming.factory.url.pkgs="org.eclipse.jetty.jndi" \
	    -Djava.naming.factory.initial="org.eclipse.jetty.jndi.InitialContextFactory" \
            -Dosgi.configuration.area="${basedir}/configuration" \
            -Dosgi.logfile="${basedir}/logs/osgi.log" \
            -Dlogback.configurationFile="$basedir/configuration/logback.xml" \
            -Djetty.home="$basedir/configuration/osgi-jetty-home" \
            -Dfelix.fileinstall.dir="${basedir}/plugins" \
            -jar "${basedir}/lib/$equinoxjar" \
            -console  \
            -consoleLog 
   fi
fi

