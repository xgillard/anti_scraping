-- Ce bout de code sert à faire deux choses:
-- 1. vérifier le token jwt dans les headers de toutes les requetes qui
--    demandent à avoir accès aux images servies par le server iiif
-- 2. implémenter un controle de cache qui limite le nombre d'images qu'un
--    utilisateur peut voir par jour (on parle bien d'images, pas de tuiles
--    et on implémente ça en utilisant redis histoire d'être performant et
--    de protéger toutes les requetes, meme celles qui cherchent à bypasser
--    agatha).

local jwt = require("resty.jwt")
local redis = require("resty.redis")

-- 1. CONFIGURATION
local secret = os.getenv("JWT_SECRET") or "default"
local redis_host = os.getenv("REDIS_HOST") or "127.0.0.1"
local redis_port = os.getenv("REDIS_PORT") or 6379

-- 2. VERIFICATION TOKEN
local auth_header = ngx.var.http_authorization
if not auth_header then
	ngx.status = ngx.HTTP_UNAUTHORIZED
	ngx.say('{"error": "Missing Authorization Header"}')
	ngx.exit(ngx.HTTP_UNAUTHORIZED)
end

local token = string.sub(auth_header, 8)
local jwt_obj = jwt:verify(secret, token)

if not jwt_obj["verified"] then
	ngx.status = ngx.HTTP_UNAUTHORIZED
	ngx.say('{"error": "Invalid Token"}')
	ngx.exit(ngx.HTTP_UNAUTHORIZED)
end

-- 3. CONNEXION REDIS (Distante cette fois)
local red = redis:new()
red:set_timeout(1000) -- 1 sec timeout

local ok, err = red:connect(redis_host, redis_port)
if not ok then
	ngx.log(ngx.ERR, "Redis connection failed: ", err)
	-- En prod: soit on bloque (fail close), soit on laisse passer (fail open)
	return
end

-- 4. LOGIQUE QUOTA (SADD)
-- On cherche l'ID image dans l'URL.
-- Suppose une URL type: /iiif/MON-IMAGE-ID/full/0/default.jpg
local image_id = string.match(ngx.var.uri, "/iiif/([^/]+)/")

if image_id then
	local user_id = jwt_obj["payload"]["sub"]
	local today = os.date("%Y-%m-%d")
	local key = "quota:" .. user_id .. ":" .. today

	-- Ajout au Set Redis
	local is_new, err = red:sadd(key, image_id)

	if is_new == 1 then
		-- C'est une nouvelle image pour ce user aujourd'hui
		local count, err = red:scard(key)

		-- Expiration 24h au premier ajout
		if count == 1 then
			red:expire(key, 86400)
		end

		-- Seuil fixé à 100 images
		if count > 100 then
			ngx.status = ngx.HTTP_FORBIDDEN
			ngx.say('{"error": "Daily quota exceeded (100 images)"}')
			ngx.exit(ngx.HTTP_FORBIDDEN)
		end
	end
end

-- 5. KEEP-ALIVE (Très important pour la perf réseau entre conteneurs)
red:set_keepalive(10000, 100)
