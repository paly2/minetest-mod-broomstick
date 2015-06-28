local broomstick_time = 120 -- Seconds (for default 2 minutes)
local broomstick_mana = 50
local broomstick_actual_users = {}
local had_fly_privilege = {}
local privs = {}

-- broomstick file
users_file = minetest.get_worldpath() .. "/broomstick_users.txt"
--load broomstick  file 
local file = io.open(users_file, "r")
if file then
	had_fly_privilege = minetest.deserialize(file:read("*all"))
	file:close()
	file = nil
	if not had_fly_privilege or type(had_fly_privilege) ~= "table" then
		had_fly_privilege = {}
	end
else
	minetest.log("error", "[broomstick] Can not open broomstick_users.txt file !")
end


-- funtion save broomstick  file
local function save()
	local input = io.open(users_file, "w")
	if input then
		input:write(minetest.serialize(had_fly_privilege))
		input:close()
	else
		minetest.log("error","[broomstick] Open failed (mode:w) of " .. users_file)
	end
end

-- on join_player remove priv fly
minetest.register_on_joinplayer(function(player)
	local playername = player:get_player_name()
	if had_fly_privilege[playername] ~= nil then
		privs = minetest.get_player_privs(playername)
		privs.fly = nil
		minetest.set_player_privs(playername, privs)
		had_fly_privilege[playername] = nil
		save()
	end
end)


-- Register broomstick
minetest.register_craftitem("broomstick:broomstick", {
	description = "Broomstick",
	inventory_image = "broomstick.png",
	stack_max = 1,
	on_use = function(itemstack, user, pointed_thing)
		local playername = user:get_player_name()
		if mana.get(playername) >= broomstick_mana then
			local has_already_a_broomstick = false
			for _, i in ipairs(broomstick_actual_users) do
				if i.name == playername then
					has_already_a_broomstick = true
				end
			end
			if not has_already_a_broomstick then
				privs = minetest.get_player_privs(playername)
				-- Set player privs...
				if not privs.fly == true then
					-- Rewrite the broomstick_users.txt file.
					had_fly_privilege[playername] = true
					save()
					privs.fly = true
					minetest.set_player_privs(playername, privs)
				else
					minetest.chat_send_player(playername, "You known you can fly by yourself, don't you?")
					return
				end
				-- Send a message...
				minetest.chat_send_player(playername, "You can now fly during " .. tostring(broomstick_time) .. " seconds.")
				minetest.log("action", "Player " .. playername .. " has use a broomstick.")
				-- Subtract mana...
				mana.subtract(playername, broomstick_mana)
				-- Insert player in the list.
				table.insert(broomstick_actual_users, {
					name = playername,
					time = 0,
					is_warning_said = false
				})
				-- Remove broomstick.
				return ItemStack("")
			else
				minetest.chat_send_player(playername, "You already have a broomstick ! Please wait until the end of your actual broomstick.")
			end
		else
			minetest.chat_send_player(playername, "You must have " .. tostring(broomstick_mana) .. " of mana to use a broomstick !")
		end
	end,
})

-- Broomstick timer
minetest.register_globalstep(function(dtime)
	for index, i in ipairs(broomstick_actual_users) do
		i.time = i.time + dtime
		-- Just a little warning message
		if i.time >= broomstick_time - 10 and not i.is_warning_said then
			minetest.chat_send_player(i.name, "WARNING ! You'll fall in 10 seconds !")
			i.is_warning_said = true
		elseif i.time >= broomstick_time then
			-- Send a message...
			minetest.chat_send_player(i.name, "End of broomstick. I hope you're not falling down...")
			-- Set player privs...
			privs = minetest.get_player_privs(i.name)
			privs["fly"] = nil
			minetest.set_player_privs(i.name, privs)
			-- Remove the player in the list.
			table.remove(broomstick_actual_users, index)
			-- Rewrite the broomstick_users.txt file.
			had_fly_privilege[i.name] = nil
			save()
		end
	end
end)

-- Craft
minetest.register_craft({
	output = "broomstick:broomstick",
	recipe = {{"default:stick","default:stick","farming:wheat",}},
})


minetest.log("info", "[OK] broomstick")
