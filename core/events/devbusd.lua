function peripheral(event, peripheral)
  if event == 'peripheral' then
    devbus.devices = devbus.populate()
  end
end

function detach(event, peripheral)
  if event == 'peripheral_detach' then
    devbus.devices = devbus.populate()
  end
end
