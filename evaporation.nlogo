globals [
  max-age               ;; maximum age that all trees live to
  base-capacity         ;; base capacity of patches

  ;max-seed-chance       ;; probability of seeding a new tree
  max-health            ;; max healthpoints tree can have

  ;global-temperature   ;; ui determines base evaporation rate
  ;forest-evap-mul      ;; ui effect of full tree neighbourhood on evaporation (e.g. 0.5)
  ;forest-capacity-mul  ;; ui effect of full tree neighbourhood on patch capacity (e.g. 2)

  ;mean-time-between-rain ;; ui mean time between rain starts
  ;mean-rain-duration     ;; ui mean duration of rain
  ;rain-intensity         ;; ui rain intensity

  mean-rainfall         ;;
  current-rain-intensity
  mean-evaporation      ;;
  num-trees             ;;
]

breed [trees tree]

patches-own [
  water
  neighbours
  capacity
  evap-pos-mul
  evap-rate
]

trees-own [
  age
  health
]

to update-rain-intensity
  set rain-intensity 8 * mean-time-between-rain / mean-rain-duration
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Setup Procedures ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  set-default-shape trees   "tree pine"

  set max-age 25
  set base-capacity 100

  set max-health 100
;  set max-seed-chance 0.05
;  set global-temperature 10
;  set forest-evap-mul 0.5
;  set forest-capacity-mul 2

  seed-trees

  ask trees [
    set age random max-age
    set color green - 2
    set health (50 + (random 50))
  ]

  ask patches [ set water 0 ]

  ifelse do-evap-pos-mul
  [ask patches [
    set evap-pos-mul (distancexy 0 0) / 8
    set evap-pos-mul max list 1 evap-pos-mul
    ]
  ]
  [ask patches [ set evap-pos-mul 1 ]]

  if normalize-rain [update-rain-intensity]

  calculate-patch-values

  update-display
  reset-ticks
end

to update-display
  set mean-evaporation (mean [evap-rate] of patches)

  (ifelse
    show-what = "water amount" [
      ask patches [
        set pcolor 89.9 - (water / capacity) * 4.8
      ]
    ]
    show-what = "evaporation rate" [
      let max-evaporation (max [evap-rate] of patches)
      let min-evaporation (min [evap-rate] of patches)
      ask patches [
        let scaled  scale-color 5 evap-rate max-evaporation min-evaporation
        set pcolor 17 + scaled / 5
      ]
    ]
  )

  ask trees [
    ifelse (health < 50)
      [set color scale-color 33 health -50 100]
      [set color scale-color (green) health 150 0]
  ]


end

to seed-trees
  let radius ceiling ( sqrt ( start-tree-count / 3.14 ) )
  ask n-of start-tree-count patches with [not any? trees-here and distancexy 0 0 <= radius]
      [ sprout-trees 1 ]
end


to go
  calculate-patch-values
    ;; neighbours
    ;; patch capacity
    ;; patch evap rate
  rain
  ;; difuse water?
  cut-water
  update-trees-health
  evaporate
  age-trees
  breed-trees
  update-display
  tick
end

to calculate-patch-values
  ask patches [
    set neighbours sum [count trees-here] of neighbors
    set neighbours neighbours + count trees-here

    let capacity-mul 1 + (forest-capacity-mul - 1) * (neighbours / 9)
    set capacity base-capacity * capacity-mul

    let evap-mul 1
    if (any? trees-here)
    [ set evap-mul 1 + (forest-evap-mul - 1) * (neighbours / 9)]
    set evap-rate global-temperature * evap-mul * evap-pos-mul
  ]
end

to rain
  set mean-rainfall mean-rain-duration * rain-intensity / mean-time-between-rain
  let rain-prog ticks mod mean-time-between-rain
  ifelse (rain-prog < mean-rain-duration) [
    set current-rain-intensity rain-intensity
    ask patches [set water water + rain-intensity]
  ] [
    set current-rain-intensity 0
  ]
end

to evaporate
  ask patches [set water max list 0 (water - evap-rate)]
end

to cut-water
  ask patches [set water min list water capacity]
end

to update-trees-health
  ask trees [
    if (water <= 0) [
      set health (health - 10 - random 5)
    ]
    if (water >= 50) [
      set health min list max-health (health + (10 + random 5))
    ]
    if (health <= 0) [die]
  ]
end

to age-trees
  ask trees [
    set age (age + 1)
    if (age > max-age) [
      set health min list health (max-health - ( (max-age - age) * 5))
    ]
  ]
end

to breed-trees
  ask trees [
    let prob 0
    let seeding-places nobody
    if age >= 10 [
      set prob (health / max-health)
      set prob (prob * prob * prob)
      set prob (prob * max-seed-chance)
      if (random-float 1.0 < prob) [
        set seeding-places up-to-n-of (1 + random 2) patches in-radius 4 with [not any? trees-here]
        if (seeding-places != nobody) [
          ask seeding-places [sprout-trees 1 [
            set color green - 2
            set health 30
            ]
          ]
        ]
      ]
    ]
  ]
end

;to setup-old
;  clear-all
;  set-default-shape trees   "tree pine"
;  ask patches [ set pcolor gray ]
;
;  set max-age 25
;  set global-temperature 0
;
;  if (scenario = "ramp-up-ramp-down"    ) [ set solar-luminosity 0.8 ]
;  if (scenario = "low solar luminosity" ) [ set solar-luminosity 0.6 ]
;  if (scenario = "our solar luminosity" ) [ set solar-luminosity 1.0 ]
;  if (scenario = "high solar luminosity") [ set solar-luminosity 1.4 ]
;
;  seed-blacks-randomly
;  seed-whites-randomly
;  ask daisies [set age random max-age]
;  ask patches [calc-temperature]
;  set global-temperature (mean [temperature] of patches)
;  update-display
;  reset-ticks
;end
;
;to seed-blacks-randomly
;   ask n-of round ((start-%-blacks * count patches) / 100) patches with [not any? daisies-here]
;     [ sprout-daisies 1 [set-as-black] ]
;end
;
;to seed-whites-randomly
;   ask n-of floor ((start-%-whites * count patches) / 100) patches with [not any? daisies-here]
;     [ sprout-daisies 1 [set-as-white] ]
;end
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Runtime Procedures ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;to go-old
;   ask patches [calc-temperature]
;   diffuse temperature .5
;   ask daisies [check-survivability]
;   set global-temperature (mean [temperature] of patches)
;   update-display
;   tick
;   if scenario = "ramp-up-ramp-down" [
;     if ticks > 200 and ticks <= 400 [
;       set solar-luminosity precision (solar-luminosity + 0.005) 4
;     ]
;     if ticks > 600 and ticks <= 850 [
;       set solar-luminosity precision (solar-luminosity - 0.0025) 4
;     ]
;   ]
;   if scenario = "low solar luminosity"  [ set solar-luminosity 0.6 ]
;   if scenario = "our solar luminosity"  [ set solar-luminosity 1.0 ]
;   if scenario = "high solar luminosity" [ set solar-luminosity 1.4 ]
;end
;
;to set-as-black ;; turtle procedure
;  set color black
;  set albedo albedo-of-blacks
;  set age 0
;  set size 0.6
;end
;
;to set-as-white  ;; turtle procedure
;  set color white
;  set albedo albedo-of-whites
;  set age 0
;  set size 0.6
;end
;
;to check-survivability ;; turtle procedure
;  let seed-threshold 0
;  let not-empty-spaces nobody
;  let seeding-place nobody
;
;  set age (age + 1)
;  ifelse age < max-age
;  [
;     set seed-threshold ((0.1457 * temperature) - (0.0032 * (temperature ^ 2)) - 0.6443)
;     ;; This equation may look complex, but it is just a parabola.
;     ;; This parabola has a peak value of 1 -- the maximum growth factor possible at an optimum
;     ;; temperature of 22.5 degrees C
;     ;; -- and drops to zero at local temperatures of 5 degrees C and 40 degrees C. [the x-intercepts]
;     ;; Thus, growth of new daisies can only occur within this temperature range,
;     ;; with decreasing probability of growth new daisies closer to the x-intercepts of the parabolas
;     ;; remember, however, that this probability calculation is based on the local temperature.
;
;     if (random-float 1.0 < seed-threshold) [
;       set seeding-place one-of neighbors with [not any? daisies-here]
;
;       if (seeding-place != nobody)
;       [
;         if (color = white)
;         [
;           ask seeding-place [sprout-daisies 1 [set-as-white]  ]
;         ]
;         if (color = black)
;         [
;           ask seeding-place [sprout-daisies 1 [set-as-black]  ]
;         ]
;       ]
;     ]
;  ]
;  [die]
;end
;
;to calc-temperature  ;; patch procedure
;  let absorbed-luminosity 0
;  let local-heating 0
;  ifelse not any? daisies-here
;  [   ;; the percentage of absorbed energy is calculated (1 - albedo-of-surface) and then multiplied by the solar-luminosity
;      ;; to give a scaled absorbed-luminosity.
;    set absorbed-luminosity ((1 - albedo-of-surface) * solar-luminosity)
;  ]
;  [
;      ;; the percentage of absorbed energy is calculated (1 - albedo) and then multiplied by the solar-luminosity
;      ;; to give a scaled absorbed-luminosity.
;    ask one-of daisies-here
;      [set absorbed-luminosity ((1 - albedo) * solar-luminosity)]
;  ]
;  ;; local-heating is calculated as logarithmic function of solar-luminosity
;  ;; where a absorbed-luminosity of 1 yields a local-heating of 80 degrees C
;  ;; and an absorbed-luminosity of .5 yields a local-heating of approximately 30 C
;  ;; and a absorbed-luminosity of 0.01 yields a local-heating of approximately -273 C
;  ifelse absorbed-luminosity > 0
;      [set local-heating 72 * ln absorbed-luminosity + 80]
;      [set local-heating 80]
;  set temperature ((temperature + local-heating) / 2)
;     ;; set the temperature at this patch to be the average of the current temperature and the local-heating effect
;end
;
;to paint-daisies   ;; daisy painting procedure which uses the mouse location draw daisies when the mouse button is down
;  if mouse-down?
;  [
;    ask patch mouse-xcor mouse-ycor [
;      ifelse not any? daisies-here
;      [
;        if paint-daisies-as = "add black"
;          [sprout-daisies 1 [set-as-black]]
;        if paint-daisies-as = "add white"
;          [sprout-daisies 1 [set-as-white]]
;      ]
;      [
;        if paint-daisies-as = "remove"
;          [ask daisies-here [die]]
;      ]
;      display  ;; update view
;    ]
;  ]
;end
;
;to update-display-old
;  ifelse (show-temp-map? = true)
;    [ ask patches [set pcolor scale-color red temperature -50 110] ]  ;; scale color of patches to the local temperature
;    [ ask patches [set pcolor grey] ]
;
;  ifelse (show-daisies? = true)
;    [ ask daisies [set hidden? false] ]
;    [ ask daisies [set hidden? true] ]
;end
;
;
; Copyright 2006 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
420
10
863
454
-1
-1
15.0
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

SLIDER
1691
504
1886
537
albedo-of-surface
albedo-of-surface
0
1
0.4
0.01
1
NIL
HORIZONTAL

CHOOSER
1691
414
1886
459
scenario
scenario
"ramp-up-ramp-down" "maintain current luminosity" "low solar luminosity" "our solar luminosity" "high solar luminosity"
1

SLIDER
1691
464
1886
497
solar-luminosity
solar-luminosity
0.0010
3
0.8
0.0010
1
NIL
HORIZONTAL

SLIDER
1716
189
1886
222
start-%-blacks
start-%-blacks
0
50
20.0
1
1
NIL
HORIZONTAL

SLIDER
1546
189
1711
222
start-%-whites
start-%-whites
0
50
20.0
1
1
NIL
HORIZONTAL

SWITCH
1529
500
1679
533
show-temp-map?
show-temp-map?
0
1
-1000

BUTTON
6
45
71
78
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
6
8
71
41
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

SWITCH
424
508
574
541
show-trees?
show-trees?
0
1
-1000

PLOT
15
319
361
469
Rainfall
NIL
NIL
0.0
100.0
0.0
20.0
true
true
"" ""
PENS
"mean" 1.0 0 -16777216 true "" "plot mean-rainfall"
"current" 1.0 0 -13791810 true "" "plot current-rain-intensity"
"evaporation" 1.0 0 -2674135 true "" "plot mean-evaporation"

PLOT
18
643
264
793
Population
NIL
NIL
0.0
100.0
0.0
100.0
true
false
"" "set num-trees  count turtles\n"
PENS
"black" 1.0 0 -16777216 true "" "plot num-trees"

SLIDER
1546
224
1711
257
albedo-of-whites
albedo-of-whites
0
0.99
0.75
0.01
1
NIL
HORIZONTAL

SLIDER
1716
224
1886
257
albedo-of-blacks
albedo-of-blacks
0
0.99
0.25
0.01
1
NIL
HORIZONTAL

BUTTON
1684
284
1819
329
remove all daisies
ask daisies [die]\ndisplay
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1544
334
1679
377
paint daisies
paint-daisies
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
1544
284
1680
329
paint-daisies-as
paint-daisies-as
"add black" "add white" "remove"
2

CHOOSER
422
458
592
503
show-what
show-what
"water amount" "evaporation rate"
0

CHOOSER
7
138
145
183
temp-scenario
temp-scenario
"maintain"
0

CHOOSER
5
197
143
242
rain-scenario
rain-scenario
"maintain"
0

SLIDER
159
138
360
171
global-temperature
global-temperature
0
20
11.0
0.1
1
NIL
HORIZONTAL

SLIDER
235
10
407
43
forest-evap-mul
forest-evap-mul
0
2
0.5
0.1
1
NIL
HORIZONTAL

SLIDER
235
47
410
80
forest-capacity-mul
forest-capacity-mul
0
4
2.0
0.1
1
NIL
HORIZONTAL

SLIDER
155
197
377
230
mean-time-between-rain
mean-time-between-rain
0
200
60.0
1
1
NIL
HORIZONTAL

SLIDER
155
234
377
267
mean-rain-duration
mean-rain-duration
0
200
20.0
1
1
NIL
HORIZONTAL

SLIDER
155
271
350
304
rain-intensity
rain-intensity
0
20
20.0
1
1
NIL
HORIZONTAL

SLIDER
75
10
231
43
start-tree-count
start-tree-count
0
500
100.0
1
1
NIL
HORIZONTAL

PLOT
16
476
328
626
Ground Water
NIL
NIL
0.0
100.0
0.0
100.0
true
true
"" ""
PENS
"water" 1.0 0 -13791810 true "" "plot (mean [water] of patches)"
"health" 1.0 0 -5298144 true "" "plot (mean [health] of trees)"

CHOOSER
6
243
141
288
rain-type
rain-type
"deterministic" "stochastic"
0

SWITCH
693
469
843
502
do-evap-pos-mul
do-evap-pos-mul
0
1
-1000

BUTTON
868
29
953
62
Config 1
set start-tree-count 100\nset global-temperature 11\nset forest-evap-mul 0.5\nset forest-capacity-mul 2\n\nset mean-time-between-rain 60\nset mean-rain-duration 20\nset rain-intensity 20\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
870
73
955
106
Config 2
set start-tree-count 100\nset global-temperature 8\nset forest-evap-mul 1\nset forest-capacity-mul 2\n\nset mean-time-between-rain 50\nset mean-rain-duration 20\nset rain-intensity 20\n
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
694
506
858
539
normalize-rain
normalize-rain
0
1
-1000

SLIDER
421
568
860
601
max-seed-chance
max-seed-chance
0
0.05
0.04
0.001
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model explores the "Gaia hypothesis", which considers the Earth as a single, self-regulating system including both living and non-living parts. In particular, this model explores how living organisms both alter and are altered by climate, which is non-living. The example organisms are daisies and the climatic factor considered is temperature.

Daisyworld is a world filled with two different types of daisies: black daisies and white daisies.  They differ in albedo, which is how much energy they absorb as heat from sunlight.  White daisies have a high surface albedo and thus reflect light and heat, thus cooling the area around them.  Black daisies have a low surface albedo and thus absorb light and heat, thus heating the area around them.  However, there is only a certain temperature range in which daisies can reproduce; if the temperature around a daisy is outside of this range, the daisy will produce no offspring and eventually die of old age.

When the climate is too cold it is necessary for the black daisies to propagate in order to raise the temperature, and vice versa -- when the climate is too warm, it is necessary for more white daisies to be produced in order to cool the temperature.  For a wide range of parameter settings, the temperature and the population of daisies will eventually stabilize.  However, it is possible for Daisyworld to get either too hot or too cold, in which case the daisies are not able to bring the temperature back under control and all of the daisies will eventually die.

## HOW IT WORKS

White daisies, black daisies, and open ground (empty patches) each have an albedo or percentage of energy they absorb as heat from sunlight. Sunlight energy can be changed with the SOLAR-LUMINOSITY slider (a value of 1.0 simulates the average solar luminosity of our sun).

Each time step, every patch will calculate the temperature at that spot based on (1) the energy absorbed by the daisy at that patch and (2) the diffusion of 50% of the temperature value at that patch between its neighbors.  Open ground patches that are adjacent to a daisy have a probability of sprouting a daisy that is the same color as the neighboring daisy, based on a parabolic probability function that depends on the local temperature (where an optimum temperature of 22.5 yields a maximum probability of 100% of sprouting a new daisy). Daisies age each step of the simulation until they reach a maximum age, at which point they die and the patch they were in becomes open.

## HOW TO USE IT

START-%-WHITES and START-%-BLACKS sets the starting percentage of the patches that will be occupied by daisies (of either color) after pressing SETUP.

Selecting PAINT-DAISIES-AS and pressing PAINT-DAISIES allows the user to draw or erase daisies in the VIEW, by left clicking on patches.

ALBEDO-OF-WHITES and ALBEDO-OF-BLACKS sets the amount of heat absorbed by each of these daisy colors. ALBEDO-OF-SURFACE sets the amount of heat absorbed by an empty patch.

The SOLAR-LUMINOSITY sets the amount of incident energy on each patch from sunlight. But this value only will stay fixed at the user set value if the SCENARIO chooser is set to "maintain current luminosity". Other values of this chooser will change the albedo values. For example "ramp-up-ramp-down" will start the solar luminosity at a low value, then start increasing it to a high value, and then bring it back down again over the course of a model run.

SHOW-TEMP-MAP? shows a color map of temperature at each patch. Light red represents hotter temperatures, and darker red represents colder temperatures.

## THINGS TO NOTICE

Run the simulation. What happens to the daisies?  Do the populations ever remain stable? Are there ever population booms and busts?  If so, what causes them? (Hint: how do the daisies affects the climate? How does the climate then affect the daisies?)

What happens if boom and bust cycles just keep getting bigger and bigger? The swings can't keep getting bigger forever.

Does the planet ever become completely filled with life, or completely devoid of life?

Try running the simulation without the daisies. What happens to the planet's temperature? How is it different from what happens with the daisies?

Can the Daisyworld system be said to exhibit "hysteresis"?  Hysteresis is a property of systems that do not instantly follow the forces applied to them, but react slowly, or do not return completely to their original state.  The state of such systems depend on their immediate history.

## THINGS TO TRY

Try running the model with SHOW-DAISIES? off and SHOW-TEMP-MAP? on. You might be able to see interesting spatial patterns that emerge in temperature concentrations and periodic redistricting of temperature regions more easily in this mode.

Try adjusting the fixed temperature diffusion setting in the procedures (change it from 0.5). What happens to the behavior of Daisyworld if temperature is never diffused (set to 0.0)?

## EXTENDING THE MODEL

Black and white daisies represent two extreme types of daisies that could exist in this world.  Implement a third species of daisy.  You will need to choose what your daisy does and how it is different from black and white daisies.  How does your new daisy affect the results of this model?

Sunlight is only one aspect that controls the growth of daisies and other forms of life. Change the model so different parts of the world have different levels of soil quality.  How will this affect the outcome?

Many people feel that the Gaia hypothesis can be disturbed by human causes.  Implement pollution in the model.  Does this cause the daisies to die off quicker or more often?

Can you think of any other ways in which living organisms both alter and are altered by their environment?

## NETLOGO FEATURES

Uses the `diffuse` primitive to distribute heat between patches.

## RELATED MODELS

An alternate Daisyworld model is listed on the [User Community Models](http://ccl.northwestern.edu/netlogo/models/community/) page. It uses patches only, no turtles.

## CREDITS AND REFERENCES

The Daisyworld model was first proposed and implemented by Lovelock and Andrew Watson. The original Gaia hypothesis is due to Lovelock.

Watson, A.J., and J.E. Lovelock, 1983, "Biological homeostasis of the global environment: the parable of Daisyworld", Tellus 35B, 286-289. (The original paper by Watson and Lovelock introducing the Daisyworld model.)

Wikipedia also has a high-level description of the Daisyworld model: https://en.wikipedia.org/wiki/Daisyworld.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Novak, M. and Wilensky, U. (2006).  NetLogo Daisyworld model.  http://ccl.northwestern.edu/netlogo/models/Daisyworld.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2006 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2006 Cite: Novak, M. -->
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
