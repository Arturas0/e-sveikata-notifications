#!/usr/bin/env bash

source env.conf

if [ -n "${ACTIVE}" ] && [ "$ACTIVE" -eq 1 ]; then

  if [ -n "${LINE_TOKEN}" ]; then

  url="https://ipr.esveikata.lt/api/searches/appointments/times?municipalityId=${MUNICIPALITY_ID}"

  if [ -n "${ORGANIZATION_ID}" ]; then
    url+="&organizationId=${ORGANIZATION_ID}"
  fi

  url+="&professionCode=${PROFESSION_CODE}&page=${PAGE}&size=${SIZE}"

  reservations=$( (curl "$url" \
     -H "Host: ipr.esveikata.lt" \
     -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36" \
     -H "Accept-Language: en-US,en;q=0.9,lt;q=0.8" \
     -H "Accept: application/json, text/plain, */*") \
   | jq --argjson excludedHealthcareServices "${EXCLUDED_HEALTHCARE_SERVICES}" \
        --argjson excludedFundTypes "${EXCLUDED_FUND_TYPES}" \
   '.data | map(select(all(.healthcareServiceId; contains($excludedHealthcareServices[]) | not)) | select(all(.fundType.type; contains($excludedFundTypes[]) | not)))')

  if [ ! -f esveikataDB.json ]; then
   echo '[]' > esveikataDB.json
  fi

  if [ -s esveikataDB.json ]; then
    newReservations=$(jq -n --slurpfile db esveikataDB.json --argjson reservations "$reservations" '($reservations - $db[0])')
  else
    newReservations="$reservations"
  fi

  jq '. + (inputs|.)' esveikataDB.json <(echo "$newReservations") > tmp.json && mv tmp.json esveikataDB.json


  formatedMessage=$(jq -r 'map("\(.organizationName) \npaslauga: \(.healthcareServiceName) \nlaikas: \(.earliestTime/ 1000 | strflocaltime("%Y-%m-%d %H:%M")) \n")| .[]' <<< "$newReservations")

  if [ -n "$formatedMessage" ]; then
   curl -X POST https://notify-api.line.me/api/notify \
    -H "Authorization: Bearer ${LINE_TOKEN}" \
     -F "message=$formatedMessage"
  fi

else
  echo "Error: line token is not set";
  fi
fi