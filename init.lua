local load_time_start = os.clock()
local modname = minetest.get_current_modname()


local modstorage = minetest.get_mod_storage()

local prefix = "worldname: "
local no_name = "no worldname"

if INIT == "client" then
	worldname = {}

	local world_name
	function worldname.get()
		return world_name
	end

	local funcs = {}
	function worldname.register_on_get(f)
		funcs[#funcs+1] = f
	end

	csm_com.register_on_receive(function(msg)
		if world_name ~= nil then -- The worldname shall only be set once.
			return
		elseif msg == no_name then
			local new_num = modstorage:get_int("next_name")
			world_name = tostring(new_num)
			csm_com.send(prefix..world_name)
			modstorage:set_int("next_name", new_num + 1)
		elseif msg:sub(1, #prefix) ~= prefix then
			return
		else
			world_name = msg:sub(#prefix+1)
		end
		for i = 1, #funcs do
			funcs[i]()
		end
		return true
	end)

	minetest.register_chatcommand("worldname", {
		params = "",
		description = "Get the current worldname.",
		func = function()
			return true, worldname.get() or no_name
		end,
	})

elseif INIT == "game" then
	csm_com.register_on_know(function(player_name)
		local msg = modstorage:get_string(player_name)
		if msg == "" then
			msg = no_name
		else
			msg = prefix..msg
		end
		csm_com.send(player_name, msg)
	end)
	csm_com.register_on_receive(function(player_name, msg)
		if msg:sub(1, #prefix) ~= prefix then
			return
		end
		modstorage:set_string(player_name, msg:sub(#prefix+1, -1))
		return true
	end)

else
	print(modname.." is not made for such a use!")
end


local time = math.floor(tonumber(os.clock()-load_time_start)*100+0.5)/100
local msg = "["..modname.."] loaded after ca. "..time
if time > 0.05 then
	print(msg)
else
	minetest.log("info", msg)
end
