# Usage:
# awk -f txtdtracker.awk score.txt


# FUNCTIONS

function print_to_screen(instring) {
  if (prnt == "0") { # do nothing
    } else if (prnt == "s") { # show shell commands
    print instring
  } else if (prnt == "n") { # show notes 
  print $0
} else if (prnt == "l") { # show linenumbers
print NR "  " $0
}
}


function rnd(instring) {
  # in: 0-1 returns random integer in range 0-1
  # in: 0-1.0 returns random float in range 0-1

  instring = substr(instring, 1, length(instring) )

  split(instring,array,"-")
  min = array[1]
  max = array[2]


  if (index(instring, ".") > 0 ) { # float is true
    return (min+rand()*(max-min+1))
  } else { # integer is true
  return int(min+rand()*(max-min+1))
}
}

# parse and process random numbers in a string
# formatted like this: ^0-2.5^
function process_rnd_nrs(instring) {
  outstring = ""
  rndmode = 0
  rndstring = ""
  randomnr = ""

  for (i = 1; i<=(length(instring)); i++) {
    character = substr(instring, i , 1)
    if (rndmode == 1 && character == "^") {
      randomnr = rnd(rndstring)
      outstring = outstring randomnr
      rndmode = 0
      rndstring = ""
      randomnr = ""
    } else if (rndmode == 1 && character != "^") {
    rndstring = rndstring character
  } else if (rndmode == 0 && character == "^") {
  # start rndmode
  rndmode = 1
} else {
outstring = outstring character
}
} 
return outstring
}


# parse and replace variable names with their value
# the variables are formatted like this: %variablename
function process_variables(instring) {
  outstring = ""
  varmode = 0
  varstring = ""
  value = ""

  for (i = 1; i<=(length(instring)); i++) {
    character = substr(instring, i , 1)
    if (varmode == 1 && character == " ") {
      value = var_array[varstring]
      outstring = outstring value " "
      varmode = 0
      varstring = ""
      value = ""
    } else if (varmode == 1 && character != " ") {
    varstring = varstring character
  } else if (varmode == 0 && character == "%") {
  # start varmode
  varmode = 1
} else {
outstring = outstring character
}
} 
return outstring
}


# choose random a value from a comma separated list
function choose_random(cs_string) {
  split(cs_string,a,",")
  l = length(a)+1
  random_index = rnd(l)
  return a[random_index]
}


# sub function for diff_in_cents()
function midinr(notestring) {
  notenr["C"]  = 0
  notenr["C#"] = 1
  notenr["D"]  = 2
  notenr["D#"] = 3
  notenr["E"]  = 4
  notenr["F"]  = 5
  notenr["F#"] = 6
  notenr["G"]  = 7
  notenr["G#"] = 8
  notenr["A"]  = 9
  notenr["A#"] = 10
  notenr["B"]  = 11

  octave = substr(notestring,length(notestring),1)
  note = substr(notestring, 1, length(notestring)-1)
  nr = (octave * 12) + 12 + notenr[note]
  return nr
}


function diff_in_cents(notestr_a, notestr_b) {
  midinr(notestr_a)
  midinr(notestr_b)
  return (midinr(notestr_b) - midinr(notestr_a)) * 100
}


function calculate_xposition() {
  if (xposition = "m") { # mid -- sounds human
    beforetime = steptime/2
    aftertime = steptime/2

  } else if (xposition == "s") { # start
  beforetime = 0
  aftertime = steptime
}
}

BEGIN {

  split("", macro_array)
  split("", var_array)

  # sample vars
  pathseperator = "/"
  sample = ""
  sampleplaymethod = "pitch"
  originalpitch = "C4"
  samplefxstring = ""

  # default seed
  seed = 19345
  srand(seed)

  # default synth
  synthname = "pluck "
  # override by arg
  if (s != "") {
    synthname = s
  }

  # default steptime in seconds
  steptime = 0.5
  # override by arg
  if (t != "") {
    steptime = t
  }

  # default notelength in seconds
  notelength = 0.5
  # override by arg
  if (n != "") {
    notelength = n
  }

  # default sox effect part
  effect = "lowpass 900"
  # override by arg
  if (e != "") {
    effect = e
  }

  # default print to screen 
  # 0 = nothing, s = shell commands, n = notes, l = linenumbers
  prnt = "n"
  # override by arg
  if (p != "") {
    prnt = p
  }

  # default execute position inside step
  xposition = "m"
  # override by arg
  if (x != "") {
    xposition = x
  }
}


# PROCESS SCORE-FILE

# change sox effect: e effectstring
$1 ~ /^e$/ {
  effect = substr($0,2)
  next
}

# change steptime: t number
$1 ~ /^t$/ {
  steptime = process_rnd_nrs($2)
  next 
}

# change notelength: n number
$1 ~ /^n$/ {
  notelength = process_rnd_nrs($2)
  next 
}

# change synth: s synthname
$1 ~ /^s$/ {
  synthname = substr($0,2) " "
  next
}

# change print to screen
$1 ~ /^p$/ {
  prnt = $2
  next
}

# sleep empty line
/^$/ {
  print_to_screen("sleep " steptime)
  system("sleep " steptime);
  next
} 

# change xposition: x s or x m
$1 ~ /^x$/ {
  xposition = $2
  next
}

# comment not printed to screen
/^\-.*$/ {
  next
}

# change seed for randomization
$1 ~ /^d$/ {
  seed = $2
  print_to_screen("# seed " seed)
  srand(seed)
  next
}

# play a random note from a list TODO execution position
# A,C#,D,E,E

/^ *[ABCDEFG]#?[0-9]?,.+$/ {
  gsub(/[ ]+/, "",$0) # remove spaces

  random_note = choose_random($0)

  # construct sox play command 
  playstring = "sleep " steptime/2 "; ( play -n -q synth " notelength " "
  playstring = playstring synthname random_note " "

  #process random nrs in effect part
  parsed_effect = process_rnd_nrs(effect)

  playstring = playstring parsed_effect " ) & sleep " steptime/2

  print_to_screen(playstring)
  system(playstring)
  next
}

# play notes
/^ *[ABCDEFG][ 0-9#].*$/ {

  calculate_xposition()

  #if (xposition = "m") { # human
    #beforetime = steptime/2
    #aftertime = steptime/2

  #} else if (xposition == "s") { # machine
  #beforetime = 0
  #aftertime = steptime
#}

# construct sox play command
playstring = "sleep " beforetime "; ( play -n -q synth " notelength " "

for (t = 1; t <= NF; t++) {
  playstring = playstring synthname $t " "
}

#process random nrs in effect part
parsed_effect = process_rnd_nrs(effect)
playstring = playstring parsed_effect " ) & sleep " aftertime
print_to_screen(playstring)
system(playstring)
next
}

# define shell variable
/^%[^ ]+ {1,}[^ ]+/ {
  key = substr($1,2)
  var_array[key] = $2
  next
}

# define shell macro
/^\.[^ ]+ {1,}[^ ]+/ {
  key = substr($1,2)
  $1=""
  macro_array[key] = $0
  next
}

# execute shell macro TODO execute even with trailing spaces
/^\.[^ ]+$/ {
  search_key = substr($1,2)
  mstring = macro_array[search_key]
  comm = process_rnd_nrs(mstring)
  comm = process_variables(comm)
  print_to_screen(comm)
  system(comm)
  next
}

# samples
/^:/ {
  # samples must have their own directory for this to work
  if (match($1, pathseperator) != 0) { # get samplepath
    sample = substr($1, 2) # remove :
    originalpitch = $2
    sampleplaymethod = $3

  } else if ($1 ~ /^:[ABCDEFG][ 0-9#]/) { # play notes
  calculate_xposition()
  $1 = substr($1, 2)

  for (si = 1; si <= NF; si++) {
    cents = diff_in_cents(originalpitch, $si)
    if (sampleplaymethod == "speed") {
      cents = cents"c"
    }
    # construct sample play command
    sampleplaystring = "sleep " beforetime "; ( play -q  " sample " "
    parsed_effect = process_rnd_nrs(samplefxstring)
    sampleplaystring = sampleplaystring parsed_effect " " sampleplaymethod " " cents " ) & sleep " aftertime
    print_to_screen(sampleplaystring)
    system(sampleplaystring)
  } 
} else { # get effectstring 
samplefxstring = substr($0, 2)
  }
  next
}

# stop execution
/^halt$/ {
  exit
}


# shell command
# any line without a match is send to the shell
{
  comm = process_rnd_nrs($0)
  comm = process_variables(comm)
  print_to_screen(comm)
  system(comm)
}

