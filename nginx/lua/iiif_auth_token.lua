-- Ce petit bout de code ne fait que récupérer le token JWT qu'on a setté dans
-- un cookie via /auth/process (et qui a lui meme fait l'authentication sur
-- agatha).

local jwt = require("resty.jwt")
local secret = os.getenv("JWT_SECRET") or "secret"

-- on récupere le token qui a été mis dans un cookie
local token_cookie = ngx.var.cookie_iiif_session

if not token_cookie then
	-- Pas de cookie = Pas connecté
	ngx.status = ngx.HTTP_UNAUTHORIZED
	ngx.say('{"error": "No session cookie found"}')
	ngx.exit(ngx.HTTP_UNAUTHORIZED)
end

-- on check si c'est toujours valide.
local jwt_obj = jwt:verify(secret, token_cookie)

if not jwt_obj["verified"] then
	ngx.status = ngx.HTTP_UNAUTHORIZED
	ngx.say('{"error": "Invalid or expired session"}')
	ngx.exit(ngx.HTTP_UNAUTHORIZED)
end

-- on renvoie enfin un json avec le accessToken dont mirador a besoin
-- Mirador va prendre ce "accessToken" et le mettre dans le header Authorization des images
ngx.say('{"accessToken": "' .. token_cookie .. '", "expiresIn": 3600}')
