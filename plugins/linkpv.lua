do

function run(msg, matches)
       if not is_momod(msg) then
        return "فقط مدیران"
       end
	  local data = load_data(_config.moderation.data)
      local group_link = data[tostring(msg.to.id)]['settings']['set_link']
       if not group_link then 
        return "ابتدا لینک جدیدی بسازید، یا لینک را ذخیره کنید."
       end
         local text = "‌\nTeleGoldⓒ вот\n………………………………………\nلینک در پی وی شما:\n"..group_link.."\n………………………………………"          send_large_msg('user#id'..msg.from.id, text.."\n", ok_cb, false)
end

return {
  patterns = {"^لینک پی وی$"},
  run = run
}

end
