if not sql.TableExists("uwdplus") then
    sql.Query("CREATE TABLE IF NOT EXISTS uwdplus (key TEXT NOT NULL PRIMARY KEY, type TEXT NOT NULL, value TEXT);")
end

function DOWNLOADER:GetValue(key)
    local row = sql.QueryRow(string.format(
        [[SELECT * FROM uwdplus WHERE key = %s]],
        sql.SQLStr(key)
    ))

    if row == false then
        error(sql.LastError())
    elseif not row then
        return nil
    elseif row.type == "table" then
        return util.JSONToTable(row.value)
    elseif row.type == "number" then
        return tonumber(row.value)
    elseif row.type == "bool" then
        return tobool(row.value)
    elseif row.type == "color" then
        return string.ToColor(row.value)
    else
        return row.value
    end
end

function DOWNLOADER:SetValue(key, value)
    local type = "string"

    if istable(value) then
        type = "table"
        value = util.TableToJSON(value)
    elseif isnumber(value) then
        type = "number"
        value = tostring(value)
    elseif isbool(value) then
        type = "bool"
        value = tostring(value)
    elseif IsColor(value) then
        type = "color"
        value = string.FromColor(value)
    end

    local res = sql.Query(string.format(
        [[INSERT OR REPLACE INTO uwdplus VALUES(%s, '%s', %s)]],
        sql.SQLStr(key), type, sql.SQLStr(value)
    ))

    if res == false then
        error(sql.LastError())
    end
end