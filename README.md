# obc40-screensaver

A screensaver you switch on with the **power key on the back** of the **OBC40** board (NXP i.MX 8M Mini, 1024×600 touch display) running **Alpine Linux with XFCE**.

*Italiano: [vai alla sezione in italiano](#italiano).*

## What it does

- Press the power key: the screen fills with 3D pipes that grow in perspective, with the clock and the date on top. The backlight goes down to 5%.
- Press the key again, or touch the screen: the screensaver goes away and the backlight comes back to where it was. The touch that closes it does not reach the window below, so it never clicks anything by mistake.
- The pipes grow in a 16×10×8 grid. When the screen is full they fade out and start again. The clock moves every 20 s so that nothing stays still on the panel.
- Pressing the key never shuts the board down: turn the board off from the home screen (see [How it works](#how-it-works)).

## Requirements

- An OBC40 running Alpine Linux with an XFCE session for a normal user, and `xfce4-power-manager` running in it.
- Python 3 with GTK 3 and cairo: `apk add py3-gobject3 py3-cairo gtk+3.0` (as root).
- The user must be able to read the power key, `/dev/input/event0`. On Alpine that means being in the `input` group: `addgroup <user> input` as root, then log out and in again.
- For dimming, the user must be in the `video` group (`addgroup <user> video` as root). Without it the screensaver still works, but the brightness does not change.

Two small system files need root once (see [Install](#install)). Everything else installs in your home directory.

## Install

Copy this folder to the board (or clone the repository there). First, **once, as root**:

```sh
sh install.sh --system
```

This stops elogind from shutting the board down when the power key is pressed (`/etc/elogind/logind.conf.d/90-obc40-powerkey.conf`), and lets the `video` group change the backlight (`/etc/udev/rules.d/91-obc40-backlight.rules`). Both take effect at once, without a reboot. `sh install.sh --system --uninstall` removes them.

Then, in a terminal **inside the XFCE session, as the desktop user** (not root), run:

```sh
sh install.sh
```

The installer:
1. checks the requirements above and tells you what is missing;
2. copies `obc-screensaver` to `~/.local/bin/` and adds `~/.config/autostart/obc-screensaver.desktop`, so it starts at every XFCE login;
3. sets the XFCE power button action to *do nothing*;
4. starts the screensaver right away.

Options:

| Option | Effect |
|---|---|
| `--dim N` | backlight at N% while the screensaver is shown (default 5, `0` = leave it as it is) |
| `--no-autostart` | install only, do not start it at login |
| `--uninstall` | stop it and remove its files. The power button setting stays as it is |
| `--system` | as root: the system part described above. With `--uninstall`, remove it |

Running `sh install.sh` again updates the installed copy.

To see it without pressing the key, run `~/.local/bin/obc-screensaver --demo`. Touch the screen to close it.

## How it works

- `obc-screensaver` is a single Python/GTK 3 program. It reads the key events straight from the `snvs-powerkey` input device, and it toggles on each key press.
- The screensaver is a fullscreen window kept above the others. It grabs the touch screen and the mouse, so that the touch that closes it is used up there.
- **Why the key does not power off.** By default, elogind powers the board off when the power key is pressed, and the XFCE setting alone does not stop it. The file installed by `--system` sets `HandlePowerKey=ignore` and `HandlePowerKeyLongPress=ignore`, so elogind ignores the key at all times, even outside the XFCE session. The XFCE *power-button-action* is also set to 0 (do nothing). Turn the board off from the home screen.
- **Drawing.** Each pipe section is a shaded cylinder drawn with a cairo mesh gradient, and the elbows are shaded spheres. Both use the same light. Each frame draws only what is new, on one transparent layer per half cell of depth. The changed rectangles are then put back together from the back to the front, so a far pipe always stays behind a near one. On the OBC40 a frame takes about 2 ms and the program uses about 60 MB of RAM.
- Settings such as grid size, speed, colours and the number of pipes at once are constants at the top of the `obc-screensaver` file.

## Files

| Path | What |
|---|---|
| `~/.local/bin/obc-screensaver` | the program |
| `~/.config/autostart/obc-screensaver.desktop` | starts it with XFCE |
| `$XDG_RUNTIME_DIR/obc-screensaver-<uid>.lock` | keeps a second copy from running |
| `/etc/elogind/logind.conf.d/90-obc40-powerkey.conf` | (`--system`) elogind ignores the power key |
| `/etc/udev/rules.d/91-obc40-backlight.rules` | (`--system`) the `video` group may change the backlight |

---

## Italiano

Un salvaschermo che si accende con il **tasto di accensione sul retro** dell'**OBC40** (NXP i.MX 8M Mini, display touch 1024×600) con **Alpine Linux e XFCE**.

### Cosa fa

- Premi il tasto: lo schermo si riempie di tubi 3D che crescono in prospettiva, con davanti l'orologio e la data. La retroilluminazione scende al 5%.
- Premi di nuovo il tasto, o tocca lo schermo: il salvaschermo sparisce e la luminosità torna com'era. Il tocco che lo chiude non arriva alla finestra sotto, quindi non clicca niente per sbaglio.
- I tubi crescono in una griglia 16×10×8. Quando lo schermo è pieno sfumano e si ricomincia. L'orologio si sposta ogni 20 s, così niente resta fermo sul pannello.
- Il tasto non spegne mai la scheda: per spegnerla si usa la home.

### Requisiti

- Alpine Linux con una sessione XFCE per un utente normale, e `xfce4-power-manager` attivo.
- Python 3 con GTK 3 e cairo: `apk add py3-gobject3 py3-cairo gtk+3.0` (da root).
- L'utente deve poter leggere il tasto, `/dev/input/event0`: deve essere nel gruppo `input` (`addgroup <utente> input` da root, poi uscire e rientrare).
- Per abbassare la luminosità l'utente deve essere nel gruppo `video` (`addgroup <utente> video` da root). Senza funziona lo stesso, ma la luminosità non cambia.

### Installazione

Copia questa cartella sulla scheda, oppure clona lì il repository. Prima, **una volta sola, da root**:

```sh
sh install.sh --system
```

Così elogind non spegne più la scheda quando si preme il tasto, e il gruppo `video` può cambiare la luminosità. Vale subito, senza riavviare. `sh install.sh --system --uninstall` lo toglie.

Poi, in un terminale **dentro la sessione XFCE, come utente del desktop** (non root):

```sh
sh install.sh
```

L'installer controlla i requisiti e copia il programma in `~/.local/bin/`. Aggiunge l'avvio automatico con XFCE e imposta l'azione del tasto di accensione di XFCE su *non fare niente*. Infine avvia subito il salvaschermo.

Opzioni: `--dim N` (luminosità in % durante il salvaschermo, default 5, `0` = invariata), `--no-autostart` (solo installazione), `--uninstall` (lo ferma e lo rimuove). Rilanciare `sh install.sh` aggiorna la copia installata.

Per vederlo senza premere il tasto: `~/.local/bin/obc-screensaver --demo`, poi tocca lo schermo per chiuderlo.

### Come funziona

- Il programma legge il tasto direttamente dal dispositivo `snvs-powerkey`. Il salvaschermo è una finestra a tutto schermo sopra le altre, che cattura touch e mouse.
- **Perché il tasto non spegne.** Di default elogind spegne la scheda alla pressione del tasto, e l'impostazione di XFCE da sola non basta a fermarlo. Il file installato da `--system` imposta `HandlePowerKey=ignore` e `HandlePowerKeyLongPress=ignore`, così elogind ignora sempre il tasto, anche fuori dalla sessione XFCE. Per spegnere la scheda si usa la home.
- **Disegno.** I tratti dei tubi sono cilindri ombreggiati con un mesh gradient di cairo, e i gomiti sono sfere: entrambi hanno la stessa luce. A ogni fotogramma si disegna solo la parte nuova, su un livello trasparente ogni mezza cella di profondità. Poi si ricompongono dal fondo i rettangoli cambiati, così un tubo lontano resta sempre dietro a uno vicino. Sull'OBC40 un fotogramma richiede circa 2 ms e il programma usa circa 60 MB di RAM.
- Griglia, velocità, colori e numero di tubi contemporanei sono costanti in cima al file `obc-screensaver`.
