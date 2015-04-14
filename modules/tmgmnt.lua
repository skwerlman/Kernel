local tardixi = {}
tardixi.vmm = {
  ["allow"] = function(k, ...)
    return true
  end,
  ["sysc"] = function(k, ...)
    return false
  end,
  ["def"] = true
}

local tardix = {}

function tardix.setVmm(vmm)
  if tardixi.vmm.def == true then
    tardixi.vmm = vmm
  else
    error("Can not override currently-running VMM.")
  end
end

function tardix.runSystem(k, ...)
  if tardixi.vmm.allow(k, ...) then
    return tardixi.vmm.sysc(k, ...)
  end
end

modules.module "tardix-management" {
  ["text"] = {
    ["load"] = function()
      _G.tardix = tardix
    end,
    ["unload"] = function()
      _G.tardix = nil
    end
  }
}
