*	Script grads per stampare una mappa da un ctl
*	stampa mappa della prima variabile in elenco.

*	plot pioggia
* colori pioggia forecast
'set rgb 21 249 238 224'
'set rgb 22 234 208 173'
'set rgb 23 197 210 235'
'set rgb 24 140 165 216'
'set rgb 25 63 106 191'
'set rgb 26 216 242 229'
'set rgb 27 178 229 204'
'set rgb 28 140 216 178'
'set rgb 29 102 204 153'
'set rgb 30 255 255 178'
'set rgb 31 234 234 0'
'set rgb 32 204 204 0'
'set rgb 33 244 163 163'
'set rgb 34 236 85 85'
'set rgb 35 206 22 22'
'set rgb 36 219 158 249'
'set rgb 37 183 61 244'
'set rgb 38 140 61 244'

*	colori pioggia nuovo lema originale
'set rgb 78 155 125 150'
*'set rgb 79 0 0 255'
'set rgb 79 0 100 255'
'set rgb 80 5 140 45'
'set rgb 81 5 255 5'
'set rgb 82 255 255 0'
'set rgb 83 255 200 0'
'set rgb 84 255 125 0'
'set rgb 85 255 25 0'
'set rgb 86 175 0 220'
'set rgb 87 130 0 220'
'set rgb 88 100 0 220'

*colori francesco...

*light blue to dark blue
*'set rgb 27 255 100 255'
*'set rgb 28  7 35 70'
*'set rgb 29  10 75 110'
*'set rgb 30  15 100 160'
*'set rgb 31  30 110 210'
*'set rgb 32  40 130 220'
*'set rgb 33  60 150 245'
*'set rgb 34  80 165 240'
*'set rgb 35 120 185 250'
*'set rgb 36 150 210 250'
*'set rgb 37 180 240 250'
*'set rgb 38 225 255 255'

**beige
*'set rgb 75 210 180 130'

*grigio
'set rgb 77 200 200 200'
*'set rgb 78 220 220 220'
*'set rgb 79 100 100 100'
*'set rgb 77 200 200 200'

*azzurri
*'set rgb 48 230 255 255'
*'set rgb 49 204 255 255'
*'set rgb 50 177 229 255'
*'set rgb 51 0 0 110'

*verdi
*'set rgb 82 143 255 121'
*'set rgb 83 49 162 0'

*rossi
*'set rgb 84 150 0 0'
*'set rgb 85 255 183 238'
*'set rgb 49 255 0 0'
*'set rgb 51 255 255 0'


*** definizione path dir tmp
'printenv $LOCKDIR'
PATH_TMP = subwrd(result,1)
say 'PATH DIR TMP='PATH_TMP

'open cumulata_oraria.ctl'

'q dims'
lin_time=sublin(result,5)
time=subwrd(lin_time,6)

'q ctlinfo'
lin_numerofile=sublin(result,7)
numerofile=subwrd(lin_numerofile,2)

lema = read(PATH_TMP%'/lema.txt')
lema1 = sublin(lema,2)
say 'numero dati lema: 'lema1
albis = read(PATH_TMP%'/albis.txt')
albis1 = sublin(albis,2)
say 'numero dati albis: 'albis1
dole = read(PATH_TMP%'/dole.txt')
dole1 = sublin(dole,2)
say 'numero dati dole: 'dole1
plaine = read(PATH_TMP%'/plaine.txt')
plaine1 = sublin(plaine,2)
say 'numero dati plaine: 'plaine1

'set parea off'
'set grads off'
'set poli off'
*'set gxout grfill'
'set gxout shade2'

*scala nuovo lema
'set ccols 0 77 78 79 80 81 82 83 84 85 86 87 88'
'set clevs 0.1 0.5 1 2 4 6 10 20 40 60 80 100'
*'set clevs 0.1 0.3 0.5 1 2 3 4 5 6 10 50 100'

* scala forecast
*'set ccols 0 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38'
*'set clevs 0.1 0.5 1 3 5 7 10 15 20 30 40 50 60 70 80 100 120 150'

*'set xaxis 0 0'
*'set yaxis 0 0'
'set xlint 1'
'set ylint 1'
'set grid off'
'set xlopts 15 1 0.08'
'set ylopts 15 1 0.08'
*'set cmin 0.16'

'd radar'
*'d maskout(radar,radar-0.1)'
'draw title from 'time' (UTC) + 1hr'

'run cbarn.gs 0.9'

*titoli
'set string 2 c 6'
'set strsiz 0.12 0.12'
*'draw string 9.5 0.4 'numerofile ' su 12'
'draw string 10.5 1.2 L='lema1
'draw string 10.5 1 D='dole1
'draw string 10.5 0.8 A='albis1
'draw string 10.5 0.6 P='plaine1

* province
'set line 15 1 2'
'draw shp ITA_adm2'

* confini lombardia
'set line 1 1 2'
'draw shp ITA_adm1'

* confini stati
'set line 1 1 5'
'draw shp ITA_adm0'

* acqua
'set line 4 1 3'
'draw shp 10m_lakes'
'draw shp 10m_rivers_lake_centerlines'
'draw shp 10m_rivers_europe'
'draw shp 10m_lakes_europe'

* citta
'run citta.gs'

'close 1'

'enable print temp.gx'
'print'
'disable print'
'!/opt/opengrads/grads-2.0.1.oga.1/Contents/gxyat  -x 1024 -y 768 temp.gx'
'!rm -v temp.gx'
'quit'

