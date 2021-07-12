------------------------ DOES IT WORK?

local dataStoreService = game:GetService("DataStoreService")
local TeleportService = game:GetService("TeleportService")

local currentDatastore = dataStoreService:GetDataStore('battleRoyale', 'matchmaking')

local battleIsland = 6811065301

local keyCharacters = {'a','c','e','g','i','k','m','o','q','s','u','w','y','!','@','#'}

local teleported = {}

local parties = {
	
}

local function GetNewServer()
	
	local serverCode

	local try, catch = pcall(function()
		serverCode = TeleportService:ReserveServer(battleIsland)
	end)

	if try then
		return serverCode
	else
		warn(catch)
		return false
	end
	
end

local function Getmatchmaking()
	
	local data
	
	local one, two = pcall(function()
		data = currentDatastore:GetAsync('matches')
	end)
	
	if one then
		if data == nil then
			data = {}
		end
		return data
	else
		warn(two)
		return false
	end
end

local function AddpartyToMatchmaking(party)
	local data = Getmatchmaking()
	local couldAddToMatch = false---------- value gets set in the proccces
	local couldAddToFill = false
	
	
	for i = 1, #data do
		if data[i]['players'] + party['ready'] <= data[i]['maxPlayers'] and data[i]['teleportPlayers'] == false then ----- if the party can be added without adding more than max players then

			couldAddToMatch = true

			if party['fill'] then ---- if party has fill on search for other fill party else
				for p = 1, #data[i]['parties'] do
					if data[i]['parties'][p]['fill'] then ---- check if this party has fill enabled
						warn('fill = true')
						if data[i]['parties'][p]['ready'] + party['ready'] <= 4 then
							warn('can add')
							data[i]['parties'][p]['ready'] += party['ready'] --- add the player count of the other party to ready of new party
							for j = 1, #party['players'] do ----- loop to add all players from the party to the other.
								warn('newPLr')
								
								game.Players:FindFirstChild(party['players'][j]):WaitForChild('key').Value = data[i]['parties'][p]['key']
								
								data[i]['players'] += 1 ----- add the players to match player count
								table.insert(data[i]['parties'][p]['players'], party['players'][j]) 
							end

							couldAddToFill = true

							break ---- break if party is merged

						end
					end
				end

				if couldAddToFill == false then ----- if fill was true but there was no other fill party add the party seperately
					table.insert(data[i]['parties'], party)
					data[i]['players'] += party['ready']
				end
			end
			break
		else
			couldAddToMatch = false ---- if this match is full set could add to false the value is set true when match is joinable
		end
	end
	
	if couldAddToMatch == false then
		
		local newServer
		
		while wait() and not newServer do
			newServer = GetNewServer()
		end
		
		local newmatch = {
			maxPlayers = 100,
			players = party['ready'],
			parties = {
				party
			},
			teleportPlayers = false,
			playersAreTeleported = false,
			start = tick(),
			serverCode = newServer,
			left = {},
			death = {}
		}
		table.insert(data, newmatch)
	end
	
	currentDatastore:SetAsync('matches', data)
end

local function removePartyFromMatchmaking(partyKey)
	local data = Getmatchmaking()

	for i = 1, #data do ----- loop trough all matches
		for j = 1, #data[i]['parties'] do ---- loop trough matches parties
			if data[i]['parties'][j][partyKey] then
				data[i]['players'] -= #data[i]['parties'][j]['players']
				data[i]['parties'][j] = nil ---- make that party nil
			end
		end
	end

	currentDatastore:SetAsync('matches', data)
end

local function ReadyPlayer(partyKey, fill)
	if parties[partyKey] then
		parties[partyKey]['ready'] += 1
		
		parties[partyKey]['fill'] = fill
		
		if parties[partyKey]['ready'] == #parties[partyKey]['players'] then
			AddpartyToMatchmaking(parties[partyKey])
		end
	end
end

local function UnreadyPlayer(player, partyKey)
	if parties[partyKey] then
		parties[partyKey]['ready'] -= 1
		removePartyFromMatchmaking(parties[partyKey])
		player:WaitForChild('tel'):Destroy()
	end
end

local function AddPlayerToParty(player, targetPartyKey)
	local playerParty = parties[player.key.Value]
	local targetParty = parties[targetPartyKey]
	
	if #targetParty['players'] + #playerParty['players'] > 4 then
		warn('to much players')
		return
	else
		table.insert(targetParty['players'], player.Name)
		player.key.Value = targetParty['key']
	end	
	
	if #playerParty['players'] > 1 then -------- if more than 1 player then leaven else remove party.
		
	else
		parties[player.key] = nil
	end
	
	print(targetPartyKey)
	
	player.key.Value = targetPartyKey
end

game.Players.PlayerAdded:Connect(function(plr)
	
	local val = Instance.new("StringValue", plr)
	val.Name = "key"
	
	local key = ""
	
	local keyAllowed= false
	
	while keyAllowed == false and wait() do
		key = ""
		for i = 1, 25 do
			key = key..keyCharacters[math.random(1,#keyCharacters)]
			if parties[key] == nil then
				keyAllowed = true
			end
		end
	end
	
	val.Value = key
	
	parties[key] = { -------------------- sets a new party at the just created party key value
		['key'] = key,
		['ready'] = 0,
		['fill'] = false,
		['players'] = {plr.Name},
	}
	
end)

script.Parent.readyPlayer.OnServerEvent:Connect(function(plr, fill, partyKey)
	repeat wait() until plr.key.Value ~= "" and plr.key.Value ~= nil
	
	for i = 1, #parties[partyKey]['players'] do
		print(game.Players:FindFirstChild(parties[partyKey]['players'][i]))
		script.Parent.readyPlayer:FireClient(game.Players:FindFirstChild(parties[partyKey]['players'][i]), i) ---- fire ready to all players in party wich player ready
	end
	
	ReadyPlayer(plr.key.Value, fill)
end)

script.Parent.unreadyPlayer.OnServerEvent:Connect(function(plr)
	UnreadyPlayer(plr, plr.key.Value)
end)

script.Parent.getmatches.OnServerEvent:Connect(function(plr)
	if plr.Name == "Michel2003g" then
		script.Parent.getmatches:FireClient(plr, Getmatchmaking())
	end
end)

script.Parent.getparty.OnServerEvent:Connect(function(plr, partyKey)
	if parties[partyKey] then
		script.Parent.getparty:FireClient(plr, parties[partyKey]['players'])
	end
end)

script.Parent.invitePlayer.OnServerEvent:Connect(function(plr, targetPlayer, partyKey)
	script.Parent.invitePlayer:FireClient(targetPlayer, plr, partyKey)
end)

script.Parent.joinParty.OnServerEvent:Connect(function(plr, partyKey)
	AddPlayerToParty(plr, partyKey)
end)

while wait(1) do
	local data = Getmatchmaking()

	for i = 1, #data do

		if data[i]['players'] == data[i]['maxPlayers'] or tick() - data[i]['start'] > 60 then ---- if match is full or wait time is higher than 1 minute
			if data[i]['teleportPlayers'] == false then
				data[i]['teleportPlayers'] = true
				data[i]['start'] = tick()
				currentDatastore:SetAsync('matches', data) ------ upload that players should be teleported
			end
		end
		
		if data[i]['teleportPlayers'] and data[i]['playersAreTeleported'] == false then ----- if the party can be added without adding more than max players then
			
			local players = {}
			
			for j = 1, #data[i]['parties'] do -------- go trough parties

				local party = data[i]['parties'][j]['players']

				for p = 1, #party do
					local player = party[p]

					if game.Players:FindFirstChild(player) then
						player = game.Players:FindFirstChild(player)
						
						if not player:FindFirstChild('tel') and not data[i]['left'][player.Name] then
							local try, catch = pcall(function() ---- if it crashes the players have to rejoin but the script wont be effecte4d by the error
								
								TeleportService:TeleportToPrivateServer(battleIsland, data[i]['serverCode'], {player}, nil, {serverCode = data[i]['serverCode'], key = player.key.Value})
								
								local bool = Instance.new('BoolValue', player)
								bool.Name = "tel"
							end)
						end

					end

				end


			end

		end

	end
	
end
