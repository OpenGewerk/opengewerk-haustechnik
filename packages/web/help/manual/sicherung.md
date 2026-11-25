# Sicherung und Rückspielen

Die Sicherung läuft jede Nacht von selbst, zu der Uhrzeit, die der Bereich der Instanz festlegt, und holt eine verpasste nach. Jede Sicherung nimmt die Datenbank und den Dateispeicher zusammen mit.

Wie ein Archiv verschlüsselt wird und wohin es gehört, steht in `docker/.env.example`. Eine Sicherung, die auf derselben Platte liegt wie die Instanz, schützt nicht vor dem Ausfall dieser Platte.

## Von Hand

- Sichern, etwa vor einem Update: `docker compose -f docker/compose.yaml --profile backup run --rm backup backup.sh`
- Prüfen, ob sich die letzte Sicherung lesen lässt: `docker compose -f docker/compose.yaml --profile backup run --rm backup verify.sh latest`
- Zurückspielen: zuerst die Anwendung und die nächtliche Sicherung anhalten, `docker compose -f docker/compose.yaml stop app backup-schedule`, dann `docker compose -f docker/compose.yaml --profile backup run --rm backup restore.sh latest`, und erst wenn beides ohne Fehler durchlief, mit `sh docker/start.sh` starten. Das führt wie nach einem Update die Migrationen aus, falls die Sicherung von einer älteren Fassung stammt, und gibt der Anwendung ihre Anmeldung zurück. Verbinde die drei Befehle mit `&&`, dann läuft keiner, wenn der davor scheitert. Eine Datei, die in der Sicherung beschädigt ist, findet `restore.sh`, bevor es etwas ändert; Datenbank und Dateispeicher bleiben dann, wie sie waren, und du startest die Instanz mit `sh docker/start.sh` auf dem alten Stand oder nimmst eine andere Sicherung. Bricht es erst später ab, bleibt die Anwendung ausgesperrt. Das prüft `sh docker/start.sh` für dich: Ist ein Rückspielen auf halbem Weg stehen geblieben, startet es weder die Anwendung noch die nächtliche Sicherung und sagt das. Dann behebst du die Ursache und spielst die Sicherung noch einmal zurück.

## Beim Rückspielen

1. Das Rückspielen ersetzt den Stand der Instanz durch den der Sicherung. Was danach eingetragen wurde, ist nicht mehr da.
2. Statt `latest` nennt der Befehl auch ein Archiv mit seinem Namen.
3. Jede Datei wird gegen ihre Prüfsumme geprüft.
4. Ein Archiv einer anderen Anwendung lehnen `restore.sh` und `verify.sh` ab.
