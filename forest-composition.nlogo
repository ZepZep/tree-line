globals [
  cur-weather
  weather-hist

  target-oak-percentage

  total-profit

  pine-cuts
  pine-age-total
  oak-cuts
  oak-age-total
]

breed [pines pine]
breed [oaks oak]

turtles-own [
  age
  cut-age
  ripe-age
  max-profit
  tolerance
  health
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Setup Procedures ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  reset-ticks
  set weather-hist (list )

  set-default-shape pines  "tree pine"
  set-default-shape oaks   "tree"

  ask patches [
    set pcolor white
  ]

  plant

  ask turtles [
    set age random 5
    change_size
  ]
end


to go
  set cur-weather abs (random-normal 0 weather-variance)
  set weather-hist lput cur-weather weather-hist

  live
  cut
  plant

  tick
end


to live
  ask turtles [
    set age age + 1
    change_size
    if (is-pine? self) [
      let oak-neighbours-frac (sum [count oaks-here] of neighbors / 9)
      let tolerance-diff oak-tolerance - pine-tolerance
      set tolerance pine-tolerance + ((tolerance-diff * (oak-tolerance-share / 10)) * oak-neighbours-frac)
    ]
    if (cur-weather > tolerance) [
      if (random 100 <= 50) [
        set health health - 1
        if health = 2 [
          set color orange
        ]
        if health = 1 [
          set color brown
        ]
      ]
    ]
  ]
end

to change_size
  set size ((age + ripe-age) / ( 2 * ripe-age))
end

to cut
   ask turtles [
    if (health <= 0 or age >= cut-age) [
;      show (list health age cut-age)

      ifelse (breed = pines)
      [ set pine-cuts pine-cuts + 1
        set pine-age-total pine-age-total + age ]
      [ set oak-cuts oak-cuts + 1
        set oak-age-total oak-age-total + age ]
      add-profit
      die
    ]
  ]
end

to add-profit
  let power (3 / 4 * ripe-age - age) / (age / 10)
  let profit max-profit / ( 1 + exp power )
;  show list age profit
  set total-profit total-profit + profit
end

to plant
  let total count patches

  if (count turtles < total) [
    let missing-pines (total * (1 - oak-percentage / 100)) - (count pines)
    let missing-oaks (total * oak-percentage / 100) - (count oaks)

    set target-oak-percentage missing-oaks / (missing-oaks + missing-pines) * 100
;    show target-oak-percentage
    ask patches with [not any? turtles-here] [
      seed-tree
    ]
  ]


end

to seed-tree
  let r random 100
  ifelse (r < target-oak-percentage)
  [sprout-oaks 1  [
    set color green + 1
    set cut-age oak-cut-age
    set ripe-age oak-ripe-age
    set tolerance oak-tolerance
    set max-profit oak-max-profit
  ]]
  [sprout-pines 1 [
    set color green - 2
    set cut-age pine-cut-age
    set ripe-age pine-ripe-age
    set tolerance pine-tolerance
    set max-profit pine-max-profit
  ] ]

  ask turtles-here [
    set health tree-max-health
    set age 0
    change_size
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
398
10
1131
744
-1
-1
25.0
1
10
1
1
1
0
0
0
1
-14
14
-14
14
1
1
1
ticks
30.0

BUTTON
81
10
146
43
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
0

BUTTON
10
10
75
43
NIL
setup
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
9
162
181
195
pine-ripe-age
pine-ripe-age
0
200
50.0
1
1
NIL
HORIZONTAL

SLIDER
9
198
181
231
pine-max-profit
pine-max-profit
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
10
302
182
335
oak-ripe-age
oak-ripe-age
0
200
100.0
1
1
NIL
HORIZONTAL

SLIDER
9
341
181
374
oak-max-profit
oak-max-profit
0
100
75.0
1
1
NIL
HORIZONTAL

MONITOR
190
205
379
250
Pine base profitability
pine-max-profit / pine-cut-age * (count patches)
3
1
11

MONITOR
189
382
379
427
Oak base profitability
oak-max-profit / oak-cut-age * (count patches)
3
1
11

SLIDER
9
60
182
93
weather-variance
weather-variance
0
10
1.0
0.1
1
NIL
HORIZONTAL

PLOT
1146
295
1556
527
Weather histogram
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"set-plot-x-range 0 (4 * weather-variance)\nset-histogram-num-bars 8" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram weather-hist"

PLOT
1147
10
1557
235
Weather
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"set-plot-y-range 0 (4 * weather-variance)" ""
PENS
"weather" 1.0 2 -16777216 true "" "plot cur-weather"
"pine tolerance" 1.0 0 -13210332 true "" "plot pine-tolerance"
"oak tolerance" 1.0 0 -14454117 true "" "plot oak-tolerance"

SLIDER
9
98
181
131
oak-percentage
oak-percentage
0
100
30.0
1
1
NIL
HORIZONTAL

SLIDER
9
237
181
270
pine-tolerance
pine-tolerance
0
5
1.5
0.1
1
NIL
HORIZONTAL

SLIDER
10
381
182
414
oak-tolerance
oak-tolerance
pine-tolerance
5
2.5
0.1
1
NIL
HORIZONTAL

SLIDER
191
60
382
93
tree-max-health
tree-max-health
1
10
3.0
1
1
NIL
HORIZONTAL

PLOT
1561
295
1828
527
Profitability
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot total-profit / ticks"

MONITOR
1562
536
1827
581
Profitability
total-profit / ticks
0
1
11

PLOT
1561
10
1828
235
Cut age
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -12087248 true "" "plot pine-age-total / pine-cuts"
"pen-1" 1.0 0 -14454117 true "" "plot oak-age-total / oak-cuts"

SLIDER
189
342
379
375
oak-tolerance-share
oak-tolerance-share
0
100
75.0
1
1
%
HORIZONTAL

SLIDER
189
302
379
335
oak-cut-age
oak-cut-age
0
oak-ripe-age * 1.5
100.0
1
1
NIL
HORIZONTAL

SLIDER
190
162
378
195
pine-cut-age
pine-cut-age
0
pine-ripe-age * 1.5
50.0
1
1
NIL
HORIZONTAL

MONITOR
1697
241
1827
286
Oak cut age
oak-age-total / oak-cuts
2
1
11

MONITOR
1563
241
1692
286
Pine cut age
pine-age-total / pine-cuts
2
1
11

@#$#@#$#@
## Forest compostion

This model explores the profitability of planted mixed forests.

IV109: Modeling and simulations project
Robert Konicar, Petr Zelina
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
true
0
Circle -7500403 true true 30 30 240
Circle -7500403 true true 0 120 60
Circle -7500403 true true 240 120 60
Circle -7500403 true true 120 0 60
Circle -7500403 true true 120 240 60
Circle -7500403 true true 60 225 60
Circle -7500403 true true 180 225 60
Circle -7500403 true true 225 180 60
Circle -7500403 true true 15 180 60
Circle -7500403 true true 15 60 60
Circle -7500403 true true 225 60 60
Circle -7500403 true true 180 15 60
Circle -7500403 true true 60 15 60

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

tree pine
false
0
Rectangle -6459832 true false 120 225 180 300
Polygon -7500403 true true 150 240 240 270 150 135 60 270
Polygon -7500403 true true 150 75 75 210 150 195 225 210
Polygon -7500403 true true 150 7 90 157 150 142 210 157 150 7

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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="temp/intensity matrix" repetitions="1" runMetricsEveryStep="true">
    <setup>update-rain-intensity
setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>count trees</metric>
    <enumeratedValueSet variable="global-temperature">
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="9"/>
      <value value="10"/>
      <value value="11"/>
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-rain-duration">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="9"/>
      <value value="10"/>
      <value value="11"/>
      <value value="12"/>
      <value value="13"/>
      <value value="14"/>
      <value value="15"/>
      <value value="16"/>
      <value value="17"/>
      <value value="18"/>
      <value value="19"/>
      <value value="20"/>
      <value value="21"/>
      <value value="22"/>
      <value value="23"/>
      <value value="24"/>
      <value value="25"/>
      <value value="26"/>
      <value value="27"/>
      <value value="28"/>
      <value value="29"/>
      <value value="30"/>
      <value value="31"/>
      <value value="32"/>
      <value value="33"/>
      <value value="34"/>
      <value value="35"/>
      <value value="36"/>
      <value value="37"/>
      <value value="38"/>
      <value value="39"/>
      <value value="40"/>
      <value value="41"/>
      <value value="42"/>
      <value value="43"/>
      <value value="44"/>
      <value value="45"/>
      <value value="46"/>
      <value value="47"/>
      <value value="48"/>
      <value value="49"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="albedo-of-whites">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rain-scenario">
      <value value="&quot;maintain&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="paint-daisies-as">
      <value value="&quot;remove&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="start-%-blacks">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-trees?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-what">
      <value value="&quot;water amount&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rain-intensity">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="do-evap-pos-mul">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="start-%-whites">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="temp-scenario">
      <value value="&quot;maintain&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-time-between-rain">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="forest-evap-mul">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-temp-map?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="start-tree-count">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="albedo-of-blacks">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="forest-capacity-mul">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="solar-luminosity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="albedo-of-surface">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;maintain current luminosity&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rain-type">
      <value value="&quot;deterministic&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="temp-intensity" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>count trees</metric>
    <enumeratedValueSet variable="global-temperature">
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="9"/>
      <value value="10"/>
      <value value="11"/>
      <value value="12"/>
      <value value="13"/>
      <value value="14"/>
      <value value="15"/>
      <value value="16"/>
      <value value="17"/>
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-rain-duration">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="9"/>
      <value value="10"/>
      <value value="11"/>
      <value value="12"/>
      <value value="13"/>
      <value value="14"/>
      <value value="15"/>
      <value value="16"/>
      <value value="17"/>
      <value value="18"/>
      <value value="19"/>
      <value value="20"/>
      <value value="21"/>
      <value value="22"/>
      <value value="23"/>
      <value value="24"/>
      <value value="25"/>
      <value value="26"/>
      <value value="27"/>
      <value value="28"/>
      <value value="29"/>
      <value value="30"/>
      <value value="31"/>
      <value value="32"/>
      <value value="33"/>
      <value value="34"/>
      <value value="35"/>
      <value value="36"/>
      <value value="37"/>
      <value value="38"/>
      <value value="39"/>
      <value value="40"/>
      <value value="41"/>
      <value value="42"/>
      <value value="43"/>
      <value value="44"/>
      <value value="45"/>
      <value value="46"/>
      <value value="47"/>
      <value value="48"/>
      <value value="49"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="forest-evap-mul">
      <value value="0.5"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="forest-capacity-mul">
      <value value="2"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="percent-dev" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2000"/>
    <metric>total-profit / ticks</metric>
    <enumeratedValueSet variable="oak-percentage">
      <value value="0"/>
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
      <value value="25"/>
      <value value="30"/>
      <value value="35"/>
      <value value="40"/>
      <value value="45"/>
      <value value="50"/>
      <value value="55"/>
      <value value="60"/>
      <value value="65"/>
      <value value="60"/>
      <value value="75"/>
      <value value="70"/>
      <value value="85"/>
      <value value="80"/>
      <value value="85"/>
      <value value="90"/>
      <value value="95"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rain-deviation">
      <value value="0.5"/>
      <value value="0.75"/>
      <value value="1"/>
      <value value="1.25"/>
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="oak-tolerance-share">
      <value value="0"/>
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="cut-age-development" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2000"/>
    <metric>total-profit / ticks</metric>
    <steppedValueSet variable="pine-cut-age" first="10" step="5" last="50"/>
    <steppedValueSet variable="oak-cut-age" first="10" step="5" last="100"/>
    <enumeratedValueSet variable="weather-deviation">
      <value value="0.5"/>
      <value value="0.75"/>
      <value value="1"/>
      <value value="1.25"/>
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="oak-tolerance-share">
      <value value="0"/>
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="cut-age-development-pine" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2000"/>
    <metric>total-profit / ticks</metric>
    <steppedValueSet variable="pine-cut-age" first="10" step="1" last="75"/>
    <enumeratedValueSet variable="weather-deviation">
      <value value="0.5"/>
      <value value="0.75"/>
      <value value="1"/>
      <value value="1.25"/>
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="oak-tolerance-share">
      <value value="0"/>
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="cut-age-development-oak" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2000"/>
    <metric>total-profit / ticks</metric>
    <steppedValueSet variable="oak-cut-age" first="10" step="1" last="150"/>
    <enumeratedValueSet variable="weather-deviation">
      <value value="0.5"/>
      <value value="0.75"/>
      <value value="1"/>
      <value value="1.25"/>
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="oak-tolerance-share">
      <value value="0"/>
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
      <value value="100"/>
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
