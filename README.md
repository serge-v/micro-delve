# micro-delve
Plugin for micro editor to integrate delve golang debugger.
Plugin allows to step thru source code in the editor, set breakpoints, view variables.

## Installation

Press Ctrl+E and type command:

    plugin install delve
 
## Dependencies
Install delve: https://github.com/go-delve/delve/blob/master/Documentation/installation/README.md


## Edit key bindings

Default key bindings:

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

Create init.txt file in your project:

    breakpoint main.main
    continue

Run one of the following commands to start debugging:

    dlv-debug      -- start 'dlv debug'
    dlv-test REGEX -- start 'dlv test -- -test.run REGEX'
    dlv-connect    -- connect to headless dlv instance

## Start headless dlv instance
In the new terminal go to the project directory and run:

    dlv --headless -l 127.0.0.1:8077 debug

## Run dlv command

You can run any dlv command in micro prompt.

Command can have a placeholders which substitute upon execution:

    {w} -- current word
    {s} -- current selection
    {f} -- current file
    {l} -- current line
