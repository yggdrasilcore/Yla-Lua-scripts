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

-- Function to extract and format the first image URL from attachments
local function extractFirstImageUrlFromAttachments(attachments)
    -- Match the URL enclosed in double quotes and ending with .png, .jpg, or .jpeg
    local imageUrl = attachments:match('"url":"(https?://[%w-_%.%?%.:/%+=&]+%.(png|jpg|jpeg))"')
    if imageUrl then
        return '<img src="' .. imageUrl .. '" alt="Image" style="max-width: 500px; max-height: 500px;">'
    end
    return ""
end

-- Function to convert JSON response to formatted HTML
local function parseJsonToHtml(json)
    -- Initialize HTML content
	local html = ""

    -- Extract each message
    for message in json:gmatch("{.-}") do
        local content = message:match('"content":"(.-)"') or ""
        local attachments = message:match('"attachments":%[(.-)%]')
        local embeds = message:match('"embeds":%[(.-)%]')

        -- Skip empty content or "No content"
        if content ~= "" and content ~= "No content" then
            -- Remove all @ mentions
            content = content:gsub("@", "")
            
            -- Replace newlines with <br>
            content = content:gsub("\\n", "<br>")
            
            -- Replace *** text with <h3>
            content = content:gsub("%*%*%*([^%*]+)%*%*%*", "<h3>%1</h3>")
            
            -- Replace ** text with <h2>
            content = content:gsub("%*%*([^%*]+)%*%*", "<br><h4><b>%1</b></h4>")
            
            -- Replace * text with <i>
            content = content:gsub("%*([^%*]+)%*", "%1")
            
            -- Replace all URLs with HTML anchor tags
            content = content:gsub("%[(.-)%]%((https?://[%w-_%.%?%.:/%+=&]+)%)", '<a href="%2">%1</a>')
            
            -- Remove everything after the second </strong>
            local endStrongCount = 0
            content = content:gsub("</strong>", function()
                endStrongCount = endStrongCount + 1
                if endStrongCount >= 2 then
                    return ""  -- Remove additional </strong> tags
                else
                    return "</strong>"
                end
            end)
            
            -- Append message to HTML with the first image if present
            html = html .. "<li><strong>Posted on " .. getCurrentDate() .. "</strong><br>" .. content .. "</li>"
        end
    end
    
    html = html .. ""
    return html
end

-- Function to insert data into the database
local function insertIntoDatabase(headline, content)
    local timestamp = os.time()  -- Current UNIX time for timestamp

    -- Generate a random number between 100 and 110
    local number = math.random(100, 110)
    local type_content = string.format('[\"%d.jpeg\"]', number)

    local query = string.format([[
        INSERT INTO articles (id, timestamp, author_id, comments, type, type_content, headline, content)
        VALUES (%d, %d, 4, -1, 1, '%s', '%s', '%s');
    ]], id, timestamp, type_content, headline:gsub("'", "''"), content:gsub("'", "''"))

    -- Execute the query
    AuthDBExecute(query)
    id = nil
end

-- Updated function to fetch the most recent message and convert to HTML
local function fetchAndConvertToHtml()
    HttpRequest("GET", url, headers, function(status, body, headers)
        if status == 200 then
            -- Use match to get a single ID value
            id = math.ceil(tonumber(body:match(',"id":"(%d+)"')) / 100000000000)
            
            if id then
                print("ID OK: " .. id)
            else    
                print("NO ID!")
            end
        
            local html = parseJsonToHtml(body)
            
            -- Extract the headline and content
            local headline = '{"english":"Announcement ' .. getCurrentDate() .. '"}'
            local content = html:gsub("<li><strong>Posted on .-</strong><br>", ""):gsub("</li>", "")
            
            -- Insert into the database
            insertIntoDatabase(headline, content)
            
            -- Print HTML (Optional)
            print(html)
        else
            print("Failed to fetch message. Status code: " .. status)
        end
    end)
end

CreateLuaEvent(fetchAndConvertToHtml, 43200000, 0) -- Runs every 6 hrs


--Trigger syncing to external website table
--CREATE TRIGGER after_article_insert
--AFTER INSERT ON acore_auth.articles
--FOR EACH ROW
--BEGIN
    --INSERT INTO fusioncms.articles
    --SELECT * FROM acore_auth.articles
    --WHERE id = NEW.id;
--END