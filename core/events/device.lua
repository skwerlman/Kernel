while true do
  local data = {coroutine.yield()}
  if data[1] == 'peripheral' then
    print('hooray.')
  end

end
