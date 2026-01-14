#######
# Note Importante: j'utlise openresty et non pas un ngnix "tout cru" parce que
# je vais demander a ngnix d'exécuter un peu de code lua qui va servir à faire
# la vérification des tokens JWT
#######
FROM openresty/openresty:1.27.1.2-0-alpine

# 1. On installe curl et tar pour télécharger et extraire
# openssl-dev est nécessaire pour les fonctions crypto
RUN apk add --no-cache curl tar openssl-dev

# ---------------------------------------------------------------------
# Installation manuelle des dépendances pour pouvoir gérer le JWT en lua
# ---------------------------------------------------------------------
RUN curl -fSL https://github.com/jkeys089/lua-resty-hmac/archive/refs/tags/0.06-1.tar.gz -o hmac.tar.gz \
    && tar -zxvf hmac.tar.gz \
    && cp -r lua-resty-hmac-0.06-1/lib/resty/* /usr/local/openresty/lualib/resty/ \
    && rm -rf hmac.tar.gz lua-resty-hmac-0.06-1

RUN curl -fSL https://github.com/SkyLothar/lua-resty-jwt/releases/download/v0.1.11/lua-resty-jwt-0.1.11.tar.gz -o jwt.tar.gz \
    && tar -zxvf jwt.tar.gz \
    && cp -r lua-resty-jwt-0.1.11/lib/resty/* /usr/local/openresty/lualib/resty/ \
    && rm -rf jwt.tar.gz lua-resty-jwt-0.1.11

# Nettoyage
RUN rm -rf /var/cache/apk/*

# A ne pas oublier: 
# il faut monter la configuration de ngnix via un volume (ou alors la copier
# directement dans le conteneur). 

