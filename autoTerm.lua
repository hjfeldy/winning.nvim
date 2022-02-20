Terminals = {bufs = {}, numBufs = 0, recent = nil, toggled=false}
local a = vim.api
local function dirSplit(str)
    local matched = string.match(str, "/([%w%s]+)$") 
    return matched
end

function Terminals:create()
    -- Create a new terminal

    -- Focus and split a terminal window if there is one
    local found = self:termWins()
    if found ~= nil then
        local i = 0
        for _, win in pairs(found) do
            i = i + 1
        end
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
    self.numBufs = self.numBufs + 1
    local newBuf = {number=bufNr, name = 'Terminal ' .. self.numBufs, focused=true}
    self.bufs[self.numBufs] = newBuf
    a.nvim_buf_set_name(newBuf.number, newBuf.name)
    self.recent = Terminals.numBufs
    self.toggled = true
    self:evenWindows()
end

function Terminals:evenWindows()
    -- Space out all terminal windows evenly
    local wins = self:termWins()
    if wins == nil then
        return
    end
    local totalWidth = vim.o.columns
    local winCount = 0
    for i, win in pairs(wins) do
        winCount = winCount + 1
    end
    local desiredWidth = math.floor(totalWidth / winCount)
    for i, win in pairs(wins) do
        a.nvim_win_set_width(win, desiredWidth)
    end
end

function Terminals:delete(index)
    -- Delete a particular terminal buffer from the buffer table
    if self.numBufs == 0 then
        return
    end
    local bufNr = self.bufs[index].number
    a.nvim_buf_delete(bufNr, {force=true})
    self.bufs[index] = nil
    self.numBufs = self.numBufs - 1
    -- Rotate bufs
    for i, buf in pairs(self.bufs) do
        if i > index then
            self.bufs[i - 1] = self.bufs[i]
            local name = a.nvim_buf_get_name(self.bufs[i - 1].number)
            if dirSplit(name) == 'Terminal ' .. i then
                a.nvim_buf_set_name(self.bufs[i - 1].number, 'Terminal ' .. i - 1)
            end
            self.bufs[i] = nil
        end
    end

    -- If we deleted the last focused terminal,
    --  Set toggled to be false
    --  Configure the next terminal to bring up on the next toggle
    local wins = self:termWins()
    if wins == nil then
        self.toggled = false
        if self.numBufs > 0 then
            local nextFocus = self.recent
            if nextFocus > self.numBufs then
                nextFocus = 1
            end
        self.bufs[nextFocus].focused = true
        end
    end
    self:evenWindows()

end

function Terminals:rename(termIndex)
    -- Pick a new name for a terminal
    if termIndex == nil then 
        termIndex = self.recent
    end
    local bufNr = self.bufs[termIndex].number
    local name = a.nvim_buf_get_name(bufNr)
    local newName = vim.fn.input('New name for ' .. dirSplit(name) .. ': ')
    a.nvim_buf_set_name(bufNr, newName)
end

function Terminals:unfocus()
    -- To be called by autocmd to mark a terminal as unfocused when its window is closed
    local currentBuf = a.nvim_get_current_buf()
    for _, buf in pairs(self.bufs) do
        if buf.number == currentBuf then
            buf.focused = false
        end
    end
end

function Terminals:show()
    for i, buf in ipairs(self.bufs) do
        print(i, buf.number, buf.focused)
    end
end

function Terminals:termWins()
    -- Generate a table of all open terminal windows
    local wins = {}
    local found = false
    local index = 1
    for i, win in pairs(a.nvim_tabpage_list_wins(0)) do
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

function Terminals:toggleOff()
    -- Quit all terminal windows
    self.toggled = false
    local wins = self:termWins()
    if wins == nil then
        return
    end
    for _, win in pairs(wins) do
        local currentBuf = a.nvim_win_get_buf(win)
        a.nvim_win_close(win, true)
        for _, buf in pairs(self.bufs) do
            if buf.number == currentBuf then
                buf.focused = true
            end
        end
    end
end

function Terminals:toggleOn()
    -- Open back up all off-toggled terminal windows
    if self.numBufs == 0 then
        self:create()
        return
    end
    self.toggled = true
    local started = false
    for i, buf in pairs(self.bufs) do
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
        end
    end
end

function Terminals:toggle()
    -- Quickly open/close terminal windows
    if self.toggled then
        self:toggleOff()
    else
        self:toggleOn()
    end
end

function Terminals:setCurrent()
    -- Keep tabs on the most recently occupied terminal window
    local currentBuf = a.nvim_win_get_buf(0)
    for i, buf in pairs(self.bufs) do
        if buf.number == currentBuf then
            -- print('Setting current: ' .. i)
            self.recent = i
        end
    end
end

function Terminals:nextTerm()
    -- Cycle the current terminal window to the next terminal buffer in the buffer table
    local wins = self:termWins()
    local currentBuf = a.nvim_get_current_buf()
    local ft = a.nvim_buf_get_option(currentBuf, 'filetype')
    if ft ~= 'TERM' or self.numBufs == 0 or not self.toggled then
        return
    end

    local i = 0
    local newTermNum = self.recent + 1
    if newTermNum > self.numBufs then
        newTermNum = 1
    end
    while i < self.numBufs + 2 do
        i = i + 1
        local newTerm = self.bufs[newTermNum]
        if wins[newTerm.number] ~= nil then
            a.nvim_win_set_buf(0, newTerm.number)
            self.recent = newTermNum
            newTerm.focused = true

            -- Unfocus the buf we switched from
            for _, buf in pairs(self.bufs) do
                if buf.number == currentBuf then
                    buf.focused = false
                end
            end
            break
        end
        newTermNum = newTermNum + 1
        if newTermNum > self.numBufs then
            newTermNum = 1
        end
    end
end

function Terminals:prevTerm()
    -- Cycle the current terminal window to the previous terminal buffer in the buffer table
    local wins = self:termWins()
    local currentBuf = a.nvim_get_current_buf()
    local ft = a.nvim_buf_get_option(currentBuf, 'filetype')
    if ft ~= 'TERM' or self.numBufs == 0 or not self.toggled then
        return
    end
    local i = 0
    local newTermNum = self.recent - 1
    if newTermNum == 0 then
        newTermNum = self.numBufs
    end
    while i < self.numBufs + 2 do
        i = i + 1
        local newTerm = self.bufs[newTermNum]
        if wins[newTerm.number] ~= nil then
            a.nvim_win_set_buf(0, newTerm.number)
            self.recent = newTermNum
            newTerm.focused = true

            -- Unfocus the buf we switched from
            for _, buf in pairs(self.bufs) do
                if buf.number == currentBuf then
                    buf.focused = false
                end
            end
            break
        end
        newTermNum = newTermNum - 1
        if newTermNum == 0 then
            newTermNum = self.numBufs
        end
    end
end

-- Delete a terminal buffer from the buffer table anytime the user quits out of the terminal (not when they close the window)
vim.cmd('autocmd TermClose * lua Terminals:delete(Terminals.recent)')
-- Mark a terminal buffer as unfocused whenever its window is closed
vim.cmd('autocmd WinClosed * lua Terminals:unfocus()')
-- Check which terminal buffer was last entered whenever the user switches windows
vim.cmd('autocmd WinEnter * lua Terminals:setCurrent()')
