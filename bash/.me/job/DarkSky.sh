#!/usr/bin/env bash

if ! command -v JSON &> /dev/null; then
  me addm JSON
fi

DS_KEY="$(pass show DarkSky/key)"
DS_LOCATION="$(pass show DarkSky/location)"   # [latitude],[longitude]
DS_TIME="$(date -d '1 day' +%s)"
DS_EXCLUDE='flags,alert,hourly,minutely,currently'
DS_UNITS='si'
DS_FORECAST_API="https://api.darksky.net/forecast/${DS_KEY}/${DS_LOCATION},${DS_TIME}?exclude=${DS_EXCLUDE}&units=${DS_UNITS}"

#TW_NEWLINE="%0a"
TW_SID="$(pass show twilio/sid)"
TW_TOKEN="$(pass show twilio/token)"
TW_TO="$(pass show twilio/to)"
TW_FROM="$(pass show twilio/from)"
TW_API="https://api.twilio.com/2010-04-01/Accounts/${TW_SID}/Messages.json"

declare -A data
declare -a data_keys=(
  'summary'
  'time'
  'temperatureMin'
  'temperatureMinTime'
  'temperatureMax'
  'temperatureMaxTime'
  'windSpeed'
  'windBearing'
  'sunriseTime'
  'sunsetTime'
)

filter() {
  # plus character " to every key
  for (( i=0; i<${#data_keys[@]}; i++ )); do
    data_keys[i]=${data_keys[i]}\"
  done

  # string join
  # thx: https://stackoverflow.com/a/17841619
  local IFS='|'
  regex=${data_keys[*]}
  sed -rn "/${regex}/ p" $1
}

parse() {
  while read -r key value; do
    key=${key::-2}    # delete last two characters " and ]
    key=${key##*\"}   # delete the characters from begining unit the last "

    # test whether array contains some value
    # thx: https://stackoverflow.com/a/15394738
    # only when the data_keys contains the key, then we store it into data
    if [[ " ${data_keys[@]} " =~ " ${key} " ]]; then
      data[${key}]=${value}
    fi
  done
}

# enable 'lastpipe' option: the shell runs the last command of a pipeline not
# executed in the background in the current shell environment. (so we can modify
# the current script variable in the function 'parse')
shopt -s lastpipe
curl ${DS_FORECAST_API} | JSON -l | filter | parse

wind_bearing() {
  if [ $1 == 0 ]; then
    data[windBearing]=正北
  elif [ $1 -gt 0 -a $1 -lt 90 ]; then
    data[windBearing]=东北
  elif [ $1 == 90 ]; then
    data[windBearing]=正东
  elif [ $1 -gt 90 -a $1 -lt 180 ]; then
    data[windBearing]=东南
  elif [ $1 == 180 ]; then
    data[windBearing]=正南
  elif [ $1 -gt 180 -a $1 -lt 270 ]; then
    data[windBearing]=西南
  elif [ $1 == 270 ]; then
    data[windBearing]=正西
  elif [ $1 -gt 270 -a $1 -lt 360]; then
    data[windBearing]=西北
  elif [ $1 == 360 ]; then
    data[windBearing]=正北
  else
    data[windBearing]=
  fi
}

# TODO: check data is not null
if [[ -n "${data[summary]}" ]]; then
  en_message="Tomorrow is ${data[summary]} "
  en_message+="temperatureMax: ${data[temperatureMax]}°C. "
  en_message+="temperatureMaxTime: $(date -d @${data[temperatureMaxTime]} +'%H:%M'). "
  en_message+="temperatureMin: ${data[temperatureMin]}°C. "
  en_message+="temperatureMinTime: $(date -d @${data[temperatureMinTime]} +'%H:%M'). "
  en_message+="windSpeed: ${data[windSpeed]}km/h. "
  en_message+="windBearing: ${data[windBearing]}°. "
  en_message+="sunriseTime: $(date -d @${data[sunriseTime]} +'%H:%M'). "
  en_message+="sunsetTime: $(date -d @${data[sunsetTime]} +'%H:%M'). "

  zh_message="明日天气: ${data[summary]} "
  zh_message+="最高气温 ${data[temperatureMax]}°C ，"
  zh_message+="出现在 $(date -d @${data[temperatureMaxTime]} +'%H:%M')。"
  zh_message+="最低气温 ${data[temperatureMin]}°C ，"
  zh_message+="出现在 $(date -d @${data[temperatureMinTime]} +'%H:%M')。"
  zh_message+="日出 $(date -d @${data[sunriseTime]} +'%H:%M')，"
  zh_message+="日落 $(date -d @${data[sunsetTime]} +'%H:%M')。"
  wind_bearing ${data[windBearing]}
  if [[ -n ${data[windBearing]} ]]; then
    zh_message+="${data[windBearing]}风，风速 ${data[windSpeed]}km/h。"
  else
    zh_message+="风速 ${data[windSpeed]}km/h。"
  fi
fi

send_sms() {
  curl -X POST ${TW_API} \
    --data-urlencode "To=${TW_TO}" \
    --data-urlencode "From=${TW_FROM}" \
    -d "Body=$*" \
    -u ${TW_SID}:${TW_TOKEN}
}


printf "%s\n" "${en_message}"
printf "%s\n" "${zh_message}"
#send_sms ${en_message}
#send_sms ${zh_message}
