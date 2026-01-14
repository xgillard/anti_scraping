local cjson = require("cjson")

-- 1. Récupérer le chemin demandé (ex: /data/json/527/...)
-- On suppose que votre proxy mime la structure de l'URL originale
local original_uri = ngx.var.uri
local query_string = ngx.var.query_string -- pour garder ?nocache=...

-- 2. Aller chercher le JSON original chez Agatha
-- On utilise une "location" interne Nginx définie plus bas
local res = ngx.location.capture("/upstream_agatha" .. original_uri, {
	args = query_string,
})

if res.status ~= 200 then
	ngx.status = res.status
	ngx.say(res.body)
	return
end

-- 3. Parser le JSON
local json_data = cjson.decode(res.body)

-- Config de votre Proxy et Auth
local my_proxy_url = "http://" .. ngx.var.host .. "/iiif"
local auth_service_block = {
	["@context"] = "http://iiif.io/api/auth/1/context.json",
	["@id"] = "http://" .. ngx.var.host .. "/auth", -- Votre URL de login
	["profile"] = "http://iiif.io/api/auth/1/login",
	["label"] = "Connexion Requise (Archives)",
	["service"] = {
		{
			["@id"] = "http://" .. ngx.var.host .. "/token",
			["profile"] = "http://iiif.io/api/auth/1/token",
		},
	},
}

-- 4. Fonction récursive pour modifier les séquences/canvas/images
-- On doit descendre dans l'arborescence pour trouver les images
if json_data.sequences then
	for _, seq in ipairs(json_data.sequences) do
		if seq.canvases then
			for _, canvas in ipairs(seq.canvases) do
				if canvas.images then
					for _, img in ipairs(canvas.images) do
						local resource = img.resource

						-- C'est ici qu'on modifie !
						if resource and resource.service then
							-- A. Réécriture de l'URL de l'image
							-- On remplace le domaine i3f par votre proxy
							-- Ex: https://i3f.arch.be/iiif/123 -> http://mon-proxy/iiif/123
							local original_service_id = resource.service["@id"]

							-- On remplace le début de l'URL (simple string replacement)
							-- Adaptez "https://i3f.arch.be/iiif" selon votre réalité exacte
							local new_service_id =
								string.gsub(original_service_id, "https://i3f%.arch%.be/iiif", my_proxy_url)

							resource.service["@id"] = new_service_id

							-- On met aussi à jour l'ID de la ressource image elle-même
							resource["@id"] = string.gsub(resource["@id"], "https://i3f%.arch%.be/iiif", my_proxy_url)

							-- B. Injection du bloc Auth
							resource.service["service"] = auth_service_block
						end
					end
				end
			end
		end
	end
end

-- 5. Renvoyer le JSON modifié
ngx.header.content_type = "application/json"
ngx.say(cjson.encode(json_data))
