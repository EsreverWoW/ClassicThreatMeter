local A, C, L, _ = unpack(select(2, ...))
if A.locale ~= "ptBR" and GetLocale() ~= "ptPT" then return end

-----------------------------
--	ptBR and ptPT clients
-----------------------------
-- main frame
L.gui_threat		= "Ameaça"

-- config frame
L.default			= "Padrão"
