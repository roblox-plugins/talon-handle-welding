--[[

	Handle Weld by Ozzypig
	1/31/12

--> Instructions:

1) Select a bunch of bricks with one named "Handle".
2) Press the Tool-Weld or Tool-Weld-Script button.
3) The object will be welded together.
   If you press the Tool-Weld-Script button, the object will
   automatically be re-welded should the model change parent.
   This allows for the model to not fall apart when in a tool!

--> How does it work?

It creates a WeldProfile which is a list of bricks that are
welded to the handle and the welds' C0 and C1 values. If the welds break
(ie, when the tool changes parent) the old welds are destroyed and new
welds are made from scratch using the original C0 and C1 values used to
weld the tool in the first place.

--> What scripts are made?

Two of the same kinds of scripts are made. They do what is explained above.
One is local and one is online. This prevents tool breakage betwee pings.

]]

manager = PluginManager()
plugin = manager:CreatePlugin()
toolbar = plugin:CreateToolbar("Handle Weld")
button = toolbar:CreateButton("", "Select some bricks with one named \"Handle\" and all the bricks will be welded to the Handle.", "icon.png")
button2 = toolbar:CreateButton("", "Select some bricks with one named \"Handle\" and all the bricks will be welded to the Handle. A weld profile will be created and a script to re-weld the bricks for use in Tools.", "icon2.png")

--note:
serv = setmetatable({}, {__index = function (serv, key) if not rawget(serv,key) then serv[key] = game:GetService(key) end return rawget(serv,key) end})
selection = serv.Selection
insert = serv.InsertService

weld_script = [[
tool = script.Parent
while not tool:FindFirstChild("WeldProfile") do wait() end
profile = tool.WeldProfile
function reweld()
	wait()
	for k, v in pairs(tool.Handle:GetChildren()) do
		if v:IsA("JointInstance") then
			v:Destroy()
		end
	end
	--print("Reweld")
	local parts = {}
	local function s(m)
		for k, v in pairs(m:GetChildren()) do
			if v:IsA("BasePart") then
				parts[v] = v
			end
			s(v)
		end
	end
	s(tool)
	for k, v in pairs(profile:GetChildren()) do
		if parts[v.Value] then
			local b = v.Value
			local w = Instance.new("ManualWeld")
			w.Name = "HandleWeld"
			w.Part0 = tool.Handle
			w.Part1 = b
			w.C0 = v.C0.Value
			w.C1 = v.C1.Value
			w.Parent = tool.Handle
		end
	end
end
tool.AncestryChanged:connect(reweld)
reweld()
]]

function weldProfile(tool, welds)
	local profile = Instance.new("IntValue", tool)
	profile.Name = "WeldProfile"
	for k, v in pairs(welds) do
		local b = Instance.new("ObjectValue", profile)
		b.Value = v.Part1
		b.Name = "Profile" .. k
		local c0 = Instance.new("CFrameValue", b)
		c0.Name = "C0"
		c0.Value = v.C0
		local c1 = Instance.new("CFrameValue", b)
		c1.Name = "C1"
		c1.Value = v.C1
	end
	local s = Instance.new("Script")
	s.Source = weld_script
	s.Disabled = false
	s.Archivable = true
	s.Parent = tool
	s.Name = "Weld"
	local s = Instance.new("LocalScript")
	s.Source = weld_script
	s.Disabled = false
	s.Archivable = true
	s.Parent = tool
	s.Name = "WeldBackup"
end

function weld(x, y)
	if x == y then return end
	local CJ = CFrame.new(x.Position)
	local w = Instance.new("ManualWeld")
	w.Name = "HandleWeld"
	w.Part0 = x
	w.Part1 = y
	w.C0 = x.CFrame:inverse() * CJ
	w.C1 = y.CFrame:inverse() * CJ
	w.Parent = x
	return w
end

button.Click:connect(function ()
	local parts, handle
	parts = {}
	for k, v in pairs(selection:Get()) do
		if v.Name ~= "Handle" then
			table.insert(parts, v)
		else
			handle = v
		end
	end
	if handle then
		for k, v in pairs(parts) do
			weld(v, handle)
		end
		print("Welded " .. #parts .. " part" .. (#parts == 1 and "" or "s"))
	else
		print("No brick named \"Handle\"!")
	end
end)

button2.Click:connect(function ()
	local parts, handle
	parts = {}
	for k, v in pairs(selection:Get()) do
		if v.Name ~= "Handle" then
			table.insert(parts, v)
		else
			handle = v
		end
	end
	if handle then
		local welds = {}
		for k, v in pairs(parts) do
			table.insert(welds, weld(handle, v))
		end
		print("Welded " .. #parts .. " part" .. (#parts == 1 and "" or "s"))
		if #welds > 0 then
			weldProfile(handle.Parent, welds)
		end
	else
		print("No brick named \"Handle\"!")
	end
end)
