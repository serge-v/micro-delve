# micro-delve
Plugin for micro editor to integrate delve golang debugger. Plugin allows to step thru source code in the editor, set breakpoints, view variables.

## Installation

Press Ctrl+E and type command:

    plugin install micro-delve
 
## Dependencies
Install delve: https://github.com/go-delve/delve/blob/master/Documentation/installation/README.md


## Add key bindings

Example key bindings:

Start debugging, step over, step out, step in:

    "Shift-F5": "command: dlv-debug",
    "F5": "command: dlv next",
    "F6": "command: dlv step",
    "Shift-F6": "command: dlv stepout",

Set breakpoint on the current line (Alt-Shift-b):

    "Alt-B": "command: dlv b {f}:{l}",

Print variable under cursor (Alt-Shift-v):

    "Alt-V": "command: dlv print {w}",

## Using plugin
Currently you need 3 terminals to debug a program:

- Program under debugger
- Delve output
- Micro with debuggee source code

## Start program in debugger
In the new terminal go to the project directory and run dlv in headless mode:

    dlv --headless -l 127.0.0.1:8077 debug

## View debugger output

All commands output goes into /tmp/delve-runner.log file. Start in the new terminal:

    tail -f /tmp/delve-runner.log

## Connect micro to the debugger

Start micro.

Create startup file for delve (init.txt):

    b main.main
    continue
    
Hit Ctrl+E and type command to start debugging:

    dev-debug

Micro will connect to the headless delve (on 127.0.0.1:8077), will play init.txt startup file and should break on main function.

## Run any dlv command

From micro you can run any available dlv command using Ctrl+E.
Output will be written into /tmp/delve-runner.log file.

Command can have a placeholders which substitute upon execution:

    {w} -- current word
    {s} -- current selection
    {f} -- current file
    {l} -- current line




