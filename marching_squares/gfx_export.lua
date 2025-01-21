

local image = app.image

local s = ""
local i = 0

for px in image:pixels() do
  local v = px()
  
  if v < 10 then
    s = s .. string.char(48 + v)
  elseif v < 16 then
    s = s .. string.char(97 + v - 10)
  end
  
  i = i + 1
  if i == 128 then
    i = i - 128
    s = s .. '\n'
  end
end

print(s)
