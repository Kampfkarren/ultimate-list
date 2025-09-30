-- An example of an efficient chat
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.DevPackages.ReactRoblox)
local UltimateList = require(ReplicatedStorage.Packages["ultimate-list"])

local e = React.createElement

local WORD_BANK = {
	"time",
	"way",
	"year",
	"work",
	"government",
	"day",
	"man",
	"world",
	"life",
	"part",
	"house",
	"course",
	"case",
	"system",
	"place",
	"end",
	"group",
	"company",
	"party",
	"information",
	"school",
	"fact",
	"money",
	"point",
	"example",
	"state",
	"business",
	"night",
	"area",
	"water",
	"thing",
	"family",
	"head",
	"hand",
	"order",
	"john",
	"side",
	"home",
	"development",
	"week",
	"power",
	"country",
	"council",
	"use",
	"service",
	"room",
	"market",
	"problem",
	"court",
	"lot",
	"a",
	"war",
	"police",
	"interest",
	"car",
	"law",
	"road",
	"form",
	"face",
	"education",
	"policy",
	"research",
	"sort",
	"office",
	"body",
	"person",
	"health",
	"mother",
	"question",
	"period",
	"name",
	"book",
	"level",
	"child",
	"control",
	"society",
	"minister",
	"view",
	"door",
	"line",
	"community",
	"south",
	"city",
	"god",
	"father",
	"centre",
	"effect",
	"staff",
	"position",
	"kind",
	"job",
	"woman",
	"action",
	"management",
	"act",
	"process",
	"north",
	"age",
	"evidence",
	"idea",
}

local NAME_BANK = {
	"Alice",
	"Bob",
	"Charlie",
	"David",
	"Eve",
	"Frank",
}

local FONT = Font.fromEnum(Enum.Font.BuilderSans)
local TEXT_SIZE = 14
local WIDTH = 300

type Message = {
	richText: string,

	height: number,
	yOffset: number,
}

local function Demo()
	local messages: { Message }, setMessages = React.useState({} :: { Message })

	React.useEffect(function()
		local thread = task.spawn(function()
			local yOffset = 0

			local function newMessageAsync()
				local words = {}

				for _ = 1, math.random(100) do
					table.insert(words, WORD_BANK[math.random(#WORD_BANK)])
				end

				local richText = `<b>[{NAME_BANK[math.random(#NAME_BANK)]}]:</b> {table.concat(words, ", ")}`

				local textBoundsParams = Instance.new("GetTextBoundsParams")
				textBoundsParams.RichText = true
				textBoundsParams.Text = richText
				textBoundsParams.Font = FONT
				textBoundsParams.Size = TEXT_SIZE
				textBoundsParams.Width = WIDTH - 12 -- Subtract scrolling bar

				local height = TextService:GetTextBoundsAsync(textBoundsParams).Y

				local ourYOffset = yOffset

				setMessages(function(newMessages)
					newMessages = table.clone(newMessages)
					table.insert(newMessages, {
						richText = richText,
						height = height,
						yOffset = ourYOffset,
					})
					return newMessages
				end)

				yOffset += height
			end

			for _ = 1, 30 do
				newMessageAsync()
			end

			while true do
				task.wait(1)
				newMessageAsync()
			end
		end)

		return function()
			task.cancel(thread)
		end
	end, {})

	return e("Frame", {
		Size = UDim2.fromOffset(WIDTH, 300),
	}, {
		ScrollingFrame = e(UltimateList.Components.ScrollingFrame, {
			dataSource = UltimateList.DataSources.array(messages),

			dimensions = UltimateList.Dimensions.getter(function(message: Message)
				return {
					position = UDim2.fromOffset(0, message.yOffset),
					size = UDim2.new(1, 0, 0, message.height),
				}
			end),

			renderer = UltimateList.Renderers.byBinding(function(messageBinding)
				return e("TextLabel", {
					BackgroundTransparency = 1,
					FontFace = FONT,
					RichText = true,
					Text = messageBinding:map(function(message: Message?)
						return if message then message.richText else ""
					end),
					TextColor3 = Color3.new(1, 1, 1),
					TextStrokeColor3 = Color3.new(0, 0, 0),
					TextStrokeTransparency = 0.7,
					TextSize = TEXT_SIZE,
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					Size = UDim2.fromScale(1, 1),
				})
			end),

			direction = "y",
		}),
	})
end

return function(target)
	local root = ReactRoblox.createRoot(target)

	root:render(e(Demo))

	return function()
		root:unmount()
	end
end
