local component = require("component")
local event = require("event")
local shell = require("shell")
local os = require("os")

local gpu = component.gpu

-- CONFIGURATION VALUES
local BUFFER_SIZE_MAX = 16384   -- Maximum number of bytes that can be kept in memory for an editor (Minimum is 1, Maximum is UNKNOWN!)
local UI_BG = 0x1f1f1f
local UI_FG = 0xdfdfdf


local editors = {}              -- A list of editors (open documents)
local frameCounter = 0
local S_WIDTH, S_HEIGHT = gpu.getResolution()
RUNNING = true                  -- A global variable that determines whether the main loop of the program should repeat. Global due to how keybinds are implemented

local keystates = {}
local function keybinds(editorIDX)
    local editor = editors[editorIDX]
    if keystates[16] and keystates[29] then RUNNING = false -- If Ctrl + Q then Close Application
    -- A Not Very Elegant Solution To The Cursor Moving Too Fast (Simulating a frame limit) I Reccomend 1 or 2 
    elseif frameCounter % 1 == 0 then
        -- Moves Cursor Position According To What Key Is Pressed, Also Updates The Previous Position
        if keystates[200] then  -- Up Arrow
            editor.prevY    = editor.cursor.y
            editor.cursor.y = editor.cursor.y - 1
        elseif keystates[208] then  -- Down Arrow
            editor.prevY    = editor.cursor.y
            editor.cursor.y = editor.cursor.y + 1
        elseif keystates[205] then  -- Right Arrow
            editor.prevX    = editor.cursor.x
            editor.cursor.x = editor.cursor.x + 1
        elseif keystates[203] then  -- Left Arrow
            editor.prevX    = editor.cursor.x
            editor.cursor.x = editor.cursor.x - 1
        end
    else end
end




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
        buffer.len = bufIDX
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
    editor.cursor.xSel     = 0
    editor.cursor.ySel     = 0
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
    editor.offsetX         = 4
    editor.offsetY         = 2


    table.insert(editors, editor)
end

local function scratchRenderEditor(idx)
    local editor = editors[idx]
    gpu.setBackground(UI_BG)
    gpu.fill(1, 1, S_WIDTH, S_HEIGHT, " ")
    gpu.setForeground(editor.fg)
    gpu.setBackground(editor.bg)
    gpu.fill(1+editor.offsetX, 1+editor.offsetY, editor.width, editor.height-editor.offsetY, " ")
    -- Render text while respecting the editor position
    for i=1,editor.height,1 do
        if editor.buffer[i] then    -- Makes sure there is a value to render
            local cx,cy = 1+editor.offsetX, i+editor.offsetY
            if cx > 0 and cy > 0 and cx <= editor.width and cy <= editor.height then
                gpu.set(cx, cy, editor.buffer[i])
            end
        end
    end

    do
        gpu.setForeground(editor.cursor.fg) 
        gpu.setBackground(editor.cursor.bg)

        for i=0,math.min(editor.cursor.ySel, editor.height),1 do
            for j=0,math.min(editor.cursor.xSel, editor.width),1 do
                local cx, cy = math.min(editor.cursor.x+j, editor.width)+editor.offsetX, math.min(editor.cursor.y+i, editor.height)+editor.offsetY
                if cx > editor.offsetX and cy > editor.offsetY and cx <= editor.width and cy <= editor.height then -- Check to make sure its in bounds
                    local c, _, _ = gpu.get(cx, cy)
                    gpu.set(cx, cy, c) -- Changes the color of the pixel at the cursors position
                end
            end
        end
        
        -- Reset colors
        gpu.setForeground(editor.fg)
        gpu.setBackground(editor.bg)
    end
end

local function renderUI(idx)

end
-- Encased To Prevent Polluting This Files Namespace
do
    -- Event Listeners
    local function onClick(_, _, x, y, button, _)

    end

    local function onKeyDown(_, _, _, code, _)
        keystates[code] = true
        print("Key With Code: " .. code)
    end

    local function onKeyUp(_, _, _, code, _)
        keystates[code] = false
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
        local editorIDX = 1
        createEditor("/home/editor.lua")
        scratchRenderEditor(editorIDX)
        while RUNNING do
            os.sleep()
            -- Checks and Updates When Keys Are Pressed
            keybinds(editorIDX)
            scratchRenderEditor(editorIDX)
            frameCounter = frameCounter + 1
        end

        -- De-Register Events
        for i,k in pairs(handles) do
            event.cancel(k)
        end
    end
end

Main()