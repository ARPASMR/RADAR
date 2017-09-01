# RADAR
codice per l'elaborazione dei dati radar Monte Lema

copia di radar_ora.sh e radar_giorno.sh su libertario

# crontab
```
# Radar orario
10 * * * * /home/meteo/radar_ora/radar_ora.sh >> /home/meteo/log/radar_ora_`/bin/date +\%Y\%m\%d`.log 2>&1
# Radar giorno
30 0 * * * /home/meteo/radar_giorno/radar_giorno.sh >> /home/meteo/log/radar_giorno_`/bin/date +\%Y\%m\%d`.log 2>&1
```
