local _VFS = class(
	function(self)

		self._fsreg = {} -- Filesystem registry
		self._mtab  = {} -- Mount table
	end
)

-- Mounts an unmounted filesystem, with variable argument otions:
function _VFS:mount(node, fstype, path, ...)

	-- TODO
end

-- Unmounts a mounted filesystem on path:
function _VFS:umount(path)

	-- TODO
end

-- Registers a filesystem. driver must be a valid driver kernel object:
function _VFS:registerFS(name, driver)

	-- TODO
end

-- Unregisters a filesystem. This should only be called when a driver
-- that implements a filesystem becomes unloaded:
function _VFS:unregisterFS(name)

	-- TODO
end

-- Opens a file with options:
function _VFS:open(path, ...)

end

local _vfs = modules.module 'vfs' {
	text = {
		load = function()
			_G.vfs = _VFS
		end,
		unload = function()

			_G.vfs = nil
			-- TODO: We should probably panic()
		end
	}
}
