# anti scraping

Un exemple pour la facon de configurer ngnix pour qu'il utilise un token
jwt qui sert à faire l'authentification des utilisateur.


## Lancer le prototype
```
docker compose up --build
```

## voire que ca marche (ou pas)

http://localhost?id=527_0236_000_00357_000

(on ne doit rien voir)

Mais si on fait d'abord un tour par

http://localhost/login.html

ca devrait passer
