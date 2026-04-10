
local kConfigFileName = "UnrealNvim.json"
local kCurrentVersion = "0.0.2"

local kLogLevel_Error = 1
local kLogLevel_Warning = 2
local kLogLevel_Log = 3
local kLogLevel_Verbose = 4
local kLogLevel_VeryVerbose = 5

local TaskState =
{
    scheduled = "scheduled",
    inprogress = "inprogress",
    completed = "completed"
}

-- fix false diagnostic about vim
if not vim then
    vim = {}
end


local logFilePath = vim.fn.stdpath("data") .. '/unrealnvim.log'

local function logWithVerbosity(verbosity, message)
    if not vim.g.unrealnvim_debug then return end
    local cfgVerbosity = kLogLevel_Log
    if vim.g.unrealnvim_loglevel then
        cfgVerbosity = vim.g.unrealnvim_loglevel
    end
    if verbosity > cfgVerbosity then return end

    local file = nil
    if Commands.logFile then
        file = Commands.logFile
    else
        file = io.open(logFilePath, "a")
    end

    if file then
        local time = os.date('%m/%d/%y %H:%M:%S');
        file:write("["..time .. "]["..verbosity.."]: " .. message .. '\n')
    end
end

local function log(message)
    if not message then
        logWithVerbosity(kLogLevel_Error, "message was nill")
        return
    end

    logWithVerbosity(kLogLevel_Log, message)
end

local function logError(message)
    logWithVerbosity(kLogLevel_Error, message)
end

local function PrintAndLogMessage(a,b)
    if a and b then
        log(tostring(a)..tostring(b))
    elseif a then
        log(tostring(a))
    end
end

local function PrintAndLogError(a,b)
    if a and b then
        local msg = "Error: "..tostring(a)..tostring(b)
        print(msg)
        log(msg)
    elseif a then
        local msg = "Error: ".. tostring(a)
        print(msg)
        log(msg)
    end
end

local function MakeUnixPath(win_path)
    if not win_path then
        logError("MakeUnixPath received a nil argument")
        return;
    end
    -- Convert backslashes to forward slashes
    local unix_path = win_path:gsub("\\", "/")

    -- Remove duplicate slashes
    unix_path = unix_path:gsub("//+", "/")

    return unix_path
end

local function FuncBind(func, data)
    return function()
        func(data)
    end
end

if not vim.g.unrealnvim_loaded then
    Commands = {}

    CurrentGenData =
    {
        config = {},
        target = nil,
        prjName = nil, 
        targetNameSuffix = nil,
        prjDir = nil,
        tasks = {},
        currentTask = "",
        ubtPath = "",
        ueBuildBat = "",
        projectPath = "",
        logFile = nil
    }
    -- clear the log
    CurrentGenData.logFile = io.open(logFilePath, "w")

    if CurrentGenData.logFile then
        CurrentGenData.logFile:write("")
        CurrentGenData.logFile:close()

        CurrentGenData.logFile = io.open(logFilePath, "a")
    end
    vim.g.unrealnvim_loaded = true
end

Commands.LogLevel_Error = kLogLevel_Error
Commands.LogLevel_Warning = kLogLevel_Warning
Commands.LogLevel_Log = kLogLevel_Log
Commands.LogLevel_Verbose = kLogLevel_Verbose
Commands.LogLevel_VeryVerbose = kLogLevel_VeryVerbose

function Commands.Log(msg)
    if not msg then
        logWithVerbosity(kLogLevel_Error, "message was nill")
        return
    end
    print(msg)
    logWithVerbosity(kLogLevel_Log, msg)
end


Commands.onStatusUpdate = function()
end

function Commands:Inspect(objToInspect)
    if not vim.g.unrealnvim_debug then return end
    if not objToInspect then
        log(objToInspect)
        return
    end

    if not self._inspect then
        local inspect_path = vim.fn.stdpath("data") .. "/site/pack/packer/start/inspect.lua/inspect.lua"
        self._inspect = loadfile(inspect_path)(Commands._inspect)
        if  self._inspect then
            log("Inspect loaded.")
        else
            logError("Inspect failed to load from path" .. inspect_path)
        end
        if self._inspect.inspect then
            log("inspect method exists")
        else
            logError("inspect method doesn't exist")
        end
    end
    return self._inspect.inspect(objToInspect)
end

function SplitString(str)
    -- Split a string into lines
    local lines = {}
    for line in string.gmatch(str, "[^\r\n]+") do
        table.insert(lines, line)
    end
    return lines
end

function Commands._CreateConfigFile(configFilePath, projectName)
        local platformName = "Win64"
    if Commands.IsMac() then
        platformName = "Mac"
    end
    local configContents = [[
{
    "version" : "0.0.2",
    "_comment": "dont forget to escape backslashes in EnginePath",    
    "EngineDir": "",
    "Targets":  [

        {
            "TargetName" : "]] .. projectName .. [[-Editor",
            "Configuration" : "DebugGame",
            "withEditor" : true,
            "UbtExtraFlags" : "",
            "PlatformName" : "]].. platformName ..[["
        },
        {
            "TargetName" : "]] .. projectName .. [[",
            "Configuration" : "DebugGame",
            "withEditor" : false,
            "UbtExtraFlags" : "",
            "PlatformName" : "]].. platformName ..[["
        },
        {
            "TargetName" : "]] .. projectName .. [[-Editor",
            "Configuration" : "Development",
            "withEditor" : true,
            "UbtExtraFlags" : "",
            "PlatformName" : "]].. platformName ..[["
        },
        {
            "TargetName" : "]] .. projectName .. [[",
            "Configuration" : "Development",
            "withEditor" : false,
            "UbtExtraFlags" : "",
            "PlatformName" : "]].. platformName ..[["
        },
        {
            "TargetName" : "]] .. projectName .. [[-Editor",
            "Configuration" : "Shipping",
            "withEditor" : true,
            "UbtExtraFlags" : "",
            "PlatformName" : "]].. platformName ..[["
        },
        {
            "TargetName" : "]] .. projectName .. [[",
            "Configuration" : "Shipping",
            "withEditor" : false,
            "UbtExtraFlags" : "",
            "PlatformName" : "]].. platformName ..[["
        }
    ]
}
    ]]
    -- local file = io.open(configFilePath, "w")
    -- file:write(configContents)
    -- file:close()
    Commands.Log("Please populate the configuration for the Unreal project, especially EnginePath, the path to the Unreal Engine")
    -- local buf = vim.api.nvim_create_buf(false, true)
    vim.cmd('new ' .. configFilePath)
    vim.cmd('setlocal buftype=')
    -- vim.api.nvim_buf_set_name(0, configFilePath)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, SplitString(configContents))
    -- vim.api.nvim_open_win(buf, true, {relative="win", height=20, width=80, row=1, col=0})
end

function Commands._EnsureConfigFile(projectRootDir, projectName)
    local configFilePath = projectRootDir.."/".. kConfigFileName
    local configFile = io.open(configFilePath, "r")


    if (not configFile) then
        Commands._CreateConfigFile(configFilePath, projectName)
        Commands.Log("created config file")
        return nil
    end

    local content = configFile:read("*all")
    configFile:close()

    local data = vim.fn.json_decode(content)
    Commands:Inspect(data)
    if data and (data.version ~= kCurrentVersion) then
        PrintAndLogError("Your " .. configFilePath .. " format is incompatible. Please back up this file somewhere and then delete this one, you will be asked to create a new one") 
        data = nil
    end

    if data then
        data.EngineDir = MakeUnixPath(data.EngineDir)
    end

    return data
end

function Commands._GetDefaultProjectNameAndDir(filepath)
    local uprojectPath, projectDir
    projectDir, uprojectPath = Commands._find_file_with_extension(filepath, "uproject")
    if not uprojectPath then
        Commands.Log("Failed to determine project name, could not find the root of the project that contains the .uproject")
        return nil, nil
    end
    local projectName = vim.fn.fnamemodify(uprojectPath, ":t:r")
    return projectName, projectDir
end
function Commands.IsMac()
    return vim.loop.os_uname().sysname == "Darwin"
end

function Commands.IsWindows()
    return vim.loop.os_uname().sysname == "Windows_NT"
end

function Commands.GetPlatformName()
    if Commands.IsMac() then
        return "Mac"
    else
        return "Win64"
    end
end

function Commands.GetEditorName()
    if Commands.IsMac() then
        return "UnrealEditor"
    else
        return "UnrealEditor"
    end
end

function Commands.GetExecutableFileExtension()
    if Commands.IsMac() then
        return ""
    else
        return ".exe"
    end
end



local CurrentCompileCommandsTargetFilePath = ""
function CurrentGenData:GetTaskAndStatus()
    if not self or not self.currentTask or self.currentTask == "" then
        return "[No Task]"
    end
    local status = self:GetTaskStatus(self.currentTask)
    return self.currentTask.."->".. status
end


function CurrentGenData:GetTaskStatus(taskName)
    local status = self.tasks[taskName]

    if not status then
       status = "none"
    end
    return status
end

function CurrentGenData:SetTaskStatus(taskName, newStatus)
    if (self.currentTask ~= "" and self.currentTask ~= taskName) and (self:GetTaskStatus(self.currentTask) ~= TaskState.completed) then
        Commands.Log("Cannot start a new task. Current task still in progress " .. self.currentTask)
        PrintAndLogError("Cannot start a new task. Current task still in progress " .. self.currentTask)
        return
    end
    Commands.Log("SetTaskStatus: " .. taskName .. "->" .. newStatus)
    self.currentTask = taskName
    self.tasks[taskName] = newStatus
end

function CurrentGenData:ClearTasks()
    self.tasks = {}
    self.currentTask = ""
end

local function file_exists(name)
   local f = io.open(name, "r")
   if f then
      io.close(f)
      return true
   end

   return false
end

function ExtractRSP(rsppath)
    rsppath = MakeUnixPath(rsppath)
    Commands.Log("Extracting from RSP: " .. rsppath)

    if not file_exists(rsppath) then
       Commands.Log("RSP file does not exist: " .. rsppath)
       return nil
    end

    local lines = {}

    if Commands.IsMac() then
        for line in io.lines(rsppath) do
            table.insert(lines, line)
        end
        return table.concat(lines, "\n")
    end

    local extraFlags = "-std=c++20 -Wno-deprecated-enum-enum-conversion -Wno-deprecated-anon-enum-enum-conversion -ferror-limit=0 -Wno-inconsistent-missing-override"
    local extraIncludes = {
        "Engine/Source/Runtime/CoreUObject/Public/UObject/ObjectMacros.h",
        "Engine/Source/Runtime/Core/Public/Misc/EnumRange.h"
    }
    
    -- First line in UE response files is the source file, which we don't want here.
    local isFirstLine = true 

    for line in io.lines(rsppath) do
        if not isFirstLine then
            -- Remove quotes surrounding the line
            line = line:gsub('^"', ''):gsub('"$', '')
            
            -- Translate Windows-style flags to clang-style
            if line:find("^/I") then
                -- Convert /I "path" to -I"path"
                line = line:gsub("^/I(.*)", "-I%1")
                table.insert(lines, line)
            elseif line:find("^/FI") then
                -- Convert /FI "path" to -include "path"
                line = line:gsub("^/FI(.*)", "-include%1")
                table.insert(lines, line)
            elseif line:find("^-W") then
                -- Keep existing warning flags
                table.insert(lines, line)
            end
            -- Other flags like /D (defines) are ignored for now, but could be added.
        end
        isFirstLine = false
    end

    for _, incl in ipairs(extraIncludes) do
        table.insert(lines, "-include \"" .. CurrentGenData.config.EngineDir .. "/" .. incl .. "\"")
    end
    table.insert(lines, extraFlags)
    
    return table.concat(lines, "\n")
end

function CreateCommandLine()
end

function EscapePath(path)
    -- path = path:gsub("\\", "\\\\")
    path = path:gsub("\\\\", "/")
    path = path:gsub("\\", "/")
    path = path:gsub("\"", "\\\"")
    return path
end
function EnsureDirPath(path)
    Commands.Log("Ensuring path exists: "..path)
    if Commands.IsMac() then
        os.execute("mkdir -p " .. path)
    else
        local handle = io.popen("cmd.exe /c mkdir \"" .. path.. "\"")
        handle:flush()
        local result = handle:read("*a")
        handle:close()
    end
end

local function IsEngineFile(path, start)
    local unixPath = MakeUnixPath(path)
    local unixStart = MakeUnixPath(start)
    local startIndex, _ = string.find(unixPath, unixStart, 1, true)
    return startIndex ~= nil
end

local function IsQuickfixWin(winid)
    if type(winid) ~= "number" or winid <= 0 then
        return false
    end
    if not vim.api.nvim_win_is_valid(winid) then return false end
    local bufnr = vim.api.nvim_win_get_buf(winid)
    local buftype = vim.api.nvim_buf_get_option(bufnr, 'buftype')

    return buftype == 'quickfix'
end

local function GetQuickfixWinId()
    local quickfix_winid = nil

    for _, winid in ipairs(vim.api.nvim_list_wins()) do

        if IsQuickfixWin(winid) then
            quickfix_winid = winid
            break
        end
    end
    return quickfix_winid
end

Commands.QuickfixWinId = 0

local function ScrollQF()
    if not IsQuickfixWin(Commands.QuickfixWinId) then
        Commands.QuickfixWinId = GetQuickfixWinId()
    end

    if not IsQuickfixWin(Commands.QuickfixWinId) then
        return
    end

    if not Commands.QuickfixWinId or not vim.api.nvim_win_is_valid(Commands.QuickfixWinId) then
        -- No quickfix window found, so we can't scroll.
        -- This can happen if the dispatch command hasn't opened it yet.
        return
    end

    local qf_list = vim.fn.getqflist()
    local last_line = #qf_list
    if last_line > 0 then
        vim.api.nvim_win_set_cursor(Commands.QuickfixWinId, {last_line, 0})
    end
end

local function AppendToQF(entry)
    vim.fn.setqflist({}, 'a', { items = { entry } })
    ScrollQF()
end

local function DeleteAutocmd(AutocmdId)
    local success, _ = pcall(function()
        vim.api.nvim_del_autocmd(AutocmdId)
    end)
end

function Stage_UbtGenCmd()
    coroutine.yield()
    Commands.BeginTask("gencmd")
    Commands.Log("callback called!")

    -- Determine where UBT is expected to generate the file based on the command used.
    local ubtJsonPath
    if CurrentGenData.WithEngine then
        -- UnrealBuildTool -mode=GenerateClangDatabase with -engine flag places the output in the Engine directory.
        ubtJsonPath = CurrentGenData.config.EngineDir .. "/compile_commands.json"
    else
        -- When run for a specific game project, it places it in the project directory.
        ubtJsonPath = CurrentGenData.prjDir .. "/compile_commands.json"
    end
    
    -- This is the final destination file that clangd will use, which is always in the project root.
    local clangdJsonPath = CurrentGenData.prjDir .. "/compile_commands.json"
    
    local rspdir = CurrentGenData.prjDir .. "/Intermediate/clangRsp/" .. 
    Commands.GetPlatformName() .. "/" .. 
    CurrentGenData.target.Configuration .. "/"

    -- all these replaces are slow, could be rewritten as a parser
    EnsureDirPath(rspdir)

    -- The file we read from is the one generated by UBT.
    local file_path = ubtJsonPath

    local old_text = "Llvm\\\\x64\\\\bin\\\\clang%-cl%.exe"
    local new_text = "Llvm/x64/bin/clang++.exe"

    local contentLines = {}
    Commands.Log("processing compile_commands.json and writing response files")
    Commands.Log("Reading UBT output from: " .. file_path)

    local skipEngineFiles = true
    if CurrentGenData.WithEngine then
        skipEngineFiles = false
    end

    local qflistentry = {text = "Preparing files for parsing." }
    if not skipEngineFiles then
        qflistentry.text = qflistentry.text .. " Engine source files included, process will take longer" 
    end
    AppendToQF(qflistentry)

    local currentFilename = ""
    for line in io.lines(file_path) do
        local i,j = line:find("\"command")
        if i then
            coroutine.yield()

            -- show progress
            logWithVerbosity(kLogLevel_Verbose, "Preparing for LSP symbol parsing: " .. currentFilename)
            local isEngineFile = IsEngineFile(currentFilename, CurrentGenData.config.EngineDir)
            local shouldSkipFile = isEngineFile and skipEngineFiles

            local qflistentry = {filename = "", lnum = 0, col = 0,
                text = currentFilename}
            if not shouldSkipFile then
                AppendToQF(qflistentry)
            end

            line = line:gsub(old_text, new_text)

            -- content = content .. "matched:\n"
            i,j = line:find("%@")

            if i then
                if Commands.IsMac() then
                    -- On macOS, UBT already emits clang-compatible response files.
                    -- Keep the original command line so all include paths are preserved.
                    local normalizedLine = line
                    while true do
                        local replacedCount = 0
                        normalizedLine, replacedCount = normalizedLine:gsub("%.rsp%.clang%.rsp", ".rsp")
                        if replacedCount == 0 then
                            break
                        end
                    end
                    table.insert(contentLines, normalizedLine .. "\n")
                else
                    -- The file name might have an optional \" around to shell escape the file name in the command.
                    local backslashValue = string.byte("\\", 1)
                    if string.byte(line, j+1) == backslashValue then
                        j = j+2 -- \ and "
                    end

                    local _,endpos = line:find("\"", j+1)

                    -- same thing here
                    if string.byte(line, endpos-1) == backslashValue then
                        endpos = endpos-1
                    end

                     local rsppath = line:sub(j+1, endpos-1)
                    if rsppath and file_exists(rsppath) then
                        local newrsppath = rsppath
                        if not newrsppath:match("%.clang%.rsp$") then
                            newrsppath = rsppath .. ".clang.rsp"
                        end

                        -- rewrite rsp contents
                        if not shouldSkipFile then
                            -- IMPORTANT: ExtractRSP now takes the *original* rsp path.
                            local rspcontent = ExtractRSP(rsppath) 
                            if rspcontent then
                                local rspfile = io.open(newrsppath, "w")
                                rspfile:write(rspcontent)
                                rspfile:close()
                            end
                        end
                        coroutine.yield()
                        
                        local newCmd = string.format([["command": "clang++ @%s"]], newrsppath)
                        table.insert(contentLines, "\t\t" .. newCmd .. ",\n")
                    else
                        PrintAndLogError("RSP file not found: " .. (rsppath or "nil"))
                        -- Fallback to keep the original line if rsp is missing
                        table.insert(contentLines, line .. "\n")
                    end
                end
            else
                -- This case handles commands that don't use response files.
                -- We'll just clean up the compiler path and keep the rest.
                if not Commands.IsMac() then
                    line = line:gsub("clang%+%+%S*", "clang++")
                end
                table.insert(contentLines, line .. "\n")
            end
        else
            local fbegin, fend = line:find("\"file\": ")
            if fbegin then
                currentFilename = line:sub(fend+1, -2)
                logWithVerbosity(kLogLevel_Verbose, "currentfile: " .. currentFilename)
            end
            table.insert(contentLines, line .. "\n")
        end
        ::continue::
    end


    Commands.Log("Writing final clangd output to: " .. clangdJsonPath)
    local file = io.open(clangdJsonPath, "w")
    file:write(table.concat(contentLines))
    file:flush()
    file:close()

    Commands.Log("finished processing compile_commands.json")
    Commands.Log("generating header files with Unreal Header Tool...")
    Commands.EndTask("gencmd")
    DeleteAutocmd(Commands.gencmdAutocmdid)

    Commands.ScheduleTask("headers")
    Commands.BeginTask("headers")
    Commands.headersAutocmdid = vim.api.nvim_create_autocmd("ShellCmdPost",{
        pattern = "*",
        callback = FuncBind(DispatchUnrealnvimCb, "headers")
    })

    local ubt = Commands.IsMac() and CurrentGenData.ueBuildBat or CurrentGenData.ubtPath
    local cmd = ubt .. " -project=" ..
        CurrentGenData.projectPath .. " " .. CurrentGenData.target.UbtExtraFlags .. " " ..
        CurrentGenData.prjName .. CurrentGenData.targetNameSuffix .. " " .. CurrentGenData.target.Configuration .. " " ..
        Commands.GetPlatformName() .. " -headers"

    vim.cmd("compiler " .. (Commands.IsMac() and "gcc" or "msvc"))
    vim.cmd("Dispatch " .. cmd)
end

function Stage_GenHeadersCompleted()
    Commands.Log("Finished generating header files with Unreal Header Tool...")
    vim.api.nvim_command('autocmd! ShellCmdPost * lua DispatchUnrealnvimCb()')
    vim.api.nvim_command('LspRestart')
    Commands.EndTask("headers")
    Commands.EndTask("final")
    Commands:SetCurrentAnimation("kirbyIdle")
    DeleteAutocmd(Commands.headersAutocmdid)
end

Commands.renderedAnim = ""

 function Commands.GetStatusBar()
     local status = "unset"
    if CurrentGenData:GetTaskStatus("final") == TaskState.completed then
        status = Commands.renderedAnim .. " Build completed!"
    elseif CurrentGenData.currentTask ~= "" then
        status = Commands.renderedAnim .. " Building... Step: " .. CurrentGenData.currentTask .. "->".. CurrentGenData:GetTaskStatus(CurrentGenData.currentTask)
    else
        status = Commands.renderedAnim .. " Idle"
    end
    return status
end

function DispatchUnrealnvimCb(data)
     log("DispatchUnrealnvimCb()")
     Commands.taskCoroutine = coroutine.create(FuncBind(DispatchCallbackCoroutine, data))
 end

function DispatchCallbackCoroutine(data)
    coroutine.yield()
    if not data then
        log("data was nil")
    end
    Commands.Log("DispatchCallbackCoroutine()")
    Commands.Log("DispatchCallbackCoroutine() task="..CurrentGenData:GetTaskAndStatus())
    if data == "gencmd" and CurrentGenData:GetTaskStatus("gencmd") == TaskState.scheduled then
        CurrentGenData:SetTaskStatus("gencmd", TaskState.inprogress)
        Commands.taskCoroutine = coroutine.create(Stage_UbtGenCmd)
    elseif data == "headers" and CurrentGenData:GetTaskStatus("headers") == TaskState.inprogress then
        Commands.taskCoroutine = coroutine.create(Stage_GenHeadersCompleted)
    end
end

function PromptBuildTargetIndex()
    print("target to build:")
    for i, x in ipairs(CurrentGenData.config.Targets) do
        local configName = x.Configuration
        if x.withEditor then
            configName = configName .. "-Editor"
        end
       print(tostring(i) .. ". " .. configName)
    end
    return tonumber(vim.fn.input "<number> : ")
end

function Commands.GetProjectName()
    local current_file_path = vim.api.nvim_buf_get_name(0)
    local prjName, _ = Commands._GetDefaultProjectNameAndDir(current_file_path)
    if not prjName  then
        return "" --"<Unknown.uproject>"
    end

    return CurrentGenData.prjName .. ".uproject"
end

function Commands._GetEngineAssociation(uprojectPath)
    local file = io.open(uprojectPath, "r")
    if not file then
        return nil
    end
    local content = file:read("*all")
    file:close()
    local data = vim.fn.json_decode(content)
    if data and data.EngineAssociation then
        return data.EngineAssociation
    end
    return nil
end

function Commands._TryAutoDetectEngineDir(uprojectPath)
    if not Commands.IsMac() then
        return nil
    end

    local engineAssociation = Commands._GetEngineAssociation(uprojectPath)
    if not engineAssociation then
        Commands.Log("Could not read EngineAssociation from .uproject file.")
        return nil
    end

    local launcherDataPath = vim.fn.expand('~/Library/Application Support/Epic/UnrealEngineLauncher/LauncherInstalled.dat')
    if vim.fn.filereadable(launcherDataPath) == 0 then
        Commands.Log("Could not find Epic Games Launcher installation data.")
        return nil
    end

    local file = io.open(launcherDataPath, "r")
    if not file then
        return nil
    end
    local content = file:read("*all")
    file:close()

    local data = vim.fn.json_decode(content)
    if not data or not data.InstallationList then
        return nil
    end

    for _, installation in ipairs(data.InstallationList) do
        if installation.AppName == "UE_" .. engineAssociation then
            Commands.Log("Auto-detected Unreal Engine installation: " .. installation.InstallLocation)
            return installation.InstallLocation
        end
    end

    Commands.Log("Could not find a matching Unreal Engine installation for version " .. engineAssociation)
    return nil
end

function InitializeCurrentGenData()
    Commands.Log("initializing")
    local current_file_path = vim.api.nvim_buf_get_name(0)
    CurrentGenData.prjName, CurrentGenData.prjDir = Commands._GetDefaultProjectNameAndDir(current_file_path)
    if not CurrentGenData.prjName then
        Commands.Log("could not find project. aborting")
        return false
    end

    local uprojectPath = CurrentGenData.prjDir .. "/" .. CurrentGenData.prjName .. ".uproject"
    CurrentGenData.config = Commands._EnsureConfigFile(CurrentGenData.prjDir,
        CurrentGenData.prjName)

    if not CurrentGenData.config then
        Commands.Log("no config file. aborting")
        return false
    end
    
    if not CurrentGenData.config.EngineDir or CurrentGenData.config.EngineDir == "" then
        CurrentGenData.config.EngineDir = Commands._TryAutoDetectEngineDir(uprojectPath)
    end

    if not CurrentGenData.config.EngineDir or CurrentGenData.config.EngineDir == "" then
        Commands.Log("EngineDir is not set in your UnrealNvim.json file. Please set it to the root of your Unreal Engine installation.")
        return false
    end

    if Commands.IsMac() then
        CurrentGenData.ubtPath = "dotnet " .. vim.fn.shellescape(CurrentGenData.config.EngineDir .. "/Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool.dll")
        CurrentGenData.ueBuildBat = "/bin/bash " .. vim.fn.shellescape(CurrentGenData.config.EngineDir .."/Engine/Build/BatchFiles/Mac/Build.sh")
    else
        CurrentGenData.ubtPath = vim.fn.shellescape(CurrentGenData.config.EngineDir .."/Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool.exe")
        CurrentGenData.ueBuildBat = vim.fn.shellescape(CurrentGenData.config.EngineDir .."/Engine/Build/BatchFiles/Build.bat")
    end
    CurrentGenData.projectPath = vim.fn.shellescape(CurrentGenData.prjDir .. "/" .. CurrentGenData.prjName .. ".uproject")

    local desiredTargetIndex = PromptBuildTargetIndex()
    CurrentGenData.target = CurrentGenData.config.Targets[desiredTargetIndex]

    CurrentGenData.targetNameSuffix = ""
    if CurrentGenData.target.withEditor then
        CurrentGenData.targetNameSuffix = "Editor"
    end

    Commands.Log("Using engine at:"..CurrentGenData.config.EngineDir)

    return true
end

function Commands.ScheduleTask(taskName)
    Commands.Log("ScheduleTask: " .. taskName)
    CurrentGenData:SetTaskStatus(taskName, TaskState.scheduled)
end

function Commands.ClearTasks()
    CurrentGenData:ClearTasks()
end

function Commands.BeginTask(taskName)
    Commands.Log("BeginTask: " .. taskName)
    CurrentGenData:SetTaskStatus(taskName, TaskState.inprogress)
end

function Commands.EndTask(taskName)
    Commands.Log("EndTask: " .. taskName)
    CurrentGenData:SetTaskStatus(taskName, TaskState.completed)
    Commands.taskCoroutine = nil
end

function BuildComplete()
    Commands.EndTask("build")
    Commands.EndTask("final")
    Commands:SetCurrentAnimation("kirbyIdle")
    DeleteAutocmd(Commands.buildAutocmdid)
end

function Commands.BuildCoroutine()
    Commands.buildAutocmdid = vim.api.nvim_create_autocmd("ShellCmdPost",
        {
            pattern = "*",
            callback = BuildComplete 
        })

    local cmd
    if Commands.IsMac() then
        cmd = CurrentGenData.ueBuildBat .. " " .. CurrentGenData.prjName .. 
            CurrentGenData.targetNameSuffix .. " " ..
            Commands.GetPlatformName()  .. " " .. 
            CurrentGenData.target.Configuration .. " " .. 
            "-project=" .. CurrentGenData.projectPath .. " -waitmutex"
        vim.cmd("compiler gcc")
    else
        cmd = CurrentGenData.ueBuildBat .. " " .. CurrentGenData.prjName .. 
            CurrentGenData.targetNameSuffix .. " " ..
            Commands.GetPlatformName()  .. " " .. 
            CurrentGenData.target.Configuration .. " " .. 
            CurrentGenData.projectPath .. " -waitmutex"
        vim.cmd("compiler msvc")
    end
    vim.cmd("Dispatch " .. cmd)

end

function Commands.build(opts)
    CurrentGenData:ClearTasks()
    Commands.Log("Building uproject")

    if not InitializeCurrentGenData() then
        return
    end
    Commands.EnsureUpdateStarted();

    Commands.ScheduleTask("build")
    Commands:SetCurrentAnimation("kirbyFlip")
    Commands.taskCoroutine = coroutine.create(Commands.BuildCoroutine)

end

function Commands.run(opts)
    CurrentGenData:ClearTasks()
    Commands.Log("Running uproject")
    
    if not InitializeCurrentGenData() then
        return
    end

    Commands.ScheduleTask("run")

    local cmd = ""

    if CurrentGenData.target.withEditor then
        local editorSuffix = ""
        if CurrentGenData.target.Configuration ~= "Development" then
            editorSuffix = "-" .. Commands.GetPlatformName() .. "-" .. 
            CurrentGenData.target.Configuration
        end

        if Commands.IsMac() then
            local appPath = vim.fn.shellescape(CurrentGenData.config.EngineDir .. "/Engine/Binaries/" ..
            Commands.GetPlatformName() .. "/" .. Commands.GetEditorName() .. editorSuffix .. ".app")

            cmd = "open " .. appPath .. " --args " ..
            CurrentGenData.projectPath .. " -skipcompile"
        else
            local executablePath = "\"".. CurrentGenData.config.EngineDir .. "/Engine/Binaries/" ..
            Commands.GetPlatformName() .. "/" .. Commands.GetEditorName() ..  editorSuffix .. Commands.GetExecutableFileExtension() .. "\""

            cmd = executablePath .. " " ..
            CurrentGenData.projectPath .. " -skipcompile"
        end
    else
        local exeSuffix = ""
        if CurrentGenData.target.Configuration ~= "Development" then
            exeSuffix = "-" .. Commands.GetPlatformName() .. "-" .. 
            CurrentGenData.target.Configuration
        end

        if Commands.IsMac() then
            local appPath = vim.fn.shellescape(CurrentGenData.prjDir .. "/Binaries/" ..
            Commands.GetPlatformName() .. "/" .. CurrentGenData.prjName .. exeSuffix .. ".app")

            cmd = "open " .. appPath
        else
            local executablePath = "\"".. CurrentGenData.prjDir .. "/Binaries/" ..
            Commands.GetPlatformName() .. "/" .. CurrentGenData.prjName ..  exeSuffix .. Commands.GetExecutableFileExtension() .. "\""

            cmd = executablePath
        end
    end

    Commands.Log(cmd)
    vim.cmd("compiler " .. (Commands.IsMac() and "gcc" or "msvc"))
    vim.cmd("Dispatch " .. cmd)
    Commands.EndTask("run")
    Commands.EndTask("final")
end

function Commands.EnsureUpdateStarted()
    if Commands.cbTimer then return end

    Commands.lastUpdateTime = vim.loop.now()
    Commands.updateTimer = 0

    -- UI update loop
    Commands.cbTimer = vim.loop.new_timer()
    Commands.cbTimer:start(1,30, vim.schedule_wrap(Commands.safeUpdateLoop))

    -- coroutine update loop
    vim.schedule(Commands.safeLogicUpdate)
end

function Commands.generateCommands(opts)
    log(Commands.Inspect(opts))

    if not InitializeCurrentGenData() then
        Commands.Log("init failed")
        return
    end

    if opts.WithEngine then
        CurrentGenData.WithEngine = true
    end

    -- vim.api.nvim_command('autocmd ShellCmdPost * lua DispatchUnrealnvimCb()')
    Commands.gencmdAutocmdid = vim.api.nvim_create_autocmd("ShellCmdPost",
        {
            pattern = "*",
            callback = FuncBind(DispatchUnrealnvimCb, "gencmd")
        })

    Commands.Log("listening to ShellCmdPost")
    --vim.cmd("compiler msvc")
    Commands.Log("compiler set to msvc")

    Commands.taskCoroutine = coroutine.create(Commands.generateCommandsCoroutine)
    Commands.EnsureUpdateStarted()
end


function Commands.updateLoop()
    local elapsedTime = vim.loop.now() - Commands.lastUpdateTime
    Commands:uiUpdate(elapsedTime)
    Commands.lastUpdateTime = vim.loop.now()
end

function Commands.safeUpdateLoop()
    local success, errmsg = pcall(Commands.updateLoop)
    if not success then
        vim.api.nvim_err_writeln("Error in update:".. errmsg)
    end
end

local gtimer = 0
local resetCount = 0

function Commands:uiUpdate(delta)
    local animFrameCount = 4
    local animFrameDuration = 200
    local animDuration = animFrameCount * animFrameDuration

    local anim = {
    "▌",
			"▀",
			"▐",
			"▄"
    }
    local anim1 = {
    "1",
			"2",
			"3",
			"4"
    }
    if Commands.animData then
        anim = Commands.animData.frames
        animFrameDuration = Commands.animData.interval
        animFrameCount = #anim
        animDuration = animFrameCount * animFrameDuration
    end

    local index = 1 + (math.floor(math.fmod(vim.loop.now(), animDuration) / animFrameDuration))
    Commands.renderedAnim = (anim[index] or "")
end

function Commands.safeLogicUpdate()
    local success, errmsg = pcall(function() Commands:LogicUpdate() end)

    if not success then
        vim.api.nvim_err_writeln("Error in update:".. errmsg)
    end
    vim.defer_fn(Commands.safeLogicUpdate, 1)
end

function Commands:LogicUpdate()
    if self.taskCoroutine then
        if coroutine.status(self.taskCoroutine) ~= "dead"  then
            local ok, errmsg = coroutine.resume(self.taskCoroutine)
            if not ok then
                self.taskCoroutine = nil
                error(errmsg)
            end
        else
            self.taskCoroutine = nil
        end
    end
    vim.defer_fn(Commands.onStatusUpdate, 1)
end

 local function GetInstallDir()
    local packer_install_dir = vim.fn.stdpath('data') .. '/site/pack/packer/start/'
    return packer_install_dir .. "Unreal.nvim//"
end

local mydbg = true
function Commands:SetCurrentAnimation(animationName)
    local jsonPath = GetInstallDir() .. "lua/spinners.json"
    local file = io.open(jsonPath, "r")
    if file then
        local content = file:read("*all")
        local json = vim.fn.json_decode(content)
        Commands.animData = json[animationName]
    end
end

function Commands.generateCommandsCoroutine()
    Commands.Log("Generating clang-compatible compile_commands.json")
    Commands:SetCurrentAnimation("kirbyFlip")
    coroutine.yield()
    Commands.ClearTasks()

    local editorFlag = ""
    if CurrentGenData.target.withEditor then
        Commands.Log("Building editor")
        editorFlag = "-Editor"
    end

    Commands.ScheduleTask("gencmd")
    local ubt = Commands.IsMac() and CurrentGenData.ueBuildBat or CurrentGenData.ubtPath
    -- local cmd = ubt .. " -mode=GenerateClangDatabase -StaticAnalyzer=Clang -project=" ..
    local cmd = ubt .. " -mode=GenerateClangDatabase -project=" ..
    CurrentGenData.projectPath .. " -game -engine " .. CurrentGenData.target.UbtExtraFlags .. " " ..
    editorFlag .. " " ..
    CurrentGenData.prjName .. CurrentGenData.targetNameSuffix .. " " .. CurrentGenData.target.Configuration .. " " ..
    Commands.GetPlatformName()

    Commands.Log("Dispatching command:")
    Commands.Log(cmd)
    -- This variable is used by the callback to know where to write the *final* file.
    CurrentCompileCommandsTargetFilePath =  CurrentGenData.prjDir .. "/compile_commands.json"
    vim.api.nvim_command("Dispatch " .. cmd)
    Commands.Log("Dispatched")
end

function Commands.SetUnrealCD()
    local current_file_path = vim.api.nvim_buf_get_name(0)
    local prjName, prjDir = Commands._GetDefaultProjectNameAndDir(current_file_path)
    if prjDir then
        vim.cmd("cd " .. prjDir)
    else
        Commands.Log("Could not find unreal project root directory, make sure you have the correct buffer selected")
    end
end


function Commands._check_extension_in_directory(directory, extension)
    local dir = vim.loop.fs_opendir(directory)
    if not dir then
        return nil
    end

    handle = vim.loop.fs_scandir(directory) 
    local name, typ

    while handle do
        name, typ = vim.loop.fs_scandir_next(handle)
        if not name then break end
        local ext = vim.fn.fnamemodify(name, ":e")
        if ( ext == "uproject" ) then
            return directory.."/"..name
        end
    end
    return nil
end

function Commands._find_file_with_extension(filepath, extension)
    local current_dir = vim.fn.fnamemodify(filepath, ":h")
    local parent_dir = vim.fn.fnamemodify(current_dir, ":h")
    -- Check if the file exists in the current directory
    local filename = vim.fn.fnamemodify(filepath, ":t")

    local full_path = Commands._check_extension_in_directory(current_dir, extension)
    if full_path then
        return current_dir, full_path
    end

    -- Recursively check parent directories until we find the file or reach the root directory
    if current_dir ~= parent_dir then
        return Commands._find_file_with_extension(parent_dir .. "/" .. filename, extension)
    end

    -- File not found
    return nil
end


return Commands
