function main()
  if kthread and threading and threading.scheduler then
    threading.scheduler:spawnThread(
      function()
        while true do
          local data = {coroutine.yield()}
          for k, v in pairs(kthread.getHandlers()) do
            v(unpack(data))
          end
        end
      end
    ,'kernel event handler')
  end
end
