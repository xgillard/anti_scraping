#######
# Note Importante: j'utlise openresty et non pas un ngnix "tout cru" parce que
# je vais demander a ngnix d'exécuter un peu de code lua qui va servir à faire
# la vérification des tokens JWT
#######
FROM openresty/openresty:1.27.1.2-0-alpine-fat

RUN opm get SkyLothar/lua-resty-jwt

# A ne pas oublier: 
# il faut monter la configuration de ngnix via un volume (ou alors la copier
# directement dans le conteneur). 

