local function run(msg)
    local data = load_data(_config.moderation.data)

     if data[tostring(msg.to.id)]['settings']['lock_english'] == 'yes' then
if msg.to.type == 'channel' and not is_momod(msg) then
	delete_msg(msg.id,ok_cb,false)
        return 
      end
   end
end

return {patterns = {
"[qwertyuioplkjhgfdsazxcvbnmQWERTYUIOPLKJHGFDSAZXCVBNM]",
}, run = run}
