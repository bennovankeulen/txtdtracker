# Txtdtracker
Txtdtracker is an AWK-script with many hats. It can be:
* a simple score player
* a SoX/shell preprocessor (tested with Bash)
* a music programming language interpreter, with SoX and shell syntax
* a one channel tracker


## Installation
Clone the repository or download the zip and set the script to be executable:

https://github.com/bennovankeulen/txtdtracker.git  
chmod +x txtdtracker.awk

## Dependencies
SoX  
(G)AWK (Everything works fine in traditional AWK except shell macros and shell variables).  
GNU sleep (type 'sleep 0.5' into the terminal to check if you can use floats). 


## Usage
Create a text file in the scores directory with some music notes:

```
E1
E1 G2 B3 C#4

G1
```

#### Play the file
```
awk -f txtdtracker.awk scores/name-of-your-file.txt
```

Txtdracker will play all lines in the file, from top to bottom, with the pluck synth of SoX and a default tempo of 120 bpm.  
Multiple notes on a line form a chord and every line is considered one step. An empty line is a silent step. 

By adding commands you can alter the sound.


```
E1
s sawtooth
E1 G2 B3 C#4

s sine
G1
```

This will play the chord with a sawtooth synth and the last note with a sine synth.



## Commands
Command  | Value or explanation
-------- | --------------------
s        | synth [sine square triangle sawtooth trapezium exp pluck]
t        | steptime in seconds
n        | note length in seconds
e        | SoX effects string
p        | print to screen [0 nothing, s shell commands, n notes, l linenumbers and notes]
x        | execute position in step [s]tart or [m]id
d        | seed for random commands
A1,C#,B  | play random note from list
^0-1.0^  | range for a random number
.m       | shell macro
%var     | shell variable
halt     | stop execution
\- this is a comment


The demo song contains all txtdtracker commands.
```
awk -f txtdtracker.awk scores/demo.txt
```


## Arguments
Example with arguments  
```
awk -f txtdtracker.awk -v t=2.5 -v e="lowpass 400 channels 2 reverb 90" -v p="n" scores/name-of-your-textfile.txt
```

t=steptime  
e=effectstring  
p=print to screen  
s=synth  
n=notelength  
x=execute position  


## License
This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

 You should have received a copy of the GNU General Public License along with this program.  If not, see [www.gnu.org/licenses](https://www.gnu.org/licenses).


