#!/bin/sh

# A script to reset the permissions on PGAdmin so that it still works after it's been deployed by Jamf.

# 1. Get the current username and the PrimaryGroupID for that user
myName=$(whoami)
PGID=$(dscl . read /users/$myName PrimaryGroupID | cut -d " " -f2)

# 2. Get the list of all available domains - Just in case the device is joined to AD.
domainList=$(dscl localhost -list /)

# 3. Search through the list of domains you got in step 2 looking for the name of the group with the same PrimaryGroupID as the user in step 1.
for domain in $domainList
do
    # dscl won't accept 'Local' so substitute it for '.' 
    if [ $domain == "Local" ]; then
        domain="."
    fi
    searchResult=$(dscl $domain list /Groups PrimaryGroupID  | grep -w $PGID | cut -d " " -f1)
    # Fingers crossed we don't get any groups with matching IDs.
    if [[ $searchResult != "" ]]; then
        groupName=$searchResult
    fi
done

# 4. Now you have the user (see step 1) and the name of the group (see step 3), use chown to set the permissions so PGAdmin can work.
sudo chown -R $myName:$groupName /Applications/pgAdmin\ 4.app
