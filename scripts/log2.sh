#!/bin/bash

#Parameters:
#    vLogFile:  Location and name of file to log to.
#    vAddFile:  What to log.
#    vLogPoint: Where to log to. (optional, defaults to Screen and File [Screen])
#        Screen - Show this message on the screen, also in the file.
#        File   - Only show this message in the file, not the screen.

vLogFile="$1"
vAddFile="$2"
if [ -n "$3" ] ; then
   vLogPoint="$3"
else
   vLogPoint="Screen"
fi

#To force stop logging to the screen, create a file called logtofile in the home folder.
if [ -f $HOME/logtofile ] ; then
   vLogPoint="File"
fi

if [ "$vLogPoint" != "File" ] ; then
   cat "${vAddFile}"
fi

touch ${vLogFile}
cat "${vAddFile}" >> "${vLogFile}"

#Remove any log file created.
rm -f /tmp/log.tmp
