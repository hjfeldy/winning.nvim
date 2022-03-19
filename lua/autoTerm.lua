local Terminals = {bufs = {}, numBufs = 0, recent = nil, toggled=false}
local a = vim.api

local function dirSplit(str)
    local matched = string.match(str, "/([%w%s]+)$")
    return matched
end

-- Generate a table of all open terminal windows
local function termWins()
    local wins = {}
    local found = false
    local index = 1
    for _, win in pairs(a.nvim_list_wins()) do
        local bufNr = a.nvim_win_get_buf(win)
        local ft = a.nvim_buf_get_option(bufNr, 'filetype')
        if ft == 'TERM' then
            found = true
            wins[index] = win
            index = index + 1
        end
        -- print(i, win, ft)
    end
    if not found then
        return nil
    end
    return wins
end

-- Space out all terminal windows evenly
local function evenWindows()
    local wins = termWins()
    if wins == nil then
        return 
    end
    local totalWidth = vim.o.columns
    local winCount = 0
    for _, _ in pairs(wins) do
        winCount = winCount + 1
    end
    local desiredWidth = math.floor(totalWidth / winCount)
    for _, win in pairs(wins) do
        a.nvim_win_set_width(win, desiredWidth)
    end
end

-- Create a new terminal
local function create()
    -- Focus and split a terminal window if there is one
    local found = termWins()
    if found ~= nil then
        local i = 0
        for _, _ in pairs(found) do
            i = i + 1
        end
        -- print('Found!')
        a.nvim_set_current_win(found[i])
        vim.cmd('vsplit term://zsh')

    else
        -- Create terminal buffer in new window
        vim.cmd('topleft split term://zsh')
        local lines = vim.o.lines
        local toResize = .25 * lines
        vim.cmd('resize ' .. toResize)
    end

    vim.cmd('set filetype=TERM')
    local bufNr = a.nvim_get_current_buf()

    -- Add to the buffer table
    Terminals.numBufs = Terminals.numBufs + 1
    local newBuf = {number=bufNr, name = 'Terminal ' .. Terminals.numBufs, focused=true, index=Terminals.numBufs}
    Terminals.bufs[Terminals.numBufs] = newBuf
    a.nvim_buf_set_name(newBuf.number, newBuf.name)
    Terminals.recent = Terminals.numBufs
    Terminals.toggled = true
    evenWindows()
end


-- Delete the most recently focused terminal from the buffer table
-- To be triggered by TermClose autocmd when a terminal buffer is deleted 
local function delete()
    if Terminals.numBufs == 0 then
        return
    end
    local bufNr = Terminals.bufs[Terminals.recent].number
    a.nvim_buf_delete(bufNr, {force=true})
    Terminals.bufs[Terminals.recent] = nil
    Terminals.numBufs = Terminals.numBufs - 1
    for i, _ in pairs(Terminals.bufs) do
        if i > Terminals.recent then
            Terminals.bufs[i - 1] = Terminals.bufs[i]
            local name = a.nvim_buf_get_name(Terminals.bufs[i - 1].number)
            if dirSplit(name) == 'Terminal ' .. i then
                a.nvim_buf_set_name(Terminals.bufs[i - 1].number, 'Terminal ' .. i - 1)
            end
            Terminals.bufs[i] = nil
        end
    end
    -- Set toggled to be false if we deleted the last focused terminal
    local wins = termWins()
    if wins == nil then
        Terminals.toggled = false
        if Terminals.numBufs > 0 then
            local nextFocus = Terminals.recent
            if nextFocus > Terminals.numBufs then
                nextFocus = 1
            end
        Terminals.bufs[nextFocus].focused = true
        end
    end
    evenWindows()

end

-- Rename a terminal buffer interactively
local function rename(termIndex)
    if termIndex == nil then 
        termIndex = Terminals.recent
    end
    local bufNr = Terminals.bufs[termIndex].number
    local name = a.nvim_buf_get_name(bufNr)
    local newName = vim.fn.input('New name for ' .. dirSplit(name) .. ': ')
    Terminals.bufs[termIndex].name = newName
    a.nvim_buf_set_name(bufNr, newName)
    return newName
end

-- Mark a terminal as unfocused such that it will not reappear on the next toggle-on 
-- (you want to keep the terminal buffer, but not in an open window)
-- To be called by autocmd to mark a terminal as unfocused when its window is closed
local function unfocus()
    local currentBuf = a.nvim_get_current_buf()
    for _, buf in pairs(Terminals.bufs) do
        if buf.number == currentBuf then
            buf.focused = false
        end
    end
end

-- Check if a particular terminal buffer is currently visible in a window
local function isAttached(termBuf)
    for i, win in pairs(a.nvim_list_wins()) do
        local buf = a.nvim_win_get_buf(win)
        if buf == termBuf then
            return true
        end
    end
    return false
end

local function toggleOff()
    Terminals.toggled = false
    local wins = termWins()
    if wins == nil then
        return
    end
    for _, win in pairs(wins) do
        local currentBuf = a.nvim_win_get_buf(win)
        a.nvim_win_close(win, true)
        for _, buf in pairs(Terminals.bufs) do
            if buf.number == currentBuf then
                buf.focused = true
            end
        end
    end
end

local function toggleOn()
    if Terminals.numBufs == 0 then
        create()
        return
    end
    Terminals.toggled = true
    local started = false
    local toFocus = nil
    for _, buf in pairs(Terminals.bufs) do
        if buf.focused then
            if not started then
                vim.cmd('topleft split')
                local lines = vim.o.lines
                local toResize = .25 * lines
                vim.cmd('resize ' .. toResize)
                a.nvim_win_set_buf(0, buf.number)
                started = true
            else
                vim.cmd('vsplit')
                a.nvim_win_set_buf(0, buf.number)
            end
            if buf.index == Terminals.recent then
                toFocus = a.nvim_get_current_win()
                print('index ' .. buf.index ' == ' .. Terminals.recent)
            end
        end
    end
    evenWindows()
    if toFocus ~= nil then
        a.nvim_set_current_win(toFocus)
    end
end

local function toggle()
    if Terminals.toggled then
        toggleOff()
    else
        toggleOn()
    end
end

-- Mark the recent terminal such that we always know which one was last focused
-- This way we know which one to pull up on the next on-toggle if we delete the only visible terminal
local function setCurrent()
    local currentBuf = a.nvim_win_get_buf(0)
    for i, buf in pairs(Terminals.bufs) do
        if buf.number == currentBuf then
            Terminals.recent = i
        end
    end
end

-- Cycle the current window to contain the next available terminal buffer
local function nextTerm()
    local currentBuf = a.nvim_get_current_buf()
    local wins = termWins()
    local ft = a.nvim_buf_get_option(currentBuf, 'filetype')
    if ft ~= 'TERM' or Terminals.numBufs == 0 or not Terminals.toggled then
        return
    end

    local i = 0
    local newTermNum = Terminals.recent + 1
    if newTermNum > Terminals.numBufs then
        newTermNum = 1
    end
    while i < Terminals.numBufs + 2 do
        i = i + 1
        local newTerm = Terminals.bufs[newTermNum]
        if not isAttached(newTerm.number) then
        -- if not isAttached(newTerm.number) then
            a.nvim_win_set_buf(0, newTerm.number)
            Terminals.recent = newTermNum
            newTerm.focused = true

            -- Unfocus the buf we switched from
            for _, buf in pairs(Terminals.bufs) do
                if buf.number == currentBuf then
                    buf.focused = false
                end
            end
            break
        end
        newTermNum = newTermNum + 1
        if newTermNum > Terminals.numBufs then
            newTermNum = 1
        end
    end
end

-- Cycle the current window to contain the next available terminal buffer (traversing the table backwards)
local function prevTerm()
    local currentBuf = a.nvim_get_current_buf()
    local ft = a.nvim_buf_get_option(currentBuf, 'filetype')
    local wins = termWins()
    if ft ~= 'TERM' or Terminals.numBufs == 0 or not Terminals.toggled then
        return
    end
    local i = 0
    local newTermNum = Terminals.recent - 1
    if newTermNum == 0 then
        newTermNum = Terminals.numBufs
    end
    while i < Terminals.numBufs + 2 do
        i = i + 1
        local newTerm = Terminals.bufs[newTermNum]
        if not isAttached(newTerm.number) then
        -- if not isAttached(newTerm.number) then
            a.nvim_win_set_buf(0, newTerm.number)
            Terminals.recent = newTermNum
            newTerm.focused = true

            -- Unfocus the buf we switched from
            for _, buf in pairs(Terminals.bufs) do
                if buf.number == currentBuf then
                    buf.focused = false
                end
            end
            break
        end
        newTermNum = newTermNum - 1
        if newTermNum == 0 then
            newTermNum = Terminals.numBufs
        end
    end
end

return {create=create,
        nextTerm=nextTerm,
        prevTerm=prevTerm,
        toggle=toggle,
        evenWindows=evenWindows,
        unfocus=unfocus,
        setCurrent=setCurrent,
        recent=Terminals.recent,
        rename=rename,
        delete=delete,
        Terminals=Terminals,
        isAttached=isAttached}
