local A, C, L, _ = unpack(select(2, ...))
if GetLocale() ~= "ptBR" and GetLocale() ~= "ptPT" then return end

-----------------------------
--	ptBR and ptPT clients
-----------------------------
-- main frame
L.gui.threat		= "Ameaça"