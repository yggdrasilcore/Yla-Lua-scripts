local token = "NTE4MTM1NTYzNjIzMzMzODk4.GcQAVV.NpaKPuOV2HsUs5SczcSlBQvNFuuhjGi2-hFZ5I"
local channel_id = "1241347117943881768"
local url = "https://discord.com/api/v9/channels/" .. channel_id .. "/messages?limit=1"
local id

local headers = {
Authorization = token
}

-- Function to get the current date in yyyy-mm-dd format
local function getCurrentDate()
local time = os.time()
local year, month, day = os.date("%Y", time), os.date("%m", time), os.date("%d", time)
return string.format("%04d-%02d-%02d", year, month, day)
end

-- Function to sanitize strings for SQL insertion
local function sanitizeString(str)
if type(str) ~= "string" then
return tostring(str)
end

-- Remove emoji sequences
str = str:gsub("\\u%x%x%x%x\\u%x%x%x%x", "")
-- Remove single Unicode emoji characters
str = str:gsub("[\xF0-\xF7][\x80-\xBF][\x80-\xBF][\x80-\xBF]", "")

return str:gsub("'", "''")
          :gsub("\\", "\\\\")
          :gsub("\n", "\\n")
          :gsub("\r", "\\r")
          :gsub("\000", "\\0")
end

-- Function to parse JSON response to formatted HTML
local function parseJsonToHtml(json)
local html = ""
for message in json:gmatch("{.-}") do
local content = message:match('"content":"(.-)"') or ""
content = content:gsub("\"", "\""):gsub("\n", "\n")

-- Remove emoji sequences
    content = content:gsub("\\u%x%x%x%x\\u%x%x%x%x", "")
    -- Remove single Unicode emoji characters
    content = content:gsub("[\xF0-\xF7][\x80-\xBF][\x80-\xBF][\x80-\xBF]", "")
    
    if content ~= "" and content ~= "No content" then
        content = content:gsub("@", "")
                 :gsub("\n", "<br>")
                 :gsub("%*%*%*([^%*]+)%*%*%*", "<h3>%1</h3>")
                 :gsub("%*%*([^%*]+)%*%*", "<h4><b>%1</b></h4>")
                 :gsub("%*([^%*]+)%*", "<i>%1</i>")
                 :gsub("%[(.-)%]%(https?://[%w-_%.%?%.:/%+=&]+%)", '<a href="%2">%1</a>')
        
        html = html .. "<li><strong>Posted on " .. getCurrentDate() .. "</strong><br>" .. content .. "</li>"
    end
end
return html
end

-- Function to insert data into the database
local function insertIntoDatabase(headline, content)
if not id then
print("[News Bot]: Error - No valid ID to insert")
return false
end

local timestamp = os.time()
local number = math.random(100, 110)
local type_content = string.format('[\"%d.jpeg\"]', number)

local sanitized_headline = sanitizeString(headline)
local sanitized_content = sanitizeString(content)

local query = string.format([[
    INSERT IGNORE INTO articles 
    (id, timestamp, author_id, comments, type, type_content, headline, content)
    VALUES 
    (%d, %d, 4, -1, 1, '%s', '%s', '%s');
]], id, timestamp, type_content, sanitized_headline, sanitized_content)

local success, error_message = pcall(function()
    AuthDBExecute(query)
end)

if not success then
    print("[News Bot]: Database insertion failed. Error: " .. tostring(error_message))
    return false
end

print("[News Bot]: Successfully inserted article with ID: " .. tostring(id))
id = nil
return true
end

-- Function to fetch the most recent message and convert to HTML
local function fetchAndConvertToHtml()
print("[News Bot]: Checking for news...")
HttpRequest("GET", url, headers, function(status, body, headers)
if status == 200 then
id = math.ceil(tonumber(body:match(',"id":"(%d+)"')) / 100000000000)

if not id then
            print("[News Bot]: Error - No message ID!")
            return
        end
        
        print("[News Bot]: Message ID OK: " .. id)
    
        local html = parseJsonToHtml(body)
        
        local headline = string.format('{"english":"Announcement %s","persian":"","portuguese-brazilian":"","spanish":""}', getCurrentDate())
        local content = html:gsub("<li><strong>Posted on .-</strong><br>", ""):gsub("</li>", "")
        
        if insertIntoDatabase(headline, content) then
            print("[News Bot]: Successfully processed and inserted new announcement.")
        else
            print("[News Bot]: Failed to insert new announcement into database.")
        end
    else
        print("[News Bot]: Failed to fetch message. Status code: " .. status)
    end
end)
end

CreateLuaEvent(fetchAndConvertToHtml, 5000, 1) -- Run on reload eluna/server startup

-- Trigger syncing to external website table (MySQL trigger)
--[[
CREATE TRIGGER after_article_insert
AFTER INSERT ON acore_auth.articles
FOR EACH ROW
BEGIN
INSERT INTO fusioncms.articles
SELECT * FROM acore_auth.articles
WHERE id = NEW.id;
END
]]