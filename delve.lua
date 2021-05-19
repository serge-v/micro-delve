VERSION = "1.0.2"

local micro = import("micro")
local config = import("micro/config")
local shell = import("micro/shell")
local buffer = import("micro/buffer")
local os = import("os")
local fmt = import("fmt")
local strings = import("strings")

micro.Log("dlv plugin started")

function init()
	config.MakeCommand("dlv", dlvCommand, config.NoComplete)
	config.MakeCommand("dlv-debug", runDebug, config.NoComplete)
	config.MakeCommand("dlv-test", runTest, config.NoComplete)
	config.MakeCommand("dlv-connect", runConnect, config.NoComplete)
	config.AddRuntimeFile("delve", config.RTHelp, "help/delve.md")

	config.TryBindKey("Shift-F5", "command:dlv-debug", false)
	config.TryBindKey("F5", "command:dlv next", false)
	config.TryBindKey("F6", "command:dlv step", false)
	config.TryBindKey("Shift-F6", "command:dlv stepout", false)
	config.TryBindKey("Alt-V", "command:dlv print {w}", false)
	config.TryBindKey("Alt-B", "command:dlv b {f}:{l}", false)
end

local debugger = nil

function dlvStderr(text, args)
	micro.Log("stderr:"..text)
	local bp = args[1]
	local cc = strings.SplitN(text, ": ", 2)
	if cc[1] == "error" then
		micro.InfoBar():Error(cc[2])
	end
end

local logPane = nil

function dlvStdout(text, args)
	micro.Log("stdout:"..text)
	local bp = args[1]
	local cc = strings.SplitN(text, ": ", 2)
	if cc[1] == "command" then
		bp:HandleCommand(cc[2])
		bp:Center()
	elseif cc[1] == "message" then
		micro.InfoBar():Message(cc[2])
	end
	logPane.Buf:ReOpen()
	logPane:Center()
end

function dlvExit(output, args)
	micro.Log("exit:"..output)
	micro.InfoBar():Error(output)
end

function startDelve(bp, args)
	if logPane ~= nil then
		logPane:Quit()
	end
	bp:HandleCommand("vsplit /tmp/delve-runner.log")
	logPane = micro.CurPane()
	micro.CurTab():SetActive(0)

	local path = os.Getenv("HOME").."/.config/micro/plug/delve/delve-runner.go"
	local cmdargs = {"run", path}
	for k,v in ipairs(args) do
		table.insert(cmdargs, v)
	end
	micro.InfoBar():Message("starting delve")
	micro.Log("starting go", cmdargs)
	debugger = shell.JobSpawn("go", cmdargs, dlvStdout, dlvStderr, dlvExit, bp)
end

function replacePlaceholders(bp, args)
	local c = bp.Cursor
	local cmd = ""
	cmd = strings.Join(args, " ")

	if strings.Contains(cmd, "{s}") then
		if c:HasSelection() then
			sel = c:GetSelection()
			cmd = strings.Replace(cmd, "{s}", sel, 1)
		end
	end

	if strings.Contains(cmd, "{w}") then
		local sel = ""
		if not c:HasSelection() then
			c:SelectWord()
		end
		sel = c:GetSelection()
		cmd = strings.Replace(cmd, "{w}", sel, 1)
	end
	
	cmd = strings.Replace(cmd, "{f}", c:Buf().AbsPath, 1)

	local loc = buffer.Loc(c.X, c.Y)
	local offs = buffer.ByteOffset(loc, c:Buf())
	cmd = strings.Replace(cmd, "{o}", tostring(offs), 1)
	cmd = strings.Replace(cmd, "{l}", tostring(c.Y+1), 1)

	return cmd
end

function dlvCommand(bp, args)
	if debugger == nil then
		micro.InfoBar():Error("dlv is not started")
		return
	end
	local cmd = replacePlaceholders(bp, args)
	micro.Log(cmd)
	micro.InfoBar():Message(cmd)
	shell.JobSend(debugger, cmd.."\n")
end

function runDebug(bp, args)
	startDelve(bp, {})
end

function runTest(bp, args)
	startDelve(bp, {"-test", args[1]})
end

function runConnect(bp, args)
	startDelve(bp, {"-connect"})
end

function onQuitAll(bp)
	if debugger ~= nil then
		shell.JobSend(debugger, "quit\n")
	end
end
