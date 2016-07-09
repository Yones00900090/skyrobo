package.path = package.path .. ';.luarocks/share/lua/5.2/?.lua'
  ..';.luarocks/share/lua/5.2/?/init.lua'
package.cpath = package.cpath .. ';.luarocks/lib/lua/5.2/?.so'

require("./bot/utils")

local f = assert(io.popen('/usr/bin/git describe --tags', 'r'))
VERSION = assert(f:read('*a'))
f:close()

-- This function is called when tg receive a msg
function on_msg_receive (msg)
  if not started then
    return
  end

  msg = backward_msg_format(msg)

  local receiver = get_receiver(msg)
  print(receiver)
  --vardump(msg)
  --vardump(msg)
  msg = pre_process_service_msg(msg)
  if msg_valid(msg) then
    msg = pre_process_msg(msg)
    if msg then
      match_plugins(msg)
      if redis:get("bot:markread") then
        if redis:get("bot:markread") == "on" then
          mark_read(receiver, ok_cb, false)
        end
      end
    end
  end
end

function ok_cb(extra, success, result)

end

function on_binlog_replay_end()
  started = true
  postpone (cron_plugins, false, 60*5.0)
  -- See plugins/isup.lua as an example for cron

  _config = load_config()

  -- load plugins
  plugins = {}
  load_plugins()
end

function msg_valid(msg)
  -- Don't process outgoing messages
  if msg.out then
    print('\27[36mNot valid: msg from us\27[39m')
    return false
  end

  -- Before bot was started
  if msg.date < os.time() - 5 then
    print('\27[36mNot valid: old msg\27[39m')
    return false
  end

  if msg.unread == 0 then
    print('\27[36mNot valid: readed\27[39m')
    return false
  end

  if not msg.to.id then
    print('\27[36mNot valid: To id not provided\27[39m')
    return false
  end

  if not msg.from.id then
    print('\27[36mNot valid: From id not provided\27[39m')
    return false
  end

  if msg.from.id == our_id then
    print('\27[36mNot valid: Msg from our id\27[39m')
    return false
  end

  if msg.to.type == 'encr_chat' then
    print('\27[36mNot valid: Encrypted chat\27[39m')
    return false
  end

  if msg.from.id == 777000 then
    --send_large_msg(*group id*, msg.text) *login code will be sent to GroupID*
    return false
  end

  return true
end

--
function pre_process_service_msg(msg)
   if msg.service then
      local action = msg.action or {type=""}
      -- Double ! to discriminate of normal actions
      msg.text = "!!tgservice " .. action.type

      -- wipe the data to allow the bot to read service messages
      if msg.out then
         msg.out = false
      end
      if msg.from.id == our_id then
         msg.from.id = 0
      end
   end
   return msg
end

-- Apply plugin.pre_process function
function pre_process_msg(msg)
  for name,plugin in pairs(plugins) do
    if plugin.pre_process and msg then
      print('Preprocess', name)
      msg = plugin.pre_process(msg)
    end
  end
  return msg
end

-- Go over enabled plugins patterns.
function match_plugins(msg)
  for name, plugin in pairs(plugins) do
    match_plugin(plugin, name, msg)
  end
end

-- Check if plugin is on _config.disabled_plugin_on_chat table
local function is_plugin_disabled_on_chat(plugin_name, receiver)
  local disabled_chats = _config.disabled_plugin_on_chat
  -- Table exists and chat has disabled plugins
  if disabled_chats and disabled_chats[receiver] then
    -- Checks if plugin is disabled on this chat
    for disabled_plugin,disabled in pairs(disabled_chats[receiver]) do
      if disabled_plugin == plugin_name and disabled then
        local warning = 'Plugin '..disabled_plugin..' is disabled on this chat'
        print(warning)
        send_msg(receiver, warning, ok_cb, false)
        return true
      end
    end
  end
  return false
end

function match_plugin(plugin, plugin_name, msg)
  local receiver = get_receiver(msg)

 
  for k, pattern in pairs(plugin.patterns) do
    local matches = match_pattern(pattern, msg.text)
    if matches then
      print("msg matches: ", pattern)

      if is_plugin_disabled_on_chat(plugin_name, receiver) then
        return nil
      end
      if plugin.run then

        if not warns_user_not_allowed(plugin, msg) then
          local result = plugin.run(msg, matches)
          if result then
            send_large_msg(receiver, result)
          end
        end
      end
      return
    end
  end
end
function _send_msg(destination, text)
  send_large_msg(destination, text)
end
function save_config( )
  serialize_to_file(_config, './data/config.lua')
  print ('saved config into ./data/config.lua')
end
function load_config( )
  local f = io.open('./data/config.lua', "r")
  if not f then
    print ("Created new config file: data/config.lua")
    create_config()
  else
    f:close()
  end
  local config = loadfile ("./data/config.lua")()
  for v,user in pairs(config.sudo_users) do
    print("Sudo user: " .. user)
  end
  return config
end
function create_config( )
  config = {
    enabled_plugins = {
	   "admin",
    "all",
    "anti_spam",
    "arabic_lock",
    "badword",
    "banhammer",
    "bego",
    "broacast",
    "getplug",
    "invite",
    "leave_ban",
    "linkpv",
    "lockcmd",
    "lockeng",
    "locknum",
    "locksite",
    "locktag",
    "msg_checks",
    "onservice",
    "owners",
    "plugins",
    "pv",
    "rmsg",
    "robot",
    "savefile",
    "saveplug",
    "set",
    "supergroup",
    "whitelist"
    },
    sudo_users = {194849320,190079094,168753158,97648706,0,tonumber(our_id)},--Sudo users
    moderation = {data = 'data/moderation.json'},
    about_text = [[
    TeleGoldⓒ вот
_______________
>سازنده ربات و دارای امتیاز : @omidhttp 
>مدیر ربات و دارای امتیاز : @ssomartin
>مدیر ربات و دارای امتیاز : @Navidhttp
>مدیر ربات و دارای امتیاز : @GeniusBoys
>مدیر ربات و دارای امتیاز : @Djmiladacero
_______________
*--با تشکر از :
> @FeriSystem
> @JanLou
> @AlirezaMee
_______________
>Our Channel : @TeleGold_Team
⭐⭐⭐⭐⭐]],
    help_text_realm = [[]],
    help_text = [[TeleGoldⓒ вот
____________________
 تنظیمات
--- تنظیمات گروه
____________________
 لینک جدید
--- لینک جدید
____________________
لینک 
--- ارسال لینک
____________________
تنظیم لینک 
--- ثبت و ذخیره لینک
____________________
لینک پی وی
--- ارسال لینک در پی وی
____________________
اخراج
--- برای اخراج فردی از گروه
____________________
انبن
--- خارج کردن از مسدود.
____________________
بن
--- برای مسدود گروه فردی از گروه
____________________
لیست بن 
--- لیست مسدود شدگان
____________________
بلاک
--- بلاک کردن شخصی از گروه
____________________
ترفیع 
--- مدیر کردن دیگران
____________________
عزل 
--- از مدیریت برکنار میشود
____________________
تنظیم اسم [نام گروه]
--- برای تعویض اسم گروه
____________________
تنظیم عکس
--- برای تعویض عکس گروه
____________________
تنظیم یوزرنیم [یوزرنیم گروه]
--- تنطیم یوزرنیم برای گروه (در ایران مجاز نیست ! )
____________________
فیلتر [کلمه مورد نظر]
--- برای فیلتر کردن کلمه‌ای 
____________________
حذف فیلتر [کلمه مورد نظر]
--- حذف کلمه‌ای از فیلترشدها
____________________
لیست فیلتر 
--- لیست فیلترشدها
____________________
حذف لیست فیلتر 
--- برای حذف همه فیلتر ها
____________________
حذف
--- پاک کردن یک پیام با ریپلی
____________________
عمومی خاموش | روشن
--- شخصی یا عمومی کردن گروه
____________________
پاکسازی [قوانین-درباره-لیست مدیران-لیست کاربران بیصدا-یوزرنیم-ربات ها]

--- پاک کردن موارد بالا شامل: قوانین+توضیحات+لیست مدیران+افراد بیصدا شده
____________________
لیست ممنوعیات
--- نمایش لیست پست های ممنوع شده
____________________
سکوت 
--- باصدا و بیصدا کردن شخصی
____________________
لیست کاربران بیصدا 
--- لیست بیصداشدگان 
____________________
ممنوع کردن [همه+صدا+گیف+عکس+ویدیو+متن+فایل+پیام سرویسی+]

--- بیصدا کردن و موارد بالا، یکی از موارد رو جلوی دستور بزارید.
____________________
ازاد کردن [یکی از موارد بالا] 
--- با صدا کردن موارد بالا 👆
____________________
 قفل کردن [لینک+اسپم+ اموجی+تگ+تبلیغات+دستورات+انگلیسی+اعداد+فلود+اعضا+rtl+پیام سرویسی+استیکر+مخاطب+سختگیرانه]

--- قفل کردن موارد بالا، یکی از موارد رو جلوی دستور بزارید.
____________________
باز کردن [یکی از موارد]
--- باز کردن موارد ذکر شده بالا
____________________
حساسیت [4-30]
--- حساسیت اسپم بین 4-30
____________________
تنظیم قوانین [قوانین]
--- برای تنظیم قوانین
____________________
قوانین 
--- نمایش قوانین
____________________
تنظیم درباره 
--- تنظیم توضیحات پروفایل گروه
____________________
ایدی
--- نمایش آیدی گروه
____________________
اخراجم کن 
--- خروج از گروه
____________________
لیست مدیران 
--- لیست مدیران
____________________
درمورد [ایدی | یوزرنیم]
--- گرفتن اطلاعات صاحب آیدی
____________________
افراد
--- لیست اعضای گروه
____________________
ربات ها
--- لیست ربات های گروه
____________________
ادمین ها
--- لیست ادمین های گروه
____________________
تنظیم ادمین 
--- ادمین شدن
____________________
اطلاعات
--- نشان دادن دقیق مشخصات خودتان و گروه
____________________
Our Channel : @TeleGold_Team]],
  }
  serialize_to_file(config, './data/config.lua')
  print('saved config into ./data/config.lua')
end
function on_our_id (id)
  our_id = id
end
function on_user_update (user, what)
end
function on_chat_update (chat, what)
end
function on_secret_chat_update (schat, what)
end
function on_get_difference_end ()
end
function load_plugins()
  for k, v in pairs(_config.enabled_plugins) do
    print("Loading plugin", v)

    local ok, err =  pcall(function()
      local t = loadfile("plugins/"..v..'.lua')()
      plugins[v] = t
    end)
    if not ok then
      print('\27[31mError loading plugin '..v..'\27[39m')
	  print(tostring(io.popen("lua plugins/"..v..".lua"):read('*all')))
      print('\27[31m'..err..'\27[39m')
    end
  end
end
function load_data(filename)

	local f = io.open(filename)
	if not f then
		return {}
	end
	local s = f:read('*all')
	f:close()
	local data = JSON.decode(s)
	return data
end
function save_data(filename, data)
	local s = JSON.encode(data)
	local f = io.open(filename, 'w')
	f:write(s)
	f:close()
end
function cron_plugins()
  for name, plugin in pairs(plugins) do
    if plugin.cron ~= nil then
      plugin.cron()
    end
  end
  postpone (cron_plugins, false, 120)
end
our_id = 0
now = os.time()
math.randomseed(now)
started = false
