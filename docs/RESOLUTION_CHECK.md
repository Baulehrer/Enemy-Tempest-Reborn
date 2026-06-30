# Resolution Check

Stand: 2026-06-30

## Ergebnis

FS-UAE 3.2.35 uebernimmt die vom Launcher geschriebenen
`window_width`/`window_height` Werte.

| Launcher Scale | Config-Werte | FS-UAE Log-Nachweis |
| --- | --- | --- |
| `2x` | `window_width = 640`, `window_height = 480` | `setting (windowed) video mode 640 480` |
| `3x` | `window_width = 960`, `window_height = 720` | `setting (windowed) video mode 960 720` |
| `4x` | `window_width = 1280`, `window_height = 960` | `setting (windowed) video mode 1280 960` |

Die Testconfigs liegen hier:

```text
work/resolution-check/enemy1_de_2x.fs-uae
work/resolution-check/enemy1_de_3x.fs-uae
work/resolution-check/enemy1_de_4x.fs-uae
```

Die zugehoerigen FS-UAE-stdout-Logs liegen hier:

```text
work/resolution-check/2x.stdout.log
work/resolution-check/3x.stdout.log
work/resolution-check/4x.stdout.log
```

## Einordnung

Dieser Check bleibt als Mess-/Debug-Nachweis erhalten. Fuer den normalen
Spielstart ist inzwischen `Fullscreen` der Launcher-Default; `2x`/`3x`/`4x`
sind keine primaeren Spieleroptionen mehr.

## Einschraenkung

`xdotool` konnte die sichtbare Fenstergeometrie nicht messen, weil das aktuelle
Desktop-Setup die FS-UAE-Fenster nicht als X11-Fenster meldet. Der Nachweis
kommt daher aus den FS-UAE-Logs.

Wichtig: Der Log zeigt weiterhin:

```text
scale: -1.00 -1.00 align: 0.50 0.50
```

Das bedeutet: Die Fensteraufloesung wird korrekt gesetzt, aber der interne
FS-UAE-Renderer verwendet weiterhin Auto-Scaling. Pixelgenaue Integer-Skalierung
ist damit noch nicht abschliessend nachgewiesen. Fuer echte `sharp pixels`,
`smooth pixels`, CRT/xBRZ usw. muss der FS-UAE-Renderpfad spaeter gezielter
verdrahtet oder geforkt werden.
