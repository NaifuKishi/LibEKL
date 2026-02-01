local addonInfo, privateVars = ...

---------- init namespace ---------

if not LibEKL then LibEKL = {} end
if not LibEKL.Tools then LibEKL.Tools = {} end
if not LibEKL.Tools.Gfx then LibEKL.Tools.Gfx = {} end

function LibEKL.Tools.Gfx.Rotate(frame, angle, scale)

  local midx = frame:GetHeight() / 2
  local midy = frame:GetWidth() / 2
  local m = Libs.Transform2:new()
  
  m:Translate(midx,midy)
  m:Rotate(angle)
  m:Translate(-midx,-midy)
  if scale then m:Scale(scale, scale) end
  
  return m
  
end

function LibEKL.Tools.Gfx.Scale(frame, scale)

  local midx = frame:GetHeight() / 2
  local midy = frame:GetWidth() / 2
  local m = Libs.Transform2:new()
  
  m:Translate(midx,midy)
  --m:Rotate(angle)  
  if scale then m:Scale(scale, scale) end
  m:Translate(-midx,-midy)
  
  return m
  
end