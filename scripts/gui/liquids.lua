-- Interface front-end for liquids plugin.

local utils = require 'utils'
local gui = require 'gui'
local guidm = require 'gui.dwarfmode'

local liquids = require('plugins.liquids')

local sel_rect = df.global.selection_rect

local brushes = {
    { tag = 'range', caption = 'Rectangle', range = true },
    { tag = 'block', caption = '16x16 block' },
    { tag = 'column', caption = 'Column' },
    { tag = 'flood', caption = 'Flood' },
}

local paints = {
    { tag = 'water', caption = 'Water', liquid = true, key = 'w' },
    { tag = 'magma', caption = 'Magma', liquid = true, key = 'l' },
    { tag = 'obsidian', caption = 'Obsidian Wall' },
    { tag = 'obsidian_floor', caption = 'Obsidian Floor' },
    { tag = 'riversource', caption = 'River Source' },
    { tag = 'flowbits', caption = 'Flow Updates' },
    { tag = 'wclean', caption = 'Clean Salt/Stagnant' },
}

local flowbits = {
    { tag = '+', caption = 'Enable Updates' },
    { tag = '-', caption = 'Disable Updates' },
    { tag = '.', caption = 'Keep Updates' },
}

local setmode = {
    { tag = '.', caption = 'Set Exactly' },
    { tag = '+', caption = 'Only Increase' },
    { tag = '-', caption = 'Only Decrease' },
}

Toggle = defclass(Toggle)

function Toggle:init(items)
    self:init_fields{
        items = items,
        selected = 1
    }
    return self
end

function Toggle:get()
    return self.items[self.selected]
end

function Toggle:render(dc)
    local item = self:get()
    if item then
        dc:string(item.caption)
        if item.key then
            dc:string(" ("):string(item.key, COLOR_LIGHTGREEN):string(")")
        end
    else
        dc:string('NONE', COLOR_RED)
    end
end

function Toggle:step(delta)
    if #self.items > 1 then
        delta = delta or 1
        self.selected = 1 + (self.selected + delta - 1) % #self.items
    end
end

LiquidsUI = defclass(LiquidsUI, guidm.MenuOverlay)

LiquidsUI.focus_path = 'liquids'

function LiquidsUI:init()
    self:init_fields{
        brush = mkinstance(Toggle):init(brushes),
        paint = mkinstance(Toggle):init(paints),
        flow = mkinstance(Toggle):init(flowbits),
        set = mkinstance(Toggle):init(setmode),
        amount = 7,
    }
    guidm.MenuOverlay.init(self)
    return self
end

function LiquidsUI:onDestroy()
    guidm.clearSelection()
end

function LiquidsUI:onRenderBody(dc)
    dc:clear():seek(1,1):string("Paint Liquids Cheat", COLOR_WHITE)

    local cursor = guidm.getCursorPos()
    local block = dfhack.maps.getTileBlock(cursor)
    local tile = block.tiletype[cursor.x%16][cursor.y%16]
    local dsgn = block.designation[cursor.x%16][cursor.y%16]

    dc:seek(2,3):string(df.tiletype.attrs[tile].caption, COLOR_CYAN):newline(2)

    if dsgn.flow_size > 0 then
        if dsgn.liquid_type == df.tile_liquid.Magma then
            dc:pen(COLOR_RED):string("Magma")
        else
            dc:pen(COLOR_BLUE)
            if dsgn.water_stagnant then dc:string("Stagnant ") end
            if dsgn.water_salt then dc:string("Salty ") end
            dc:string("Water")
        end
        dc:string(" ["..dsgn.flow_size.."/7]")
    else
        dc:string('No Liquid', COLOR_DARKGREY)
    end

    dc:newline():pen(COLOR_GREY)

    dc:newline(1):string("b", COLOR_LIGHTGREEN):string(": ")
    self.brush:render(dc)
    dc:newline(1):string("p", COLOR_LIGHTGREEN):string(": ")
    self.paint:render(dc)

    local liquid = self.paint:get().liquid

    dc:newline()
    if liquid then
        dc:newline(1):string("Amount: "..self.amount)
        dc:advance(1):string("("):string("-+", COLOR_LIGHTGREEN):string(")")
        dc:newline(3):string("s", COLOR_LIGHTGREEN):string(": ")
        self.set:render(dc)
    else
        dc:advance(0,2)
    end

    dc:newline():newline(1):string("f", COLOR_LIGHTGREEN):string(": ")
    self.flow:render(dc)

    dc:newline():newline(1):pen(COLOR_WHITE)
    dc:string("Esc", COLOR_LIGHTGREEN):string(": Back, ")
    dc:string("Enter", COLOR_LIGHTGREEN):string(": Paint")
end

function LiquidsUI:onInput(keys)
    local liquid = self.paint:get().liquid
    if keys.CUSTOM_B then
        self.brush:step()
    elseif keys.CUSTOM_P then
        self.paint:step()
    elseif liquid and keys.SECONDSCROLL_UP then
        self.amount = math.max(0, self.amount-1)
    elseif liquid and keys.SECONDSCROLL_DOWN then
        self.amount = math.min(7, self.amount+1)
    elseif liquid and keys.CUSTOM_S then
        self.set:step()
    elseif keys.CUSTOM_F then
        self.flow:step()
    elseif keys.LEAVESCREEN then
        if guidm.getSelection() then
            guidm.clearSelection()
            return
        end
        self:dismiss()
        self:sendInputToParent('CURSOR_DOWN_Z')
        self:sendInputToParent('CURSOR_UP_Z')
    elseif keys.SELECT then
        local cursor = guidm.getCursorPos()
        local sp = guidm.getSelection()
        local size = nil
        if self.brush:get().range then
            if not sp then
                guidm.setSelectionStart(cursor)
                return
            else
                guidm.clearSelection()
                cursor, size = guidm.getSelectionRange(cursor, sp)
            end
        else
            guidm.clearSelection()
        end
        liquids.paint(
            cursor,
            self.brush:get().tag, self.paint:get().tag,
            self.amount, size,
            self.set:get().tag, self.flow:get().tag
        )
    elseif self:propagateMoveKeys(keys) then
        return
    elseif keys.D_LOOK_ARENA_WATER then
        self.paint.selected = 1
    elseif keys.D_LOOK_ARENA_MAGMA then
        self.paint.selected = 2
    end
end

if not string.match(dfhack.gui.getCurFocus(), '^dwarfmode/LookAround') then
    qerror("This script requires the main dwarfmode view in 'k' mode")
end

local list = mkinstance(LiquidsUI):init()
list:show()