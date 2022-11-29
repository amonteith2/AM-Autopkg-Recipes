#!/bin/sh

serverURL="https://stir.jamfcloud.com:8443"
authFile="/tmp/authFile"
Username=$(osascript -e 'tell app "System Events" to display dialog "What is your username?" default answer "" with title "What is your Username?" with icon caution' | cut -d ":" -f3)
Password=$(osascript -e 'tell app "System Events" to display dialog "What is your password?" default answer "" with title "What is your Password?" with hidden answer with icon caution' | cut -d ":" -f3)
BasicAuth=$(printf $Username:$Password | iconv -t ISO-8859-1 | base64 -i -)
tmpDownload=/private/tmp/tempfile.xml
selection=$(osascript -e 'return choose from list {"Policy", "Patch Policy", "Configuration Profile", "Application"}')

if [ "$selection" == "Policy" ]; then
    choice="policies"
elif [ "$selection" == "Patch Policy" ]; then
    choice="patchpolicies"
elif [ "$selection" == "Configuration Profile" ]; then
    choice="osxconfigurationprofiles"
elif [ "$selection" == "Application" ]; then
    choice="macapplications"
else
    echo "Selection Invalid"
    exit 1
fi

ID=$(osascript -e 'tell app "System Events" to display dialog "What is the ID number of the '$selection' you are after? (this is available in URL in Jamf)" default answer "" with title "What is the ID number?"' | cut -d ":" -f3)

# Get token from Jamf.  Uses base64 hash of username and password for an account that has access to Jamf.
http_code_token=$(curl --request POST --silent --url $serverURL/api/v1/auth/token -w %{http_code} --header 'Accept: application/json' --header 'authorization: Basic '$BasicAuth -o $authFile)

if [ $http_code_token != "200" ]; then
    # handle error
    echo "Could not get token from Jamf - HTTP Code is "$http_code_token
	exit 1
else
    authToken=$(cat $authFile)
    rm $authFile
fi

# Read the output, extract the token information and store the token information as a variable in a script:
api_token=$(/usr/bin/plutil -extract token raw -o - - <<< $authToken)

echo ""
echo "Checking token..."
echo ""

# Verify that the token is valid and unexpired by making a separate API call, checking the HTTP status code and storing status code information as a variable in a script:
# Troubleshooting note: This was how i got this particular GET request to work...
api_authentication_check=$(curl $serverURL/api/v1/auth -w %{http_code} -o /dev/null --silent --header "Authorization: Bearer ${api_token}")

# 200 means the request is successful
if [ $api_authentication_check != "200" ]; then
    # handle error
    echo "API Authentication check failed - API authenticatiosn result is "$api_authentication_check
    exit 1
else
    echo "API authentication check passed."
fi
#echo ""

echo ""
echo "Getting requested information from Jamf..."
echo ""

# Finally, get the information onwhatever Jamf object it is that you're looking for
curl --request GET --header "Authorization: Bearer ${api_token}" --header 'Accept: application/xml' "$serverURL/JSSResource/$choice/id/$ID" -o $tmpDownload

# Extract the name of the object
objectName=$(xmllint --xpath "//policy/general/name" $tmpDownload | awk -F'[><]' '{print $3}')

# Convert the downloaded information to a (mostly) readable format
xmllint --format $tmpDownload > ~/desktop/"$objectName"-"$selection".xml
