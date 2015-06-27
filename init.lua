local broomstick_time = 120 -- Seconds (for default 2 minutes)
local broomstick_mana = 210
local broomstick_actual_users = {}
local had_fly_privilege = {}
local privs = {}

-- Remove fly to old users of broomstick
users_file = io.open(minetest.get_modpath(minetest.get_current_modname()).."/broomstick_users.txt", "r")
if users_file then
	local string = users_file:read()
	if string ~= nil then
		broomstick_actual_users = minetest.deserialize(string)
		for _, i in ipairs(broomstick_actual_users) do
			privs = minetest.get_player_privs(i.name)
			privs.fly = nil
			minetest.set_player_privs(i.name, privs)
		end
	end
	io.close(users_file)
else
	minetest.log("error", "[broomstick] Can not open broomstick_users.txt file !")
end

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
				-- Rewrite the broomstick_users.txt file.
				users_file = io.open(minetest.get_modpath(minetest.get_current_modname()).."/broomstick_users.txt", "w")
				if users_file then
					users_file:write(minetest.serialize(broomstick_actual_users))
					io.close(users_file)
				end
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
			users_file = io.open(minetest.get_modpath(minetest.get_current_modname()).."/broomstick_users.txt", "w")
			if users_file then
				users_file:write(minetest.serialize(broomstick_actual_users))
				io.close(users_file)
			end
		end
	end
end)

-- Craft
minetest.register_craft({
	output = "broomstick:broomstick",
	recipe = {{"default:stick","default:stick","farming:wheat",}},
})


minetest.log("info", "[OK] broomstick")
