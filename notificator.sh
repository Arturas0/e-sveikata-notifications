#!/usr/bin/env bash

cd "$(dirname "$0")"
source env.conf

if [ -n "${ACTIVE}" ] && [ "$ACTIVE" -eq 1 ]; then
  if [ -n "${TELEGRAM_BOT_TOKEN}" ] && [ -n "${TELEGRAM_CHAT_ID}" ]; then

    url="https://ipr.esveikata.lt/api/searches/appointments/times?municipalityId=${MUNICIPALITY_ID}"

    if [ -n "${ORGANIZATION_ID}" ]; then
      url+="&organizationId=${ORGANIZATION_ID}"
    fi

    LEFT_BOUND=$(date +%s)000

    url+="&professionCode=${PROFESSION_CODE}&paymentType=${PAYMENT_TYPE}&leftBound=${LEFT_BOUND}&rightBound=${RIGHT_BOUND}&page=${PAGE}&size=${SIZE}"

    reservations=$( (curl -s "$url" \
       -H "Host: ipr.esveikata.lt" \
       -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36" \
       -H "Accept-Language: en-US,en;q=0.9,lt;q=0.8" \
       -H "Accept: application/json, text/plain, */*") \
     | jq --argjson excludedHealthcareServices "${EXCLUDED_HEALTHCARE_SERVICES}" \
          --argjson excludedOrganizationIds "${EXCLUDED_ORGANIZATION_IDS}" \
       '.data | map(select(
         all(.healthcareServiceId; contains($excludedHealthcareServices[]) | not)
         and (.organizationId | IN($excludedOrganizationIds[]) | not)
       ))')

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
      curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        --data-urlencode "text=${formatedMessage}" > /dev/null
    fi

  else
    echo "Error: TELEGRAM_BOT_TOKEN or TELEGRAM_CHAT_ID is not set";
  fi
fi