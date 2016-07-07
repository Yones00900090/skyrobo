function run(msg, matches)
local reply = msg['id']
local text = 'جان :)'
local text2 = 'جان بابایی :)'
if not is_sudo(msg) then
reply_msg(reply, text, ok_cb, false)
elseif is_sudo(msg) then
reply_msg(reply, text2, ok_cb, false)
end
end
return {
patterns = {
"^تله گولد$",
"^تله گولد؟$",
"^رباتی؟$",
"^ربات جون$",
"^ربات جون؟$",
"^ربوت؟$",
"^ربات؟$",
"^ربوت؟$",
"^ربات$",
"^رباط؟$",
"^رباط$"
},
run = run
}
