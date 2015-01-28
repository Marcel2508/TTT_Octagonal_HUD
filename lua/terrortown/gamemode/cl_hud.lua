-- HUD HUD HUD

local table = table
local surface = surface
local draw = draw
local math = math
local string = string

local GetTranslation = LANG.GetTranslation
local GetPTranslation = LANG.GetParamTranslation
local GetLang = LANG.GetUnsafeLanguageTable
local interp = string.Interp

-- Fonts
surface.CreateFont("TraitorState_ex", {font = "Octin Sports RG",
                                    size = 30,
                                    weight = 1000})
surface.CreateFont("TimeLeft_ex",     {font = "Octin Sports RG",
                                    size = 28,
                                    weight = 800})
surface.CreateFont("HealthAmmo_ex",   {font = "Octin Sports RG",
                                    size = 28,
                                    weight = 750})
surface.CreateFont("HasteMode_ex",   {font = "Octin Sports RG",
									size = 14,
									weight = 250})
									
-- Default TTT fonts for SpecDM support
surface.CreateFont("TraitorState", {font = "Trebuchet24",
                                    size = 28,
                                    weight = 1000})
surface.CreateFont("TimeLeft",     {font = "Trebuchet24",
                                    size = 24,
                                    weight = 800})
surface.CreateFont("HealthAmmo",   {font = "Trebuchet24",
                                    size = 24,
									weight = 750})
									
-- Color presets
local bg_colors = {
   background_main = Color(40, 49, 58, 255),
   background_haste = Color(120, 125, 146),

   noround = Color(100,100,100,200),
   traitor = Color(192, 37, 23, 200),
   innocent = Color(39, 204, 56, 200),
   detective = Color(41, 108, 185, 200)
};

local health_colors = {
   border = COLOR_WHITE,
   background = Color(40, 49, 58, 255),
   fill = Color(200, 50, 50, 250)
};

local ammo_colors = {
   border = COLOR_WHITE,
   background = Color(40, 49, 58, 255),
   fill = Color(205, 155, 0, 255)
};

local highlight_colors = {
	noround = Color(50,50,50,200),
	haste = Color(70, 75, 96),
	
	traitor = Color(142, 0, 0, 200),
	innocent = Color(0, 154, 6, 200),
	detective = Color(0, 58, 135, 200),
	
	ammo = Color(155, 105, 0, 255),
	health = Color(150, 0, 0, 250),
}

-- Modified RoundedBox
local Tex_Corner8 = surface.GetTextureID( "gui/corner8" )
local function RoundedMeter( bs, x, y, w, h, color)
   surface.SetDrawColor(clr(color))

   surface.DrawRect( x+bs, y, w-bs*2, h )
   surface.DrawRect( x, y+bs, bs, h-bs*2 )

   surface.SetTexture( Tex_Corner8 )
   surface.DrawTexturedRectRotated( x + bs/2 , y + bs/2, bs, bs, 0 )
   surface.DrawTexturedRectRotated( x + bs/2 , y + h -bs/2, bs, bs, 90 )

   if w > 14 then
      surface.DrawRect( x+w-bs, y+bs, bs, h-bs*2 )
      surface.DrawTexturedRectRotated( x + w - bs/2 , y + bs/2, bs, bs, 270 )
      surface.DrawTexturedRectRotated( x + w - bs/2 , y + h - bs/2, bs, bs, 180 )
   else
      surface.DrawRect( x + math.max(w-bs, bs), y, bs/2, h )
   end
end

---- The bar painting is loosely based on:
---- http://wiki.garrysmod.com/?title=Creating_a_HUD

-- Paints a graphical meter bar
local function PaintBar(x, y, w, h, colors, value, bg)
   -- Background
   -- slightly enlarged to make a subtle border
   
	if bg then
		draw.RoundedBox(0, x-1, y-1, w+2, h+2, colors.background)
	end

   -- Fill
   local width = w * math.Clamp(value, 0, 1)

   if width > 0 then
      RoundedMeter(0, x, y, width, h, colors.fill)
   end
end

local roundstate_string = {
   [ROUND_WAIT]   = "round_wait",
   [ROUND_PREP]   = "round_prep",
   [ROUND_ACTIVE] = "round_active",
   [ROUND_POST]   = "round_post"
};

-- Returns player's ammo information
local function GetAmmo(ply)
   local weap = ply:GetActiveWeapon()
   if not weap or not ply:Alive() then return -1 end

   local ammo_inv = weap:Ammo1() or 0
   local ammo_clip = weap:Clip1() or 0
   local ammo_max = weap.Primary.ClipSize or 0

   return ammo_clip, ammo_max, ammo_inv
end

local function DrawBg(x, y, width, height, client)
   -- Role area
   local th = 40
   local tw = 170

   -- Adjust for these
   y = y - th + 25
   height = height + th - 30

   -- main bg area, invariant
   -- encompasses entire area
   draw.RoundedBox(0, x, y, width, height, bg_colors.background_main)

   -- main border, traitor based
   local col = bg_colors.innocent
   local high = highlight_colors.innocent
   if GAMEMODE.round_state != ROUND_ACTIVE then
      col = bg_colors.noround
	 high = highlight_colors.noround
   elseif client:GetTraitor() then
      col = bg_colors.traitor
	  high = highlight_colors.traitor
   elseif client:GetDetective() then
      col = bg_colors.detective
	  high = highlight_colors.detective
   end

	-- Role bar
   draw.RoundedBox(0, x + 10, y, tw + 10, th + 1, col)
   RoundedMeter( 0, x , y, 10, th + 1, high)
end

local sf = surface
local dr = draw

local function ShadowedText(text, font, x, y, color, xalign, yalign)

	-- Shadowed text function
  -- dr.SimpleText(text, font, x+2, y+2, COLOR_BLACK, xalign, yalign)

   dr.SimpleText(text, font, x, y, color, xalign, yalign)
end

local margin = 30

-- Paint punch-o-meter
local function PunchPaint(client)
   local L = GetLang()
   local punch = client:GetNWFloat("specpunches", 0)

   local width, height = 200, 25
   local x = ScrW() / 2 - width/2
   local y = margin/2 + height

   PaintBar(x, y, width, height, ammo_colors, punch, true)

   local color = bg_colors.background_main

   dr.SimpleText(L.punch_title, "HealthAmmo_ex", ScrW() / 2, y, Color(250,250,250,255), TEXT_ALIGN_CENTER)

   dr.SimpleText(L.punch_help, "TabLarge", ScrW() / 2, margin, COLOR_WHITE, TEXT_ALIGN_CENTER)

   local bonus = client:GetNWInt("bonuspunches", 0)
   if bonus != 0 then
      local text
      if bonus < 0 then
         text = interp(L.punch_bonus, {num = bonus})
      else
         text = interp(L.punch_malus, {num = bonus})
      end

      dr.SimpleText(text, "TabLarge", ScrW() / 2, y * 2, COLOR_WHITE, TEXT_ALIGN_CENTER)
   end
end

local key_params = { usekey = Key("+use", "USE") }

local function SpecHUDPaint(client)
   local L = GetLang() -- for fast direct table lookups

   -- Draw round state
   local x       = margin
   local height  = 32
   local width   = 250
   local round_y = ScrH() - height - margin

   -- move up a little on low resolutions to allow space for spectator hints
   if ScrW() < 1000 then round_y = round_y - 15 end

   local time_x = x + 170
   local time_y = round_y + 4

   draw.RoundedBox(0, x, round_y, width/2, height, bg_colors.background_main)
   draw.RoundedBox(0, x, round_y - height, width/1.2, height, bg_colors.noround)

   local text = L[ roundstate_string[GAMEMODE.round_state] ]
   ShadowedText(text, "TraitorState_ex", x + 10, round_y - height, COLOR_WHITE)

   -- Draw round/prep/post time remaining
   local text = util.SimpleTime(math.max(0, GetGlobalFloat("ttt_round_end", 0) - CurTime()), "%02i:%02i")
   ShadowedText(text, "TimeLeft_ex", x + (width/8), time_y, COLOR_WHITE)

   local tgt = client:GetObserverTarget()
   if IsValid(tgt) and tgt:IsPlayer() then
      ShadowedText(tgt:Nick(), "TimeLeft_ex", ScrW() / 2, margin, COLOR_WHITE, TEXT_ALIGN_CENTER)

   elseif IsValid(tgt) and tgt:GetNWEntity("spec_owner", nil) == client then
      PunchPaint(client)
   else
      ShadowedText(interp(L.spec_help, key_params), "TabLarge", ScrW() / 2, margin, COLOR_WHITE, TEXT_ALIGN_CENTER)
   end
end

local ttt_health_label = CreateClientConVar("ttt_health_label", "0", true)

local function InfoPaint(client)
   local L = GetLang()

   local width = 300
   local height = 111

   local x = margin
   local y = ScrH() - margin - height

   DrawBg(x, y, width, height, client)

   local bar_height = 40
   local bar_width = width

   -- Draw health
   local health = math.max(0, client:Health())
   local health_y = y + margin - 4

	-- Health Bar
   PaintBar(x + 10 , health_y, bar_width - 10 , bar_height, health_colors, health/100)
   -- Health bar highlight
   RoundedMeter( 0, x , health_y, 10, bar_height, highlight_colors.health)

	-- Health number
   ShadowedText(tostring(health), "HealthAmmo_ex", bar_width - 252, health_y + 7, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT)

   if ttt_health_label:GetBool() then
      local health_status = util.HealthToString(health)
	  -- Health label
      --draw.SimpleText(L[health_status], "TraitorState", x + margin*6, health_y + bar_height/2, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
   end

   -- Draw ammo
   if client:GetActiveWeapon().Primary then
      local ammo_clip, ammo_max, ammo_inv = GetAmmo(client)
      if ammo_clip != -1 then
         local ammo_y = health_y + bar_height + margin
		 
		 -- Ammo bar
         PaintBar(x + 10, ammo_y - margin, bar_width - 10, bar_height, ammo_colors, ammo_clip/ammo_max)
		 -- Ammo bar Highlight
		 RoundedMeter( 0, x, ammo_y - margin, 10, bar_height, highlight_colors.ammo)
		 
         local text = string.format("%i + %02i", ammo_clip, ammo_inv)
	
		-- Ammo number
         ShadowedText(text, "HealthAmmo_ex", bar_width - 252, ammo_y - margin + 7, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT)
      end
   end

   -- Draw traitor state
   local round_state = GAMEMODE.round_state

   local traitor_y = y - 10
   local text = nil
    if round_state == ROUND_ACTIVE then
		if (client.IsGhost and client:IsGhost()) then
			text = "Spec DM"
		else
            text = L[ client:GetRoleStringRaw() ] or text
		end
    else
        text = L[ roundstate_string[round_state] ] or text
    end


	-- Role text
   ShadowedText(text, "TraitorState_ex", x + margin - 15, traitor_y, COLOR_WHITE, TEXT_ALIGN_LEFT)

   -- Draw round time
   local is_haste = HasteMode() and round_state == ROUND_ACTIVE
   local is_traitor = client:IsActiveTraitor()

   local endtime = GetGlobalFloat("ttt_round_end", 0) - CurTime()

   local text
   local font = "TimeLeft_ex"
   local color = COLOR_WHITE -- Haste color
   local rx = x + margin + 170
   local ry = traitor_y + 3

   -- Time displays differently depending on whether haste mode is on,
   -- whether the player is traitor or not, and whether it is overtime.
   if is_haste then
      local hastetime = GetGlobalFloat("ttt_haste_end", 0) - CurTime()
      if hastetime < 0 then
         if (not is_traitor) or (math.ceil(CurTime()) % 7 <= 2) then
            -- innocent or blinking "overtime"
            text = L.overtime
            font = "TimeLeft_ex"

            -- need to hack the position a little because of the font switch
            ry = ry + 5
            rx = rx - 3
         else
            -- traitor and not blinking "overtime" right now, so standard endtime display
            text  = util.SimpleTime(math.max(0, endtime), "%02i:%02i")
            color = COLOR_RED
         end
      else
         -- still in starting period
         local t = hastetime
         if is_traitor and math.ceil(CurTime()) % 6 < 2 then
            t = endtime
            color = COLOR_RED
         end
         text = util.SimpleTime(math.max(0, t), "%02i:%02i")
      end
   else
      -- bog standard time when haste mode is off (or round not active)
      text = util.SimpleTime(math.max(0, endtime), "%02i:%02i")
   end
	--bg_colors.background_haste 
	--RoundedMeter( bs, x, y, w, h, color)
	RoundedMeter( 0, x + margin + 170, ry - 8, 100, 41, bg_colors.background_haste )
	RoundedMeter( 0, x+ margin + 160, ry - 8, 10, 41, highlight_colors.haste)
   ShadowedText(text, font, x + margin + 190, ry + 5, color)

   if is_haste then
      dr.SimpleText(L.hastemode, "HasteMode_ex", x + margin + 185, traitor_y - 8 + 5)
   end

end

-- Paints player status HUD element in the bottom left
function GM:HUDPaint()
   local client = LocalPlayer()

   hook.Call( "HUDDrawTargetID", GAMEMODE )

   MSTACK:Draw(client)

    if (not client:Alive()) or (client:Team() == TEAM_SPEC and !(client.IsGhost and client:IsGhost())) then
      SpecHUDPaint(client)

      return
   end


   RADAR:Draw(client)
   TBHUD:Draw(client)
   WSWITCH:Draw(client)

   VOICE.Draw(client)
   DISGUISE.Draw(client)

   hook.Call( "HUDDrawPickupHistory", GAMEMODE )

   -- Draw bottom left info panel
   InfoPaint(client)
end

-- Hide the standard HUD stuff
local hud = {"CHudHealth", "CHudBattery", "CHudAmmo", "CHudSecondaryAmmo"}
function GM:HUDShouldDraw(name)
   for k, v in pairs(hud) do
      if name == v then return false end
   end

   return true
end
