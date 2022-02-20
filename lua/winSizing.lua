local a = vim.api

local Windows = {dimensions = {}}

function Windows:winInfo()
    -- Keep tabs on window dimensions
    local wins = a.nvim_tabpage_list_wins(0)
    local width, height
    self.dimensions = {}
    for _, window in ipairs(wins) do
        width = a.nvim_win_get_width(window)
        height = a.nvim_win_get_height(window)
        self.dimensions[window] = {width=width, height=height}
    end
end

function Windows:zoomedExists()
    -- Check if a window is currently zoomed in on
    local wins = a.nvim_tabpage_list_wins(0)
    for _, window in ipairs(wins) do
        if self.dimensions[window].zoomed then
            return true
        end
    end
    return false
end

function Windows:zoomIn()

    -- Call winInfo only BEFORE zooming. We want to keep track of the non-zoomed dimensions
    -- Do not call winInfo in the scenario where you
    -- zoom into a minimized window while another window is already zoomed in
    if self:zoomedExists() then
        self:zoomOut()
    else
        self:winInfo()
    end
    local ui = a.nvim_list_uis()[1]
    local width, height = ui.width, ui.height
    local win = a.nvim_get_current_win()
    self.dimensions[win].zoomed = true
    a.nvim_win_set_width(0, width)
    a.nvim_win_set_height(0, height)
end

function Windows:zoomOut()
    local width, height
    for win, dim in pairs(self.dimensions) do
        width, height = dim.width, dim.height
        a.nvim_win_set_width(win, width)
        a.nvim_win_set_height(win, height)
        dim.zoomed = false
    end
    -- Redundant?
    self:winInfo()
end

function Windows:toggleZoom()
    -- Zoom an unzoomed window. Unzoom a zoomed window
    local thisWin = a.nvim_get_current_win()
    local wins = a.nvim_tabpage_list_wins(0)
    local numWins = 0
    for i, win in ipairs(wins) do
        numWins = numWins + 1
    end
    if numWins == 1 then
        return
    end

    if self.dimensions[thisWin].zoomed then
        self:zoomOut()
    else
        self:zoomIn()
    end
end

-- Keep tabs on window dimensions upon creation/deletion
--[[ vim.cmd('autocmd TermClose * lua Windows:winInfo()')
vim.cmd('autocmd WinNew * lua Windows:winInfo()') ]]

return Windows
