local component = require("component")
local event = require("event")
local shell = require("shell")
local os = require("os")

local gpu = component.gpu

local BUFFER_SIZE_MAX = 16384   -- Maximum number of bytes that can be kept in memory for an editor (Minimum is 1, Maximum is UNKNOWN!)
local editors = {}              -- A list of editors (open documents)

RUNNING = true                  -- A global variable that determines whether the main loop of the program should repeat. Global due to how keybinds are implemented

-- pads a string to a fixed length
local function padString(src, len, pad)
    local lengthReq = len - #src
    if lengthReq <= 0 then return src end
    
    pad = pad or ' '
    for i=1,lengthReq,1 do
        src = src .. pad
    end

    return src
end

local function assertStringLen(src, len, pad)
    if #src > len then
       return string.sub(src, 1, len) 
    else
        return padString(src, len, pad)
    end
end

-- Requires a file handle and a cursor. Returns a table of strings based on newline characters
local function updateBuffer(filehandle, cursor, offsetY)
    local buffer = {}
    buffer[1] = ""

    local d = nil
    local datLen = 0
    local bufIDX = 1

    -- Moves the read head to the line offset
    filehandle:seek(offsetY)

    -- Reads until nil is returned and appends characters read to buffer
    repeat 
        d = filehandle:read(1)
        datLen = datLen + 1

        if d == '\n' then 
            bufIDX = bufIDX + 1     -- If the character is a newline, increments the buffer index
            buffer[bufIDX] = ""
        elseif not (d == nil) then  -- If the character is valid and not a newline, it appends it to the buffer
            buffer[bufIDX] = buffer[bufIDX] .. d
        end

    until (d == nil) or (datLen >= BUFFER_SIZE_MAX)

    return buffer
end

-- Creates and appends a editor to editors table
local function createEditor(filepath)
    local editor = {}

    -- Initialise Cursor Position
    editor.cursor = {}
    editor.cursor.prevX    = 1
    editor.cursor.prevY    = 1
    editor.cursor.x        = 1
    editor.cursor.y        = 1
    editor.cursor.offsetX  = 1
    editor.cursor.offsetY  = 1
    
    -- Initialise File Data
    editor.filepath        = filepath
    editor.filehandle      = io.open(filepath, "r")
    editor.buffer          = updateBuffer(editor.filehandle, editor.cursor)
    editor.buffer.offsetX  = 0
    editor.buffer.offsetY  = 0

    -- Initialise Renderer Variables 
    editor.fg              = 0xefefef
    editor.bg              = 0x2f2f2f
    editor.cursor.fg       = 0x2f2f2f
    editor.cursor.bg       = 0xefefef

    editor.width,_         = gpu.getResolution()
    _,editor.height        = gpu.getResolution()
    editor.width           = editor.width
    editor.height          = editor.height - 2
    editor.offsetX         = 1
    editor.offsetY         = 3


    table.insert(editors, editor)
end

local function scratchRenderEditor(idx)
    local editor = editors[idx]

    gpu.setForeground(editor.fg)
    gpu.setBackground(editor.bg)

    -- Render text while respecting the editor position
    for i=1,editor.height,1 do
        if editor.buffer[i] then    -- Makes sure there is a value to render
            gpu.set(1+editor.offsetX, i+editor.offsetY, editor.buffer[i])
        end
    end

    do
        gpu.setForeground(editor.cursor.fg) 
        gpu.setBackground(editor.cursor.bg)

        local cx, cy = math.min(editor.cursor.x, editor.width)+editor.offsetX, math.min(editor.cursor.y, editor.height+editor.offsetY)
        local c, _, _ = gpu.get(cx, cy)
        gpu.set(cx, cy, c) -- Changes the color of the pixel at the cursors position

        -- Reset colors
        gpu.setForeground(editor.fg)
        gpu.setBackground(editor.bg)
    end
end

createEditor("/home/editor.lua")
scratchRenderEditor(1)
os.sleep(3)


-- Encased To Prevent Polluting This Files Namespace
do
    local function renderUI()

    end


    -- Event Listeners
    local function onClick(_, _, x, y, button, _)

    end

    local function onKeyDown(_, _, _, code, _)

    end

    local function onKeyUp(_, _, _, code, _)

    end

    local function onDrag(_, _, x, y, button, _)

    end

    local function onDrop(_, _, x, y, button, _)

    end

    local function onScroll(_, _, x, y, dir, _)

    end

    local function onClipboard(_, _, str, _)

    end

    -- Main Function
    function Main()
        -- Register Event Handles And Associate With Appropriate Functions Above 
        local handles = {}
        handles.keyDown = event.listen("key_down", onKeyDown)
        handles.keyUp = event.listen("key_up", onKeyUp)
        handles.click = event.listen("touch", onClick)
        handles.drag = event.listen("drag", onDrag)
        handles.drop = event.listen("drop", onDrop)
        handles.scroll = event.listen("scroll", onScroll)
        handles.clipboard = event.listen("clipboard", onClipboard)

        -- Main Loop For Program
        while RUNNING do
            
        end

        -- De-Register Events
        for i,k in pairs(handles) do
            event.cancel(k)
        end
    end
end

Main()