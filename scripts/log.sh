#!/bin/bash

#This script is designed to have data re-directed to it with a pipe and it reads that data in to process it.

#Parameters:
#    vLogFile:  Location and name of file to log to.
#    vLogPoint: Where to log to. (optional, defaults to Screen and File [Screen])
#        Screen - Show this message on the screen, also in the file.
#        File   - Only show this message in the file, not the screen.

read vMessageIn #This reads a string from stdin and stores it in a variable called vMessageIn.

vLogFile="$1"
if [ -n "$2" ] ; then
   vLogPoint="$2"
else
   vLogPoint="Screen"
fi

#To force stop logging to the screen, create a file called logtofile in the home folder.
if [ -f $HOME/logtofile ] ; then
   vLogPoint="File"
fi

if [ "${vMessageIn: -3}" == "..." ] ; then
   vOutput="`date "+%Y/%m/%d %H:%M:%S"` ${vMessageIn}"
else
   if [ "${vMessageIn: 0:3}" == "..." ] ; then
      vOutput=" ${vMessageIn: 3}\n"
   else
      vOutput="`date "+%Y/%m/%d %H:%M:%S"` ${vMessageIn}\n"
   fi
fi

if [ "$vLogPoint" == "File" ] ; then
   printf "${vOutput}" >> ${vLogFile}
else
   printf "${vOutput}" | tee -a $vLogFile
fi
