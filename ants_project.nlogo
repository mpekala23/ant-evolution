;extensions [array]

;breed [blue_ants blue_ant]
;breed[red_ants red_ant]
breed[ants ant]
turtles-own [state num health age]

patches-own [
  diff-active-chem  ;; temporarily hold chemical value so diffuse primitive can be used
  chemical             ;; amount of chemical on this patch
  food                 ;; amount of food on this patch (0, 1, or 2)
  nest_num               ;; array placement of nest
  nest-scent          ;; number that is higher closer to the nest
  food-source-number   ;; number (1, 2, or 3) to identify the food sources
]
globals[
  nest-listx
  nest-listy
  nest-colors
  nest-health
  nest-reprod-count
]



;;;;;;;;;;;;;;;;;;;;;;;;
;;; Setup procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  set watch-num 1
  ;; set nest infos

  set nest-listx (list );(random 100 - 50) (random 100 - 50) (random 100 - 50) (random 100 - 50) (random 100 - 50))
  set nest-listy (list );(random 100 - 50) (random 100 - 50) (random 100 - 50) (random 100 - 50) (random 100 - 50))
  set nest-colors (list red blue yellow pink magenta grey brown orange lime turquoise cyan sky violet pink red blue yellow pink magenta grey brown orange lime turquoise cyan sky violet pink)
  set nest-health (list )
  set nest-reprod-count (list )


  set-default-shape ants "bug"

  let string-temp ""
  let i 0
  while [i < number-ants][

    ;; set nest infos

    set nest-listx insert-item i nest-listx (random 120 - 60)
    set nest-listy insert-item i nest-listy (random 120 - 60)
    set nest-health insert-item i nest-health initial-nest-health
    set nest-reprod-count insert-item i nest-reprod-count 0

    ;; plot pens

    set string-temp insert-item i string-temp "1"
    set-current-plot "health-plot"
    create-temporary-plot-pen string-temp
    set-plot-pen-color (item i nest-colors)
    set-plot-pen-mode 0




  create-ants population
  [ set size 2         ;; easier to see
    set color (item i nest-colors)
    set state 0 ;; state 0 = foraging, 1 = carrying food, 2 = healing, 3 = returning-empty
    set num i   ;; colony number
    set age (who / population - num) * ant-lifespan ;; age, make sure to scaled to prevent massive die-off
    setxy (item i nest-listx) (item i nest-listy)
    set health initial-ant-health
   ]
  ;ask ants [setxy (item i nest-listx) (item i nest-listy)]
   set i i + 1
  ]

  ;set-default-shape blue_ants "bug"
  ;create-blue_ants population
  ;[ set size 2         ;; easier to see
  ;  set color blue
  ;  set state 0  ;; 1 = not carrying food
  ;  set num 1  ]
  ;ask blue_ants [setxy -15 0]
  setup-patches
  reset-ticks

end

to setup-patches

  ask patches
  [ set chemical (list )
    set nest-scent (list )
    let i 0
    while [i < number-ants][
      set chemical insert-item i chemical 0
      set nest-scent insert-item i nest-scent 0
      set i i + 1
    ]
    set nest_num -1
    setup-nest
    setup-food
    recolor-patch
      ]

end

to setup-nest  ;; patch procedure
  ;; set nest? variable to true inside the nest, false elsewhere
  ;set nest_red? (distancexy 15 0) < 5
  ;set nest_blue? (distancexy -15 0) < 5
  ;; spread a nest-scent over the whole world -- stronger near the nest
  ;set nest-scent list(200 - distancexy 15 0) (200 - distancexy -15 0)
  let i 0

  while [i < number-ants][
      if (distancexy (item i nest-listx) (item i nest-listy)) < 3.5 [
      set nest_num i

      ]

      set nest-scent replace-item i nest-scent (200 - distancexy (item i nest-listx) (item i nest-listy))
      set i i + 1
    ]

end

to setup-food  ;; patch procedure
  ;; setup food source one on the right
  if (distancexy (0.6 * max-pxcor) 0) < 5
  [ set food-source-number 1 ]
  ;; setup food source two on the lower-left
  if (distancexy (-0.6 * max-pxcor) (-0.6 * max-pycor)) < 5
  [ set food-source-number 2 ]
  ;; setup food source three on the upper-left
  if (distancexy (-0.8 * max-pxcor) (0.8 * max-pycor)) < 5
  [ set food-source-number 3 ]
  ;; set "food" at sources to either 1 or 2, randomly
  if food-source-number > 0
  [ set food one-of [1 1] ]
end

to recolor-patch  ;; patch procedure
  ;; give color to nest and food sources
  ifelse nest_num != -1[set pcolor (item nest_num nest-colors)]
  [ifelse food > 0
    [ if food-source-number = 1 [ set pcolor green ]
      if food-source-number = 2 [ set pcolor green  ]
      if food-source-number = 3 [ set pcolor green ] ]


    ;; scale color to show chemical concentration
      [ ;let i 0
        ;foreach chemical
        ;[chem] -> if chem > 250
         ;[ [set chemical replace-item i chemical 250]
         ; set i i + 1
        ;]
      set pcolor scale-color (item (watch-num - 1) nest-colors) (item (watch-num - 1) chemical) 0 200] ]
end

;;;;;;;;;;;;;;;;;;;;;
;;; Go procedures ;;;
;;;;;;;;;;;;;;;;;;;;;

to go  ;; forever button

  let k 0
  while [k < number-ants][
    if item k nest-reprod-count > initial-ant-health[
      create-ants 1
      [ set size 2         ;; easier to see
    set color (item k nest-colors)
    set state 0 ;; state 0 = foraging, 1 = carrying food, 2 = healing, 3 = returning-empty
    set num k   ;; colony number
    set age 0 ;; age
    setxy (item k nest-listx) (item k nest-listy)
    set health initial-ant-health
   ]
    set nest-reprod-count replace-item k nest-reprod-count (item k nest-reprod-count - initial-ant-health)
    ]
    set nest-reprod-count replace-item k nest-reprod-count (item k nest-reprod-count + (reprod-rate / 100) * (item k nest-health))
    set nest-health replace-item k nest-health ((item k nest-health) * (1 - reprod-rate / 100))

    set k k + 1
  ]

  ask turtles
  [
    if 2 * who >= (ticks + 2 * num * population) [ stop ] ;; delay initial departure



    ifelse state = 0
    [ look-for-food  ]       ;; not carrying food? look for it
    [ifelse state = 2
    [heal-up]
    [ return-to-nest ]       ;; go back to nest
    ]
    wiggle
    fd 1
    set health (health - metabolic-burn)
    set age age + 1
    ]


  ;ask blue_ants
  ;[ if who >= ticks [ stop ] ;; delay initial departure
   ; ifelse state = 0
   ; [ look-for-food  ]       ;; not carrying food? look for it
   ; [ return-to-nest ]       ;; carrying food? take it back to nest
   ; wiggle
   ; fd 1 ]


  ; big diffuse attempt here -- success
  let j 0
  while [j < number-ants][
    ask patches[set diff-active-chem (item j chemical)]

    diffuse diff-active-chem (diffusion-rate / 100)

    ask patches[set chemical replace-item j chemical diff-active-chem]

    set j j + 1
  ]





  ask patches
  [ ;set chemical chemical * (100 - evaporation-rate) / 100  ;; slowly evaporate chemical
    let i 0
        foreach chemical[
        [chem] ->
          set chemical replace-item i chemical (chem * (100 - evaporation-rate) / 100)
          set i i + 1
        ]
    recolor-patch ]

  ; try to get plot going here
  let string-temp ""
  let i 0
  while [i < number-ants][
    set string-temp insert-item i string-temp "1"
    set-current-plot "health-plot"
    create-temporary-plot-pen string-temp

    plot item i nest-health

    set i i + 1
  ]


  tick
end

to heal-up ;; turtle procedure
  ifelse nest_num = num
  [
  ifelse age > ant-lifespan [die] ; kill off if ant has outlived, killing here prevents death while busy

  [set health health + 1
  set nest-health replace-item num nest-health (item num nest-health - 1)
    if health > initial-ant-health [

        set state 0]
  ]][set state 3]
end

to return-to-nest  ;; turtle procedure
  ifelse nest_num = num
  [ ;; drop food and head out again
    if state = 1 [ set nest-health replace-item num nest-health (item num nest-health + food-worth)]
    set state 2 ; healing state
    setxy (item num nest-listx) (item num nest-listy) ;; recenter that fucker
    rt 180
  ]

  [
    if state = 1 [set chemical replace-item num chemical (item num chemical + chem-pungency)  ; drop some chemical change to be item + chem pungency
    ]

      uphill-nest-scent ]         ;; head toward the greatest value of nest-scent
end

to look-for-food ;; turtle procedure
  ifelse food > 0
  [ set state 1     ;; pick up food
    set food food - 1        ;; and reduce the food source
    rt 180                   ;; and turn around
    stop ][if health < 0.3 * initial-ant-health [set state 3]]

  ;; go in the direction where the chemical smell is strongest
  let antchem item num chemical
  if (antchem >= 0.05) and (antchem < 2)
  [ uphill-chemical ]
end

;; sniff left and right, and go where the strongest smell is
to uphill-chemical  ;; turtle procedure
  let scent-ahead chemical-scent-at-angle   0 num
  let scent-right chemical-scent-at-angle  45 num
  let scent-left  chemical-scent-at-angle -45 num
  if (scent-right > scent-ahead) or (scent-left > scent-ahead)
  [ ifelse scent-right > scent-left
    [ rt 45 ]
    [ lt 45 ] ]
end

;; sniff left and right, and go where the strongest smell is
to uphill-nest-scent  ;; turtle procedure
  let scent-ahead nest-scent-at-angle   0 num
  let scent-right nest-scent-at-angle  45 num
  let scent-left  nest-scent-at-angle -45 num
  if (scent-right > scent-ahead) or (scent-left > scent-ahead)
  [ ifelse scent-right > scent-left
    [ rt 45 ]
    [ lt 45 ] ]
end

to wiggle  ;; turtle procedure
  rt random 40
  lt random 40
  if not can-move? 1 [ rt 180 ]
end

to-report nest-scent-at-angle [angle ant-num]
  let p patch-right-and-ahead angle 1
  if p = nobody [ report 0 ]
  report [item ant-num nest-scent] of p
end

to-report chemical-scent-at-angle [angle ant-num]
  let p patch-right-and-ahead angle 1
  if p = nobody [ report 0 ]
  report [item ant-num chemical] of p
end


; Copyright 1997 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
526
14
1019
508
-1
-1
3.44
1
10
1
1
1
0
0
0
1
-70
70
-70
70
0
0
1
ticks
30.0

BUTTON
110
21
173
54
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
17
17
80
50
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
55
181
88
population
population
0
100
15.0
1
1
NIL
HORIZONTAL

SLIDER
319
11
491
44
Diffusion-Rate
Diffusion-Rate
0
10
2.0
1
1
NIL
HORIZONTAL

SLIDER
320
44
492
77
evaporation-rate
evaporation-rate
0
10
3.0
1
1
NIL
HORIZONTAL

SLIDER
9
89
181
122
number-ants
number-ants
1
10
3.0
1
1
NIL
HORIZONTAL

SLIDER
1044
44
1216
77
watch-num
watch-num
1
number-ants
1.0
1
1
NIL
HORIZONTAL

SLIDER
8
123
180
156
initial-nest-health
initial-nest-health
0
1000
100.0
50
1
NIL
HORIZONTAL

SLIDER
319
77
491
110
food-worth
food-worth
0
50
30.0
5
1
NIL
HORIZONTAL

PLOT
186
193
524
486
health-plot
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

SLIDER
9
156
181
189
initial-ant-health
initial-ant-health
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
319
110
491
143
metabolic-burn
metabolic-burn
0
0.1
0.03
0.01
1
NIL
HORIZONTAL

SLIDER
10
189
182
222
ant-lifespan
ant-lifespan
0
1000
500.0
50
1
NIL
HORIZONTAL

SLIDER
319
143
491
176
chem-pungency
chem-pungency
0
100
60.0
10
1
NIL
HORIZONTAL

SLIDER
10
224
182
257
reprod-rate
reprod-rate
0
1
0.5
.1
1
NIL
HORIZONTAL

PLOT
1025
122
1235
244
Ant populations
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"let string-temp \"\"\nlet i 0\nwhile [i < number-ants][\nset string-temp insert-item i string-temp \"1\"\n    create-temporary-plot-pen string-temp\n    set-plot-pen-color (item i nest-colors) \n    set-plot-pen-mode 0\nset i i + 1\n]" "let string-temp \"\"\nlet i 0\nwhile [i < number-ants][\nset string-temp insert-item i string-temp \"1\"\n    create-temporary-plot-pen string-temp\n    \n    plot count ants with[ num = i]\nset i i + 1\n]"
PENS

PLOT
1029
278
1229
428
nest-reprod-energy
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"let string-temp \"\"\nlet i 0\nwhile [i < number-ants][\nset string-temp insert-item i string-temp \"1\"\n    create-temporary-plot-pen string-temp\n    set-plot-pen-color (item i nest-colors) \n    set-plot-pen-mode 0\nset i i + 1\n]" "let string-temp \"\"\nlet i 0\nwhile [i < number-ants][\nset string-temp insert-item i string-temp \"1\"\n    create-temporary-plot-pen string-temp\n    \n    plot item i nest-reprod-count\nset i i + 1\n]"
PENS

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
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
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
