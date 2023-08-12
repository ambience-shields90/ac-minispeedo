local fontDigitalDisplay = ui.DWriteFont("Digital Display", "assets")

local colorTextForeground = rgbm(255, 255, 255, 1.0)
local colorTextBackground = rgbm(0, 0, 0, 0.5)
local colorTextForegroundWarn = rgbm(240, 0, 0, 1.0)
local colorShiftUp = colorTextForegroundWarn

local FONT_SIZE = 32
local CHAR_SIZE = vec2(14, 21) * (FONT_SIZE / 32)

local FOCUSED_CAR = -1
local MAX_TURBO = 0

local drawCursor
local function easyDrawChar(chr, clr)
	drawCursor = ui.getCursor()
	ui.dwriteTextAligned("8", FONT_SIZE, ui.Alignment.Center, ui.Alignment.Center, CHAR_SIZE, false, colorTextBackground)
	ui.setCursor(drawCursor)
	ui.dwriteTextAligned(chr, FONT_SIZE, ui.Alignment.Center, ui.Alignment.Center, CHAR_SIZE, false, clr)
	ui.setCursor(vec2(drawCursor.x + CHAR_SIZE.x + 1, drawCursor.y))
end

local function easyDrawText(str, clr)
	for i, v in ipairs(string.split(str, "")) do
		easyDrawChar(v, clr)
	end
end

local charn
local function getStringFromNumber4(n)
	charn = 0
	return string.gsub(string.format("%04d", n), ".", function(c)
		charn = charn + 1

		if 10 > n and charn == 4 then
			return c
		elseif n >= 10 and 100 > n and charn >= 3 then
			return c
		elseif n >= 100 and 1000 > n and charn >= 2 then
			return c
		elseif n >= 1000 then
			return c
		end

		return " "
	end)
end

local car, cursor, speed, gear, color, rpm, turbo
function script.minispeedo()
	car = ac.getCar(FOCUSED_CAR) or {
		engagedGear = 0;
		gear = 0;
		rpm = 0;
		rpmLimiter = 0;
		speedKmh = 0;
		turboBoost = 0;
	}

	cursor = ui.getCursor()

	ui.pushDWriteFont(fontDigitalDisplay)

	speed = math.max(0, math.min(999, math.round(car.speedKmh)))
	easyDrawText(getStringFromNumber4(speed), colorTextForeground)

	gear = car.engagedGear == -1 and "R" or car.engagedGear == 0 and "N" or tostring(car.engagedGear)
	color = (car.rpmLimiter * 0.90) < car.rpm and colorShiftUp or colorTextForeground
	easyDrawText(string.format(" %s", gear), color)

	ui.setCursor(vec2(cursor.x, cursor.y + CHAR_SIZE.y + 4))

	rpm = math.max(0, math.min(9999, math.round(car.rpm)))
	color = car.rpm > (car.rpmLimiter - 25) and colorTextForegroundWarn or colorTextForeground
	easyDrawText(getStringFromNumber4(rpm), color)

	turbo = MAX_TURBO == 0 and "-" or math.round(car.turboBoost / MAX_TURBO * 9)
	easyDrawText(string.format(" %s", turbo), colorTextForeground)

	ui.popDWriteFont()
end

local turboValue, iniEngine, iniValue
function getFocusedCarMaxTurbo()
	if not ac.getCar(FOCUSED_CAR) then
		return 0
	end

	turboValue = 0

	iniEngine = ac.INIConfig.carData(FOCUSED_CAR, "engine.ini")

	for i = 0, 7 do
		iniValue = math.min(
			iniEngine:get("TURBO_" .. i, "MAX_BOOST", 0),
			iniEngine:get("TURBO_" .. i, "WASTEGATE", 0)
		)
		if iniValue > 0.0 then
			turboValue = turboValue + iniValue
		end
	end

	return turboValue
end

local s, t = nil, 0
function script.update(dt)
	s = ac.getSim()
	if s.focusedCar ~= FOCUSED_CAR then
		FOCUSED_CAR = s.focusedCar
		MAX_TURBO = getFocusedCarMaxTurbo()
	end

	t = (t + dt * s.replayPlaybackRate * 1000) % 600
	if t > 250 then
		colorShiftUp = colorTextForegroundWarn
	else
		colorShiftUp = colorTextForeground
	end
end
