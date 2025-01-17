globals [
  road_blocked
  total_speed_all
  total_speed_1
  total_speed_2
  ticks_lane_2
]

;; Elke agent heeft een snelheid en een rijbaan
turtles-own [
  speed
  lane
]

;; De setup functie activeert alle andere functies om de simulatie op te starten
to setup
  clear-all
  setup_road
  setup_cars
  reset-ticks
end

;; De setup_cars functie spawnt alle auto's (agents) in.
to setup_cars
  set-default-shape turtles "car"
  create-turtles aantal_autos [
    set lane 1
    set xcor random-xcor
    set ycor 8.5
    set heading 90 ; horizontaal naar rechts
    set color one-of base-colors ; Random kleur
    set size 1
    set speed (0.1 + random-float 0.9) * speed_limit ; Snelheid is voor elke auto iets anders, * speed_limit omdat anders het optrekken onnatuurlijk gaat.
    while [ any? other turtles-here ] [ fd 1 ] ; Zorgt ervoor dat de autos mooi verspreid komen te staan (anders staan er veel op 1 kluitje)
  ]


end

;; De setup_road functie creeërt de omgeving (wegen & gras)
to setup_road
  ask patches [ ifelse pycor < 10 and pycor > 7
    [ set pcolor gray - random-float 0.2 ] ; Maakt de weg grijs
    [ set pcolor 54 ] ] ; Maakt het gras groen
  ask patches [ if pycor = 10 or pycor = 7 [ set pcolor 4 ] ] ; Buitenlijnen van de weg
  ask patches with [ pxcor = 50 ] [ if pycor < 10 and pycor > 7 [ set pcolor red ]] ; Rode 'stopstreep'
  road_diagonal

  create-turtles 1 [ setxy -42  7 ] ; Deze onzichtbare turtle kijkt of er autos aan komen, 'de ogen' van de andere auto's
  ask turtle 5 [ hide-turtle ] ; Dit command zorgt ervoor dat de gebruiker de turtle niet kan zien (hij heeft ook geen lane dus zal geen invloed hebben op de uitkomsten of andere agents)

  ;; Deze turtles zijn bedoeld als aankleding, het zijn boompjes die op een random locatie verschijnen (niet op de weg)
  create-turtles 20 [
    ifelse random 2 = 1
    [ set shape "tree" set color green - random-float 0.5 ] ; Iedereen boom net een andere kleur
    [ set shape "house" ]
    set size 4
    setxy -38 -5 ; Begint linksonder
    setxy xcor + random-float 85 ycor + random-float 9 ; Versprijd random tussen 0 & 85 patches naar rechts en 0 tot 9 naar boven
  ]
end

;; De road_diagnal functie maakt de invoegstrook
to road_diagonal
  create-turtles 3 [ set heading 45 ] ; De functie maakt 3 turtles
  ask turtle 0 [ setxy -50 -3 ] ; En zet deze turtles neer op 3 plekken
  ask turtle 1 [ setxy -50 -4 ]
  ask turtle 2 [ setxy -50 -5 ]
  ask turtles [ set pcolor gray repeat 17 [ fd 1 set pcolor gray - random-float 0.5 ] ] ; Deze turtles rijden met een hoek van 45 graden naar de hoofdweg toe en kleuren elke patch waar ze over rijden grijs
  create-turtles 2 [ set heading 45 ] ; Dit zelfde gebeurt met de buitenlijnen
  ask turtle 3 [ setxy -50 -2 set pcolor 4 repeat 12 [ fd 1 set pcolor 4 ] ] ; Deze rijden precies even lang door todat ze bij de weg zijn.
  ask turtle 4 [ setxy -50 -6 set pcolor 4 repeat 17 [ fd 1 set pcolor 4 ] ]
  ask turtles [ die ] ; Als ze klaar zijn gaan de turtles weg.
  ask patches with [ pycor = 7 ] [ if pxcor >= -42 and pxcor <= -38 [ set pcolor 8 ] ]
  ;; Deze oplossing ziet er misschien een beetje gek uit maar word ook regelmatig gebruikt in de premade Netlogo simulaties.
end

;; Reset de simulatie en zet de parameters naar standaardwaarde
to reset
  ca
  set speed_limit 1
  set aantal_autos 25
  set invoeg true
  set invoeg_spawnrate 30
  setup
end

;; In de go functie gaan we alle auto's af, dit gebeurt per lane ( Lane1 = Rijbaan, Lane2 = Invoegstrook, Lane3 = Auto's op grijze streep bij invoegstrook (die gaan invoegen)
to go
  ; Auto's op rijbaan
  ask turtles with [ lane = 1 ] [
    let next-car one-of (turtles-on patch-ahead 1) with [ lane = 1 ] ; defineert next-car als de auto die (eventueel) op de voorliggende patch rijd.
    ifelse next-car = nobody ; Checkt of er wel of niet een auto op de voorliggende patch rijd
    [ set speed speed + ((0.0050 + random-float 0.0040) * speed_limit ) ] ; Versnel als er geen auto voor je zit
    [ set speed [ speed ] of next-car - (0.050 * speed_limit ) ] ;Rem af als er een auto voor je zit
    if speed < 0 [ set speed 0 ]
    if speed > speed_limit [ set speed speed_limit ]
    fd speed ; Rijden
    if pcolor = red [ die ] ; Auto verdwijnt als deze op het einde (rood) aankomt
  ]

  check_road ; Checkt nadat alle auto's opde hoofdrijbaan hebben gereden of er een auto de invoegstrook blokeert.

  ; Auto's op invoegstrook
  ask turtles with [ lane = 2 ] [
    let next-car one-of (turtles-on  patch-ahead 1.5) with [ lane = 2 or lane = 3 ] ; Zelfde rem/rij werking als lane1
    ifelse next-car = nobody
    [ set speed speed + ((0.0050 + random-float 0.0040) * speed_limit ) ]
    [ set speed [ speed ] of next-car - (0.050 * speed_limit ) ]
    if pcolor = 8 [  ; Wanneer de auto op de grijze streep komt
      ifelse road_blocked [ set speed 0 ] [ set lane 3 ] ] ; stilstaan als er een auto aan komt, rijden als deze voorbij zijn.
    if speed < 0 [ set speed 0 ]
    if speed > speed_limit [ set speed speed_limit ]
    fd speed
  ]

  ; Auto's die van strook wisselen (invoeg naar rijbaan)
  ask turtles with [ lane = 3 ] [
      ifelse speed = 0
      [ set speed (0.7 + random-float 0.2 ) * speed_limit ]
      [ set speed speed + (random-float 0.1) * speed_limit ]
      fd speed
      if ycor > 8.5 [ set lane 1 set ycor 8.5 set heading 90 ] ; Wanneer de auto op het midden van de rijbaan komt verandert hij van lane en rijd hij mee met de andere auto's
    ]

  ; Voor De gemiddelde snelheden slaan we de totale snelheid per tick op.
  set total_speed_all total_speed_all + mean [ speed ] of turtles with [ lane = 1 or lane = 2 ]
  set total_speed_1 total_speed_1 + mean [ speed ] of turtles with [ lane = 1 ]
  if any? turtles with [ lane = 2 ] [ set total_speed_2 total_speed_2 + mean [ speed ] of turtles with [ lane = 2 ] set ticks_lane_2 ticks_lane_2 + 1] ; De checkt any? doen we omdat er niet altijd een agent op de invoegstrook rijd

  spawn_car
  tick
end

;; De functie spawn_car spawnt een aantal nieuwe auto's in (evenveel als er de huidige tick verdwenen zijn)
to spawn_car
  create-turtles cars_missing [
    ifelse invoeg = true
    [ifelse random 100 < invoeg_spawnrate [ setxy -50 -4 set lane 2 set heading 45  ] [ setxy -50 8.5 set lane 1 set heading 90 ] ] ; Spawnt een % op de invoegstrook
    [ setxy -50 8.5 set lane 1 set heading 90 ]
    set speed (0.1 + random-float 0.9) * speed_limit
  ]
end

;; De functie check_road kijkt vanuit turtle 5 (die eerder is geplaatst en onzichtbaar is) of er auto's aan komen rijden bij de invoegstrook, en zet road_blocked op true als deze dus niet vrij is om in te voegen.
to check_road
  ask turtle 5 [ ifelse any? (turtles-on patches in-radius 5 ) with [ lane = 1 ] [ set road_blocked true] [ set road_blocked false ] ]
end

;; Report functies
;; Het aantal auto's dat verdwenen (died) zijn
to-report cars_missing
  report aantal_autos - count turtles with [ lane = 1 or lane = 2 or lane = 3 ]
end

;; report de huidige snelheid van alle auto's op de invoegstrook en de hoofdrijbaan
to-report speed_all
  report mean [ speed ] of turtles with [ lane = 1 or lane = 2 ]
end

;; report de huidige snelheid van alle auto's op de hoofdrijbaan
to-report speed_1
  report mean [ speed ] of turtles with [ lane = 1 ]
end

;; report de huidige snelheid van alle auto's op de invoegstrook
to-report speed_2
  report mean [ speed ] of turtles with [ lane = 2 ]
end

;; report de gemiddelde snelheid van alle auto's op de invoegstrook en de hoofdrijbaan (aller tijde)
to-report avr_speed
  ifelse ticks = 0 [ report 0 ] [ report total_speed_all / ticks ]
end

;; report de gemiddelde snelheid van alle auto's op de hoofdrijbaan (aller tijde)
to-report avr_speed_1
  ifelse ticks = 0 [ report 0 ] [ report total_speed_1 / ticks ]
end

;; report de gemiddelde snelheid van alle auto's op de invoegstrook  (aller tijde)
to-report avr_speed_2
  ifelse ticks_lane_2 = 0 [ report 0 ] [ report total_speed_2 / ticks_lane_2 ]
 end


;; Bronnen:
;; While loop: http://ccl.northwestern.edu/netlogo/docs/dict/while.html
;; Let/Nobody: http://ccl.northwestern.edu/netlogo/docs/dict/let.html
;; turtles-on/patch-ahead: http://ccl.northwestern.edu/netlogo/docs/dict/turtles-on.html
@#$#@#$#@
GRAPHICS-WINDOW
243
10
1564
344
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-50
50
-12
12
1
1
1
ticks
30.0

SLIDER
35
20
207
53
aantal_autos
aantal_autos
0
world-width
25.0
1
1
NIL
HORIZONTAL

BUTTON
37
62
94
96
NIL
setup\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
35
103
207
136
speed_limit
speed_limit
0.01
1
1.0
0.01
1
NIL
HORIZONTAL

BUTTON
153
63
208
96
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
95
62
152
95
NIL
reset
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
243
366
471
411
Gemiddelde snelheid alle auto's
avr_speed
3
1
11

PLOT
729
364
1576
583
Average Speed
NIL
Speed
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Gemiddelde" 1.0 0 -2674135 true "" "set-plot-y-range 0 1\nplot avr_speed"
"Huidig alle auto's" 1.0 0 -7500403 true "" "plot speed_all"
"Huidig rijbaan" 1.0 0 -955883 true "" "plot speed_1"
"Huidig invoeg" 1.0 0 -6459832 true "" "plot speed_2"

MONITOR
117
637
200
682
NIL
count turtles
17
1
11

BUTTON
29
648
108
681
Go Once
go 
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
31
172
134
205
invoeg
invoeg
0
1
-1000

MONITOR
242
414
470
459
Gemiddelde snelheid auto's op hoofdrijbaan
avr_speed_1
3
1
11

MONITOR
242
463
470
508
Gemiddelde snelheid auto's op invoegstrook
avr_speed_2
3
1
11

MONITOR
477
366
703
411
Huidige gemiddelde snelheid alle auto's
speed_all
3
1
11

MONITOR
477
415
704
460
Huidige gemiddelde snelheid hoofdrijbaan
speed_1
3
1
11

MONITOR
476
464
705
509
Huidige gemiddelde snelheid invoegstrook
speed_2
3
1
11

MONITOR
26
597
113
642
NIL
road_blocked
17
1
11

SLIDER
31
208
203
241
invoeg_spawnrate
invoeg_spawnrate
0
100
30.0
1
1
%
HORIZONTAL

MONITOR
121
591
203
636
NIL
cars_missing
17
1
11

TEXTBOX
161
335
311
353
NIL
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2000"/>
    <metric>avr_speed</metric>
    <metric>avr_speed_1</metric>
    <metric>avr_speed_2</metric>
    <enumeratedValueSet variable="speed_limit">
      <value value="0.05"/>
      <value value="0.1"/>
      <value value="0.15"/>
      <value value="0.2"/>
      <value value="0.25"/>
      <value value="0.3"/>
      <value value="0.35"/>
      <value value="0.4"/>
      <value value="0.45"/>
      <value value="0.5"/>
      <value value="0.55"/>
      <value value="0.6"/>
      <value value="0.65"/>
      <value value="0.7"/>
      <value value="0.75"/>
      <value value="0.8"/>
      <value value="0.85"/>
      <value value="0.9"/>
      <value value="0.95"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="aantal_autos">
      <value value="15"/>
      <value value="25"/>
      <value value="35"/>
      <value value="45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="invoeg">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
