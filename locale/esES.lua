local A, C, L, _ = unpack(select(2, ...))
if GetLocale() ~= "esES" and GetLocale() ~= "esMX" then return end

-----------------------------
--	esES and esMX clients
-----------------------------
-- main frame
L.gui.threat		= "Amenaza"