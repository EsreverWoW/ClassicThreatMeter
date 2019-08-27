local A, C, L, _ = unpack(select(2, ...))
if A.locale ~= "esES" and GetLocale() ~= "esMX" then return end

-----------------------------
--	esES and esMX clients
-----------------------------
-- main frame
L.gui_threat		= "Amenaza"

-- config frame
L.default			= "Predeterminado"
