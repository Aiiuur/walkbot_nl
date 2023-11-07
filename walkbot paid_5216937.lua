_DEBUG = true
local paid = true
local stuff = require("neverlose/stuff")
local cfg = require("neverlose/cfg")

--мне лень писать постоянно main.zalupa.blablabla.nodes поэтому пускай будет так
local selected_node = nil
local nodes = { }
local path = { }
local open_list = { }
local closed_list = { }
local came_from = { }
local path = { }
local path_found = false
local g_score, f_score = {}, {}
local start = nil
local target = nil

local tester_open_list = { }
local tester_closed_list = { }

local node_time_limit_temp = 0
local node_time_limit = 2

local spawn_delay = 0

local generator_open_list = { }
local generator_closed_list = { }

local hitchance_t = { }
local g_hitchance = 0

local groups = {
	main = ui.create("Main", "Main"),
	aimbot = ui.create("Main", "Aimbot"),
	lobby = ui.create("Main", "Lobby"),
	render = ui.create("Render", "Main"),
	render_nodes = ui.create("Render", "Nodes"),
	map_main = ui.create("Map", "Main"),
	map_editor = ui.create("Map", "Editor"),
	map_bind = ui.create("Map", "Binds"),
	map_cfg = ui.create("Map", "Config")
}

local main = {
	info = {
		sc = render.screen_size(),
		username = common.get_username(),
		mouse_pos = ui.get_mouse_position(),
		player = nil,
		weap = nil,
		can_shoot = false,
		game_rules = nil,
		player_flags = { },
		state = 1,
		menu_state = false
	},
	trash = {
		conditionals = { },
		conditionals_combo = { },
		fun_render = { },
		fun_createmove = { },
		already_drag_drop = nil,
		weapon_select_pos = vector(0, 0),
		hp_bar_pos = vector(0, 0),
		weapon_clip = vector(0, 0),
		roundtime_pos = vector(0, 0)
	},
	menu_items = {
		main = {
			master = groups.main:switch("Enable Walkbot"),
			auto_stop = groups.main:switch("Auto Stop"),
			follow_team = groups.main:switch("Allow to follow teammate"),
			bomb_defuse = groups.main:switch("Auto bomb defuse")
		},
		aimbot = {
			master = groups.aimbot:switch("Enable Aimbot"),
			aim_node = groups.aimbot:switch("Aim At Node"),
			autowall = groups.aimbot:switch("Penetrate Walls"),
			auto_fire = groups.aimbot:switch("Automatic Fire"),
			smooth = groups.aimbot:slider("Smooth", 1, 100, 10),
			hitchance = groups.aimbot:slider("Hitchance", 0, 100, 60),
			mindamage = groups.aimbot:slider("Min Damage", 0, 100, 30),
			max_fov = groups.aimbot:slider("Fov", 0, 180, 90),
			prefer_body_aim = groups.aimbot:switch("Prefer Body Aim"),
			hitgroup = groups.aimbot:selectable("HitGroup", {"Head", "Body"})
		},
		lobby = {
			auto_queue = groups.lobby:switch("Enable Auto Queue"),
			auto_disconnect = groups.lobby:switch("Enable Auto Disconnect")
		},
		render = {
			debug_info = groups.render:switch("Debug Info"),
			nodes = groups.render_nodes:switch("Render Nodes"),
			connections = groups.render_nodes:switch("Render Connections (fps ripper)"),
			more_info = groups.render_nodes:switch("Info About Nodes"),
			hitchance = groups.render:switch("Hitchance Visualizer"),
			distance = groups.render_nodes:slider("Render Distance", 100, 5000, 1000)
		},
		map_main = {
			allow_remove_nodes = groups.map_main:switch("Allow Remove Nodes"),
			map_generator = groups.map_main:switch("Map Generator \a"..color(255,0,0):to_hex().." ( ".. ui.get_icon("triangle-exclamation").." game freeze )"),
			auto_map_generator = groups.map_main:switch("Automatic Map Generator"),
			neighbors_indent = groups.map_main:slider("Neighbors Distance", 20, 300, 100),
			map_tester = groups.map_main:switch("Map Tester"),
			indent = groups.map_main:slider("generator_indent", 20, 200, 70)
		},
		map_editor = {
			master = groups.map_editor:switch("Enable Editor"),
			select_node = groups.map_editor:hotkey("Select Node"),
			add_node = groups.map_editor:hotkey("Add Node"),
			remove_node = groups.map_editor:hotkey("Remove Node"),
			connect_node = groups.map_editor:hotkey("Connect Node"),
			disconnect_node = groups.map_editor:hotkey("Disconnect Node"),
			text = groups.map_editor:label("Selected node: " .. tostring(selected_node)),
			flags = groups.map_editor:selectable("Selected node flags", {"none"})
		},
		map_bind = {
			update_neighbors = groups.map_bind:switch("Update neighbors nodes"),
			reset_path = groups.map_bind:switch("Reset Path"),
			reset_map = groups.map_bind:switch("Reset Map")
		},
		map_cfg = {
			auto_load_cfg = groups.map_cfg:switch("Automatic Map Load"),
			prefer_local_cfg = groups.map_cfg:switch("Prefer local cfg")
		}
	},
	vars = {
		AA = {
			main = {
				master = ui.find("Aimbot", "Anti Aim", "Angles", "Enabled"),
				pitch = ui.find("Aimbot", "Anti Aim", "Angles", "Pitch"),
				yaw = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw"),
				base = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw", "Base"),
				yaw_offset = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw", "Offset"),
				yaw_modifier = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw Modifier"),
				yaw_freestanding = ui.find("Aimbot", "Anti Aim", "Angles", "Freestanding"),
				modifier_offset = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw Modifier", "Offset")
			},
			fake_angle = {
				body_yaw = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw"),
				inverter = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Inverter"),
				left_limit = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Left Limit"),
				right_limit = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Right Limit"),
				options = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Options"),
				freestanding = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Freestanding"),
			},
			fake_lag = {
				master = ui.find("Aimbot", "Anti Aim", "Fake Lag", "Enabled"),
				limit =  ui.find("Aimbot", "Anti Aim", "Fake Lag", "Limit"),
				randomization = ui.find("Aimbot", "Anti Aim", "Fake Lag", "Variability")
			},
			misc = {
				slow_walk = ui.find("Aimbot", "Anti Aim", "Misc", "Slow Walk"),
				leg_movement = ui.find("Aimbot", "Anti Aim", "Misc", "Leg Movement"),
				fake_duck = ui.find("Aimbot", "Anti Aim", "Misc", "Fake Duck")
			}
		},
		rage = {
			exploits = {
				double_tap = ui.find("Aimbot", "Ragebot", "Main", "Double Tap"),
				lag_options = ui.find("Aimbot", "Ragebot", "Main", "Double Tap", "Lag Options"),
				hide_shots = ui.find("Aimbot", "Ragebot", "Main", "Hide Shots")
			},
			selection = {
				hitchance = ui.find("Aimbot", "Ragebot", "Selection", "Hit Chance")
			}
		},
		visuals = {
			remove_scope = ui.find("Visuals", "World", "Main", "Override Zoom", "Scope Overlay"),
			windows = ui.find("Miscellaneous", "Main", "Other", "Windows")
		},
		misc = {
			auto_peek = ui.find("Aimbot", "Ragebot", "Main", "Peek Assist")
		}
	}
}
-- local gamemode = "deathmatch"
-- local gametype = "gungame"
-- local map = "mg_dust247"
groups.auto_queue = main.menu_items.lobby.auto_queue:create()
main.menu_items.lobby.gamemode = groups.auto_queue:combo("gamemode", {"test"})
main.menu_items.lobby.gametype = groups.auto_queue:combo("gametype", {"test"})
main.menu_items.lobby.map = groups.auto_queue:combo("map", {"test"})

main.menu_items.main.bomb_defuse:tooltip("If detecting planted bomb, walking to bomb and trying to defuse bomb")
main.menu_items.map_main.map_tester:tooltip("creates list of not checked nodes, and walking to all nodes and checking is can walk to node or not")
main.menu_items.map_main.auto_map_generator:tooltip("Automatically turns on \"map generation\", if there is no map")
main.menu_items.map_bind.update_neighbors:tooltip("Use only if you using map generator")
main.menu_items.map_main.allow_remove_nodes:tooltip("Allows the bot to remove nodes, if cant walk to node")
main.menu_items.map_main.neighbors_indent:tooltip("Distance limit for automatic of connections for nodes")

if common.get_username() ~= "Aiiuur" then
	main.menu_items.map_main.indent:visibility(false)
end

--main.menu_items.aimbot.master:visibility(false)
for i=1, 3 do
	main.trash.fun_render[i] = { }
	main.trash.fun_createmove[i] = { }
end
files.create_folder("nl/walkbot_by_aiiuur")

-- files.read(path)
-- files.write(path, stuff.enc(data), false)

function clamp_angles(angles)
	if (angles.y > 180) then angles.y = angles.y - 360 end
	if (angles.y < -180) then angles.y = angles.y + 360 end
	return angles
end

function save_map_local()
	local t_to_save = { }
	for k,v in pairs(nodes) do
		table.insert(t_to_save, {
			id = v.id,
			x = v.pos.x,
			y = v.pos.y,
			z = v.pos.z,
			neighbors = v.neighbors,
			flags = v.flags
		})
	end

	local out = json.stringify(t_to_save)
	local map_data = common.get_map_data()
	if map_data ~= nil then
		local path = "nl/walkbot_by_aiiuur/" .. map_data.shortname:gsub("%.", ""):gsub("\\",""):gsub("/","") .. ".json"
		files.write(path, out, false)
	end
	reset_path()
end

function load_map_local()
	local map_data = common.get_map_data()
	if map_data ~= nil then
		local path = "nl/walkbot_by_aiiuur/" .. map_data.shortname:gsub("%.", ""):gsub("\\",""):gsub("/","") .. ".json"
		local response = files.read(path)
		if response == nil then
			common.add_notify("Walkbot", "Can't find local cfg for this map")
			return
		end
		local data = json.parse(response)
		nodes = { }
		for k,v in pairs(data) do
			if v.flags == nil or v.flags.duck == nil or v.flags.avoid_jumping == nil then v.flags = {duck = false, avoid_jumping = false} end
			table.insert(nodes, {
				id = v.id,
				pos = vector(v.x, v.y, v.z),
				color = color(255),
				color2 = color(255),
				neighbors = v.neighbors,
				flags = v.flags
			})
		end
	end
	common.add_notify("Walkbot", "Local Config Loaded")
	reset_path()
end
main.menu_items.main.text = groups.map_cfg:label("local:")
main.menu_items.main.load_map_local = groups.map_cfg:button("load_map", load_map_local)
main.menu_items.main.save_map_local = groups.map_cfg:button("save_map", save_map_local)


function save_map()
	local t_to_save = { }
	for k,v in pairs(nodes) do
		table.insert(t_to_save, {
			id = v.id,
			x = v.pos.x,
			y = v.pos.y,
			z = v.pos.z,
			neighbors = v.neighbors,
			flags = v.flags
		})
	end

	local out = json.stringify(t_to_save)
	local map_data = common.get_map_data()
	if map_data ~= nil then
		local url = "https://niggerhook.su/walkbot_nl/index.php?config_name=" .. map_data.shortname:gsub("%.", ""):gsub("\\",""):gsub("/","") .. "&save"
		local response = network.post(url, "data="..out)
	end
	reset_path()
end

function load_map()
	local map_data = common.get_map_data()
	if map_data ~= nil then
		local url = "https://niggerhook.su/walkbot_nl/index.php?config_name=" .. map_data.shortname:gsub("%.", ""):gsub("\\",""):gsub("/","") .. "&load"
		local response = network.get(url)
		if response == "error" then
			common.add_notify("Walkbot", "Can't find cloud cfg for this map")
			return
		end
		local data = json.parse(response)
		nodes = { }
		for k,v in pairs(data) do
			if v.flags == nil or v.flags.duck == nil or v.flags.avoid_jumping == nil then v.flags = {duck = false, avoid_jumping = false} end
			table.insert(nodes, {
				id = v.id,
				pos = vector(v.x, v.y, v.z),
				color = color(255),
				color2 = color(255),
				neighbors = v.neighbors,
				flags = v.flags
			})
		end
	end
	common.add_notify("Walkbot", "Cloud Config Loaded")
	reset_path()
end
main.menu_items.main.text2 = groups.map_cfg:label("cloud:")

main.menu_items.main.load_map = groups.map_cfg:button("load_map", load_map)

if common.get_username() == "Aiiuur" then
	main.menu_items.main.save_map = groups.map_cfg:button("save_map", save_map)
end

function has_value2(tab, val)
	for index, value in pairs(tab) do
		if value.id == val then
			return true
		end
	end
	return false
end

function get_node(node_id)
	for k,v in pairs(nodes) do
		if node_id == v.id then
			return v
		end
	end
	return nil
end

function nearest_node(entity, tab)
	local entity_origin = entity:get_origin()
	if tab == nil then
		tab = nodes
	end

	local best_dist, best_node = 999999, nil
	for k,v in pairs(tab) do
		local dist = entity_origin:dist(v.pos)
		if dist < best_dist then
			best_dist, best_node = dist, v
		end
	end
	return best_node
end

function create_node(pos)
	if main.info.state ~= 3 then return end
	if pos == nil then pos = main.info.player:get_origin() end
	for i=1, #nodes+1 do
		if get_node(i) == nil then
			table.insert(nodes, {
				id = i,
				pos = pos,
				color = color(255),
				color2 = color(255),
				neighbors = { },
				flags = {duck = false, avoid_jumping = false}
			})
			break
		end
	end
	reset_path()
end


function remove_node(t, cur)
	for k, v in pairs(t) do
		if v.id == cur.id then
			table.remove(t, k)
		end
	end
end

function remove_dis_node(t)
	if not main.menu_items.map_main.allow_remove_nodes:get() then reset_path(); return end
	common.add_notify("Walkbot", "Node Deleted\nid: " .. t.id)

	for k,v in pairs(t.neighbors) do
		local neighbor_node = get_node(v)
		for k2,v2 in pairs(neighbor_node.neighbors) do
			if t.id == v2 then
				table.remove(neighbor_node.neighbors, k2)
			end
		end
	end

	remove_node(nodes, t)
	remove_node(tester_open_list, t)
	remove_node(tester_closed_list, t)

	update_neighbors(false)
	reset_path()
end

function update_neighbors(full_reset)
	for k,v in pairs(nodes) do
		if full_reset then v.neighbors = { } end
		if #v.neighbors < 1 then
			for k2,v2 in pairs(nodes) do
				if v.id ~= v2.id and v.pos:dist(v2.pos) < main.menu_items.map_main.neighbors_indent:get() and math.abs(v.pos.z - v2.pos.z) < 40 then
					table.insert(v.neighbors, v2.id)
				end
			end
		end
	end
end

function reset_path()
	if #nodes < 1 then return end
	for k,v in pairs(nodes) do
		v.color = color(255)
		v.color2 = color(255)
	end
	g_score = { }
	f_score = { }
	open_list = { }
	closed_list = { }
	came_from = { }
	path = { }
	start = nearest_node(main.info.player)
	start.color = color(0, 255, 0)

	-- if start.pos:dist(main.info.player:get_origin()) > 300 then
	-- 	nodes = {}
	-- 	return
	-- end

	local bomb_list = entity.get_entities("CPlantedC4", true)
	if selected_node ~= nil then
		target = get_node(selected_node)
		if target == nil then
			selected_node = nil
			reset_path()
			return
		end
	elseif main.menu_items.main.bomb_defuse:get() and #bomb_list > 0 and bomb_list[1].m_flC4Blow - globals.curtime > (main.info.player.m_bHasDefuser and 5 or 10) and not bomb_list[1].m_bBombDefused then
		target = nearest_node(bomb_list[1])
	elseif not main.menu_items.map_main.map_tester:get()  then
		local players = entity.get_players(true, true)
		local best_dist, best_player = 999999, nil
		local player_origin = main.info.player:get_origin()
		for k,v in pairs(players) do
			local dist = player_origin:dist(v:get_origin())
			if dist < best_dist and v:is_alive() and v:get_network_state() <= 3 then
				best_dist, best_player = dist, v
			end
		end

		if best_player ~= nil then
			target = nearest_node(best_player)
		else
			if main.menu_items.main.follow_team:get() then
				local players = entity.get_players(false, true)
				for k,v in pairs(players) do
					local dist = player_origin:dist(v:get_origin())
					if v ~= main.info.player and dist < best_dist and v:is_alive() and v:get_network_state() <= 3 then
						best_dist, best_player = dist, v
					end
				end
			end

			if best_player ~= nil then
				target = nearest_node(best_player)
			else
				target = nearest_node(main.info.player)
			end
		end

		tester_closed_list = { }
	else
		if #tester_open_list < 1 then
			tester_closed_list = { }
			tester_open_list = { }
			if main.menu_items.map_main.map_tester:get() then
				for k,v in pairs(nodes) do
					table.insert(tester_open_list, v)
				end
			end
			return
		end

		--if #nodes/2 > #tester_open_list then
		target = nearest_node(main.info.player, tester_open_list)
		-- else
		-- 	target = tester_open_list[math.random(1, #tester_open_list)]
		-- end

		if start.id == target.id then
			remove_node(tester_open_list, target)
			table.insert(tester_closed_list, target)
		end
	end
	target.color = color(255, 0, 0)
	table.insert(open_list, start)
	g_score[start.id] = 0
	f_score[start.id] = g_score[start.id] + start.pos:dist(target.pos)
	node_time_limit_temp = globals.curtime + node_time_limit
	path_found = false
end

function lowest_f_score()
	local lowest, best_node = 999999, nil
	for k,v in pairs(open_list) do
		local score = f_score[v.id]
		if score < lowest then
			lowest, best_node = score, v
		end
	end
	return best_node
end

local function unwind_path ( flat_path, map, current_node )
	if map[current_node.id] then
		table.insert ( flat_path, 1, map [ current_node.id ] ) 
		return unwind_path ( flat_path, map, map [ current_node.id ] )
	else
		return flat_path
	end
end

function create_fun(state, event, fun, menu_item, index)
	local value = nil
	if menu_item ~= nil then
		value = menu_item
	end
	if event == "render" then
		table.insert(main.trash.fun_render[state], {
			fun = fun,
			menu_item = value,
			index = index
		})
	elseif event == "createmove" then
		table.insert(main.trash.fun_createmove[state], {
			fun = fun,
			menu_item = value,
			index = index
		})
	end
end

function call()
	for t=1, main.info.state do
		for i=1, #main.trash.fun_render[t] do
			if main.trash.fun_render[t][i].menu_item == nil then
				main.trash.fun_render[t][i].fun()
			else
				if main.trash.fun_render[t][i].index ~= nil then
					if main.trash.fun_render[t][i].menu_item:get(main.trash.fun_render[t][i].index) then
						main.trash.fun_render[t][i].fun()
					end
				else
					if main.trash.fun_render[t][i].menu_item:get() then
						main.trash.fun_render[t][i].fun()
					end
				end
			end
		end
	end
end

function call_createmove(cmd)
	for t=1, main.info.state do
		for i=1, #main.trash.fun_createmove[t] do
			if main.trash.fun_createmove[t][i].menu_item == nil then
				main.trash.fun_createmove[t][i].fun(cmd)
			else
				if main.trash.fun_createmove[t][i].index ~= nil then
					if main.trash.fun_createmove[t][i].menu_item:get(main.trash.fun_createmove[t][i].index) then
						main.trash.fun_createmove[t][i].fun(cmd)
					end
				else 
					if main.trash.fun_createmove[t][i].menu_item:get() then
						main.trash.fun_createmove[t][i].fun(cmd)
					end
				end
			end
		end
	end
end

function rainbow(s, alpha, offset)
	if offset == nil then offset = 0 end
	local clr = color(255)
	return clr:as_hsv((globals.tickcount - offset) * s % 360 / 360, 1, 1, alpha/255)
end

function custom_sidebar()
	if not main.info.menu_state then return end
	local text = paid and "walkbot" or "walkbot (free)"
	local icon = "robot"
	local text_tmp = ""
	local grad = nil
	local clr = rainbow(1, 255, 0)
	local clr2 = rainbow(1, 255, 30)
	icon = "\a" .. (clr):to_hex() .. ui.get_icon(icon)
	grad = stuff.gradient(clr, clr2, text)
	-- icon = "\a" .. color(185, 215, 255, 255):to_hex() .. ui.get_icon(icon)
	-- grad = stuff.gradient(color(185, 215, 255, 255), color(244, 200, 250, 255), text)

	for i=1, #text do
		text_tmp = text_tmp .. "\a" .. grad[i]:to_hex() .. text:sub(i, i)
	end

	ui.sidebar(text_tmp, icon)
end
custom_sidebar()

function debug_info()
	local indent_y = 0
	local text_sz
	local text = {
		"state: " .. tostring(main.info.state),
		"player flags: ",
		"can_shoot: " .. tostring(main.info.can_shoot),
		"path_found: " .. tostring(path_found),
		"nodes_count: " .. tostring(#nodes),
		"path_nodes_count: " .. tostring(#path),
		"open_list: " .. tostring(#open_list),
		"closed_list: " .. tostring(#closed_list),
		"node_time_limit: " .. tostring(node_time_limit_temp - globals.curtime),
		"spawn_delay: " .. tostring(spawn_delay - globals.curtime),
		"generator_open_list: " .. tostring(#generator_open_list),
		"generator_closed_list: " .. tostring(#generator_closed_list),
		"tester_open_list: " .. tostring(#tester_open_list),
		"tester_closed_list: " .. tostring(#tester_closed_list),
		"hitchance: " .. tostring(g_hitchance)
	}

	for i=1, #main.info.player_flags do
		text[2] = text[2] .. main.info.player_flags[i] .. " "
	end

	for i=1, #text do
		text_sz = render.measure_text(3, nil, text[i])
		render.text(3, vector(0, indent_y), color(255), nil, text[i])
		indent_y = indent_y + text_sz.y
	end
end

local bind_press = 0
function render_editor()
	if selected_node ~= nil then
		if get_node(selected_node) == nil then selected_node = nil; return end
		main.menu_items.map_editor.text:name("Selected node id: " .. tostring(selected_node) .. "\nConnected nodes: " .. #get_node(selected_node).neighbors)
	end
	local camera_position = render.camera_position()
	local direction = vector():angles(render.camera_angles())

	local best_dist, best_node = math.huge
	for k,v in pairs(nodes) do
		local head_position = v.pos
		local ray_distance = head_position:dist_to_ray(camera_position, direction)
		if ray_distance < best_dist then
			best_dist = ray_distance
			best_node = v.id
		end
	end

	if best_dist > 30 then
		best_node = nil
	end
	
	-- local render_pos = render.world_to_screen(trace.end_pos)
	-- render.circle_outline(render_pos, color(0, 255, 255), 10 + stuff.bruh(1.5, 5, 0.75), 0, 1, 2)
	-- render.circle(render_pos, color(255), 5, 0, 1)

	if main.menu_items.map_editor.add_node:get() and bind_press == 0 then
		local trace = utils.trace_line(main.info.player:get_eye_position(), main.info.player:get_eye_position() + (vector():angles(render.camera_angles())*5000), main.info.player, nil, 0)
		create_node(trace.end_pos + vector(0,0,3))
		common.add_notify("Walkbot", "Created Node")
		bind_press = 1
	elseif not main.menu_items.map_editor.add_node:get() and bind_press == 1 then
		bind_press = 0
	end
	print(main.menu_items.map_editor.select_node:key())
	if main.menu_items.map_editor.select_node:get() and bind_press == 0 then
		if best_node ~= nil then
			local flags = {}
			for k,v in pairs(get_node(best_node).flags) do
				table.insert(flags, k)
				main.menu_items.map_editor.flags:update(flags)
			end
			flags = {}
			for k,v in pairs(main.menu_items.map_editor.flags:list()) do
				if get_node(best_node).flags[v] then
					table.insert(flags, v)
				end
			end
			main.menu_items.map_editor.flags:set(flags)
			if selected_node ~= best_node then
				selected_node = best_node
				common.add_notify("Walkbot", "Node selected\nid: " .. best_node)
			else
				selected_node = nil
				common.add_notify("Walkbot", "Node unselected")
			end
		else
			common.add_notify("Walkbot", "Failed to find node")
		end
		bind_press = 2
	elseif not main.menu_items.map_editor.select_node:get() and bind_press == 2 then
		bind_press = 0
	end

	if main.menu_items.map_editor.connect_node:get() and bind_press == 0 then
		if best_node ~= nil and selected_node ~= nil and best_node ~= selected_node then
			if not stuff.has_value(best_node, get_node(selected_node).neighbors) and not stuff.has_value(selected_node, get_node(best_node).neighbors) then
				common.add_notify("Walkbot", "Node connected\n" .. selected_node .. " to " .. best_node)
				table.insert(get_node(selected_node).neighbors, best_node)
				table.insert(get_node(best_node).neighbors, selected_node)
			else
				common.add_notify("Walkbot", "Already connected")
			end
		else
			common.add_notify("Walkbot", "Failed to find node")
		end
		bind_press = 3
	elseif not main.menu_items.map_editor.connect_node:get() and bind_press == 3 then
		bind_press = 0
	end

	if main.menu_items.map_editor.disconnect_node:get() and bind_press == 0 then
		if best_node ~= nil and selected_node ~= nil then
			local notify = 0
			for k,v in pairs(get_node(selected_node).neighbors) do
				if v == best_node then
					table.remove(get_node(selected_node).neighbors, k)
					notify = notify + 1
				end
			end
			
			for k,v in pairs(get_node(best_node).neighbors) do
				if v == selected_node then
					table.remove(get_node(best_node).neighbors, k)
					notify = notify + 1
				end
			end
			if notify >= 2 then
				common.add_notify("Walkbot", "Node disconnected\n" .. selected_node .. " from " .. best_node)
			else
				common.add_notify("Walkbot", "Node disconnect failed\nreason: not connected")
			end
		else
			common.add_notify("Walkbot", "Failed to find node")
		end
		bind_press = 4
	elseif not main.menu_items.map_editor.disconnect_node:get() and bind_press == 4 then
		bind_press = 0
	end

	if main.menu_items.map_editor.remove_node:get() and bind_press == 0 then
		if best_node ~= nil then
			common.add_notify("Walkbot", "Node Deleted\nid: " .. best_node)
			for k,v in pairs(get_node(best_node).neighbors) do
				local neighbor_node = get_node(v)
				for k2,v2 in pairs(neighbor_node.neighbors) do
					if best_node == v2 then
						table.remove(neighbor_node.neighbors, k2)
					end
				end
			end

			remove_node(nodes, get_node(best_node))
			reset_path()
		else
			common.add_notify("Walkbot", "Failed to find node")
		end
		bind_press = 5
	elseif not main.menu_items.map_editor.remove_node:get() and bind_press == 5 then
		bind_press = 0
	end
end

function render_nodes()
	if main.menu_items.map_bind.reset_path:get() then main.menu_items.map_bind.reset_path:set(false) end
	if main.menu_items.map_bind.reset_map:get() then main.menu_items.map_bind.reset_map:set(false) end
	if main.menu_items.map_bind.update_neighbors:get() then main.menu_items.map_bind.update_neighbors:set(false) end

	for k,v in pairs(generator_open_list) do
		local render_pos = render.world_to_screen(v)
		render.circle(render_pos, color(0, 255, 0), 5, 0, 1)
	end

	for k,v in pairs(generator_closed_list) do
		local render_pos = render.world_to_screen(v)
		render.circle(render_pos, color(255, 0, 0), 5, 0, 1)
	end

	if main.menu_items.render.hitchance:get() then
		for k,v in pairs(hitchance_t) do
			local world = render.world_to_screen(v)
			render.circle_gradient(world, color(255, 0), color(0, 255, 0, 150), 5, 0, 1)
		end
	end

	if #nodes < 1 then return end
	if main.menu_items.render.nodes:get() then
		local player_origin = main.info.player:get_origin()
		for k,v in pairs(nodes) do
			if player_origin:dist(v.pos) < main.menu_items.render.distance:get() then
				local render_pos = render.world_to_screen(v.pos)
				if render_pos ~= nil then
					if main.menu_items.render.connections:get() then
						for k2,v2 in pairs(v.neighbors) do
							local neighbor = get_node(v2)
							render.line(render_pos,	render.world_to_screen(neighbor.pos), v.id == selected_node and color(0,255,0,60 + stuff.bruh(1.5, 100, 0.75)) or color(255, 60))
						end
					end
					if main.menu_items.render.more_info:get() then
						render.text(3, render_pos + vector(5, 10), color(255), nil, v.id)
						render.text(3, render_pos + vector(5, 20), color(255), nil, json.stringify(v.neighbors))
						render.text(3, render_pos + vector(5, 30), color(255), nil, json.stringify(v.flags))
					end
					render.circle_outline(render_pos, v.id == selected_node and color(0, 255, 0) or v.color2, v.id == selected_node and 10 + stuff.bruh(1.5, 5, 0.75) or 10, 0, 1, 2)
					render.circle(render_pos, v.color, 5, 0, 1)
				end
			end
		end
	end

	if #path > 0 then
		local render_pos = render.world_to_screen(path[1].pos)
		render.line(render.world_to_screen(main.info.player:get_origin()), render_pos, color(255, 0, 0, 255))
	end

	local old_render_pos = vector(0,0)
	for k,v in pairs(path) do
		local render_pos = render.world_to_screen(v.pos)
		if k ~= 1 then
			render.line(render_pos,	old_render_pos, color(255, 0, 0, 255))
		end
		old_render_pos = render_pos
	end
end

events.render:set(function(ctx)
	main.info.menu_state = ui.get_alpha() > 0
	main.info.player = entity.get_local_player()
	main.info.game_rules = entity.get_game_rules()
	main.info.mouse_pos = ui.get_mouse_position()

	if not globals.is_connected then main.info.state = 1; call(); return end
	if not globals.is_in_game then main.info.state = 1; call(); return end

	if main.info.player == nil then main.info.state = 2; call(); return end
	main.info.weap = main.info.player:get_player_weapon(false)
	if main.info.weap == nil then main.info.state = 2; call(); return end
	if not main.info.player:is_alive() then main.info.state = 2; call(); return end
	main.info.state = 3
	call()
end)


function check_can_shoot()
	local weap = main.info.player:get_player_weapon(false)
	if main.info.game_rules.m_bFreezePeriod then return end
	if stuff.check_flag(main.info.player, stuff.flags.IsFrozen) then return end
	if main.info.player == nil or weap == nil or not weap:is_weapon() or not main.info.player:is_player() then return end
	if globals.curtime <= main.info.player.m_flNextAttack or globals.curtime <= weap.m_flNextPrimaryAttack then
		main.info.can_shoot = false
	else
		main.info.can_shoot = true
	end
end

function update_flags()
	main.info.player_flags = {}
	if stuff.check_flag(main.info.player, stuff.flags.OnGround) then
		table.insert(main.info.player_flags, "on_ground")
	end

	if stuff.get_speed(main.info.player) > 2 then
		table.insert(main.info.player_flags, "moving")
	end

	if stuff.check_flag(main.info.player, stuff.flags.IsDucking) then
		table.insert(main.info.player_flags, "is_ducking")
	end

	if main.info.player.m_bIsDefusing then
		table.insert(main.info.player_flags, "is_defusing")
	end

	if main.vars.AA.misc.slow_walk:get() then
		table.insert(main.info.player_flags, "slowwalk")
	end

	if common.is_button_down(0x45) then
		table.insert(main.info.player_flags, "use")
	end
end

function move_to_pos(cmd, pos, speed) 
	--local angles = main.info.player:get_angles()
	--print(angles.y, " | ", main.info.player:get_anim_state().abs_yaw, " | ", main.info.player:get_anim_state().abs_yaw_last, " | ", main.info.player:get_anim_state().eye_yaw)
	local angle_to_target = (pos - main.info.player:get_origin()):angles()
	--local angles = main.info.player:get_angles()
	local yaw = main.info.player:get_anim_state().eye_yaw
	cmd.forwardmove = math.cos(math.rad(yaw-angle_to_target.y))*speed
	cmd.sidemove = math.sin(math.rad(yaw-angle_to_target.y))*speed
end

local range_multip = 11

function hitchance_fun(hitbox, v, h)
	local rays = 64
	local hits = 0
	local spread = main.info.weap:get_inaccuracy() + main.info.weap:get_spread()
	local weapon_info = main.info.weap:get_weapon_info()
	if weapon_info == nil then return 0 end
	for i=1, rays do
		--local mul = i/rays
		local randomized = vector(utils.random_float(-spread, spread), utils.random_float(-spread, spread), utils.random_float(-spread, spread))
		local trace_damage, trace = utils.trace_bullet(main.info.player, main.info.player:get_eye_position(), hitbox + (randomized * (weapon_info.range/range_multip)), main.info.player)
		local mindamage = main.menu_items.aimbot.mindamage:get() < v.m_iHealth + 1 and main.menu_items.aimbot.mindamage:get() or v.m_iHealth + 1
		if trace_damage >= mindamage and trace.entity == v then
			hits = hits + 1
		end
		table.insert(hitchance_t, trace.end_pos)
	end

	return (hits/rays)*100
end

local hitboxes = {
	["Head"] = 0,
	["Body"] = 3
}

local last_jump_time = globals.curtime
local speed = 0

local bomb_active = false
local bomb_dist = 0
local bomb_dist_limit = 0

local auto_map_delay = 0

function on_death()
	if main.info.player:is_alive() then return end
	spawn_delay = globals.curtime + 2;
end

function w_main(cmd)	
	if cmd.in_jump then 
		utils.console_exec("-jump")
	end

	if cmd.in_duck then 
		utils.console_exec("-duck")
	end

	if (cmd.in_use and not bomb_active) or (cmd.in_use and bomb_active and bomb_dist < bomb_dist_limit) then
		utils.console_exec("-use")
	end
	
	-- or main.info.game_rules.m_fWarmupPeriodStart ~= -1	
	local warmup = main.info.game_rules.m_fWarmupPeriodEnd > globals.curtime
	if main.menu_items.map_main.auto_map_generator:get() and not main.menu_items.map_main.map_generator:get() and #nodes < 1 and not warmup then
		main.menu_items.map_main.map_generator:set(true)
		common.add_notify("Walkbot", "Map Generator Activated")
	end

	if main.menu_items.map_cfg.auto_load_cfg:get() and #nodes < 1 and not warmup and auto_map_delay < globals.realtime then
		auto_map_delay = globals.realtime + 5
		common.add_notify("Walkbot", "Starting Automatic Map Loading...")
		if main.menu_items.map_cfg.prefer_local_cfg:get() then
			load_map_local()
			if #nodes < 1 then
				load_map()
			end
		else
			load_map()
			if #nodes < 1 then
				load_map_local()
			end
		end
	end

	if #nodes < 1 or warmup then return end
	if main.info.game_rules.m_bFreezePeriod then node_time_limit_temp = globals.curtime + node_time_limit; return end
	if stuff.check_flag(main.info.player, stuff.flags.IsFrozen) then node_time_limit_temp = globals.curtime + node_time_limit; return end

	local bomb_list = entity.get_entities("CPlantedC4", true)
	bomb_dist = 99
	bomb_active = false
	bomb_dist_limit = 50
	if #bomb_list > 0 then
		local bomb_timer = bomb_list[1].m_flC4Blow - globals.curtime
		local defuse_timer = bomb_list[1].m_flDefuseCountDown - globals.curtime

		bomb_dist = bomb_list[1]:get_origin():dist(main.info.player:get_origin())
		bomb_active = (bomb_timer > defuse_timer or bomb_timer > (main.info.player.m_bHasDefuser and 5 or 10)) and not bomb_list[1].m_bBombDefused
	end

	if not main.info.player:is_alive() then return end
	if spawn_delay > globals.curtime then
		reset_path()
		return
	end

	if path_found and #path > 0 then 
		local player_origin = main.info.player:get_origin()
		local node_origin = path[1].pos
		local node_distance = node_origin:dist(player_origin)

		local players = entity.get_players(true, true)
		
		local player_origin = main.info.player:get_origin()
		local enemy_visible = false
		local best_dist, best_player = 999999, nil
		local hitbox = {}
		if #main.menu_items.aimbot.hitgroup:get() == 0 then
			hitbox = {0}
		end
		for k,v in pairs(main.menu_items.aimbot.hitgroup:get()) do
			table.insert(hitbox, hitboxes[v])
		end
		if main.menu_items.aimbot.prefer_body_aim:get() then
			table.sort(hitbox, function(a,b) return a > b end)
		end
		local ray_distance = 1488
		for k,v in pairs(players) do
			for k2,v2 in pairs(hitbox) do
				local dist = player_origin:dist(v:get_origin())
				if v:is_alive() and not v:is_dormant() then
					local trace = nil
					local num = 0
					if main.menu_items.aimbot.autowall:get() then
						num, trace = utils.trace_bullet(main.info.player, main.info.player:get_eye_position(), v:get_hitbox_position(v2), main.info.player)
					else
						trace = utils.trace_line(main.info.player:get_eye_position(), v:get_hitbox_position(v2), main.info.player, nil, 0)
					end
					if trace:did_hit_non_world() and trace.entity == v then
						local t_ang = clamp_angles((v:get_hitbox_position(v2) - render.camera_position()):angles() - render.camera_angles())
						if ray_distance == 1488 then
							ray_distance = t_ang:length()
							if dist < best_dist and ray_distance < main.menu_items.aimbot.max_fov:get() then
								best_dist, best_player = dist, v
								best_hitbox = v2
								enemy_visible = true
							end
						end
					end
				end
			end
		end

		local allow_stop = main.menu_items.main.auto_stop:get() or main.menu_items.aimbot.master:get()
		if ((enemy_visible or entity.get_threat(true) ~= nil) and allow_stop) then
			node_time_limit_temp = globals.curtime + node_time_limit
		end

		if path[1].flags.duck then
			utils.console_exec("+duck")
		end

		if main.menu_items.main.bomb_defuse:get() and bomb_active and bomb_dist < bomb_dist_limit then
			utils.console_exec("+use")
			render.camera_angles((bomb_list[1]:get_origin() - main.info.player:get_eye_position()):angles())
			node_time_limit_temp = globals.curtime + node_time_limit
		end

		if not (enemy_visible and allow_stop) and not (bomb_dist < bomb_dist_limit and bomb_active) then
			local d = node_distance + (path[2] ~= nil and node_origin:dist(player_origin) or 0)
			speed = (450*(d/150) - speed) * 0.04 + speed
			move_to_pos(cmd, path[1].pos, math.min(speed, 450))
		end

		if node_distance > 15 and main.menu_items.aimbot.aim_node:get() and not enemy_visible and not (bomb_dist < bomb_dist_limit and bomb_active) then
			local aim_angles = clamp_angles((node_origin - (player_origin + vector(0,0,5))):angles() - render.camera_angles())
			render.camera_angles(render.camera_angles() + (aim_angles/30))
		end

		if not path[1].flags.avoid_jumping and player_origin.z + 20 < node_origin.z and globals.curtime > last_jump_time and not (enemy_visible and allow_stop) or (main.info.player:get_anim_state().on_ladder and globals.curtime > last_jump_time) then
			utils.console_exec("+jump")
			last_jump_time = globals.curtime + 0.5
		end

		if node_time_limit_temp < globals.curtime then
			if best_dist > 100 then
				remove_dis_node(path[1])
				print("1")
			else
				node_time_limit_temp = globals.curtime + node_time_limit
			end
		end

		if node_distance < 15 then
			if path[1] ~= nil then
				if main.menu_items.map_main.map_tester:get() and not has_value2(tester_closed_list, path[1].id) then
					table.insert(tester_closed_list, path[1])
					remove_node(tester_open_list, path[1])
				end
			end
			remove_node(path, path[1])
			node_time_limit_temp = globals.curtime + node_time_limit
		end
	end

	for zzz=1, 32 do
		if not path_found and #open_list > 0 then
			local current = lowest_f_score( open_list, f_score )
			if current == target then
				-- if target == start then
				-- 	reset_path()
				-- 	break
				-- end
				local path2 = unwind_path({}, came_from, target)
				table.insert(path2, target)
				path = path2
				path_found = true
				node_time_limit_temp = globals.curtime + node_time_limit
			end
			remove_node(open_list, current)        
			table.insert(closed_list, current)
			current.color2 = color(0, 125, 125)
			for k, neighbor in ipairs(current.neighbors) do 
				neighbor = get_node(neighbor)
				if not has_value2(closed_list, neighbor.id) then
					local tentative_g_score = (g_score[current.id] + current.pos:dist(neighbor.pos)) * (neighbor.flags.duck and 1.1 or 1)
					if not has_value2( open_list, neighbor.id ) or tentative_g_score < g_score [ neighbor.id ] then 
						came_from[neighbor.id] = current
						g_score[neighbor.id] = tentative_g_score
						f_score[neighbor.id] = g_score[neighbor.id] + neighbor.pos:dist(target.pos)
						if not has_value2(open_list, neighbor.id) then
							table.insert(open_list, neighbor)
							neighbor.color2 = color(255, 255, 0)
						end
					end
				end
			end
		end
	end

	if not path_found and #open_list < 1 then
		print("3")
		remove_dis_node(target)
	end

	if path_found and #path < 1 then
		reset_path()
	end	
end

function aimbot(cmd)
	hitchance_t = { }
	if cmd.in_attack then
		utils.console_exec("-attack")
	end


	local players = entity.get_players(true, true)
	
	local player_origin = main.info.player:get_origin()
	local best_hitbox = 0
	local best_dist, best_player = 999999, nil

	local hitbox = {}
	for k,v in pairs(main.menu_items.aimbot.hitgroup:get()) do
		table.insert(hitbox, hitboxes[v])
	end
	if main.menu_items.aimbot.prefer_body_aim:get() then
		table.sort(hitbox, function(a,b) return a > b end)
	end
	
	local ray_distance = 1488
	for k,v in pairs(players) do
		for k2,v2 in pairs(hitbox) do
			local dist = player_origin:dist(v:get_origin())
			if v:is_alive() and not v:is_dormant() then
				local trace = nil
				local num = 0
				if main.menu_items.aimbot.autowall:get() then
					num, trace = utils.trace_bullet(main.info.player, main.info.player:get_eye_position(), v:get_hitbox_position(v2), main.info.player)
				else
					trace = utils.trace_line(main.info.player:get_eye_position(), v:get_hitbox_position(v2), main.info.player, nil, 0)
				end
				if trace:did_hit_non_world() and trace.entity == v then
					local t_ang = clamp_angles((v:get_hitbox_position(v2) - render.camera_position()):angles() - render.camera_angles())
					if ray_distance == 1488 then
						ray_distance = t_ang:length()
						if dist < best_dist and ray_distance < main.menu_items.aimbot.max_fov:get() then
							best_dist, best_player = dist, v
							best_hitbox = v2
							enemy_visible = true
						end
					end
				end
			end
		end
	end
	
	if best_player == nil then return end
	local allow_stop = main.menu_items.main.auto_stop:get() or main.menu_items.aimbot.master:get()
	if (enemy_visible and allow_stop) and not (bomb_dist < bomb_dist_limit and bomb_active) then
		local hitbox_pos = best_player:get_hitbox_position(best_hitbox)
		local aim_angles = clamp_angles((hitbox_pos - render.camera_position()):angles() - render.camera_angles()) - main.info.player.m_aimPunchAngle
		render.camera_angles(render.camera_angles() + (aim_angles/main.menu_items.aimbot.smooth:get()))
		local weapon_info = main.info.weap:get_weapon_info()
		if weapon_info == nil then return end
		local hitchance = hitchance_fun(best_player:get_hitbox_position(best_hitbox), best_player, best_hitbox)
		g_hitchance = hitchance
		local dmg, trace = utils.trace_bullet(main.info.player, main.info.player:get_eye_position(), main.info.player:get_eye_position() + (vector():angles(render.camera_angles())*8000))
		if main.menu_items.aimbot.auto_fire:get() and main.info.can_shoot and hitchance >= main.menu_items.aimbot.hitchance:get() and trace:did_hit_non_world() then
			utils.console_exec("+attack")
		end
	end

end

function map_generator(cmd)
	for zzz=1, 24 do
		if main.menu_items.map_main.map_generator:get() then
			if #generator_open_list > 0 then
				local v = generator_open_list[1] + vector(0,0,5)
				--for k,v in pairs(generator_open_list) do
				local indent = main.menu_items.map_main.indent:get()
				local pos_y = {
					vector(indent, 0, 0),
					vector(-indent, 0, 0),
					vector(0, indent, 0),
					vector(0, -indent, 0),
					-- vector(indent, indent, 0),
					-- vector(-indent, indent, 0),
					-- vector(indent, -indent, 0),
					-- vector(-indent, -indent, 0),
				}

				for k2,v2 in pairs(pos_y) do
					local cur = v+v2
					local allow_place_node = true
					local trace = utils.trace_line(v + vector(0, 0, 45), cur, nil, nil, 1)
					local end_pos = trace.end_pos
					-- if not trace:did_hit() then
					trace = utils.trace_line(end_pos, end_pos - vector(0, 0, 45), nil, nil, 1)
					local end_pos2 = trace.end_pos
					if trace:did_hit() and end_pos2:dist(v) > indent/2 then
						for k3,v3 in pairs(generator_open_list) do
							if not allow_place_node then break end
							if end_pos2:dist(v3) < indent/1.4 then
								allow_place_node = false
							end
						end

						for k3,v3 in pairs(generator_closed_list) do
							if not allow_place_node then break end
							if end_pos2:dist(v3) < indent/1.4 then
								allow_place_node = false
							end
						end
						
						if allow_place_node then
							if (end_pos2 - v):length() < main.menu_items.map_main.indent:get() then
								table.insert(generator_open_list, end_pos2 - ((end_pos2 - v)/2))
							else
								table.insert(generator_open_list, end_pos2)
							end
						end
					end
				end
				table.insert(generator_closed_list, v)
				table.remove(generator_open_list, 1)
				--end
			else
				for k,v in pairs(generator_closed_list) do
					create_node(v)
				end
				generator_open_list = { }
				generator_closed_list = { }
				main.menu_items.map_main.map_generator:set(false)
				update_neighbors(true)
				reset_path()
			end
		else
			generator_open_list = { }
			generator_closed_list = { }
			table.insert(generator_open_list, main.info.player:get_origin() + vector(0,0,5))
		end
	end
end

events.createmove_run:set(function(cmd)
	call_createmove(cmd)
end)

for k, v in pairs(main.menu_items) do
	if type(v) == "table" then
		for k2, v2 in pairs(v) do
			if type(v2) == "table" then
				for k3,v3 in pairs(v2) do
					if type(v3) == "userdata" then
						cfg.inalizate(v3)
					end
				end
			end

			if type(v2) == "userdata" then
				cfg.inalizate(v2)
			end
		end
	end
end

events.mouse_input:set(function()
	return not (main.info.menu_state)
end)

events.cs_win_panel_match:set(function()
	if main.menu_items.lobby.auto_disconnect:get() then
		utils.console_exec("disconnect")
	end
end)

events.round_freeze_end:set(reset_path)
events.player_death:set(function(e)
	if entity.get(e.userid, true) == main.info.player then
		reset_path()
	end
end)
events.player_spawned:set(function(e)
	if entity.get(e.userid, true) == main.info.player then
		reset_path()
	end
end)
events.bomb_planted:set(reset_path)

main.menu_items.main.master:set_callback(function()
	reset_path()
end)

main.menu_items.map_main.map_tester:set_callback(function()
	tester_closed_list = { }
	tester_open_list = { }
	if main.menu_items.map_main.map_tester:get() then
		for k,v in pairs(nodes) do
			table.insert(tester_open_list, v)
		end
	end
	reset_path()
end)

main.menu_items.map_bind.reset_path:set_callback(function()
	if not main.menu_items.map_bind.reset_path:get() then return end
	reset_path()
	common.add_notify("Walkbot", "Path Reseted")
end)

main.menu_items.map_bind.reset_map:set_callback(function()
	if not main.menu_items.map_bind.reset_map:get() then return end
	nodes = {}
	reset_path()
	common.add_notify("Walkbot", "Map Reseted")
end)

main.menu_items.map_bind.update_neighbors:set_callback(function()
	if not main.menu_items.map_bind.update_neighbors:get() then return end
	update_neighbors(true)
	common.add_notify("Walkbot", "Neighbors Updated")
end)

main.menu_items.map_editor.flags:set_callback(function()
	if selected_node ~= nil and main.info.menu_state then
		for k,v in pairs(main.menu_items.map_editor.flags:list()) do
			get_node(selected_node).flags[v] = main.menu_items.map_editor.flags:get(v)
		end
	end
end)

local gamemode_updated = false
function queue_update()
	local autoQueueData = panorama.loadstring([[
		let gamemodes = GameTypesAPI.GetConfig()["gameTypes"]
		let values = {};
		values.deathmatch = {};
		values.deathmatch.gametype = "gungame";
		values.deathmatch.maps = {};
		for (const [key, value] of Object.entries(gamemodes["gungame"]["gameModes"]["deathmatch"]["mapgroupsMP"])) {
			values.deathmatch.maps[value] = key;
		}
		values.casual = {};
		values.casual.gametype = "classic";
		values.casual.maps = {}
		for (const [key, value] of Object.entries(gamemodes["classic"]["gameModes"]["casual"]["mapgroupsMP"])) {
			values.casual.maps[value] = key;
		}
		return {
			data: values
		};
		]])()["data"]
	--
	local gamemodes = { }
	local gametypes = { }
	local maps = { }
	for k,v in pairs(autoQueueData) do
		table.insert(gamemodes, k)
		if main.menu_items.lobby.gamemode:get() == k then
			for k2,v2 in pairs(v) do
				if k2 == "gametype" then
					table.insert(gametypes, v2)
				elseif k2 == "maps" then
					for k3,v3 in pairs(v2) do
						table.insert(maps, v3)
					end
				end
			end
		end
	end 
	if not gamemode_updated then
		main.menu_items.lobby.gamemode:update(gamemodes)
		gamemode_updated = true
	end
	main.menu_items.lobby.gametype:update(gametypes)
	main.menu_items.lobby.map:update(maps)
end
main.menu_items.lobby.gamemode:set_callback(queue_update)
main.menu_items.lobby.gametype:set_callback(queue_update)
main.menu_items.lobby.map:set_callback(queue_update)

main.menu_items.map_editor.master:set_callback(function()
	selected_node = nil
	for k,v in pairs(main.menu_items.map_editor) do
		if k ~= "master" then
			v:visibility(main.menu_items.map_editor.master:get())
		end
	end
end)
for k,v in pairs(main.menu_items.map_editor) do
	if k ~= "master" then
		v:visibility(main.menu_items.map_editor.master:get())
	end
end

queue_update()
queue_update()
local p = panorama
local auto_queue_time = globals.realtime
function auto_queue()
	local queue = auto_queue_time - globals.realtime > 0
	stuff.anim("queue", queue and 255 or 0, queue and 0.03 or 0.01) 
	if stuff.anal["queue"] > 0 then
		local text = "[walkbot] queue started "
		local text_sz = render.measure_text(4, nil, text)
		render.text(4 , vector(main.info.sc.x/2 - text_sz.x/2, main.info.sc.y/6), color(255, stuff.anal["queue"]), nil, text)
	end

	if #p.LobbyAPI.GetMatchmakingStatusString() == 0 and not p.GameStateAPI.IsConnectedOrConnectingToServer() then
		if not globals.is_connected and auto_queue_time < globals.realtime then
			auto_queue_time = globals.realtime + 5
			if p.LobbyAPI.IsSessionActive() then
				local lobbyAPI = panorama.LobbyAPI

				local gamemode = main.menu_items.lobby.gamemode:get()
				local gametype = main.menu_items.lobby.gametype:get()
				local map = main.menu_items.lobby.map:get()
				print(gamemode)
				print(gametype)
				print(map)
				print((gamemode == "casual" and 0 or 16))
				--gamemode == "casual" and 0 or 16
				panorama.loadstring([[
					LobbyAPI.UpdateSessionSettings({
						update: {
							Options: {
								action: "custommatch",
								server: "official"
								},
								Game: {
									mode: "]] .. gamemode .. [[",
									type: "]] .. gametype .. [[",
									mapgroupname: "]] .. map .. [[",
									gamemodeflags: "]] .. (gamemode == "casual" and 0 or 16) .. [[",
									questid: 0
								}
							}
							});
							]])()
				--
				utils.execute_after(1, function() p.LobbyAPI.StartMatchmaking("", "", "", "") end)
				
			else
				p.LobbyAPI.CreateSession()
			end
		end
	end
end

create_fun(3, "render", debug_info, main.menu_items.render.debug_info)
create_fun(3, "render", render_nodes)
create_fun(1, "render", auto_queue, main.menu_items.lobby.auto_queue)
create_fun(3, "render", render_editor, main.menu_items.map_editor.master)
create_fun(2, "render", on_death)
create_fun(3, "createmove", check_can_shoot)
create_fun(3, "createmove", update_flags)
create_fun(3, "createmove", w_main, main.menu_items.main.master)
create_fun(3, "createmove", aimbot, main.menu_items.aimbot.master)
create_fun(3, "createmove", map_generator)
create_fun(1, "render", custom_sidebar)
if not paid then
	main.menu_items.map_main.allow_remove_nodes:name(main.menu_items.map_main.allow_remove_nodes:name() .. " (in paid)")
	main.menu_items.map_main.allow_remove_nodes:set(true)
	main.menu_items.map_main.allow_remove_nodes:disabled(true)
	local disabled_t = {
		main.menu_items.map_main.map_tester,
		main.menu_items.render.debug_info,
		main.menu_items.render.more_info,
		main.menu_items.map_main.auto_map_generator,
		main.menu_items.map_main.neighbors_indent,
		main.menu_items.main.save_map_local
	}
	for k,v in pairs(main.menu_items.aimbot) do
		if v:type() == "switch" then
			v:set(false)
		end
		v:name(v:name() .. " (in paid)")
		v:disabled(true)
	end

	-- for k,v in pairs(main.menu_items.map_editor) do
	-- 	if v:type() == "switch" then
	-- 		v:set(false)
	-- 	end
	-- 	v:name(v:name() .. " (in paid)")
	-- 	v:disabled(true)
	-- end

	for k,v in pairs(disabled_t) do
		if v:type() == "switch" then
			v:set(false)
		end
		v:name(v:name() .. " (in paid)")
		v:disabled(true)
	end
end