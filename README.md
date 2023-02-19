# E-sveikata notifications

[![N|Esveikata](https://www.esveikata.lt/img/esveikata.png)](https://ipr.esveikata.lt/)

## What it does
Checks https://ipr.esveikata.lt for available appointments and notifies user about available spots for specialists.

## Requirements 

- bash shell
- [jq](https://github.com/stedolan/jq) (^1.6)
- [LINE Notify token](https://notify-bot.line.me/en/) (requires LINE account: https://line.me/en/)

## Configuration
For notifier to work you need to set up some variable.
### Basic configuration
Set up `env.conf` file with parameters for:
`MUNICIPALITY_ID` and `PROFESSION_CODE` or `ORGANIZATION_ID`. These can be obtained from:
1. Visiting: https://ipr.esveikata.lt/
2. Right click on page and select `inspect` (shortcut is `F12`) select `Network` tab
3. Apply search filters on page and click `Ieškoti`
4. You can filter responses by entering `times` or scroll manually until you see line near column `File` `times?municipalityId=11`, where `11` is number for selected municipality. Other filter variable will be shown after this
5. Fill these variables in `env.conf`.

Also you need to register LINE account to be able to generate `LINE Notify` token.

## Auto checking
Using linux system can be set up using `crontab` (command `crontab -e`)

Add this line to run script every 15 minutes between 7-23 hours monday to saturday:

`*/15 7-23 * * 1-6 /home/pi/projects/esveikata-notifier/notificator.sh`