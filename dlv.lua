VERSION = "1.0.0"

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
	config.MakeCommand("dlv-debug", startDebugging, config.NoComplete)
end

local debugger = nil

function dlvStderr(err, args)
	micro.Log("stderr:"..err)
end

function dlvStdout(text, args)
	micro.Log("stdout:"..text)
	local bp = args[1]
	local cc = strings.SplitN(text, ": ", 2)
	if cc[1] == "command" then
		bp:HandleCommand(cc[2])
		bp:HandleCommand("center")
	elseif cc[1] == "message" then
		micro.InfoBar():Message(cc[2])
	end
end

function dlvExit(output, args)
	micro.Log("exit:"..output)
end

function startDebugging(bp, args)
	local path = os.Getenv("HOME").."/.config/micro/plug/dlv/delve-runner.go"
	local cmdargs = {"run", path}
	micro.InfoBar():Message("starting delve")
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

function onQuitAll(bp)
	if debugger ~= nil then
		shell.JobSend(debugger, "quit\n")
	end
end
