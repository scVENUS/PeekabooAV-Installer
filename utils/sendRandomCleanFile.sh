#!/bin/bash
#                                                                             #
# Copyright (C) 2019  Sittig Technologies GmbH                            #
# Author: Marcel Caspar
#
# This program is free software: you can redistribute it and/or modify        #
# it under the terms of the GNU General Public License as published by        #
# the Free Software Foundation, either version 3 of the License, or (at       #
# your option) any later version.                                             #
#                                                                             #
# This program is distributed in the hope that it will be useful, but         #
# WITHOUT ANY WARRANTY; without even the implied warranty of                  #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU           #
# General Public License for more details.                                    #
#                                                                             #
# You should have received a copy of the GNU General Public License           #
# along with this program.  If not, see <http://www.gnu.org/licenses/>.       #
#                                                                             #
###############################################################################


#
# This script can generate some files that can be analyzed by Peekaboo.
# In order to have every time a unique file, a random string is used to cosntruct the file.
# Currently this scripts supports the following files:
#       * rar with .docx inside
#       * zip with .docx inside
#       * docx
#       * pdf
#       * doc
#
# Setup:
#       apt update && apt install unrar zip pandoc texlive swaks pwgen rar
#       Replace down below the default values to yours. 
#       * shouldpass@domain.tld (receiver)
#       * mailserver.domain.tld (mailserver of the receiver. Might be different than the MX record)
#       * test@mail.otherdomain.tld (sender)
#       * mail.otherdomain.tld (HELO of the mailserver you mimmic)
#
#       Please also assure that you have a valid PTR/rDNS record in place. My scripts runs on a external server that is sending those emails to my mailserver at work
#
# Usage:
#       sendRandomCleanfile.sh rar
#       sendRandomCleanfile.sh docx

TYPE=$1

if [ $TYPE = "rar" ]; then
        RND_NAME=$(pwgen 6 1);
        echo $(pwgen 1024 1) > $RND_NAME.txt
        pandoc $RND_NAME.txt -o $RND_NAME.docx

        rar a $RND_NAME.rar  $RND_NAME.docx
elif [ $TYPE = "zip" ]; then
        RND_NAME=$(pwgen 6 1);
        echo $(pwgen 1024 1) > $RND_NAME.txt
        pandoc $RND_NAME.txt -o $RND_NAME.docx

        zip $RND_NAME.zip  $RND_NAME.docx
else
        RND_NAME=$(pwgen 6 1);
        echo $(pwgen 1024 1) > $RND_NAME.txt
        pandoc $RND_NAME.txt -o $RND_NAME.$TYPE
fi



if [ $TYPE = "docx" ]; then
        SAMPLE_MIME_TYPE="application/vnd.openxmlformats-officedocument.wordprocessingml.document"
elif [ $TYPE = "pdf" ]; then
        SAMPLE_MIME_TYPE="application/pdf"
elif [ $TYPE = "doc" ]; then
        SAMPLE_MIME_TYPE="application/msword"
elif [ $TYPE = "rar" ]; then
        SAMPLE_MIME_TYPE="application/x-rar"
elif [ $TYPE = "zip" ]; then
        SAMPLE_MIME_TYPE="application/zip"
else
        echo "no known format"
        exit 1;
fi

echo $SAMPLE_MIME_TYPE

swaks --to shouldpass@domain.tld --tls --attach-type $SAMPLE_MIME_TYPE --attach-name --attach $RND_NAME.$TYPE --suppress-data --server mailserver.domain.tld --from test@mail.otherdomain.tld --helo mail.otherdomain.tld
rm -f $RND_NAME.$TYPE
rm -f $RND_NAME.txt
