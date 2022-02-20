local a = vim.api

windows = {dimensions = {}}

local function winInfo()
    local wins = a.nvim_tabpage_list_wins(0)
    local width, height
    windows.dimensions = {}
    for _, window in ipairs(wins) do
        width = a.nvim_win_get_width(window)
        height = a.nvim_win_get_height(window)
        windows.dimensions[window] = {width=width, height=height}
    end
end

local function zoomedExists()
    local wins = a.nvim_tabpage_list_wins(0)
    for _, window in ipairs(wins) do
        if windows.dimensions[window].zoomed then
            return true
        end
    end
    return false
end

local function zoomOut()
    local width, height
    for win, dim in pairs(windows.dimensions) do
        width, height = dim.width, dim.height
        a.nvim_win_set_width(win, width)
        a.nvim_win_set_height(win, height)
        dim.zoomed = false
    end
    winInfo()
end

local function zoomIn()
    if zoomedExists() then
        -- print('Zoomed window exists')
        -- winInfo()
        zoomOut()
    else
        winInfo()
    end
    local ui = a.nvim_list_uis()[1]
    local width, height = ui.width, ui.height
    local win = a.nvim_get_current_win()
    windows.dimensions[win].zoomed = true
    a.nvim_win_set_width(0, width)
    a.nvim_win_set_height(0, height)
end

local function toggleZoom()
    local thisWin = a.nvim_get_current_win()
    local wins = a.nvim_tabpage_list_wins(0)
    local numWins = 0
    for _, _ in ipairs(wins) do
        numWins = numWins + 1
    end
    if numWins == 1 then
        return
    end

    if windows.dimensions[thisWin].zoomed then
        zoomOut()
    else
        zoomIn()
    end
end

return {toggleZoom=toggleZoom,
        winInfo=winInfo}
