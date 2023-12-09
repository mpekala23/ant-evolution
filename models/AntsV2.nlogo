extensions [ table ]

breed [ workers worker ]
breed [ scouts scout ]
breed [ queens queen ]
breed [ chunks chunk ]

globals [
  num-queens ;; how many queens are there right now?
  chemical-threshold ;; how small does a chemical need to be for us to set it to zero? (avoid floating point underflow)
  scent-id-count ;; unique id for each colony
  num-kills ;; how many kills have there been? for plotting/testing
]

workers-own
[
  energy ;; ~ health. Decreases every tick. 0 = death
  state ;; What is the ant doing right now?
  mother ;; Who birthed me? Useful for knowing when I'm home
  has-food ;; Am I carrying food right now?
]

scouts-own
[
  energy ;; ~ health. Decreases every tick. 0 = death
  state ;; what is the ant doing right now?
  mother ;; who birthed me? Useful for knowing when I'm home
]

queens-own
[
  energy ;; ~ health of the colony
  scent-id ;; unique string for the scent
  fight-prob ;; how likely are they to fight?
  coop-prob ;; if they don't fight, how likely are they to cooperate?
]

chunks-own
[
  cx ;; where is this chunk
  cy ;; where is this chunk
  supply ;; how much food is left in this chunk
  refresh-time ;; how many ticks left until this chunk refreshes
]

patches-own [
  food-chemicals ;;
  food ;; amount of food on this patch (0 or 1)
  chunk-x ;; x value of the chunk that this patch is a part of
  chunk-y ;; y value of the chunk that this patch is a part of
]

;;;;;;;;;;;;;;;;;;;;;;;;
;;; Parameters ;;;
;;; NOTE These are set in the editor, just documenting here for clarity ;;;
;;;;;;;;;;;;;;;;;;;;;;;;
;;; WORLD PARAMS ;;;
;;; initial-population = how many workers to start with
;;; nest-diffusion = [0-100] what percent of nest chemical should diffuse to neighbors at each step
;;; nest-evaporation = [0-100] what percent of the nest smell evaporates every tick
;;; chunk-size = how big should each chunk of food be
;;; chunk-refresh-threshold = how little food needs to be in a chunk to start refresh timer?
;;; chunk-refresh-time = how many ticks should a chunk wait before replenishing
;;;;;;;;;;;;;;;;;;;;;;;;
;;; ANT PARAMS ;;;
;;; home-dist-threshold = [0-10] how close does an ant need to be to home to deposit / grab food

;;;;;;;;;;;;;;;;;;;;;;;;
;;; Setup procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;;;

;; Helper function to obtain the chunk-x value of a patch
to-report get-chunk-x [#patch]
  let _dx [pxcor] of #patch - min-pxcor
  let _x int (_dx / chunk-size)
  report _x
end

;; Helper function to obtain the chunk-y value of a patch
to-report get-chunk-y [#patch]
  let _dy [pycor] of #patch - min-pycor
  let _y int (_dy / chunk-size)
  report _y
end

;; Puts the patches in the proper initial state
to setup-patches
  set chemical-threshold 0.0001
  ask patches
  [
    ;; Assign to the proper chunk
    set chunk-x get-chunk-x self
    set chunk-y get-chunk-y self
    set food-chemicals table:make
  ]
end

;; Initializes the chunks of food
to setup-chunks
  setup-patches
  let row 0
  let n-rows int ((max-pxcor - min-pxcor) / chunk-size)
  let n-cols int ((max-pycor - min-pycor) / chunk-size)
  while [row <= n-rows]
  [
    let col 0
    while [col <= n-cols]
    [
      let thingys patches with [(chunk-x = row) and (chunk-y = col)]
      create-chunks 1
      [
        set cx row
        set xcor min-pxcor + row * chunk-size
        set cy col
        set ycor min-pycor + col * chunk-size
        set supply 0
        set refresh-time random chunk-refresh-time
        set shape "box"
      ]
      set col col + 1
    ]
    set row row + 1
  ]
end

;; Initializes the queens
to setup-queens
  set num-queens initial-queens
  create-queens num-queens
  ask queens [
    set xcor random world-width
    set ycor random world-height
    set size 10
    set heading 0
    set energy 1000
    set scent-id scent-id-count
    set scent-id-count scent-id-count + 1
    set fight-prob random 10
    set coop-prob random 10
  ]
end

;; Handles spawning an ant for a queen
to spawn-baby
  let mycolor color
  ifelse random 100 > proportion-workers
  [
    hatch-scouts 1
    [
      set size 2
      set heading random 360
      set color red
      set energy scout-lifespan
      set state "explore"
      set mother myself
      set color mycolor
    ]
  ]
  [
    hatch-workers 1
    [
      set size 2
      set heading random 360
      set color red
      set energy worker-lifespan
      set state "patrol"
      set mother myself
      set color mycolor
    ]
  ]
end

;; Hatches scouts under each queen
to setup-scouts
  ask queens
  [
    let mycolor color
    hatch-scouts initial-ants * ((100 - proportion-workers) / 100)
    [
      set size 2
      set heading random 360
      set color red
      set energy random scout-lifespan
      set state "explore"
      set mother myself
      set color mycolor
    ]
  ]
end

;; Hatches workers under each queen
to setup-workers
  ask queens
  [
    let mycolor color
    hatch-workers initial-ants * ((proportion-workers) / 100)
    [
      set size 2
      set heading random 360
      set color red
      set energy random worker-lifespan
      set state "patrol"
      set mother myself
      set color mycolor
    ]
  ]
end

;; General setup
to setup
  set scent-id-count 0
  clear-all
  setup-chunks
  set-default-shape turtles "bug"
  setup-queens
  setup-scouts
  setup-workers
  reset-ticks
end

;;;;;;;;;;;;;;;;;;;;;;;;
;;; Helper functions ;;;
;;;;;;;;;;;;;;;;;;;;;;;;

;; Refills all the food in a given chunk
to refresh-chunk [chun]
  let _cx [cx] of chun
  let _cy [cy] of chun
  let pats patches with [(chunk-x = _cx) and (chunk-y = _cy)]
  ask pats
  [
    set food 1
  ]
  ask chun
  [
    set supply count pats
  ]
end

;; Handles eating a patch. Involves setting food = 0 and updating associated chunk
to eat-patch [p]
  let chun chunks with [(cx = [chunk-x] of p) and (cy = [chunk-y] of p)]
  ask chun
  [
    set supply supply - 1
  ]
  ask p
  [
    set food 0
  ]
end

;;;;;;;;;;;;;;;;;;;;;
;;; Go procedures ;;;
;;;;;;;;;;;;;;;;;;;;;

;; Rotates a little bit
to wiggle
  rt random 40
  lt random 40
  if not can-move? 1 [ rt 180 ]
end

;; Get the food scent for an id on a specific patch
to-report get-food-scent [sid p]
  let m [food-chemicals] of p
  report (table:get-or-default m sid 0)
end

;; Get the food scent at a specific angle
to-report food-scent-at-angle [sid angle]
  let p patch-right-and-ahead angle 1
  if p = nobody [ report 0 ]
  report get-food-scent sid p
end

;; Helper function for an ant to return home
to go-home
  face mother
  fd 1
end

;; Helper function for an ant to follow food scent
to go-food
  let sid [scent-id] of mother
  let scent-ahead food-scent-at-angle sid  0
  let scent-right food-scent-at-angle sid 30
  let scent-left  food-scent-at-angle sid -30
  if (scent-right > scent-ahead) or (scent-left > scent-ahead)
  [
    ifelse scent-right > scent-left
    [
      rt 30
    ]
    [
      lt 30
    ]
  ]
  fd 1
end

;; Update the scout state machine
to update-scout-state
  if state = "explore"
  [
    if food > 0
    [
      set state "recruit"
      rt 180
    ]
  ]
  if state = "recruit"
  [
    if distance mother < home-dist-threshold
    [
      set state "explore"
    ]
  ]
end

;; To start a fight
to start-fight [others]
  let my-fight-prob [fight-prob] of mother
  let my-coop-prob [coop-prob] of mother
  let ive-died false
  let matriarch mother
  ask others
  [
    if matriarch != mother
    [
      let i-fight random 100 < my-fight-prob
      ifelse i-fight
      [
        let other-fight-prob [fight-prob] of mother
        let other-fight random 100 < other-fight-prob
        ifelse other-fight
        [
          ;; Both ants fight
          ifelse random 2 = 1
          [
            ;; I live, other dies
            set num-kills num-kills + 1
            ask matriarch
            [
              set energy energy + fight-win-bonus
            ]
            die
          ]
          [
            ;; I die, other lives
            set ive-died true
            set num-kills num-kills + 1
            ask mother
            [
              set energy energy + fight-win-bonus
            ]
          ]
        ]
        [
          ;; I fight and they ignore
          set num-kills num-kills + 1
          ask matriarch
          [
            set energy energy + fight-win-bonus
          ]
          die
        ]
      ]
      [
        let i-coop random 100 < my-coop-prob
        if i-coop
        [
          let other-coop-prob [coop-prob] of mother
          let other-coop random 100 < other-coop-prob
          ifelse other-coop
          [
            ;; We both cooperate!
            ask mother
            [
              set energy energy + coop-both-bonus
            ]
            ask matriarch
            [
              set energy energy + coop-both-bonus
            ]
          ]
          [
            ;; I get scammed
            ask mother
            [
              set energy energy + coop-one-cost
            ]
            ask matriarch
            [
              set energy energy - coop-one-cost
            ]
          ]
        ]
      ]
    ]
  ]
  if ive-died
  [
    set num-kills num-kills + 1
    die
  ]
end

;; Fights what it needs to
to handle-fighting
  let other-scouts scouts-here
  let other-workers workers-here
  start-fight other-scouts
  start-fight other-workers

end

;; Performs a scout update
to update-scout
  ;; Behave according to state
  if state = "explore"
  [
    wiggle
    fd 1
  ]
  if state = "recruit"
  [
    go-home
    let mom-id [scent-id] of mother
    table:put food-chemicals mom-id 1
  ]
  ;; Update state
  update-scout-state
  ;; Look for fights/cooperation
  handle-fighting
  ;; Die if needed
  if energy < 0
  [
    die
  ]
  set energy energy - 1
end

;; Updates all the scouts
to update-scouts
  ask scouts
  [
    update-scout
  ]
end

to dropoff-food
  ask mother
  [
    set energy energy + 1
  ]
end

;; Updates the worker state
to update-worker-state
  let sid [scent-id] of mother
  let p patch-here
  let fval get-food-scent sid p
  if state = "patrol"
  [
    if fval > 0.4
    [
      ;; Food scent has to be strong to start searching
      set state "find"
      face mother
      rt 180
    ]
  ]
  if state = "find"
  [
    if fval < chemical-threshold
    [
      ;; Give up once the scent is very small
      set state "return"
    ]
    if food > 0
    [
      eat-patch patch-here
      set has-food true
      set state "return"
    ]
  ]
  if state = "return"
  [
    if distance mother < home-dist-threshold
    [
      set state "patrol"
      set has-food false
      dropoff-food
    ]
    if has-food = true
    [
      table:put food-chemicals sid 1
    ]
  ]
end

;; Performs a worker update
to update-worker
  ;; Behave according to state
  if state = "patrol"
  [
    ifelse distance mother > 10
    [
      face mother
    ]
    [
      wiggle
    ]
    fd 1
  ]
  if state = "find"
  [
    go-food
  ]
  if state = "return"
  [
    go-home
  ]
  ;; Update state
  update-worker-state
  ;; Do fights/coops
  handle-fighting
  ;; Die if needed
  if energy < 0
  [
    die
  ]
  set energy energy - 1
end

;; Updates all of the worker ants calling the appropriate action and state update
to update-workers
  ask workers
  [
    update-worker
  ]
end

to queen-death
  let matriarch self
  ask scouts
  [
    if mother = matriarch
    [
      die
    ]
  ]
  ask workers
  [
    if mother = matriarch
    [
      die
    ]
  ]
  die
end

;; Spawns a new colony by splitting this one
to split-colony
  set energy energy - 1000
  let new-x random world-width
  let new-y random world-height
  let dist distancexy new-x new-y
  while [dist > split-distance]
  [
    set new-x random world-width
    set new-y random world-height
    set dist distancexy new-x new-y
  ]
  let mycolor color
  let agg-diff (random 10) - 5
  let nice-diff (random 10) - 5
  let new-fight-prob fight-prob + agg-diff
  let new-coop-prob coop-prob + nice-diff
  hatch-queens 1 [
    set xcor new-x
    set ycor new-y
    set size 10
    set heading 0
    set energy 1000
    set scent-id scent-id-count
    set scent-id-count scent-id-count + 1
    set fight-prob new-fight-prob
    set coop-prob new-coop-prob
    repeat 100 [ spawn-baby ]
  ]
  ;; Kill 1/4 of the kids
  let matriarch self
  ask scouts
  [
    if mother = matriarch and random 3 = 1
    [
      die
    ]
  ]
  ask workers
  [
    if mother = matriarch and random 3 = 1
    [
      die
    ]
  ]
end

;; Updates the queen (refresh nest chemical)
to update-queens
  ask queens
  [
    if energy < 0
    [
      queen-death
    ]
    if energy > random birth-threshold
    [
      spawn-baby
      set energy energy - birth-cost
    ]
    if energy > split-threshold
    [
      split-colony
    ]
    set energy energy - 1
  ]
end

to custom-evaporation
  foreach ( table:keys food-chemicals ) [ [key] ->
    let existing table:get-or-default food-chemicals key 0
    ifelse existing > chemical-threshold
    [
      table:put food-chemicals key existing * (100 - food-evaporation) / 100
    ]
    [
      table:remove food-chemicals key
    ]
  ]
end

;; Specifically handles diffusion and evaporation of each frame
to update-scents
  ask patches
  [
    custom-evaporation
  ]
end

;; Handles updating the patch color each frame
to update-patch-color
  ifelse food > 0
  [
    set pcolor blue
  ]
  [
    ifelse show-trails
    [
      let maxval 0
      foreach ( table:values food-chemicals ) [ [val] ->
        if val > maxval
        [
          set maxval val
        ]
      ]
      set pcolor scale-color yellow maxval chemical-threshold 1
    ]
    [
      set pcolor black
    ]
  ]
end

;; Keep the patch color consistent with its state
to update-patches
  update-scents
  ask patches
  [
    update-patch-color
  ]
end

;; Update the chunks
to update-chunks
  ask chunks
  [
    ifelse refresh-time < 0
    [
      ;; refresh-time < 0 -> this chunk had enough food last frame, see if that's still true
      if supply < chunk-refresh-threshold
      [
        set refresh-time chunk-refresh-time
      ]
    ]
    [
      ifelse refresh-time > 0
      [
        ;; refresh-time > 0 -> we're waiting to refresh this chunk
        set refresh-time refresh-time - 1
      ]
      [
        ;; refresh-time = 0 -> it's time to refresh this chunk
        set refresh-time -1
        refresh-chunk self
      ]
    ]
  ]
end

to go  ;; forever button
  update-workers
  update-scouts
  update-queens
  update-chunks
  update-patches
  plot-queen-energy
  plot-ant-count
  plot-average-aggresiveness
  tick
end

;;;;;;;;;;;;;;;;;;;;;;
;;;; PLOT SECTION ;;;;
;;;;;;;;;;;;;;;;;;;;;;

to plot-queen-energy
  set-current-plot "nest-energies"
  ask queens [
    create-temporary-plot-pen (word who)
    set-plot-pen-color color
    plotxy ticks energy
  ]
end

to plot-ant-count
  set-current-plot "num-ants"
  ask queens [
    let me self
    let num-workers count workers with [mother = me]
    let num-scouts count scouts with [mother = me]
    create-temporary-plot-pen (word who)
    set-plot-pen-color color
    plotxy ticks num-workers + num-scouts
  ]
end

to plot-average-aggresiveness
  set-current-plot "avg-agg"
  let agg-total 0
  ask queens [
    set agg-total agg-total + fight-prob
  ]
  create-temporary-plot-pen "data"
  set-plot-pen-color black
  plotxy ticks agg-total / (count queens)
end

to-report test
  report 4
end
@#$#@#$#@
GRAPHICS-WINDOW
244
272
766
795
-1
-1
2.0
1
10
1
1
1
0
1
1
1
-128
128
-128
128
1
1
1
ticks
30.0

SLIDER
16
337
194
370
proportion-workers
proportion-workers
0
100
75.0
1
1
NIL
HORIZONTAL

SLIDER
24
47
197
80
nest-diffusion
nest-diffusion
0
100
36.0
1
1
NIL
HORIZONTAL

SLIDER
24
94
197
127
nest-evaporation
nest-evaporation
0
100
4.0
1
1
NIL
HORIZONTAL

BUTTON
344
220
411
254
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

BUTTON
417
217
481
251
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

SLIDER
16
288
204
321
home-dist-threshold
home-dist-threshold
0
10
2.4
0.1
1
NIL
HORIZONTAL

TEXTBOX
32
14
194
59
Chemical Params
18
0.0
1

TEXTBOX
18
256
168
278
Ant Params
18
0.0
1

SLIDER
254
163
426
196
chunk-size
chunk-size
10
100
25.0
5
1
NIL
HORIZONTAL

SLIDER
255
67
465
100
chunk-refresh-threshold
chunk-refresh-threshold
0
1000
125.0
50
1
NIL
HORIZONTAL

SLIDER
256
120
449
153
chunk-refresh-time
chunk-refresh-time
0
10000
2700.0
100
1
NIL
HORIZONTAL

TEXTBOX
257
31
407
91
Chunk Params
18
0.0
1

SLIDER
20
145
192
178
food-diffusion
food-diffusion
0
100
4.0
1
1
NIL
HORIZONTAL

SLIDER
21
193
193
226
food-evaporation
food-evaporation
0
100
3.0
1
1
NIL
HORIZONTAL

SLIDER
17
431
189
464
initial-queens
initial-queens
0
10
5.0
1
1
NIL
HORIZONTAL

SLIDER
18
478
191
511
scout-lifespan
scout-lifespan
0
1000
576.0
1
1
NIL
HORIZONTAL

SLIDER
17
527
190
560
worker-lifespan
worker-lifespan
0
1000
576.0
1
1
NIL
HORIZONTAL

PLOT
798
245
998
395
nest-energies
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
18
576
190
609
initial-nest-energy
initial-nest-energy
0
3000
1000.0
100
1
NIL
HORIZONTAL

SLIDER
19
623
191
656
food-value
food-value
0
10
8.0
1
1
NIL
HORIZONTAL

SLIDER
19
668
191
701
birth-threshold
birth-threshold
0
2000
1000.0
100
1
NIL
HORIZONTAL

SLIDER
18
711
190
744
birth-cost
birth-cost
0
20
4.0
1
1
NIL
HORIZONTAL

PLOT
799
418
999
568
num-ants
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

SWITCH
509
217
636
250
show-trails
show-trails
1
1
-1000

SLIDER
14
380
186
413
initial-ants
initial-ants
0
500
240.0
20
1
NIL
HORIZONTAL

SLIDER
20
755
192
788
split-threshold
split-threshold
0
5000
2000.0
100
1
NIL
HORIZONTAL

SLIDER
19
799
191
832
split-distance
split-distance
0
100
65.0
5
1
NIL
HORIZONTAL

PLOT
795
586
995
736
num-kills
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
"default" 1.0 0 -16777216 true "" "plot num-kills"

PLOT
802
746
1002
896
avg-agg
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
20
854
193
887
fight-win-bonus
fight-win-bonus
0
10
3.0
1
1
NIL
HORIZONTAL

SLIDER
217
863
390
896
coop-both-bonus
coop-both-bonus
0
10
2.0
1
1
NIL
HORIZONTAL

SLIDER
412
864
585
897
coop-one-cost
coop-one-cost
0
10
1.0
1
1
NIL
HORIZONTAL

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
NetLogo 6.0.4
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
