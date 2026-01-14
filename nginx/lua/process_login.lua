local jwt = require("resty.jwt")

-- 1. Lire les données du formulaire POST
ngx.req.read_body()
local args, err = ngx.req.get_post_args()

if not args then
	ngx.say("Erreur de formulaire")
	return
end

-- 2. Interroger le vieux serveur PHP (Sous-requête)
-- On envoie les mêmes params à la route interne définie dans nginx.conf
local res = ngx.location.capture("/internal-php-login", {
	method = ngx.HTTP_POST,
	body = ngx.encode_args({
		username = args.username,
		password = args.password,
	}),
})

-- 3. Vérifier la réponse du PHP
if res.status == 200 and res.body == "1" then
	-- A. On génère le JWT ici
	local secret = os.getenv("JWT_SECRET") or "secret"
	local token = jwt:sign(secret, {
		header = { typ = "JWT", alg = "HS256" },
		payload = {
			sub = args.username, -- On utilise le username comme ID
			iss = "iiif_auth_bridge",
			exp = os.time() + 3600, -- Expire dans 1h
		},
	})

	-- B. On stocke ce JWT dans un Cookie "HttpOnly"
	-- C'est ce cookie que le navigateur va retenir
	local cookie = "iiif_session=" .. token .. "; Path=/; HttpOnly; SameSite=Lax"
	ngx.header["Set-Cookie"] = cookie

	ngx.exec("/cnx_success.html")
else
	ngx.exec("/cnx_failed.html")
end
