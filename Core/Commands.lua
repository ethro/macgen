local macgen, E, L, V, P, G = unpack(select(2, ...))
local AB = E:GetModule('ActionBars')

local pairs = pairs

local _blank_macro_icon = 134400

-- Supported chat commands for macgen
function macgen:usage()
    print('macgen version '..macgen.Version..' chat commands:')
    print('')
    print('macgen    Scan and regenerate current macros')
    print('macreset  Delete all user specific macros and regenerate current configuration')
    print('machelp   Show macgen usage')
    print('')
end

-- Scan the action bars 2[nomod], 3[ctrl], 4[shift], 5[alt] for their current
-- contents and generate macro text for the character's personal macros
function macgen:generate_macros()
   if macgen_vars['enabled'] then
      local _action_bar_contents = macgen:scan_action_bars()
      for _button = 1, 12 do
         _button_entry = _action_bar_contents['button_'.._button]
         _alt_txt   = ""
         _shift_txt = ""
         _ctrl_txt  = ""
         _nomod_txt = ""
         if _button_entry then
            if _button_entry['alt'] then
               _alt_txt = _alt_txt.."[mod:alt]".._button_entry['alt']..";"
            end
            if _button_entry['shift'] then
               _shift_txt = _shift_txt.."[mod:shift]".._button_entry['shift']..";"
            end
            if _button_entry['ctrl'] then
               _ctrl_txt = _ctrl_txt.."[mod:ctrl]".._button_entry['ctrl']..";"
            end
            if _button_entry['nomod'] then
               _nomod_txt = _nomod_txt.._button_entry['nomod']
            end
         end
         _macro_text = "#showtooltip\n/use ".._alt_txt.._shift_txt.._ctrl_txt.._nomod_txt
         _button_entry['macro_text'] = _macro_text
         macro_id = EditMacro(120 + _button, nil, _blank_macro_icon, _macro_text)
      end
   end
end

-- Scan each action bar in the set [2,3,4,5] and return their contents in a custom
-- table indicating the spell, item or summonmount action_type for each modifier
-- key for a given button
--
-- Action Bar 2 is for nomod
-- Action Bar 3 is for ctrl
-- Action Bar 4 is for shift
-- Action Bar 5 is for alt
function macgen:scan_action_bars()
    local _action_bar_contents = {}
    local nomod = 2
    local ctrl = 3
    local shift = 4
    local alt = 5
    local mod_map = {}
    mod_map[nomod] = 'nomod'
    mod_map[ctrl] = 'ctrl'
    mod_map[shift] = 'shift'
    mod_map[alt] = 'alt'
    for barName, bar in pairs(AB.handledBars) do
        if bar and (bar.id == nomod or bar.id == ctrl or bar.id == shift or bar.id == alt) then
            for _button_idx, _button in pairs(bar.buttons) do
                _button_key = 'button_'.._button_idx
                _mod_key = mod_map[bar.id]
                if not _action_bar_contents[_button_key] then
                    _action_bar_contents[_button_key] = {}
                end
                if _button._state_type == "action" then
                    local action_type, action_id, action_subtype = GetActionInfo(_button._state_action)
                    if action_type == "spell" then
                        local _ability_name, _, _, _, _, _, _spell_id, _= GetSpellInfo(action_id)
                        if _spell_id == 324128 then
                           _base_spell_id = FindBaseSpellByID(_spell_id)
                           -- print(_ability_name, _spell_id, _base_spell_id)
                           _ability_name = GetSpellInfo(_base_spell_id)
                           -- print(_ability_name, _spell_id, _base_spell_id)
                        end
                        _action_bar_contents[_button_key][_mod_key] = _ability_name
                    elseif action_type == "item" then
                        local itemInfo = GetItemInfo(action_id)
                        _action_bar_contents[_button_key][_mod_key] = itemInfo
                    elseif action_type == "summonmount" then
                        local mount_name = C_MountJournal.GetMountInfoByID(action_id)
                        _action_bar_contents[_button_key][_mod_key] = mount_name
                     -- else
                     --    print(action_type, action_id, action_ssummonmountubtype)
                    end
                end
            end
        end
    end
    return _action_bar_contents
end

-- Delete any existing character specific macros and create dummy numbered macros.
-- Then call generate_macros to edit the contents of the numbered macros according
-- to the contents of the characters action bars
-- TODO: Need to be able to put the user specific macros back onto ActionBar 1
-- after deleting them...
function macgen:reset_user_specific_macros()
   if macgen_vars['enabled'] then
      -- Start at the end, and move backward to first position (121).
      for i = 120 + select(2,GetNumMacros()), 121, -1 do
         local _name, _icon, _body = GetMacroInfo(i)
         if _name then
            DeleteMacro(i)
         end
      end
      for _button = 1, 12 do
         local _macro_name = string.format("N_%02d",_button)
         local _name, _icon, _body = GetMacroInfo(120+_button)
         if not _name then
            macro_id = CreateMacro(_macro_name, _blank_macro_icon, "/train", true)
         end
      end
      macgen:generate_macros()
   end
end

function macgen:ACTIONBAR_SLOT_CHANGED(self, slot)
   if slot > 12 and slot <= 60 then
      if macgen_vars['auto'] then
         macgen:generate_macros()
      end
   end
end

function macgen:PLAYER_SPECIALIZATION_CHANGED()
   if macgen_vars['enabled'] then
      macgen:generate_macros()
   end
end

function macgen:toggle_auto()
   if macgen_vars['auto'] then
      macgen_vars['auto'] = false
   else
      macgen_vars['auto'] = true
   end
   print("mac auto has been set to", macgen_vars['auto'])
end

function macgen:disable_macgen()
   macgen_vars['enabled'] = false
   print("macgen has been disabled")
end

function macgen:enable_macgen()
   macgen_vars['enabled'] = true
   print("macgen has been enabled")
end

-- This is called in macgen:Initialize()
function macgen:RegisterEvents()
   macgen:RegisterEvent('PLAYER_ENTERING_WORLD')
   macgen:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED')
   macgen:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
end

function macgen:PLAYER_ENTERING_WORLD(_, initLogin, isReload)
   if not macgen_vars then
      macgen_vars = {}
      macgen_vars['enabled'] = false
      macgen_vars['auto']    = false
   end
   macgen:load_commands()
   macgen:generate_macros()
end

-- Register all commands
function macgen:load_commands()
    self:RegisterChatCommand('macenable', 'enable_macgen')
    self:RegisterChatCommand('macdisable','disable_macgen')
    self:RegisterChatCommand('macauto',   'toggle_auto')
    self:RegisterChatCommand('macgen',    'generate_macros')
    self:RegisterChatCommand('macreset',  'reset_user_specific_macros')
    self:RegisterChatCommand('machelp',   'usage')
end

