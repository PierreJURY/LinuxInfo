# Linux Information

Permet d'afficher toutes les informations utiles de votre distribution Linux
Les informations ci-dessous sont lister par le script :

* Distribution
* Modèle de l'ordinateur
* Nom de l'ordinateur
* Processeur
* Nombre de coeur
* Architecture
* Carte graphique
* Mémoire
* Taille du swap
* Listes des disques et leurs espace
* Carte réseau


## Compatibilité

Compatible avec toutes les distributions récente


## Utilisation

### wget

```bash
wget https://raw.githubusercontent.com/PierreJURY/LinuxInfo/main/info.sh -qO - | bash -s
```

### curl

```bash
curl https://raw.githubusercontent.com/PierreJURY/LinuxInfo/main/info.sh | bash -s
```
