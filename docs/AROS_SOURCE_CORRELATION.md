# AROS Source Correlation

Stand: 2026-06-28

## Ergebnis

AROS bleibt nicht dauerhaft beim ersten ROMTag-Scan stehen. Die Runtime-Captures
zeigen drei Phasen:

1. Frueh: AROS scannt ROM-Bereiche nach Resident-Strukturen.
2. Spaeter: AROS erreicht Code nahe `trackdisk.device` und arbeitet offenbar an
   Floppy-/MFM-Daten.
3. Danach: AROS laeuft in einen Reset-Pfad. Im 60s-Capture steht vorher eine
   68000-Exception 3 bei `0x00f87452`.

Damit ist die bisherige Annahme "AROS erzeugt keine Diskettenaktivitaet" zu
hart formuliert. Belegt ist jetzt: AROS kommt spaet bis in Disk-Code, erreicht
aber keinen stabilen Enemy-/DOS-Bootzustand.

## Runtime-Belege

| Capture | Debugger-Zeit | PC | Interpretation |
| --- | ---: | --- | --- |
| `enemy1_aros_a500_20260628T101244+0200` | 4s | `0x00fe88c6` | ROMTag-/Resident-Scan |
| `enemy1_aros_a500_20260628T103847+0200` | 30s | `0x00fb31a4` | Code nahe `trackdisk.device`, MFM/Bit-Masken |
| `enemy1_aros_a500_20260628T104020+0200` | 60s | `0x00fe8908` | Wieder ROMTag-/Resident-Scan nach Reset |

Der 60s-Log enthaelt vor dem Reset:

```text
Exception 3 (2489 f87452) at f87452 -> fe774c!
Reset at 00F85894. Chipset mask = 00000000
```

Auf 68000 ist Exception 3 ein Address-Error. Das ist wahrscheinlich naeher am
eigentlichen Fehler als der spaeter erneut sichtbare ROMTag-Scan.

## Source-Abgleich

Die AROS-Quellen wurden aus dem oeffentlichen Repository
`aros-development-team/AROS` verglichen. Das ist ein struktureller Abgleich mit
dem aktuellen Source-Tree, kein bytegenauer Build-Nachweis fuer das konkrete
Nightly-ROM.

Relevante Dateien:

- `rom/kernel/kernel_romtags.c`
- `compiler/include/exec/resident.h`
- `arch/m68k-amiga/boot/start.c`
- `rom/dosboot/bootstrap.c`
- `rom/exec/findresident.c`

Der ROM-Code bei `0x00fe88c2`:

```asm
00fe88c2: cmpi.w #$4afc,(a2)
00fe88c8: cmpa.l $2(a2),a2
```

passt zu `krnScanResidents()` aus `rom/kernel/kernel_romtags.c`:

```c
if (res->rt_MatchWord == RTC_MATCHWORD && res->rt_MatchTag == res)
```

`RTC_MATCHWORD` ist in `compiler/include/exec/resident.h` als `0x4AFC`
definiert.

Die Runtime-Register passen ebenfalls:

- `A2`: aktueller Scan-Zeiger.
- `D2`: Ende des aktuellen Scan-Bereichs.
- `A4`: Callback-Funktion fuer Count/Register.
- `D4`: optionaler Callback-Parameter.

Der m68k-Amiga-Startcode baut die Scanbereiche in `arch/m68k-amiga/boot/start.c`
auf und ruft danach `krnPrepareExecBase(kickrom, ...)`.

## Enemy-Bootblock

Der Bootblock von `ENEMY1_V2_DE_A.adf` ist ein DOS-Bootblock und macht am
Anfang nur:

```asm
lea     dos.library(pc),a1
jsr     -$60(a6)        ; Exec FindResident
tst.l   d0
beq     failure
movea.l d0,a0
movea.l $16(a0),a0     ; rt_Init
moveq   #0,d0
rts
```

Das bestaetigt: Die erste harte Kickstart-Abhaengigkeit ist `FindResident` fuer
`dos.library` und die anschliessende Initialisierung ueber den Resident-Tag.

## Aktuelle Schlussfolgerung

`boot-only` ist noch nicht bewiesen, weil wir noch keinen erfolgreichen
Bootblock-Handoff mit AROS haben. Aber der aktuelle Fehler liegt wahrscheinlich
vor oder waehrend DOS-/Trackdisk-Boot, nicht in spaeterem Enemy-Spielcode.

Naechster sinnvoller Schritt: gezielt den Address-Error bei `0x00f87452`
untersuchen und mappen, inklusive Stack/Return-Adresse, statt weiter nur
spaete PCs im Reset-Loop zu sammeln.

## Address-Error-Nachverfolgung

Der Address-Error wurde auf die Exec-Listenroutine `AddTail()` eingegrenzt.
AROS-Source: `rom/exec/addtail.c`.

Der relevante ROM-Code:

```asm
00f8743c: move.l a2,-(a7)
00f8743e: lea.l  $4(a0),a2
00f87442: move.l a2,(a1)
00f87444: move.l $8(a0),$4(a1)
00f8744a: movea.l $8(a0),a2
00f8744e: move.l a1,(a2)
00f87450: move.l a1,$8(a0)
00f87454: movea.l (a7)+,a2
00f87456: rts
```

Das entspricht der AROS-Source-Logik:

```c
node->ln_Succ              = (struct Node *)&list->lh_Tail;
node->ln_Pred              = list->lh_TailPred;
list->lh_TailPred->ln_Succ = node;
list->lh_TailPred          = node;
```

UAE meldet den spaeteren Fehler als:

```text
Exception 3 (2489 f87452) at f87452 -> fe774c!
```

`0x2489` ist der Opcode fuer `MOVE.L A1,(A2)`. Die gemeldete Adresse
`0x00f87452` liegt unmittelbar im folgenden Store und ist daher als UAE-
Exception-Kontext zu lesen; der relevante Codebereich beginnt bei
`0x00f8743c`, der kritische Store bei `0x00f8744e`.

Ein gezielter Breakpoint-Lauf mit stdin-Kommandos:

```bash
HOTKEY_DELAY=2 \
DEBUGGER_COMMAND_DELAY=1 \
DEBUGGER_COMMAND_METHOD=stdin \
DEBUGGER_COMMANDS=$'f f8744e\nil 8\ng\nr\nm 0003fd80 80\nm 00c00870 20\nm 00c010b0 20\nm 00000400 20\nd f8743c 20\n' \
./scripts/capture_kickstart_runtime.sh enemy1 a500 aros 45
```

erzeugte den Capture
`work/kickstart-deps/runtime/enemy1_aros_a500_20260628T163248+0200`.

Erfasster erster `AddTail()`-Treffer:

```text
A0 00C0087E   A1 00C010C0   A2 00C0087E   A3 00C00560
A4 00F8C5D6   A5 00F8C65C   A6 00C00560   A7 0003FEA8
PC 00F8744E
```

Der Stackdump zeigt fuer diesen Treffer als naechste ROM-Return-Adresse
`0x00f8c60c`. Das mappt auf den Code direkt nach:

```asm
00f8c608: jsr -$f6(a6)
00f8c60c: lea.l $c(a7),a7
```

`-$f6(a6)` ist Exec `AddTail`. Damit ist der erfasste Callsite-Kontext:
ROM-Code um `0x00f8c5d6` ruft `AddTail(list=A0,node=A1)`.

Ein langer Breakpoint-Lauf
`work/kickstart-deps/runtime/enemy1_aros_a500_20260628T165025+0200`
erfasste 98 `AddTail()`-Treffer. In diesen Treffern lagen `A0`, `A1` und `A2`
in Chip- oder Slow-RAM und waren gerade ausgerichtet. Der eigentliche
Address-Error trat dabei nicht mehr auf. Das ist ein wichtiger Vorbehalt:
Der Breakpoint veraendert Timing/Ablauf genug, dass der spaetere Reset-Fehler
in diesem Lauf nicht reproduziert wurde.

Aktueller Stand:

- `binary/runtime`: `0x00f8744e` ist sicher `AddTail()`/`MOVE.L A1,(A2)`.
- `source`: Die Sequenz passt exakt zu `rom/exec/addtail.c`.
- `runtime`: Ein normaler `AddTail()`-Callsite wurde mit Stack und Return
  `0x00f8c60c` erfasst.
- `offen`: Der konkrete kaputte `AddTail()`-Aufruf direkt vor Exception 3 ist
  noch nicht isoliert, weil Breakpoints den Fehler nicht mehr ausloesen.

## Illegal-Access-Watcher

Als naechster Versuch wurde der UAE-Debugger-Watcher fuer illegale Zugriffe
getestet, um den Address-Error moeglichst direkt zu erwischen, ohne bei jedem
`AddTail()`-Aufruf zu stoppen.

Capture mit `wd 1`:

```bash
HOTKEY_DELAY=2 \
DEBUGGER_COMMAND_DELAY=1 \
DEBUGGER_COMMAND_METHOD=stdin \
DEBUGGER_COMMANDS=$'wd 1\ng\nr\nm 0003fd80 80\nm 00c00000 20\nm 00c00870 20\nm 00c010b0 20\nm 00c2e500 40\nd f8743c 24\nH 32\n' \
./scripts/capture_kickstart_runtime.sh enemy1 a500 aros 75
```

Ergebnisordner:
`work/kickstart-deps/runtime/enemy1_aros_a500_20260628T175405+0200`.

Der Debugger bestaetigt:

```text
Memwatch breakpoints enabled
Illegal memory access logging enabled. Break=1
```

Der erste Treffer war aber nicht der spaetere `AddTail()`-Address-Error,
sondern ein Zugriff auf Custom-Register:

```text
WO: 00DFF07D    PC=00FC8F88
WO: 00DFF07C    PC=00FC8F88
```

Die gemappten Reports `pc_00fc8f88_map_report.md` und
`pc_00fc8f94_map_report.md` zeigen ROM-Code in
`kickstart_rom_f8_512k`, Offset `0x048f88`/`0x048f94`, mit dieser Sequenz:

```asm
00fc8f68: move.w $dff004.l,d0
00fc8f88: move.w $dff07c.l,d0
00fc8f8e: move.w $dff002.l,d1
00fc8f94: move.w d1,$dff07c.l
00fc8f9a: move.w $dff07c.l,d1
00fc8fae: move.w d1,$dff07c.l
00fc8fb4: move.w $dff07c.l,d1
```

Das sieht nach AROS-Chipsatz-/Custom-Register-Probing aus, nicht nach dem
konkreten Listenfehler bei `AddTail()`.

Ein zweiter Lauf mit `wd 0` sollte pruefen, ob reines Logging ohne Break
moeglich ist:

```bash
HOTKEY_DELAY=2 \
DEBUGGER_COMMAND_DELAY=1 \
DEBUGGER_COMMAND_METHOD=stdin \
DEBUGGER_COMMANDS=$'wd 0\ng\n' \
./scripts/capture_kickstart_runtime.sh enemy1 a500 aros 75
```

Ergebnisordner:
`work/kickstart-deps/runtime/enemy1_aros_a500_20260628T175704+0200`.

Auch dieser Lauf meldete jedoch:

```text
Illegal memory access logging enabled. Break=1
```

und stoppte/loggte wieder frueh bei `0x00fc8f88`, `0x00fc8f9a` und
`0x00fc8fb4` auf Zugriffen rund um `$dff07c`.

Aktuelle Bewertung:

- `wd` ist in dieser FS-UAE-Konfiguration kein sauberer nicht-intrusiver
  Logger fuer den spaeteren Address-Error.
- Die neue Spur belegt fruehe AROS-Custom-Register-Probes, erklaert aber den
  `AddTail()`-Fehler noch nicht.
- Normale Breakpoints und `wd` veraendern den Ablauf genug, dass der
  urspruengliche Fehler nicht verlaesslich im selben Lauf reproduziert wird.

Naechster sinnvoller technischer Schritt ist deshalb Emulator-seitige
Instrumentierung: an der Stelle, an der UAE `Exception 3 (...)` loggt, sollten
vollstaendig `D0-D7`, `A0-A7`, `SR`, `USP/ISP`, `PC`, Fault-Adresse und ein
Supervisor-Stackfenster ausgegeben werden. Das wuerde den kaputten
`AddTail()`-Aufruf ohne Debugger-Breakpoint erfassen.

## Emulator-Instrumentierung

Der naechste Lauf wurde mit einem lokal gebauten FS-UAE 3.2.35 durchgefuehrt.
Instrumentiert wurde `src/newcpu.cpp` im 68000-Exception-3-Pfad, direkt vor dem
Exception-Frame-Aufbau. Der Capture lief ohne Debugger-Hotkey und ohne
Breakpoints:

```bash
FS_UAE_BIN=/tmp/fs-uae-instrument-src/fs-uae-3.2.35-enemy-exception-log/fs-uae \
SEND_DEBUGGER_HOTKEY=0 \
./scripts/capture_kickstart_runtime.sh enemy1 a500 aros 75
```

Relevanter Ergebnisordner:
`work/kickstart-deps/runtime/enemy1_aros_a500_20260628T182819+0200`.

Der Fehler reproduziert sich ohne Debugger-Breakpoint:

```text
ENEMY_EXCEPTION3 ce000-preframe PC=00F87452 INSTR_PC=00F8744E FAULT=24892489 LAST_ADDR=00F87452 OP=2489 SR=0000 OLD_S=0 S=1 USP=00041E24 ISP=00C80000 A7=00C80000 VBR=00000000
ENEMY_EXCEPTION3 D0-D3 B08BB08B 0000002F 0003E358 00C20000 D4-D7 00000001 00000000 00000001 00C25378
ENEMY_EXCEPTION3 A0-A3 74F07548 00041E40 24892489 0003E358 A4-A7 00C00560 00041E70 00C00560 00C80000
ENEMY_EXCEPTION3 USERSTACK 00041E24: 74F0 7538 00F8 D886 0004 1EE8 74F0 74F0
Exception 3 (2489 f87452) at f87452 -> fe774c!
```

Damit ist der konkrete kaputte `AddTail()`-Aufruf isoliert:

- Ausfuehrende Instruktion: `0x00f8744e`, `MOVE.L A1,(A2)`.
- `A2 = 0x24892489`, also ungueltig/ungerade. Das erklaert den Address-Error.
- `A1 = 0x00041e40`, der einzufuegende Node.
- `A0 = 0x74f07548`, die uebergebene Liste. Auch dieser Wert ist offensichtlich
  kein gueltiger RAM-/ROM-Zeiger.
- Der User-Stack zeigt zuerst das von `AddTail()` gesicherte `A2`:
  `0x74f07538`.
- Direkt danach liegt die Return-Adresse `0x00f8d886`.

Die Return-Adresse wurde gemappt in
`addtail_crash_return_map_report.md`. Der Aufrufer ist:

```asm
00f8d878: lea.l $10(a2),a0
00f8d87c: lea.l $14(a7),a1
00f8d880: movea.l a4,a6
00f8d882: jsr -$f6(a6)      ; Exec AddTail()
00f8d886: moveq #$10,d0
```

Das bedeutet: Der kaputte Wert entsteht nicht in `AddTail()` selbst.
Der Aufrufer bei `0x00f8d878` verwendet bereits ein kaputtes `A2`; daraus
werden `list = A2 + 0x10 = 0x74f07548` und spaeter in `AddTail()`
`lh_TailPred = 0x24892489`.

Naechster sinnvoller Schritt ist jetzt nicht mehr weiteres Exception-Logging,
sondern die Rueckverfolgung des Aufrufers um `0x00f8d878`: Funktionseintritt,
Argumente auf dem User-Stack und Quelle des kaputten `A2=0x74f07538`.

## Rueckverfolgung ueber `0x00f8d878`

Capture:
`work/kickstart-deps/runtime/enemy1_aros_a500_20260628T201613+0200`.

Der erweiterte FS-UAE-Trace zeigt, dass `0x00f8d878` nicht selbst die
Ursache ist. Der Wert `A2=0x74f07538` ist der Semaphore-Pointer, den
`ObtainSemaphore()` bereits als `A0` erhaelt:

```text
ENEMY_TRACE 25031 entry_obtainsemaphore PC=00F890B8 ... A7=00041E74 ...
ENEMY_TRACE 25031 entry_obtainsemaphore A0-A7=74F07538,666C7C66,74F074F0,00041F8E,00041F96,74F074F0,00C00560,00041E74
ENEMY_TRACE 25031 entry_obtainsemaphore STACK 00041E74: 00F8 041A 666C 0004 0000 002F 74F0 7538
ENEMY_TRACE 25031 entry_obtainsemaphore STACK2 00041E84: 666C 7C66 00E0 27EA 666C 0004 0000 002F
```

Die statische Zuordnung bestaetigt die Kette:

```asm
00f80410: movem.l d0-d1/a0-a1,-(a7)
00f80414: jsr $f890b8.l
00f8041a: movem.l (a7)+,d0-d1/a0-a1

00f890b8: link.w a5,#$fff4
00f890d0: move.l a6,-(a7)
00f890d2: pea.l -$c(a5)
00f890d6: move.l $114(a6),-(a7)
00f890da: move.l a0,-(a7)
00f890dc: jsr $f8d7ec.l

00f8d878: lea.l $10(a2),a0
00f8d87c: lea.l $14(a7),a1
00f8d882: jsr -$f6(a6)      ; AddTail()
```

Interpretation mit Evidenzgrad `runtime/static`:

- `0x00f80410` ist der AROS-Exec-LVO-Stub fuer `ObtainSemaphore()`.
- Der echte externe Ruecksprung oberhalb dieses Stubs ist `0x00e027ea`.
- `0x00e027ea` liegt im AROS-Extension-ROM `aros-ext.bin`, nicht im
  Enemy-Code.
- Der zugehoerige Ext-ROM-Block ruft `ObtainSemaphore()` so auf:

```asm
00e027d8: movem.l d0-d1/a0-a1/a6,-(a7)
00e027dc: movea.l $4.l,a6
00e027e2: lea.l $48(a5),a0
00e027e6: jsr -$234(a6)     ; ObtainSemaphore()
00e027ea: movem.l (a7)+,d0-d1/a0-a1/a6
```

Damit ist die Quelle des kaputten `A2` fuer den `AddTail()`-Crash genauer:
`A2=0x74f07538` in `0x00f8d878` stammt aus `ObtainSemaphore(A0)`;
dieses `A0` stammt wiederum aus `0x00e027e2`, also `A5 + 0x48`.
Zur Crash-Zeit muss `A5` in diesem AROS-Ext-ROM-Code bereits auf eine
kaputte oder nicht mehr gueltige Struktur zeigen.

Naechster sinnvoller Schritt: den Ext-ROM-Block um `0x00e027d8` weiter
rueckverfolgen, insbesondere den Funktionseintritt bei `0x00e0266c`,
die Herkunft von `A5` und die Quelle des Objekt-/Strukturzeigers, aus dem
`A5 + 0x48 == 0x74f07538` berechnet wird.

## Herkunft von `A5` vor `0x00e027d8`

Capture:
`work/kickstart-deps/runtime/enemy1_aros_a500_20260628T211548+0200`.

Die Spur `0x00e0266c..0x00e027d8` ist nicht als einfache lineare
Funktion zu lesen. Zwischen diesen Adressen liegen Rueckspruenge/Dispatch-Code;
der konkrete Crash-Lauf erreicht `0x00e027d8` ueber einen indirekten
Methodenaufruf aus `0x00e13908`, nicht durch lineares Fallen aus
`0x00e0266c`.

Die entscheidende statische Sequenz ist:

```asm
00e1394e: movea.l $8(a5),a0
00e13952: move.l  $4(a0),-$20(a5)
00e13958: movea.l (a0),a2
...
00e13a50: movea.l $28(a5),a6
00e13a54: move.l  a5,-(a7)
00e13a56: movea.l a2,a5
00e13a58: jsr     -$1b0(a6)
00e13a5c: movea.l (a7)+,a5
```

Der indirekte Call landet im bereits bekannten Helper:

```asm
00e027d8: movem.l d0-d1/a0-a1/a6,-(a7)
00e027dc: movea.l $4.l,a6
00e027e2: lea.l   $48(a5),a0
00e027e6: jsr     -$234(a6)     ; ObtainSemaphore()
```

Runtime-Werte direkt vor dem Fehler:

```text
ENEMY_TRACE 27148 dispatch_load_a2_from_arg0 PC=00E13958 ...
ENEMY_TRACE 27148 dispatch_load_a2_from_arg0 A0-A7=666C7C66,666C7C66,666C7C66,00041F8E,00041F96,00041EF8,00C25378,00041EA8

ENEMY_TRACE 27149 dispatch_prepare_indirect_call PC=00E13A50 ...
ENEMY_TRACE 27149 dispatch_prepare_indirect_call A0-A7=666C7C66,666C7C66,74F074F0,00041F8E,00041F96,00041EF8,00C25378,00041EA8

ENEMY_TRACE 27151 dispatch_call_method_minus_1b0 PC=00E13A58 ...
ENEMY_TRACE 27151 dispatch_call_method_minus_1b0 A0-A7=666C7C66,666C7C66,74F074F0,00041F8E,00041F96,74F074F0,00C25378,00041EA4

ENEMY_TRACE 27154 ext_helper_call_obtain PC=00E027E6 ...
ENEMY_TRACE 27154 ext_helper_call_obtain A0-A7=74F07538,666C7C66,74F074F0,00041F8E,00041F96,74F074F0,00C00560,00041E8C
```

Damit ist `A5` fuer `0x00e027d8` konkret erklaert:

- `0x00e13958` laedt `A2 = (A0)`.
- In diesem Lauf ist `A0 = 0x666c7c66`.
- Nach dem Load ist `A2 = 0x74f074f0`.
- `0x00e13a56` kopiert `A2` nach `A5`.
- `0x00e027e2` berechnet daraus `A0 = A5 + 0x48 = 0x74f07538`.
- Dieser Wert geht als Semaphore an `ObtainSemaphore()` und fuehrt spaeter zum
  kaputten `AddTail()`-Pfad.

Der Ruecksprung oberhalb von `0x00e13908` ist `0x00e13c84`. Der zugehoerige
Caller wurde in
`work/kickstart-deps/runtime/enemy1_aros_a500_20260628T211548+0200/ext_dispatch_caller_return_e13c84_map_report.md`
gemappt:

```asm
00e13c44: movem.l d2-d5,-(a7)
00e13c48: move.l  $14(a7),d2
00e13c4c: move.l  $28(a7),d4
00e13c50: move.l  $2c(a7),d5
00e13c54: move.l  $30(a7),d3
00e13c58: move.l  d3,-(a7)
00e13c5a: move.l  d2,-(a7)
00e13c5c: jsr     $e12d66(pc)
...
00e13c7c: move.l  d2,-(a7)
00e13c7e: jsr     $e13908.l
00e13c84: lea.l   $2c(a7),a7
```

`0x00e12d66` liefert in `D0` einen Pointer auf eine Struktur bei
`A2 + 0x4e` oder aus Objekt-/Backend-Feldern; der Helper liest unter anderem
`$4(a2)`, `$19(a2)`, `$1a(a2)`, `$1c(a2)` und schreibt Felder bei
`$4a(a2)`, `$52(a2)`, `$56(a2)`, `$5a(a2)`, `$61(a2)`, `$62(a2)`.
Die lokale AROS-Source-Kopie enthaelt fuer diesen Graphics/HIDD-Bereich bisher
keine passende Source-Datei, daher ist das aktuell eine Binary-/Runtime-
Zuordnung.

Aktueller Stand:

- `0x00e027d8` ist nur der Benutzer von `A5`, nicht die Quelle.
- Die Quelle von `A5` im Crash-Lauf ist `A2` aus `0x00e13958`.
- `A2` stammt aus `(0x666c7c66)`, also aus einem bereits kaputten
  Container-/Argumentpointer.
- Der naechste sinnvolle Tracepunkt ist nicht mehr `0x00e027d8`, sondern der
  Caller `0x00e13c44`/`0x00e13c7e` und der Helper `0x00e12d66`, mit
  Speicher-Dump fuer `0x666c7c66` sowie die Stackargumente, aus denen
  `0x00e13c44` seine Argumentliste fuer `0x00e13908` baut.

## Wrapper-Trace um `0x00e13c44`

Capture:
`work/kickstart-deps/runtime/enemy1_aros_a500_20260628T212418+0200`.

Der zusaetzliche Trace bestaetigt, dass `0x00e13c44` den kaputten Pointer
bereits als Argument erhaelt. Der Wrapper erzeugt `0x666c7c66` nicht selbst.

Wrapper-Eintritt:

```text
ENEMY_TRACE 27213 entry_ext_wrapper_e13c44 PC=00E13C44 ...
ENEMY_TRACE 27213 entry_ext_wrapper_e13c44 A0-A7=00000000,666C7C66,666C7C66,00C25378,0004215A,00041FB4,00C25378,00041F3C
ENEMY_TRACE 27213 entry_ext_wrapper_e13c44 STACK 00041F3C: 00E0 6290 666C 7C66 0000 0000 0004 1F8E
ENEMY_TRACE 27213 entry_ext_wrapper_e13c44 STACK2 00041F4C: 00E0 60C4 0004 1F96 0000 0001 0000 0000
```

Damit ist der Stack beim Eintritt:

- Return-Adresse: `0x00e06290`
- Arg0: `0x666c7c66`
- Arg1: `0x00000000`
- Arg2: `0x00041f8e`
- Arg3: `0x00e060c4`
- Arg4: `0x00041f96`
- Arg5: `0x00000001`
- Arg6: `0x00000000`

Der Helper `0x00e12d66` wird innerhalb des Wrappers mit `A2=0x666c7c66`
aufgerufen und liefert `D0=0x666c7cb4`:

```text
ENEMY_TRACE 27216 entry_ext_helper_e12d66 PC=00E12D66 ...
ENEMY_TRACE 27216 entry_ext_helper_e12d66 A0-A7=00000000,666C7C66,666C7C66,00C25378,0004215A,00041FB4,00C25378,00041F20

ENEMY_TRACE 27218 wrapper_after_e12d66 PC=00E13C60 ...
ENEMY_TRACE 27218 wrapper_after_e12d66 A0-A7=00000000,666C7C66,666C7C66,00C25378,0004215A,00041FB4,00C25378,00041F24
ENEMY_TRACE 27218 wrapper_after_e12d66 D0-D3=666C7CB4,0000002F,666C7C66,00C25378
```

Direkt vor `0x00e13908` wird daraus die Argumentliste:

```text
ENEMY_TRACE 27219 wrapper_call_e13908 PC=00E13C7E ...
ENEMY_TRACE 27219 wrapper_call_e13908 STACK 00041F00: 666C 7C66 0000 0000 0004 1F8E 00E0 60C4
ENEMY_TRACE 27219 wrapper_call_e13908 STACK2 00041F10: 0004 1F96 666C 7CB4 0000 0001 0000 0000
```

An `0x00e13958` liest der Dispatcher dann tatsaechlich aus `(A0)`:

```text
ENEMY_TRACE 27223 dispatch_load_a2_from_arg0 PC=00E13958 ...
ENEMY_TRACE 27223 dispatch_load_a2_from_arg0 A0-A7=666C7C66,666C7C66,666C7C66,00041F8E,00041F96,00041EF8,00C25378,00041EA8
ENEMY_TRACE 27223 dispatch_load_a2_from_arg0 MEM_A0 666C7C66: 74F074F0 74F074F0 74F074F0 74F074F0
```

Hinweis: Die spaeteren `MEM_A0`/`MEM_A2`-Dumps fuer dieselbe Adresse wechseln
stark (`00280028`, `C0C2C0C2`, `FDCCFDCC` usw.). Diese Werte sind daher nicht
als stabiler RAM-Inhalt zu behandeln. Belastbar ist aber der unmittelbare
Instruktionszeitpunkt bei `0x00e13958`: Dort liefert `(0x666c7c66)` den Wert
`0x74f074f0`, und dieser Wert wird danach nach `A5` uebernommen.

Der Ruecksprung `0x00e06290` wurde in
`work/kickstart-deps/runtime/enemy1_aros_a500_20260628T212418+0200/ext_wrapper_caller_return_e06290_map_report.md`
gemappt. Der Callsite ist:

```asm
00e061e0: link.w  a5,#$ffd4
00e061e4: movem.l d2-d7/a2-a4/a6,-(a7)
00e061e8: movea.l a1,a2
...
00e06272: move.l  d7,-(a7)
00e06274: clr.l   -(a7)
00e06276: pea.l   $1.w
00e0627a: pea.l   -$1e(a5)
00e0627e: pea.l   $e060c4(pc)
00e06282: pea.l   -$26(a5)
00e06286: clr.l   -(a7)
00e06288: move.l  a2,-(a7)
00e0628a: jsr     $e13c44.l
00e06290: lea.l   $20(a7),a7
```

Damit ist die Herkunft von `0x666c7c66` eine Ebene weiter zurueckverfolgt:
`0x00e061e0` bekommt den Wert in `A1`, kopiert ihn nach `A2` und uebergibt
`A2` als Arg0 an `0x00e13c44`.

### Rueckverfolgung bis zum ROM-Feldleser

Die naechsten Captures zeigen, dass der Wert `0x666c7c66` nicht erst in
`0x00e061e0`, `0x00e13c44` oder `0x00e13908` entsteht. Diese Funktionen
reichen ihn nur weiter.

`work/kickstart-deps/runtime/enemy1_aros_a500_20260628T214151+0200/fs-uae.log.txt`
zeigt am Eintritt von `0x00e061e0` bereits:

```text
ENEMY_TRACE 27213 entry_ext_caller_e061e0 PC=00E061E0 ...
ENEMY_TRACE 27213 entry_ext_caller_e061e0 A0-A7=00000000,666C7C66,666C7C66,00C25378,0004215A,00C6E710,00C25378,00041FB8
ENEMY_TRACE 27213 entry_ext_caller_e061e0 STACK 00041FB8: 00E0 ABD4 0000 000B 0000 0036 666C 7C66
```

Der Ruecksprung `0x00e0abd4` fuehrt zu:

```asm
00e0aba8: subq.l #$8,a7
00e0abaa: movem.l d2-d7/a2-a4/a6,-(a7)
00e0abae: movea.l a1,a2
...
00e0abd0: jsr -$138(a6)
00e0abd4: movem.l (a7)+,d2-d7/a2-a4/a6
```

`work/kickstart-deps/runtime/enemy1_aros_a500_20260628T214414+0200/fs-uae.log.txt`
zeigt auch dort den Wert schon im Argumentregister:

```text
ENEMY_TRACE 28005 entry_ext_caller_e0aba8 PC=00E0ABA8 ...
ENEMY_TRACE 28005 entry_ext_caller_e0aba8 D4-D7=666C7C66,00FB6A7C,00FB8632,00000001
ENEMY_TRACE 28005 entry_ext_caller_e0aba8 A0-A7=00000036,666C7C66,0000000B,00C76894,0004215A,00C6E710,00C25378,00041FEC
ENEMY_TRACE 28005 entry_ext_caller_e0aba8 STACK 00041FEC: 00FA F8AC 0004 215A 0000 0000 0000 0002
```

Der Ruecksprung `0x00faf8ac` liegt im Haupt-ROM. Der gemappte Callsite aus
`work/kickstart-deps/runtime/enemy1_aros_a500_20260628T214414+0200/rom_e0aba8_caller_call_faf8a8_map_report.md`
enthaelt zwei relevante D4-Ladepfade:

```asm
00faf842: movea.l $22(a2),a0
00faf846: move.l  $32(a0),d4
...
00faf896: movea.l d4,a1
00faf8a8: jsr     -$132(a6)

00faf8b8: movea.l $22(a2),a0
00faf8bc: move.l  $32(a0),d4
...
00faf8e2: beq.b   $faf86e
```

Der frische Capture
`work/kickstart-deps/runtime/enemy1_aros_a500_20260628T215216+0200/fs-uae.log.txt`
trifft beim finalen Fehler den zweiten Pfad:

```text
ENEMY_TRACE 28238 rom_alt_load_a0_from_a2_22 PC=00FAF8B8 ...
ENEMY_TRACE 28238 rom_alt_load_a0_from_a2_22 A0-A7=00C6E710,0004215A,00C76894,00C76894,0004215A,00C6E710,00C695C0,00041FF0

ENEMY_TRACE 28239 rom_alt_load_d4_from_a0_32 PC=00FAF8BC ...
ENEMY_TRACE 28239 rom_alt_load_d4_from_a0_32 A0-A7=000625B8,0004215A,00C76894,00C76894,0004215A,00C6E710,00C695C0,00041FF0

ENEMY_TRACE 28240 rom_alt_compute_a0_from_a2_offset PC=00FAF8C6 ...
ENEMY_TRACE 28240 rom_alt_compute_a0_from_a2_offset D4-D7=666C7C66,00FB6A7C,00FB8632,00000001

ENEMY_TRACE 28245 rom_call_method_minus_132 PC=00FAF8A8 ...
ENEMY_TRACE 28245 rom_call_method_minus_132 A0-A7=00000036,666C7C66,0000000B,00C76894,0004215A,00C6E710,00C25378,00041FF0
ENEMY_TRACE 28246 entry_ext_caller_e0aba8 PC=00E0ABA8 ...
ENEMY_TRACE 28246 entry_ext_caller_e0aba8 STACK 00041FEC: 00FA F8AC 0004 215A 0000 0000 0000 0002
```

Damit ist die aktuelle harte Kette:

```text
[$22(0x00c76894)] = 0x000625b8
[$32(0x000625b8)] = 0x666c7c66
0x00faf8bc laedt diesen Long nach D4
0x00faf896/0x00faf8a8 uebergibt D4 als A1 an 0x00e0aba8
0x00e0aba8 -> 0x00e061e0 -> 0x00e13c44 -> 0x00e13908 -> 0x00e027d8
0x00e027d8 ruft ObtainSemaphore(A5+0x48) mit A5=0x74f074f0 auf
ObtainSemaphore/AddTail crasht spaeter bei A2=0x24892489
```

Naechster sinnvoller Schritt: Nicht weiter den Call-Stack verfolgen, sondern
den Schreibzugriff auf `0x000625ea..0x000625ed` beobachten. Dieses Longword ist
das Feld `$32(0x000625b8)`, das im finalen AROS-Lauf zu `0x666c7c66` wird.

### Write-Watchpoint auf das korrupte Feld

Ein weiterer instrumentierter Lauf mit Watchpoint auf `0x000625ea..0x000625ed`
liegt in:

`work/kickstart-deps/runtime/enemy1_aros_a500_20260628T215713+0200/fs-uae.log.txt`

Vor dem finalen Crash wird das Feld zuerst normal geloescht bzw. gesetzt:

```text
ENEMY_WATCH 003 put_word_625ea PC=00E24A56 ADDR=000625EA SIZE=2 VAL=00000005 ...
ENEMY_WATCH 004 put_word_625ea PC=00E24A56 ADDR=000625EC SIZE=2 VAL=0005512C ...
```

Spaeter wird es geloescht:

```text
ENEMY_WATCH 005 put_word_625ea PC=00F9FEA4 ADDR=000625EA SIZE=2 VAL=00000000 ...
ENEMY_WATCH 006 put_word_625ea PC=00F9FEA6 ADDR=000625EC SIZE=2 VAL=00000000 ...
```

Danach schreibt `0x00e0c004` byteweise in genau dieses Longword. Die Werte
entstehen nicht als Pointer-Store, sondern als wiederholte Bit-Operation auf
dem Zielbyte:

```text
ENEMY_WATCH 007 put_byte_625ea PC=00E0C004 ADDR=000625EA SIZE=1 VAL=00000040 ... WATCH=00000000
ENEMY_WATCH 010 put_byte_625ea PC=00E0C004 ADDR=000625EA SIZE=1 VAL=00000066 ... WATCH=64000000
ENEMY_WATCH 014 put_byte_625ea PC=00E0C004 ADDR=000625EB SIZE=1 VAL=0000006C ... WATCH=66680000
ENEMY_WATCH 019 put_byte_625ea PC=00E0C004 ADDR=000625EC SIZE=1 VAL=0000007C ... WATCH=666C7800
ENEMY_WATCH 023 put_byte_625ea PC=00E0C004 ADDR=000625ED SIZE=1 VAL=00000066 ... WATCH=666C7C64
```

`work/kickstart-deps/runtime/enemy1_aros_a500_20260628T215713+0200/watch_writer_e0c004_map_report.md`
mappt `0x00e0c004` auf `roms/aros/aros-ext.bin` Offset `0x0000c004`:

```asm
00e0bffa: move.b $43(a7),d4
00e0bffe: and.l  d2,d4
00e0c000: tst.b  d4
00e0c002: beq.b  $e0c006
00e0c004: or.b   d3,(a5)
00e0c006: moveq  #$1,d4
```

Beim Watchpoint steht `A5` jeweils auf dem Zielbyte (`0x000625ea` bis
`0x000625ed`) und `A2=0x000625b8`. Damit ist die neue harte Aussage:
Ein AROS-Graphics/Bit-Plot-Pfad schreibt Pixel-/Maskenbits in ein RAM-Objekt,
dessen Offset `+0x32` spaeter vom ROM-Code als Pointerfeld gelesen wird.

Der lokale AROS-Source-Auszug unter `/tmp/aros-src` enthaelt nur Boot- und
Exec-Dateien, keine Graphics-Implementierung. Eine Source-Korrelation fuer
`0x00e0c004` ist damit lokal noch nicht moeglich; der binaere Map-Report und
der Watchpoint sind aktuell die belastbaren Quellen.

Naechster sinnvoller Schritt: `0x00e0c004` nicht mehr nur als Schreiber
behandeln, sondern seinen Aufrufer/Parameterkontext erfassen. Besonders wichtig
sind `A5`-Initialisierung, Ziel-Bitmap/RastPort-Argumente und warum der
Zielbereich `0x000625b8+0x32` in einen Graphics-Write-Pfad geraet.

### Aufrufer- und Parameterkontext des Schreibers

Ein frischer instrumentierter Lauf mit erweitertem Stack-/Caller-Logging liegt
in:

`work/kickstart-deps/runtime/enemy1_aros_a500_20260628T222242+0200/fsuae.stdout.log`

Der Lauf reproduziert wieder den bekannten Address-Error:

```text
Exception 3 (2489 f87452) at f87452 -> fe774c!
```

Der kritische Watchpoint zeigt jetzt zusaetzlich Stack und Objektkontext am
echten Schreibzeitpunkt. Beim ersten Byte-Schreiber:

```text
ENEMY_WATCH 007 put_byte_625ea PC=00E0C004 ADDR=000625EA SIZE=1 VAL=00000040 ...
ENEMY_WATCH 007 put_byte_625ea A0-A7=00C26808,000625EA,000625B8,00061D7C,00E01B26,000625EA,00E01A66,00C3524C WATCH=00000000
ENEMY_WATCH 007 put_byte_625ea STACK 00C3524C: 0000 0010 00E1 BE84 00C2 5378 00C2 0000
ENEMY_WATCH 007 put_byte_625ea STACK2 00C3525C: 00C3 682C 0000 0000 0006 1D7C 00C2 6808
ENEMY_WATCH 007 put_byte_625ea MEM_A2_32 000625EA=00000000 MEM_A3 00061D7C: 00061CD0 0004A750 00000000 00000000 MEM_A5 000625EA=00
```

Beim letzten Byte vor dem kompletten kaputten Longword:

```text
ENEMY_WATCH 023 put_byte_625ea PC=00E0C004 ADDR=000625ED SIZE=1 VAL=00000066 ...
ENEMY_WATCH 023 put_byte_625ea A0-A7=00C26808,000625ED,000625B8,00061D7C,00E01B19,000625ED,00E01A59,00C3524C WATCH=666C7C64
ENEMY_WATCH 023 put_byte_625ea MEM_A2_32 000625EA=666C7C64 MEM_A3 00061D7C: 00061CD0 0004A750 00000000 00000000 MEM_A5 000625ED=64
```

Damit ist `0x000625ea` eindeutig `A2+0x32` mit `A2=0x000625b8`. Dieses Feld ist
nicht durch einen Longword-Pointer-Store verdorben worden, sondern durch den
Graphics-Plotter byteweise als Ziel-Bitmap-Speicher beschrieben worden.

Die A5-Herkunft ist im Plotter statisch und zur Laufzeit belegt:

```asm
00e0bf80: lea.l  (a2,d2.w),a1
...
00e0bfb0: movea.l a1,a5
...
00e0c004: or.b   d3,(a5)
```

Runtime-Fakt fuer den korrupten Fall:

```text
A2 = 0x000625b8
A1 = 0x000625ea / 0x000625eb / 0x000625ec / 0x000625ed
A5 = A1 unmittelbar vor dem or.b-Schreiber
```

Der direkte Caller ist `0x00e066ac`, der ueber den AROS-Wrapper
`0x00e13c44` in den Plotter laeuft:

```text
ENEMY_TRACE 52964 gfx_call_plotter_e0be40 PC=00E066AC ...
ENEMY_TRACE 52964 gfx_call_plotter_e0be40 A0-A7=00000010,00061D7C,000625B8,00061D7C,00000010,00C35244,00C25378,00C351FC
ENEMY_TRACE 52964 gfx_call_plotter_e0be40 STACK 00C351FC: 0006 1D7C 0000 0000 00C3 5230 00E0 65B4
```

`work/kickstart-deps/runtime/enemy1_aros_a500_20260628T215713+0200/watch_writer_return_e066b2_map_report.md`
mappt diesen Bereich:

```asm
00e06694: move.l a6,-(a7)
00e06696: clr.l  -(a7)
00e06698: pea.l  $1.w
00e0669c: pea.l  -$c(a5)
00e066a0: pea.l  $e065b4(pc)
00e066a4: pea.l  -$14(a5)
00e066a8: clr.l  -(a7)
00e066aa: move.l a1,-(a7)
00e066ac: jsr    $e13c44.l
00e066b2: lea.l  $20(a7),a7
```

Der Stack enthaelt als hoeheren Return `0x00e065b4`; dessen Einstieg ist eine
Graphics-Routine, die ein temporaeres Parameterpaket auf dem Stack aufbaut. Der
noch hoehere Return `0x00e12f32` wurde ebenfalls gemappt:

`work/kickstart-deps/runtime/enemy1_aros_a500_20260628T222242+0200/watch_writer_return_e12f32_map_report.md`

Dort ruft ein Dispatch per Funktionszeiger:

```asm
00e12f16: move.l a2,-(a7)
00e12f18: move.l a4,-(a7)
00e12f1a: move.l $3c(a7),-(a7)
00e12f1e: move.l d2,-(a7)
...
00e12f2c: movea.l $3c(a7),a0
00e12f30: jsr    (a0)
00e12f32: move.l d0,d3
```

Aktueller Schluss mit Evidenzlevel `runtime`: AROS interpretiert in diesem
Pfad `0x000625b8` als Bitplane-/Bitmap-Zielbasis und zeichnet dort hinein.
Enemy bzw. der spaetere ROM-Code interpretiert denselben Speicherbereich aber
als Objekt mit einem Pointerfeld bei `+0x32`. Dadurch wird aus Pixelbits
`0x666c7c66`, was spaeter ueber `0x00faf8bc` als Pointer/Objektadresse weiter
gereicht wird und in `AddTail()` endet.

Naechster sinnvoller Schritt: Vergleich mit Original-Kickstart an genau diesem
Punkt. Konkret: denselben Watchpoint fuer Original-Kickstart laufen lassen und
pruefen, ob `0x000625b8+0x32` dort ebenfalls als Ziel-Bitmap beschrieben wird,
oder ob AROS vorher ein anderes Bitmap/RastPort-Layout bzw. einen anderen
Clip/Layer-Zielzeiger liefert.

### Original-Kickstart-Vergleich am selben Watchpoint

Der direkte Vergleichslauf mit Original Kickstart 1.3 liegt in:

`work/kickstart-deps/runtime/enemy1_original_a500_20260628T222816+0200`

Der Lauf verwendet nach Log eindeutig das Original-ROM:

```text
kickstart_file = /home/kaufmann/Mothership/Data/Roms/Amiga/Kickstarts/Kickstart v1.3 rev 34.5 (1987)(Commodore)(A500-A1000-A2000-CDTV).rom
UAE: KS ROM v1.3 (A500,A1000,A2000) rev 34.5 (256k) [315093-02]
Known ROM 'KS ROM v1.3 (A500,A1000,A2000)' loaded
```

Mit demselben Watchpoint auf `0x000625ea..0x000625ed` gab es im 75s-Fenster nur
zwei fruehe Writes:

```text
ENEMY_WATCH 001 put_word_625ea PC=00FC060E ADDR=000625EA SIZE=2 VAL=00000000 ...
ENEMY_WATCH 002 put_word_625ea PC=00FC060E ADDR=000625EC SIZE=2 VAL=00000000 ...
```

`work/kickstart-deps/runtime/enemy1_original_a500_20260628T222816+0200/original_watch_init_fc060e_map_report.md`
mappt `0x00fc060e` auf Kickstart 1.3 Offset `0x00060e`:

```asm
00fc0602: moveq  #$0,d2
00fc0604: sub.l  a0,d0
00fc0606: lsr.l  #$2,d0
00fc0608: move.l d0,d1
00fc060a: swap   d1
00fc060c: bra.b  $fc0610
00fc060e: move.l d2,(a0)+
00fc0610: dbra   d0,$fc060e
00fc0614: dbra   d1,$fc060e
```

Das ist die fruehe RAM-Clear-/Initialisierungsschleife, kein Enemy- oder
Graphics-Schreiber. Im Original-Lauf gibt es keinen spaeteren Treffer auf
`0x000625ea..0x000625ed` und keinen beobachteten Address-Error wie bei AROS.

Vergleich der harten Beobachtung:

```text
AROS:     0x000625b8+0x32 wird spaeter durch den Graphics-Plotter byteweise zu 0x666c7c66 beschrieben.
Original: dieselbe absolute Adresse wird im Messfenster nur initial auf 0 geloescht.
```

Wichtige Einschraenkung: Das beweist zunaechst nur den Unterschied an derselben
absoluten RAM-Adresse. Es beweist noch nicht, wo das entsprechende
Original-Kickstart-Objekt liegt, falls es unter Original anders allokiert wird.
Fuer den naechsten Beweisschritt muss deshalb nicht mehr diese feste Adresse
verfolgt werden, sondern der RastPort-/Bitmap-Zielzeiger dynamisch beim
Graphics-Aufruf unter Original und AROS verglichen werden.

### Dynamischer Graphics-Zielvergleich unter AROS

Capture:
`work/kickstart-deps/runtime/enemy1_aros_a500_20260628T225308+0200`

Der FS-UAE-Hook wurde fuer diesen Lauf auf `jsr d16(a6)`-Library-Calls mit
Enemy-RAM-/RastPort-Bezug eingeschraenkt. Der Lauf reproduziert den bekannten
Crash:

```text
Exception 3 (2489 f87452) at f87452 -> fe774c!
```

Der wichtigste neue Runtime-Treffer ist `ENEMY_GFXCALL 1482`:

```text
ENEMY_GFXCALL 1482 jsr_d16_a6 PC=00E13AC0 TARGET=00C251C2 DISP=FE4A ...
D0-D3=00000400,00000080,00000400,00C20000 D4-D7=00000005,00000004,0000000E,00000084
A0-A7=00FCE020,0004A7D8,00061D08,00000000,00C35238,00061D08,00C25378,00C35160
STACK 00C35160: 00C351B4 00061DB4 00C25378 00000001 00000000 00000008 00000080 000625F0
STACK2 00C35180: 00061DB4 00000010 00C25378 00000000 00840000 0004A788 00F8C5D6 00000000
MEM_A2 00061D08: 00000000 00061BF8 00C26CA8 00061DB4
```

Das ist der bisher sauberste Hinweis auf den Grund, warum AROS diesen
RAM-Bereich als Bitmap/RastPort-Speicher benutzt:

- `0x00061d08` ist im AROS-Lauf eine Graphics-Struktur mit Pointer
  `+0x0c -> 0x00061db4`.
- `0x00061db4` wird im Call als Ziel-RastPort/Bitmap-Kontext uebergeben.
- Auf dem Stack liegen gleichzeitig `height=0x08`, `width=0x80` und
  Zielpuffer `0x000625f0`.
- Direkt davor/danach laufen die bekannten AROS-Graphics-Dispatcher:
  `0x00e13a58` (`jsr -$1b0(a6)`) und `0x00e13ac0` (`jsr -$1b6(a6)`).

Die konkrete absolute Zieladresse ist in diesem spaeteren Lauf gegenueber dem
frueheren Watchpoint leicht verschoben (`0x000625f0` statt `0x000625b8`), aber
die Struktur ist gleich: AROS behandelt den Bereich als Ziel-Bitmap-/Raster-
Speicher, und spaeter wird ein Pointerfeld in diesem Bereich als Exec-/Objekt-
Pointer benutzt. Der spaetere Crash bleibt identisch:

```asm
00f8744e: move.l a1,(a2)    ; AddTail(), A2 ist kaputt
```

`pc_map_gfx_lvo_chain.txt` bestaetigt erneut, dass `0x00f87452` im
AROS-ROM-`AddTail()`-Block liegt.

Aktueller Schluss mit Evidenzlevel `runtime`: Der Fehler ist nicht mehr nur ein
statischer Verdacht auf falsche Pointer-Uebergabe. Im AROS-Lauf ist der
problematische RAM-Bereich dynamisch als Graphics-Zielpuffer sichtbar
(`0x80`-breiter Transfer in/um `0x000625f0`). Das passt zur frueheren
Beobachtung, dass Pixel-/Maskenbytes wie `0x666c7c66` spaeter als Pointer in
den Exec-Listenpfad gelangen.

Naechster sinnvoller Schritt: denselben fokussierten `ENEMY_GFXCALL`-Hook mit
Original-Kickstart laufen lassen und nach dem Callmuster `width=0x80`,
`height=0x08`, Zielpuffer/RastPort auf dem Stack suchen. Wichtig ist dabei
nicht dieselbe absolute Adresse, sondern ob Original an dieser Stelle einen
anderen Zielpuffer oder eine andere RastPort-/Bitmap-Verkettung liefert.

### Original-Kickstart mit adressunabhaengigem `0x80`-Shape-Hook

Capture:
`work/kickstart-deps/runtime/enemy1_original_a500_20260628T231741+0200`

Der Hook wurde fuer diesen Lauf so erweitert, dass ein `0x80`-Transfer auch
dann geloggt wird, wenn die AROS-spezifischen RAM-Adressen nicht vorkommen.
Damit ist der Vergleich nicht mehr auf `0x00061d08`/`0x000625f0` vorgefiltert.

Der Lauf laedt das echte Kickstart 1.3 und die Enemy-ADFs; im Messfenster gibt
es weiterhin keinen Address-Error. Der feste Watchpoint auf
`0x000625ea..0x000625ed` trifft wie zuvor nur die fruehe RAM-Clear-Schleife:

```text
ENEMY_WATCH 001 put_word_625ea PC=00FC060E ADDR=000625EA ... WATCH=00000000
ENEMY_WATCH 002 put_word_625ea PC=00FC060E ADDR=000625EC ... WATCH=00000000
```

Der erweiterte Hook findet unter Original sehr wohl `0x80`-Graphics-Formen,
aber mit anderen Zielstrukturen. Beispiele:

```text
ENEMY_GFXCALL 009 PC=00FD3C42 ... D0-D3=00000080,00000002,00000080,00000000
A0-A7=00C081BC,00C04288,00C08128,00001080,00C04288,00C0812C,00C00276,00C080D8
MEM_A1 00C04288: 00C08750 00C08520 00000000 00000000
MEM_A2 00C08128: 00000000 00C08200 00FC687E 00C081BC

ENEMY_GFXCALL 010 PC=00FD3C5C ... D0-D3=00000080,00000080,00C081BC,00000000
A0-A7=00C01E1E,00014D78,00C08750,00001080,00C04288,00C0812C,00C00276,00C080F0
MEM_A1 00014D78: 00000000 0006B288 00000000 00000000

ENEMY_GFXCALL 016 PC=00FD3C5C ... D0-D3=00000080,00000080,00C08244,00000000
A0-A7=00C01E1E,00014E20,00C08750,00001080,00C04288,00C081B4,00C00276,00C08178
MEM_A1 00014E20: 00000000 0006B1E0 00000000 00000000
```

Vergleich gegen AROS:

```text
AROS critical:
  stack contains width/height-like 00000080/00000008 and target 000625F0
  MEM_A2 00061D08: ... 00061DB4

Original:
  0x80 calls exist, but active pointers are around 00014D78/00014E20,
  00C081xx/00C089xx, and no write to 000625EA..000625ED occurs after RAM clear.
```

Aktueller Schluss mit Evidenzlevel `runtime`: Der Unterschied ist nicht, dass
Original keine `0x80`-Graphics-Operation ausfuehrt. Der Unterschied ist das
Ziel: AROS fuehrt die kritische `0x80`-Operation ueber die
`0x00061d08 -> 0x00061db4 -> 0x000625f0`-Kette in den spaeter als Objektfeld
gelesenen Speicherbereich. Original fuehrt vergleichbare `0x80`-Operationen
ueber andere Ziel-/Bitmap-Strukturen aus und beruehrt das beobachtete
Pointerfeld nicht.

Naechster sinnvoller Schritt: den AROS-Pfad vor `ENEMY_GFXCALL 1482`
zurueckverfolgen, also die Erzeugung/Initialisierung von `0x00061d08` und
`0x00061db4`. Ziel ist zu klaeren, warum AROS diese Struktur auf den
`0x000625f0`-Bereich richtet, waehrend Original eine andere
RastPort-/Bitmap-Kette nutzt.

### AROS-Struktur-Watchpoints vor dem Crash

Capture:
`work/kickstart-deps/runtime/enemy1_aros_a500_20260628T232850+0200`

Fuer diesen Lauf wurden zusaetzliche Watch-Bereiche auf die vermutete
Graphics-Kette gelegt:

```text
0x00061d08..0x00061d17  rp_61d08
0x00061db4..0x00061dc3  rp_target_61db4
0x000625f0..0x000625ff  bitmap_625f0
0x000625ea..0x000625ed  obj_ptr_625ea
```

Der Lauf reproduziert den bekannten Crash:

```text
Exception 3 (2489 f87452) at f87452 -> fe774c!
```

Die neue Spur zeigt, dass AROS die `0x00061d08 -> 0x00061db4`-Kette
selbst aufbaut. Die relevanten Writer liegen im AROS-Extension-ROM-Bereich:

```text
PC=00E18244 ADDR=00061D14/16  -> 0x00061d08+0x0c = 0x00061db4
PC=00E18254 ADDR=00061DB4/16  -> 0x00061db4+0x00 = 0x00061d08
PC=00E1825A ADDR=00061DB8/BA  -> 0x00061db4+0x04 = 0x0004a788
PC=00E18376 ADDR=00061D0C/0E  -> 0x00061d08+0x04 = 0x00061bf8
PC=00E17B5A ADDR=00061D10/12  -> 0x00061d08+0x08 = 0x00c26c78
```

Der daraus sichtbare Zustand nach der Initialisierung ist:

```text
61D08=00000000,00061BF8,00C20000,00061DB4
61DB4=00061D08,0004A788,00000000,00000000
```

Damit ist nicht nur der spaetere `ENEMY_GFXCALL` sichtbar, sondern auch die
vorherige Struktur-Initialisierung. AROS erzeugt hier eine
RastPort-/Layer-/Bitmap-artige Kette, die spaeter in denselben Adressraum
zeigt, in dem der Objekt-Pointer bei `0x000625ea` liegt.

Vor dem byteweisen Plotten ist der Bereich gleichzeitig als objektartiger
Block und als Bitmap-Ziel sichtbar:

```text
ENEMY_GFXCALL 1314 PC=00E0BDF2 ...
A0-A7=000625B8,00000462,000625B8,00061D7C,...
MEM_A2 000625B8: 00062CB0 00000258 02800100 00000000
MEM_A3 00061D7C: 00061CD0 0004A750 00000000 00000000
```

Danach loescht AROS/ROM-Code den Bereich `0x000625ea..0x000625ff` ueber
`0x00f9fea4`, `0x00f9fea6`, `0x00f9feaa` und `0x00f9feb2`. Direkt
anschliessend schreibt der AROS-Graphics-Plotter bei `0x00e0c004`
Pixel-/Maskenbytes in `0x000625f0` und spaeter in das Pointerfeld
`0x000625ea..0x000625ed`:

```text
PC=00E0C004 ADDR=000625F8  -> 40,60,70,78 ...
PC=00E0C004 ADDR=000625EA  -> 40,60,64,66 ...
PC=00E0C004 ADDR=000625EB  -> 40,60,68,6c ...
PC=00E0C004 ADDR=000625EC  -> 40,60,70,78,7c ...
PC=00E0C004 ADDR=000625ED  -> 40,60,64,66 ...
```

Das erzeugt erneut den spaeter gefaehrlichen Wert:

```text
MEM_A2_32 000625EA=666C7C64
WATCH=666C7C66
```

Aktueller Schluss mit Evidenzlevel `runtime`: Der gfx-Pfad haengt nicht von
hoerbaren Disketten-Schrittgeraeuschen ab. In diesem AROS-Lauf ist die CPU
bereits in ROM-/Graphics-Code aktiv, AROS initialisiert die relevante
Graphics-Struktur und der AROS-Plotter beschreibt den Speicherbereich, der
spaeter als Exec-/Objekt-Pointer gelesen wird. Hoerbare Driveclicks sind nur
ein Verhalten der emulierten Laufwerksmechanik; sie beweisen nicht, ob dieser
CPU-Pfad ausgefuehrt wurde.

Offen bleibt noch die strengere Herkunftsfrage zu `0x000625b8` und
`0x00061d7c`: Die Watchpoints beweisen den direkten AROS-Graphics-Writer,
aber noch nicht abschliessend, ob diese konkreten Basisobjekte aus Enemy-
Loaderdaten, AROS-Allokationen oder einer Ueberlagerung beider Sichtweisen
stammen.

Naechster sinnvoller Schritt: die Allokation bzw. erste sinnvolle
Initialisierung von `0x000625b8` und `0x00061d7c` verfolgen und gegen den
Original-Kickstart-Lauf spiegeln. Damit laesst sich trennen, ob AROS eine
falsche Ziel-Bitmap aus Enemy-Daten ableitet oder ob AROS selbst eine
inkompatible RAM-Struktur anlegt.

### Herkunft von `0x000625b8` und `0x00061d7c`

Captures:

```text
AROS:     work/kickstart-deps/runtime/enemy1_aros_a500_20260628T234009+0200
Original: work/kickstart-deps/runtime/enemy1_original_a500_20260628T234815+0200
```

Die Instrumentierung wurde fuer diesen Vergleich um zwei Watchbereiche
erweitert:

```text
0x000625b8..0x00062617  obj_base_625b8
0x00061d7c..0x00061d9b  rp_base_61d7c
```

AROS initialisiert `0x00061d7c` als Graphics-Struktur. Nach RAM-Clear und
einigen Byte-Initialisierungen schreibt der AROS-Extension-Code:

```text
PC=00E18254 ADDR=00061D7C/7E -> 0x00061d7c+0x00 = 0x00061cd0
PC=00E1825A ADDR=00061D80/82 -> 0x00061d7c+0x04 = 0x0004a750
```

Der sichtbare Zustand danach ist:

```text
61D7C=00061CD0,0004A750,00000000,00000000,...
```

Das ist der fruehere `MEM_A3`-Wert aus den kritischen Graphics-Calls. Damit ist
`0x00061d7c` nicht nur ein zufaelliger Wert auf dem Stack, sondern eine von
AROS Graphics aufgebaute Struktur.

Fuer `0x000625b8` ist der entscheidende spaetere Aufbau:

```text
PC=00F8C9EA ADDR=000625B8/BA -> 0x000625b8+0x00 = 0x00062cb0
PC=00F8C9EE ADDR=000625BC/BE -> 0x000625b8+0x04 = 0x00000258
```

Direkt in diesem Moment steht im Log:

```text
A0-A7=00000400,00062CB0,000625B8,00055080,00000400,00062810,00C00560,00C35330
MEM_A2_32 000625EA=0005512C
MEM_A3 00055080: 000625B8 00000178 00C26CD8 0005512C
OBJMEM 625B8=00062CB0,00000000,02800100,00000000,...
```

Das ist wichtig, weil `0x000625ea` zu diesem Zeitpunkt noch wie ein gueltiges
Pointerfeld aussieht (`0x0005512c`). Erst danach loescht AROS/ROM-Code den
Bereich und der AROS-Plotter `0x00e0c004` schreibt Pixel-/Maskenbits breit in
`0x000625b8..0x00062617`, darunter auch in `0x000625ea..0x000625ed`.

Beispiele fuer diese spaetere Plotter-Phase:

```text
PC=00E0C004 ADDR=000625C8 -> 40,60,62,63 ...
PC=00E0C004 ADDR=000625F8 -> 40,60,70,78,7c,7e,7f ...
PC=00E0C004 ADDR=000625EA..ED -> 66,6c,7c,66 als 32-bit Sicht
```

Der Original-Kickstart-Spiegel zeigt das gegenteilige Verhalten. Mit derselben
Instrumentierung beruehrt Original die absoluten Bereiche
`0x00061d7c..0x00061d9b`, `0x000625b8..0x00062617` und
`0x000625ea..0x000625ed` nur in der fruehen RAM-Clear-Schleife bei
`0x00fc060e`. Danach gibt es keine spaeteren Treffer auf:

```text
PC=00E0C004
PC=00F8C9EA / 00F8C9EE
PC=00E18254 / 00E1825A
Exception 3
```

Original fuehrt zwar ebenfalls `0x80`-Graphics-Operationen aus, aber ueber
andere Zielstrukturen:

```text
MEM_A1 00014D78: 00000000 0006B288 00000000 00000000
MEM_A1 00014E20: 00000000 0006B1E0 00000000 00000000
MEM_A2 00C08750 / 00C089A0 ...
```

Aktueller Schluss mit Evidenzlevel `runtime`: Die kaputte Kette ist
AROS-spezifisch. `0x00061d7c` ist eine von AROS Graphics initialisierte
Struktur, `0x000625b8` wird im AROS-Lauf als Ziel-/Bitmap-nahe Struktur
aufgebaut, und der AROS-Plotter beschreibt danach genau diesen Speicherbereich.
Original benutzt fuer die vergleichbaren Graphics-Operationen andere
Zieladressen und laesst `0x000625ea..0x000625ed` nach dem RAM-Clear in Ruhe.

Naechster sinnvoller Schritt: `0x00f8c9ea/0x00f8c9ee` statisch und dynamisch
als Funktionskontext aufloesen. Ziel ist zu klaeren, ob dieser ROM-Code eine
AROS-Bitmap-Struktur aus Parametern zusammensetzt oder ob ein bereits falscher
Parameter `A2=0x000625b8` aus dem vorherigen Graphics-/Layer-Kontext kommt.

### Kontext von `0x00f8c9ea/0x00f8c9ee`

Der statische und dynamische Kontext ist jetzt aufgeloest. Die Arbeitsdateien
liegen hier:

```text
work/kickstart-deps/runtime/enemy1_aros_a500_20260628T234009+0200/pc_f8c9ea_map.txt
work/kickstart-deps/runtime/enemy1_aros_a500_20260628T234009+0200/pc_f8c878_alloc_context.txt
work/kickstart-deps/runtime/enemy1_aros_a500_20260628T234009+0200/pc_f8cf8c_caller_context.txt
```

`0x00f8c9ea` liegt im AROS-ROM `roms/aros/aros-rom.bin` bei Offset
`0x00c9ea`. Die relevante Sequenz ist:

```asm
00f8c9c2: move.l d3,-(a7)
00f8c9c4: move.l a3,-(a7)
00f8c9c6: jsr $f8c1b4(pc)
00f8c9ca: addq.l #$8,a7
00f8c9cc: movea.l a3,a2
00f8c9ce: cmp.l a5,d7
00f8c9d0: bne.b $f8c9ea
00f8c9d2: cmpa.w #$0,a5
00f8c9d6: beq.b $f8c9ea
00f8c9d8: move.l d3,-(a7)
00f8c9da: move.l a5,-(a7)
00f8c9dc: jsr $f8c1b4(pc)
00f8c9e0: adda.l $4(a5),a5
00f8c9e4: movea.l d7,a0
00f8c9e6: move.l (a0),d7
00f8c9e8: addq.l #$8,a7
00f8c9ea: move.l d7,(a2)
00f8c9ec: suba.l a2,a5
00f8c9ee: move.l a5,$4(a2)
00f8c9f2: add.l d2,$1c(a4)
00f8c9f6: cmpa.l (a3),a2
00f8c9f8: bne.w $f8c8ca
```

Das ist keine Bitmap-Zeichenroutine. Die Instruktionen passen zu Exec-
Speicherverwaltung ueber `struct MemChunk`:

```text
(A2)    = D7        -> mc_Next
4(A2)  = A5 - A2   -> mc_Bytes
A4+1c += D2        -> freie Bytes / Header-Zaehler
```

Der Runtime-Zustand direkt am kritischen Treffer bestaetigt das:

```text
PC=00F8C9EA ADDR=000625B8 SIZE=2 VAL=00000006
D0-D3=000551F8,0007FFF8,00000258,00000420
D4-D7=000625B8,00000256,00000410,00062CB0
A0-A7=00000400,00062CB0,000625B8,00055080,00000400,00062810,00C00560,00C35330
MEM_A2_32 000625EA=0005512C
MEM_A3 00055080: 000625B8 00000178 00C26CD8 0005512C
```

Danach schreibt die Funktion:

```text
0x000625b8+0x00 = 0x00062cb0
0x000625b8+0x04 = 0x00000258
```

Damit ist `0x00f8c9ea/0x00f8c9ee` nicht die Stelle, die den falschen
`A2=0x000625b8` erzeugt. `A2` ist dort bereits `0x000625b8`. Die Funktion
behandelt diese Adresse als freien oder aufzuteilenden Speicherblock und legt
dort MemChunk-Metadaten ab.

Der weitere Funktionskontext ab `0x00f8c836` sieht wie ein interner Allocator-
Helper aus:

```asm
00f8c836: movem.l d2-d7/a2-a6,-(a7)
00f8c83a: movea.l $30(a7),a4
00f8c83e: move.l $34(a7),d3
00f8c842: move.l $38(a7),d4
00f8c846: move.l $3c(a7),d5
...
00f8c89a: moveq #7,d0
00f8c89c: and.l d4,d0
00f8c89e: movea.l d5,a0
00f8c8a0: lea.l $7(a0,d0.l),a0
00f8c8a4: move.l a0,d2
...
00f8c8bc: move.l d2,$4(a2)
00f8c8c0: clr.l (a2)
00f8c8c2: move.l d0,$10(a4)
00f8c8c6: add.l d2,$1c(a4)
```

Der oeffentliche/aeussere Kontext bei `0x00f8cf8c` laeuft ueber die Exec-
MemList und ruft dann Helper bei `0x00f8c65c`/`0x00f8c836`:

```asm
00f8cf8c: movem.l d2-d4/a2-a6,-(a7)
00f8cf90: move.l $24(a7),d3
00f8cf94: movea.l $30(a7),a3
00f8cf98: move.l $28(a7),d4
00f8cf9c: andi.l #$707,d4
00f8cfa2: movea.l a3,a6
00f8cfa4: jsr -$84(a6)
00f8cfa8: movea.l $142(a3),a2
...
00f8d028: move.l d0,-(a7)
00f8d02a: move.l a2,-(a7)
00f8d02c: jsr (a5)
```

Der AROS-Quellabgleich ist an dieser Stelle strukturell, nicht bytegenau. In
`/tmp/aros-src/arch/m68k-amiga/boot/early.c` taucht dieselbe MemChunk-Logik
auf:

```c
p4->mc_Next  = p2->mc_Next;
p4->mc_Bytes = (UBYTE *)p2+p2->mc_Bytes-(UBYTE *)p4;
p2->mc_Next  = p4;
```

Das ist nicht als exakter Line-Match fuer `0x00f8c9ea` zu werten, aber es
stuetzt die Interpretation der Felder `(A2)` und `4(A2)` als
`mc_Next`/`mc_Bytes`.

Aktueller Schluss mit Evidenzlevel `runtime + disasm`: AROS betrachtet
`0x000625b8` zu diesem Zeitpunkt als Teil eines freien bzw. teilbaren
Exec-MemChunk-Bereichs. Gleichzeitig zeigt `MEM_A2_32 000625EA=0005512C`,
dass innerhalb dieses Bereichs bereits ein sinnvoll wirkendes Pointerfeld
liegt. Der Konflikt ist damit frueher als `0x00f8c9ea`: Entweder wurde
`0x000625b8` irrtuemlich als frei in die AROS-MemList aufgenommen, oder ein
Enemy-/Loader-/Graphics-Pfad benutzt Speicher, den AROS danach korrekt aus
seiner Sicht als frei allokiert/aufsplittet.

Naechster sinnvoller Schritt: Den Eintritt in `0x00f8c836` und den aeusseren
Aufrufer `0x00f8cf8c` fokussiert instrumentieren. Geloggt werden sollen die
Argumente (`d3`, `d4`, `d5`, `a4`, `a6`), der aufrufende Stack und die
MemHeader/MemList-Felder, sobald der gewaehlte oder erzeugte Block mit
`0x000625b8..0x00062617` ueberlappt. Ziel ist, den konkreten AllocMem-Caller zu
finden, der diesen Bereich als nutzbaren Block anfordert oder erzeugt.

## 2026-06-29: fokussierter Caller-Kontext fuer `0x625b8`

Instrumentierter FS-UAE-Lauf:

```text
work/kickstart-deps/runtime/enemy1_aros_a500_20260629T095608+0200
```

Relevante Instrumentierung:

- `0x00f888d8`, `0x00f888de`, `0x00f888e6`
- `0x00f8d2a8`, `0x00f8d2ae`
- `0x00f8c836`, `0x00f8c83a`
- `0x00f8c9ea`, `0x00f8c9ee`

Der konkrete MemChunk-Aufrufer ist damit runtime-seitig belegt. Der Pfad ist:

```text
0x00f888de/e6  ->  0x00f8d2a8  ->  0x00f8c836  ->  0x00f8c9ea/0x00f8c9ee
```

Erste kritische Einfuegung:

```text
ENEMY_ALLOC 4278 free_wrapper_before_memchunk_call_f8d2a8
D0-D3=00000420,00C00882,000625B8,00000256
STACKL: 00000400 00000420 000625B8 00000256 ...
STACKL2: ... 00000256 ... 00F888E6

ENEMY_ALLOC 4280 memchunk_helper_entry_f8c83a_post_movem
HELPER_ARGS ret=00F8D2AE a4=00000400 d3=00000420 d4=000625B8 d5=00000256
calc_candidate=00000258 calc_end=00000678

ENEMY_ALLOC 4281 memchunk_select_write_next_f8c9ea
MEM_A2 000625B8: 00000000 00000000 02800100 00000000

ENEMY_WATCH 257/258
PC=00F8C9EA ADDR=000625B8/000625BA VAL=00000006/00062CB0

ENEMY_WATCH 259/260
PC=00F8C9EE ADDR=000625BC/000625BE VAL=00000000/00000258
```

Damit wird `0x625b8` als MemChunk-Start mit Groesse `0x258` in die Exec-Liste
eingetragen. Der aufrufende Wrapper liegt bei `0x00f888de/e6`, nicht im
normalen `AllocMem`-Returnpfad.

Zweite, spaetere Einfuegung derselben Basis:

```text
ENEMY_ALLOC 4290 caller_f888de
STACKL2 ... 00E0BE7A 00000010 00E1BE84

ENEMY_ALLOC 4291 free_wrapper_before_memchunk_call_f8d2a8
arg0=000625B8 arg1=00000080

ENEMY_ALLOC 4294 memchunk_select_write_next_f8c9ea
MEM_A2 000625B8: 00000000 00000000 00000000 00000000

ENEMY_WATCH 556/557
PC=00F8C9EA ADDR=000625B8/000625BA VAL=00000006/00062CB0

ENEMY_WATCH 558/559
PC=00F8C9EE ADDR=000625BC/000625BE VAL=00000000/00000258
```

Der Ruecksprung `0x00E0BE7A` zeigt, dass dieser spaetere FreeMem-/MemChunk-Pfad
aus dem Graphics-Code unmittelbar nach `0x00E0BE76` kommt. Das passt zur
vorherigen Beobachtung, dass AROS-Graphics zuvor mit `A2=0x625b8` zeichnet und
danach denselben Bereich als Speicherblock freigibt/einordnet.

Aktueller Schluss mit Evidenzlevel `runtime`: AROS waehlt `0x625b8` nicht nur
passiv in `AllocMem`; ein FreeMem-artiger Wrapper `0x00f888de/e6` uebergibt
`addr=0x625b8` explizit an den MemChunk-Helfer. Fuer die spaetere Instanz ist
der konkrete uebergeordnete Aufrufer `0x00E0BE7A` im Graphics-Pfad.

## 2026-06-29: E0BE-Graphics-Call direkt gegen MemChunk gemappt

Instrumentierter FS-UAE-Lauf:

```text
work/kickstart-deps/runtime/enemy1_aros_a500_20260629T101030+0200
```

Neue Instrumentierung:

- `ENEMY_E0BE` fuer `0x00e0be40`, `0x00e0be70`, `0x00e0be76`,
  `0x00e0be7a`, `0x00e0be92`, `0x00e0be96`
- Ausgabe von Opcode, Library-Ziel, D/A-Registern, Stack-Longs und Keymem
  (`0x625b8`, `0x61d7c`, `0x55080`, `0x62810`)

Kritischer Ablauf im fehlerhaften AROS-Lauf:

```text
ENEMY_E0BE 0045 e0be76_before_jsr_d16_a6
PC=00E0BE76 OP=4EAE,FE0E,306B TARGET=00C25186
A0-A7=000625B8,0004A7A0,000625B8,00061D7C,00000010,00000000,00C25378,00C3524C
MEM_A0 000625B8: 00000000 00000000 00000000 00000000
MEM_A2 000625B8: 00000000 00000000 00000000 00000000
```

Damit geht `0x625b8` als A0/A2 in einen Graphics-Library-Call
`JSR -0x1f2(A6)` mit `A6=0x00c25378`, Ziel `0x00c25186`.

Innerhalb dieses Calls laeuft der bekannte FreeMem-/MemChunk-Pfad:

```text
ENEMY_ALLOC 4293 memchunk_helper_entry_f8c83a_post_movem
HELPER_ARGS ret=00F8D2AE a4=00000400 d3=00000420 d4=000625B8 d5=00000080

ENEMY_ALLOC 4294 memchunk_select_write_next_f8c9ea
A0-A7=00062638,0006A9C0,000625B8,00055080,00000400,00062810,00C00560,00C351A0
MEM_A2 000625B8: 00000000 00000000 00000000 00000000

ENEMY_WATCH 556/557
PC=00F8C9EA ADDR=000625B8/000625BA VAL=00000006/00062CB0

ENEMY_WATCH 558/559
PC=00F8C9EE ADDR=000625BC/000625BE VAL=00000000/00000258
```

Direkt nach Rueckkehr an `0x00e0be7a` ist der Zielbereich kein leerer
Grafik-/Objektpuffer mehr, sondern ein Exec-MemChunk:

```text
ENEMY_E0BE 0046 e0be7a_after_jsr_d16_a6
PC=00E0BE7A OP=306B,0024,7000
A0-A7=0000044E,000625B8,000625B8,00061D7C,00000010,00000000,00C25378,00C3524C
MEM_A1 000625B8: 00062CB0 00000258 00000000 00000000
MEM_A2 000625B8: 00062CB0 00000258 00000000 00000000
KEYMEM 625B8=00062CB0,00000258,00000000,00000000,...
```

Danach folgt noch ein zweiter Graphics-Call bei `0x00e0be92`
(`TARGET=00C25288`), aber A2 zeigt bereits auf den als MemChunk markierten
Bereich:

```text
ENEMY_E0BE 0047 e0be92_before_second_call
PC=00E0BE92 OP=4EAE,FF10,4CDF TARGET=00C25288
A0-A7=00000005,00061D7C,000625B8,00061D7C,00000010,00000000,00C25378,00C3524C
MEM_A2 000625B8: 00062CB0 00000258 00000000 00000000
```

Der Lauf endet weiterhin reproduzierbar mit:

```text
ENEMY_EXCEPTION3 ce000-preframe PC=00F87452 INSTR_PC=00F8744E FAULT=24892489
Exception 3 (2489 f87452) at f87452 -> fe774c!
```

Schluss mit Evidenzlevel `runtime`: Die direkte Ursache liegt nicht in einem
spaeteren zufaelligen AllocMem-Treffer. AROS-Graphics nimmt bei `0x00e0be76`
den Enemy-Zielpuffer `0x625b8` an, ruft intern den FreeMem-/MemChunk-Pfad auf
und traegt denselben Bereich als freien Exec-MemChunk (`next=0x62cb0`,
`size=0x258`) ein. Ab `0x00e0be7a` arbeitet Enemy weiter mit diesem nun
umklassifizierten Speicherbereich.

## 2026-06-29: LVO und AROS-Source-Korrelation fuer `0x00e0be76`

Die LVO-Zuordnung wurde gegen die lokale FD-Tabelle aus amitools geprueft:

```text
/home/kaufmann/.local/lib/python3.14/site-packages/amitools/data/fd/graphics_lib.fd

AllocRaster(width,height)(d0/d1)
FreeRaster(p,width,height)(a0,d0/d1)
...
Move(rp,x,y)(a1,d0/d1)
```

Aus der FD-Reihenfolge ergeben sich fuer die beobachteten Library-Calls:

```text
0x00e0be76: JSR -0x01f2(A6)  ==  graphics.library/FreeRaster
0x00e0be92: JSR -0x00f0(A6)  ==  graphics.library/Move
```

Das passt zu den Runtime-Registern des kritischen Calls:

```text
ENEMY_E0BE 0045 e0be76_before_jsr_d16_a6
PC=00E0BE76 OP=4EAE,FE0E,306B TARGET=00C25186
A0-A7=000625B8,0004A7A0,000625B8,00061D7C,00000010,00000000,00C25378,00C3524C
D0-D3=00000080,00000008,00000005,00000004
```

Damit ist der konkrete API-Aufruf:

```text
FreeRaster(p=0x000625b8, width=0x0080, height=0x0008)
```

Die AROS-Quelle wurde aus dem AROS-Repository ueber den lokal vorhandenen
Tree `/tmp/aros-tree.json` lokalisiert und als Raw-Dateien nach `/tmp/aros-raw`
geladen:

```text
/tmp/aros-raw/rom/graphics/freeraster.c
/tmp/aros-raw/rom/graphics/allocraster.c
/tmp/aros-raw/rom/graphics/move.c
/tmp/aros-raw/compiler/include/graphics/gfx.h
```

Relevante AROS-Source-Stellen:

```c
/* rom/graphics/freeraster.c */
AROS_LH3(void, FreeRaster,
    AROS_LHA(PLANEPTR, p,      A0),
    AROS_LHA(UWORD,    width,  D0),
    AROS_LHA(UWORD,    height, D1),
    struct GfxBase *, GfxBase, 83, Graphics)
{
    FreeMem(p, RASSIZE(width, height));
}
```

```c
/* compiler/include/graphics/gfx.h */
#define RASSIZE(w,h)   ( (h) * ( ((w)+15) >>3 & 0xFFFE ))
```

```c
/* rom/graphics/move.c */
AROS_LH3(void, Move,
    AROS_LHA(struct RastPort *, rp, A1),
    AROS_LHA(WORD             , x, D0),
    AROS_LHA(WORD             , y, D1),
    struct GfxBase *, GfxBase, 40, Graphics)
```

Fuer den kritischen Call gilt:

```text
RASSIZE(0x80, 0x08)
= 0x08 * (((0x80 + 15) >> 3) & 0xfffe)
= 0x08 * (0x11 & 0xfffe)
= 0x08 * 0x10
= 0x80
```

Das deckt sich exakt mit dem Runtime-Wert im FreeMem-/MemChunk-Pfad:

```text
ENEMY_ALLOC 4291 free_wrapper_before_memchunk_call_f8d2a8
D0-D3=00000420,00C00882,000625B8,00000080

ENEMY_ALLOC 4293 memchunk_helper_entry_f8c83a_post_movem
HELPER_ARGS ... d4=000625B8 d5=00000080 ...
```

Schluss mit Evidenzlevel `runtime + source`: Der problematische Call ist nicht
ein unbekannter Graphics-Nebeneffekt, sondern konkret
`graphics.library/FreeRaster(0x625b8, 0x80, 0x08)`. AROS implementiert
`FreeRaster` als direkten `FreeMem(p, RASSIZE(width,height))`-Wrapper. Deshalb
entsteht der beobachtete Exec-MemChunk-Eintrag an `0x625b8`; die spaetere
Chunk-Groesse `0x258` entsteht durch Exec-Merge mit angrenzendem freiem
Speicher ab `0x62638`.

## 2026-06-29: statische Argumentkette bis `FreeRaster`

Zusaetzlich zum LVO-/Source-Abgleich wurde die lokale Callsite statisch
gemappt:

```text
work/kickstart-deps/runtime/enemy1_aros_a500_20260629T101030+0200/e0be40_freeraster_call_map_report.md
work/kickstart-deps/runtime/enemy1_aros_a500_20260629T101030+0200/e13908_dispatch_map_report.md
work/kickstart-deps/runtime/enemy1_aros_a500_20260629T101030+0200/e027d8_method_map_report.md
```

Der relevante Ausschnitt um `0x00e0be70` ist eindeutig:

```asm
00e0be6c: jsr    -$24(a6)
00e0be70: movea.l a2,a0
00e0be72: move.l  d4,d0
00e0be74: move.l  d6,d1
00e0be76: jsr    -$1f2(a6)
```

Mit der bereits belegten FD-Zuordnung ist das:

```text
FreeRaster(p=A2, width=D4, height=D6)
```

Im kritischen Runtime-Treffer:

```text
ENEMY_TRACE 52998 entry_ext_plotter_e0be40
A0-A7=00C26808,00000000,000625B8,00061D7C,00000010,00062638,00E01E22,00C3524C

ENEMY_E0BE 0045 e0be76_before_jsr_d16_a6
A0-A7=000625B8,0004A7A0,000625B8,00061D7C,00000010,00000000,00C25378,00C3524C
D0-D3=00000080,00000008,00000005,00000004
D4-D7=00000080,00000008,00000008,00000080
```

Damit ist `A2=0x625b8` bereits beim Eintritt in die `E0BE`-Routine gesetzt und
wird ohne Umweg als `FreeRaster`-Pointer uebergeben. `D4=0x80` und `D6=0x08`
werden zu `width/height`.

Der vorgelagerte Dispatch zeigt, dass diese `E0BE`-Routine als Methode ueber
`0x00e13908 -> 0x00e13a58` erreicht wird:

```asm
00e13a50: movea.l $28(a5),a6
00e13a54: move.l  a5,-(a7)
00e13a56: movea.l a2,a5
00e13a58: jsr    -$1b0(a6)
00e13a5c: movea.l (a7)+,a5
```

Passender Runtime-Kontext:

```text
ENEMY_GFXCALL 1316 jsr_d16_a6 PC=00E13A58 TARGET=00C251C8 DISP=FE50
STACK 00C35160: 00C351B4 00061D7C 00C25378 00000001 00000000 00000008 00000080 000625B8
MEM_A3 00C35230: 00050004 0084000B 000625B8 00000010

ENEMY_TRACE 53014 entry_ext_helper_e027d8
STACK3 00C3517C: 000625B8 00061D7C 00000010 00C25378
```

`0x00e027d8` selbst ist laut Map kein weiterer Raster-/Bitmap-Ursprung, sondern
nur ein Semaphore-Helfer:

```asm
00e027d8: movem.l d0-d1/a0-a1/a6,-(a7)
00e027dc: movea.l $4.l,a6
00e027e2: lea.l   $48(a5),a0
00e027e6: jsr    -$234(a6)    ; exec/ObtainSemaphore
00e027ea: movem.l (a7)+,d0-d1/a0-a1/a6
00e027ee: rts
```

Schluss mit Evidenzlevel `static + runtime`: Der kaputte Bereich entsteht nicht
dadurch, dass Exec spaeter zufaellig `0x625b8` als freien Block auswaehlt. Die
AROS-Grafikmethode bekommt `0x625b8` bereits als Methoden-/Stackparameter,
uebernimmt ihn als `A2`, und `0x00e0be70..76` macht daraus direkt
`FreeRaster(0x625b8,0x80,0x08)`. Danach schreibt Exec erwartungsgemaess den
MemChunk-Header an genau diese Adresse.

Naechster gezielter Schritt: den Setter des Methodenarguments
`MEM_A3 00C35230: ... 000625B8 00000010` bzw. des Stackslots bei
`00C3517C` vor `0x00e13a58` instrumentieren. Das ist jetzt der frueheste
konkrete Punkt, an dem `0x625b8` noch als Parameter und nicht schon als
`FreeRaster`-Argument sichtbar ist.

## 2026-06-29: Runtime-Rueckverfolgung bis `E065B4`

Neue Capture-Basis:

```text
work/kickstart-deps/runtime/enemy1_aros_a500_20260629T111143+0200/enemy1_aros_a500.fs-uae.log
/tmp/fs-uae-instrument-src/fs-uae-3.2.35-enemy-exception-log/fs-uae
```

Der kritische `FreeRaster`-Treffer wurde erneut reproduziert:

```text
594525 ENEMY_E0BE 0045 e0be76_before_jsr_d16_a6
A0-A7=000625B8,0004A7A0,000625B8,00061D7C,00000010,00000000,00C25378,00C3524C
D0-D3=00000080,00000008,00000005,00000004
D4-D7=00000080,00000008,00000008,00000080

594578 ENEMY_ALLOC 4294 memchunk_select_write_next_f8c9ea
D4-D7=000625B8,00000080,00000410,00062CB0
A0-A7=00062638,0006A9C0,000625B8,00055080,00000400,00062810,00C00560,00C351A0
```

Die neue Rueckverfolgung zeigt den unmittelbaren Aufrufer-/Parameterkontext vor
`E0BE40`:

```text
594216 ENEMY_TRACE 53008 entry_ext_wrapper_e13c44
A0-A7=00000010,00061D7C,000625B8,00061D7C,00000010,00C35244,00C25378,00C351F8
METHOD_STACK_L2 00C35218: 00C25378 00000005 00000004 00000080 00000008 00C25378 00050004 0084000B

594302 ENEMY_TRACE 53015 entry_ext_dispatch_e13908
A0-A7=00000001,00C351D0,000625B8,00061D7C,00000010,00C35244,00C25378,00C351B8

594317 ENEMY_TRACE 53018 dispatch_load_a2_from_arg0
MEM_A3 00C35230: 00050004 0084000B 000625B8 00000010
MEM_A4 00C35238: 000625B8 00000010 000000B8 00000000
METHOD_STACK_L 00C35164: 00061D7C 00C25378 00000001 00000000 00000008 00000080 000625B8 00061D7C

594357 ENEMY_TRACE 53021 dispatch_call_method_minus_1b0
STACK2 00C35170: 0000 0000 0000 0008 0000 0080 0006 25B8

594457 ENEMY_TRACE 53037 gfx_callsite_e065b4
DISPATCH_FRAME A5=00C351B4 A5_08=00061D7C A5_14=00E065B4 A5_18=00C35238 A5_1C=00061DCA

594472 ENEMY_GFXCALL 1317 jsr_d16_a6 PC=00E13AC0 TARGET=00C251C2 DISP=FE4A
STACK 00C35160: 00C351B4 00061D7C 00C25378 00000001 00000000 00000008 00000080 000625B8
```

Schluss mit Evidenzlevel `runtime`: `0x625b8` wird nicht erst in `E0BE40`
erzeugt. Es liegt bereits vor `E13908/E13A58` im Methoden-Stack und im
Argumentblock `00C35230/00C35238`. Die konkrete Kette ist:

```text
E13C44 -> E12D66 -> E13908 -> E027D8/ObtainSemaphore -> E065B4 -> E13AC0 -> E0BE40 -> FreeRaster
```

Naechster Beweisschritt ist deshalb enger: den Schreibzugriff finden, der den
Long-Wert `0x000625b8` nach `00C3517C`, `00C35238` oder in den spaeteren
Argumentblock schreibt. Dafuer wurde die FS-UAE-Instrumentierung um
`ENEMY_VALUE625B8` erweitert; sie loggt Long-Word-Writes mit genau diesem Wert
inklusive PC, Registern, Stack und Kontext um die Zieladresse.

## 2026-06-29: Setter fuer `0x625b8` in `00C35238` und `00C3517C`

Neue Capture-Basis mit enger Slot-Instrumentierung:

```text
work/kickstart-deps/runtime/enemy1_aros_a500_20260629T144050+0200/enemy1_aros_a500.fs-uae.log
work/kickstart-deps/runtime/enemy1_aros_a500_20260629T144050+0200/e06660_argwrite_map_report.md
work/kickstart-deps/runtime/enemy1_aros_a500_20260629T144050+0200/e1390c_stackcopy_map_report.md
```

Der entscheidende Setter fuer den spaeteren A4-/Argumentslot ist jetzt sichtbar:

```text
597781 ENEMY_ARGWRITE 1193 PC=00E06660 ADDR=00C35238 SIZE=2 VAL=00000006
597784 ENEMY_ARGWRITE 1194 PC=00E06660 ADDR=00C3523A SIZE=2 VAL=000625B8
597786 ARGCTX ... 00C35230=00000080,00000002,00060000,00000010
```

Das ist ein Word-Pair-Write auf `00C35238`, der den Long-Wert
`0x000625b8` erzeugt. Kurz danach wird derselbe Wert in den Method-Stack
kopiert:

```text
597892 ENEMY_ARGWRITE 1195 PC=00E1390C ADDR=00C3517C SIZE=2 VAL=00000006
597895 ENEMY_ARGWRITE 1196 PC=00E1390C ADDR=00C3517E SIZE=2 VAL=000625B8
597897 ARGCTX ... 00C35230=00050004,0084000B,000625B8,00000010
```

Die unmittelbar folgende Dispatch-Kette verbraucht genau diese Werte:

```text
597916 ENEMY_TRACE 53018 MEM_A3 00C35230: 00050004 0084000B 000625B8 00000010
597917 ENEMY_TRACE 53018 MEM_A4 00C35238: 000625B8 00000010 000000B8 00000000
597957 ENEMY_TRACE 53022 STACK3 00C3517C: 0006 25B8 0006 1D7C ...
598066 ENEMY_GFXCALL 1317 STACK ... 00000008 00000080 000625B8
598117 ENEMY_E0BE 0045 A0-A7=000625B8,...,000625B8,...
598230 ENEMY_ALLOC 4294 D4-D7=000625B8,00000080,00000410,00062CB0
612688 ENEMY_EXCEPTION3 PC=00F87452 FAULT=24892489
```

PC-Map:

```text
00E06660 -> kickstart_ext_rom_e0 offset 0x006660, backing roms/aros/aros-ext.bin
00E1390C -> kickstart_ext_rom_e0 offset 0x01390c, backing roms/aros/aros-ext.bin
```

Schluss mit Evidenzlevel `runtime`: `0x625b8` wird vor der bekannten
`E13908 -> E027D8 -> E065B4 -> E13AC0 -> E0BE40 -> FreeRaster`-Kette in
AROS-Ext-ROM-Code in den Argumentslot `00C35238` geschrieben. `E1390C`
kopiert diesen Wert in den Method-Stack bei `00C3517C`, und der spaetere
`FreeRaster(0x625b8,0x80,0x08)` ist die direkte Folge dieses
Argumentaufbaus.

Naechster gezielter Schritt: `00E06660` rueckwaerts im AROS-Ext-ROM mappen:
Funktionseintritt, Parameter von `A5`/Stack und die Quelle des Werts, der als
`0x000625b8` nach `00C35238` geschrieben wird.

## 2026-06-29: `E06658` bekommt `0x625b8` ueber `A0`, Quelle ist `A2` bei `E0BE54`

Neue Capture-Basis mit enger Instrumentierung fuer den Call-Vorbereitungsblock:

```text
work/kickstart-deps/runtime/enemy1_aros_a500_20260629T150457+0200/fsuae.stdout.log
work/kickstart-deps/runtime/enemy1_aros_a500_20260629T150457+0200/e0be54_a2_to_a0_source_map_report.md
```

Capture-Summary:

```text
capture_id=enemy1_aros_a500_20260629T150457+0200
enemy_adf_insertions=12
debugger_prompt_found=yes
debugger_register_dump_found=yes
```

Die statische ROM-Map fuer den neuen Fokuspunkt:

```text
00E0BE54 -> kickstart_ext_rom_e0 offset 0x00be54, backing roms/aros/aros-ext.bin
```

Die relevante Disassembly um den Call zeigt, dass `A0` direkt aus `A2`
kommt:

```asm
00e0be54: 204a         movea.l a2, a0
00e0be56: 7000         moveq #$0, d0
00e0be58: 220c         move.l a4, d1
00e0be5a: 224b         movea.l a3, a1
00e0be5c: 240e         move.l a6, d2
00e0be5e: d48d         add.l a5, d2
00e0be60: 9684         sub.l d4, d3
00e0be62: 282f0036     move.l $36(a7), d4
00e0be66: 2a06         move.l d6, d5
00e0be68: 2c6f0080     movea.l $80(a7), a6
00e0be6c: 4eaeffdc     jsr -$24(a6)
```

Runtime-Beleg fuer den kritischen späten Treffer:

```text
ENEMY_TRACE 53170 plotter_copy_a2_to_a0 PC=00E0BE54
A0-A7=00C26808,00000000,000625B8,00061D7C,00000010,00000000,00000005,00C3524C

ENEMY_TRACE 53171 plotter_copy_a4_to_d1 PC=00E0BE58
A0-A7=000625B8,00000000,000625B8,00061D7C,00000010,00000000,00000005,00C3524C

ENEMY_GFXCALL 1315 jsr_d16_a6 PC=00E0BE6C TARGET=00C25354 DISP=FFDC
A0-A7=000625B8,00061D7C,000625B8,00061D7C,00000010,00000000,00C25378,00C3524C
```

Direkt danach erreicht derselbe Wert den `E06658`-Wrapper und wird wieder in
den Argumentblock geschrieben:

```text
ENEMY_TRACE 53176 entry_ext_blt_template_e06658 PC=00E06658
A0-A7=000625B8,00061D7C,000625B8,00061D7C,00000010,00000000,00C25378,00C35248

ENEMY_TRACE 53178 blt_template_store_a0_to_arg_c PC=00E06660
A0-A7=000625B8,00061D7C,000625B8,00061D7C,00000010,00C35244,00C25378,00C3521C

ENEMY_ARGWRITE 1191 PC=00E06660 ADDR=00C35238 SIZE=2 VAL=00000006
ENEMY_ARGWRITE 1192 PC=00E06660 ADDR=00C3523A SIZE=2 VAL=000625B8
```

Der bekannte Crash-Pfad bleibt im selben Lauf reproduziert:

```text
ENEMY_ALLOC 4294 memchunk_select_write_next_f8c9ea
D4-D7=000625B8,00000080,00000410,00062CB0

ENEMY_EXCEPTION3 ce000-preframe PC=00F87452 FAULT=24892489
```

Schluss mit Evidenzlevel `runtime`: `E06660` ist nur der Speicher-Write in den
lokalen Argumentblock. `E0BE54` ist die konkrete Instruktion, die fuer diesen
Call `A2=0x000625b8` nach `A0` kopiert. Der naechste Ursprung liegt damit vor
oder beim Eintritt in den `E0BE40`-Plotter: gesucht wird jetzt die Quelle von
`A2=0x000625b8` fuer genau diesen spaeten Call.

## 2026-06-29: Frueherer `E0BDF2`-Call benutzt `0x625b8` bereits als Objekt

Weitere Eingrenzung derselben Capture:

```text
work/kickstart-deps/runtime/enemy1_aros_a500_20260629T150457+0200/e0bdf2_outer_plotter_context_map_report.md
work/kickstart-deps/runtime/enemy1_aros_a500_20260629T150457+0200/e0bd80_outer_plotter_entry_search_map_report.md
```

Der zeitlich fruehere Call im gleichen groesseren Plotterlauf ist:

```text
ENEMY_GFXCALL 1314 jsr_d16_a6 PC=00E0BDF2 TARGET=00C1BA58 DISP=FE74
A0-A7=000625B8,00000462,000625B8,00061D7C,00C25378,00C35324,00C1BBE4,00C3524C
MEM_A2 000625B8: 00062CB0 00000258 02800100 00000000
```

Direkt danach schreibt der aufgerufene Pfad in genau diesen Bereich:

```text
ENEMY_WATCH 274 put_word_625ea PC=00F9FEA4 ADDR=000625B8 SIZE=2 VAL=00000000
A0-A7=000625B8,000625B8,00000080,00061D7C,00C25378,00C35324,00C1BBE4,00C3523C
STACK 00C3523C: 0000 0010 0006 25B8 00C1 BBE4 00E0 BDF6

ENEMY_WATCH 275 put_word_625ea PC=00F9FEA4 ADDR=000625BA SIZE=2 VAL=00000000
OBJMEM 625B8=00002CB0,00000258,02800100,00000000,...
```

Schluss mit Evidenzlevel `runtime`: `0x625b8` ist bereits vor dem
`E0BE54 -> E0BE6C -> E06658`-Teil als Objekt-/Bitmap-naher Pointer in `A0`
und `A2` aktiv. Der fruehere Call bei `E0BDF2` nach `00C1BA58` manipuliert
den Bereich direkt. Das ist der naechste engste Kandidat fuer die Ursache,
warum spaeter derselbe Bereich als Raster-/Bitmap-Speicher und anschliessend
als freizugebender Speicherblock behandelt wird.

Naechster gezielter Schritt: `00C1BA58` beziehungsweise den zugehoerigen
Library-/Methodenvektor fuer `E0BDF2` mappen und den Codepfad bis
`PC=00F9FEA4` zurueckverfolgen. Dort muss geklaert werden, ob `0x625b8`
korrekt als Zielobjekt geloescht wird oder ob AROS einen falschen
Bitmap-/RastPort-Zeiger in diesen Pfad gibt.

## 2026-06-29: `E0BDF2` ist kein bewiesener `BltClear`- oder `ScrollRaster`-Library-Call

Quellenabgleich gegen den offiziellen AROS-Source:

- `rom/graphics/allocraster.c`: `AllocRaster` hat Location 82. Das passt zu
  `jsr -$1ec(a6)` bei `00E0BDBA`, weil `82 * 6 = 0x1ec`. Der Call liefert im
  Lauf `D0=0x000625b8`, danach `movea.l d0,a2`.
- `rom/graphics/bltclear.c`: `BltClear` hat Location 50, also nicht `-$18c`.
- `rom/graphics/scrollraster.c`: `ScrollRaster` hat Location 66, numerisch
  `-$18c`, erwartet aber `rp` in `A1`.

Der Runtime-Kontext von `E0BDF2` beweist jedoch, dass `A6` dort nicht die
oeffentliche `graphics.library`-Base ist:

```text
ENEMY_GFXCALL 1314 jsr_d16_a6 PC=00E0BDF2 TARGET=00C1BA58 DISP=FE74
A0-A7=000625B8,00000462,000625B8,00061D7C,00C25378,00C35324,00C1BBE4,00C3524C
```

`A6=00C1BBE4`; `A6-$18c` ergibt `00C1BA58`, einen RAM-Zielstub ohne Backing
File. `A4=00C25378` ist der naheliegende `GfxBase`-Kandidat aus dem Stack, aber
der tatsaechliche Call geht ueber die RAM-Methodentabelle. Damit ist die
numerische Uebereinstimmung mit `ScrollRaster` kein Funktionsbeweis.

Direkt nach dem RAM-Stub springt der Pfad in den ROM-Fill-Helfer:

```text
ENEMY_WATCH 274 put_word_625ea PC=00F9FEA4 ADDR=000625B8 SIZE=2 VAL=00000000
A0-A7=000625B8,000625B8,00000080,00061D7C,00C25378,00C35324,00C1BBE4,00C3523C
STACK 00C3523C: 0000 0010 0006 25B8 00C1 BBE4 00E0 BDF6
```

Schluss mit Evidenzlevel `runtime` plus `source`: `E0BDBA` ist
`AllocRaster`-kompatibel und gibt den Block `0x625b8` zurueck. `E0BDF2` ist
dagegen ein interner RAM-Methodencall ueber `A6=0x00c1bbe4`, der den frisch
allokierten Block ueber den ROM-Fill-Helfer `F9FE54/F9FEA4` mit Nullen fuellt.
Das Zeroing selbst ist damit eher Initialisierung als die primaere Korruption.

Naechster gezielter Schritt: Den RAM-Stub `00C1BA58` im Emulator selbst dumpen,
inklusive Codebytes, `A6`-Methodentabelle und Ruecksprung nach `E0BDF6`. Die
FS-UAE-Instrumentierung wurde dafuer erweitert:

```text
/tmp/fs-uae-instrument-src/fs-uae-3.2.35-enemy-exception-log/src/newcpu.cpp
```

Neue Tracepunkte: `00C1BA58`, `00C1BA5C`, `00C1BA60`, `00F9FE54`,
`00F9FE58`, `00F9FE80`, `00F9FE82`, `00F9FEA4`, `00F9FEBA`.

## 2026-06-29: Neuer Capture beweist `C1BA58` als direkten Jump nach `F9FE54`

Capture:

```text
work/kickstart-deps/runtime/enemy1_aros_a500_20260629T152558+0200
```

Der Lauf erreichte wegen der sehr breiten neuen Tracepunkte keinen
Debugger-Prompt im 75-Sekunden-Fenster, hat aber den relevanten `0x625b8`-Pfad
vollstaendig vor dem bekannten spaeteren Crashpunkt protokolliert.

Konkret fuer den bisherigen Kandidaten:

```text
ENEMY_GFXCALL 1314 jsr_d16_a6
A0-A7=000625B8,00000462,000625B8,00061D7C,00C25378,00C35324,00C1BBE4,00C3524C

ENEMY_TRACE 53210 ram_method_target_c1ba58 PC=00C1BA58
D0-D3=00000000,00000080,00000010,00E1BE84
A0-A7=000625B8,00000462,000625B8,00061D7C,00C25378,00C35324,00C1BBE4,00C35248
CODE_PC 00C1BA58: 4EF9 00F9 FE54 4EF9 C0ED 4101 4EF9 C0ED
METHOD_A6 00C1BBE4 ... M18C=4EF900F9 ...

ENEMY_TRACE 53211 rom_fill_entry_f9fe54 PC=00F9FE54
A0-A7=000625B8,00000462,000625B8,00061D7C,00C25378,00C35324,00C1BBE4,00C35248

ENEMY_TRACE 53212 rom_fill_save_len_a2
A0-A7=000625B8,00000462,000625B8,00061D7C,00C25378,00C35324,00C1BBE4,00C3523C

ENEMY_TRACE 53213 rom_fill_compute_end
A0-A7=000625B8,00000462,00000080,00061D7C,00C25378,00C35324,00C1BBE4,00C3523C

ENEMY_TRACE 53214 rom_fill_copy_dest_to_a1
A0-A7=000625B8,00000462,00000080,00061D7C,00C25378,00C35324,00C1BBE4,00C3523C

ENEMY_TRACE 53215 rom_fill_loop_check
A0-A7=000625B8,000625B8,00000080,00061D7C,00C25378,00C35324,00C1BBE4,00C3523C

ENEMY_TRACE 53216 rom_fill_loop_f9fea4
A0-A7=000625B8,000625B8,00000080,00061D7C,00C25378,00C35324,00C1BBE4,00C3523C
```

Die nachfolgenden Watchpoints zeigen die erwartete fortlaufende Nullfuellung:

```text
ENEMY_WATCH 274..321 put_word_625ea
A0-A7=000625B8,000625B8/000625C8/.../00062618,00000080/.../00000030,...
```

Schluss mit Evidenzlevel `runtime`: `00C1BA58` ist kein eigenstaendiger
AROS-C-Codepfad, sondern ein RAM-Trampolin:

```asm
00c1ba58: jmp $00f9fe54.l
```

`F9FE54` wird mit `A0=0x625b8`, `D0=0`, `D1=0x80` betreten. Danach wird
`D1` nach `A2` kopiert und `A1=A0` gesetzt; die Schleife bei `F9FEA4` fuellt
den Bereich `0x625b8..0x62637` mit Nullen. Das ist jetzt nicht mehr nur aus
den Watch-Writes erschlossen, sondern durch Eintritts- und Trampolin-Trace
belegt.

Interpretation: Die fruehe Behandlung von `0x625b8` als Ziel einer
Nullfuellung ist konsistent mit Initialisierung eines frisch allokierten
Raster-/Arbeitsblocks. Die eigentliche Fehlstelle liegt danach: derselbe
Bereich wird spaeter noch als Objekt/Raster-Pointer verwendet und zugleich vom
Exec-Memory-Pfad als freier Block/Chunk-Metadatenbereich ueberschrieben.

Naechster gezielter Schritt: Die Instrumentierung wieder enger schalten
(`C1BA58/F9FE54` nur bei `A0==0x625b8` oder Zielbereich-Overlap) und dann den
spaeteren Uebergang von "initialisierter Rasterblock" zu "FreeMem/Chunk
schreibt in 0x625b8" erfassen. Der relevante Bereich beginnt nach dem
`E0BE6C -> E06658`-Call und vor `F8C9EA`.

## 2026-06-29: Enger Capture zeigt `0x625b8` wird via FreeMem/MemChunk freigegeben

Capture:

```text
work/kickstart-deps/runtime/enemy1_aros_a500_20260629T153853+0200
```

Die Instrumentierung wurde auf den Bereich nach `E0BE6C -> E06658` und auf
Register-/Stack-Bezug zu `0x625b8` verengt. Der Lauf erreichte erneut keinen
Debugger-Prompt, enthaelt aber den gesuchten Uebergang.

Phasenmarke:

```text
ENEMY_PHASE after_template_625b8 PC=00E0BE6C ... KEYMEM625B8=00000000,00000000,02800100,00000000
```

Der erste entscheidende FreeMem/MemChunk-Pfad:

```text
ENEMY_ALLOC 2218 free_wrapper_before_memchunk_call_f8d2a8
D0-D3=00000420,00C00882,000625B8,00000256
STACKL ... 00000400 00000420 000625B8 00000256 ...
CALLER_CTX ... arg0=000625B8 arg1=00000256 ...

ENEMY_ALLOC 2220 memchunk_helper_entry_f8c83a_post_movem
HELPER_ARGS ret=00F8D2AE a4=00000400 d3=00000420 d4=000625B8 d5=00000256 a6=00C00560 calc_candidate=00000258 calc_end=00000678

ENEMY_ALLOC 2221 memchunk_select_write_next_f8c9ea
PC=00F8C9EA ... D4-D7=000625B8,00000256,00000410,00062CB0
A0-A7=00000400,00062CB0,000625B8,00055080,00000400,00062810,00C00560,00C35330
MEM_A2 000625B8: 00000000 00000000 02800100 00000000

ENEMY_WATCH 233 put_word_625ea AREA=obj_base_625b8 PC=00F8C9EA ADDR=000625B8 SIZE=2 VAL=00000006
ENEMY_WATCH 234 put_word_625ea AREA=obj_base_625b8 PC=00F8C9EA ADDR=000625BA SIZE=2 VAL=00062CB0

ENEMY_ALLOC 2222 memchunk_select_write_size_f8c9ee
MEM_A2 000625B8: 00062CB0 00000000 02800100 00000000

ENEMY_WATCH 236 put_word_625ea AREA=obj_base_625b8 PC=00F8C9EE ADDR=000625BE SIZE=2 VAL=00000258
```

Damit ist der Uebergang belegt: `0x625b8` wird mit `size=0x256` an den
Exec-Free-Pfad gegeben. Der MemChunk-Helper rundet auf `0x258` und schreibt
bei `F8C9EA/F8C9EE` den Free-Chunk-Header direkt in den Raster-/Objektblock:

```text
0x625b8 = next free chunk = 0x00062cb0
0x625bc = chunk size      = 0x00000258
```

Ein spaeterer zweiter Treffer (`ENEMY_ALLOC 2238/2239`) schreibt denselben
Bereich erneut als Free-Chunk, diesmal mit `arg1=0x80`. Der erste Treffer
`2218..2222` ist aber der eigentliche Umschlag von initialisiertem
Raster-/Objektblock zu freiem Exec-Memory-Chunk.

Schluss mit Evidenzlevel `runtime`: Der Crash entsteht nicht dadurch, dass
die `C1BA58 -> F9FE54`-Nullfuellung falsch waere. Der Block `0x625b8` wird
spaeter explizit an den FreeMem/MemChunk-Pfad uebergeben und dadurch mit
Exec-Free-List-Metadaten ueberschrieben, obwohl Enemy/AROS-Grafikcode ihn
danach weiter als Bitmap/Raster-/Objektspeicher benutzt.

## 2026-06-29: FreeMem-Aufrufer fuer `0x625b8,size=0x256` ist `E20882..E2088E`

Capture:

```text
work/kickstart-deps/runtime/enemy1_aros_a500_20260629T162144+0200
```

Die FS-UAE-Instrumentierung wurde um `ENEMY_FREECALL` erweitert und auf den
Exec-FreeMem-/MemChunk-Pfad sowie die AROS-Wrapper `E08730..E08760` gelegt.
Der Build des instrumentierten FS-UAE-Baums war erfolgreich. Der Lauf crasht
weiterhin an der bekannten Stelle:

```text
ENEMY_EXCEPTION3 ce000-preframe PC=00F87452 INSTR_PC=00F8744E FAULT=24892489
Exception 3 (2489 f87452) at f87452 -> fe774c!
```

Der erste schreibende MemChunk-Pfad ist jetzt mit Aufruferkontext belegt:

```text
ENEMY_FREECALL 0170 f888d8_exec_freemem_public_entry
A0-A7=000625B8,000625B8,00000256,00C353BC,00C3682C,00C37344,00C00560,00C353B0
STACKL 00C353B0: 00C40364 00070ACA 00C00560 00F839AD 00E20892 ...

ENEMY_FREECALL 0172 f8d2a8_free_wrapper_before_memchunk
D0-D3=00000420,00C00882,000625B8,00000256
STACKL ... 00000400 00000420 000625B8 00000256 ...

ENEMY_FREECALL 0175 f8c9ea_write_free_next
D4-D7=000625B8,00000256,00000410,00062CB0

ENEMY_WATCH 233 ... PC=00F8C9EA ADDR=000625B8 ... VAL=00000006
ENEMY_WATCH 234 ... PC=00F8C9EA ADDR=000625BA ... VAL=00062CB0
ENEMY_WATCH 236 ... PC=00F8C9EE ADDR=000625BE ... VAL=00000258
```

Die dazu erzeugten Map-Reports:

```text
work/kickstart-deps/runtime/enemy1_aros_a500_20260629T162144+0200/f839ad_freemem_return_site_map_report.md
work/kickstart-deps/runtime/enemy1_aros_a500_20260629T162144+0200/e20892_first_bad_free_caller_map_report.md
work/kickstart-deps/runtime/enemy1_aros_a500_20260629T162144+0200/e08760_late_wrapper_return_map_report.md
```

`F839AD` ist kein Code-PC in diesem Kontext, sondern liegt im Haupt-ROM in
einem String-/Symbolbereich nahe `FreeMem`. Die wirksame Return-Adresse des
ersten falschen Frees ist `E20892`. Die statische Disassemblierung um `E20892`
zeigt den direkten Aufruf:

```asm
00e2087e: movea.l $14(a3), a1
00e20882: move.l  #$256, d0
00e20888: movea.l $4.l, a6
00e2088e: jsr     -$d2(a6)
00e20892: move.l  a4, -(a7)
```

Damit ist der erste fehlerausloesende FreeMem-Aufruf auf
`E20882..E2088E` eingegrenzt: `A1` kommt aus `$14(a3)`, `D0` wird dort
konstant auf `0x256` gesetzt, und `jsr -$d2(a6)` ist der Exec-`FreeMem`-LVO.
Runtime war `A1=0x625b8`, also:

```text
FreeMem(0x000625b8, 0x00000256)
```

Der spaetere Treffer ueber `E08730..E08760` ist getrennt zu bewerten. Dieser
Wrapper berechnet eine Rastergroesse und ruft ebenfalls Exec-`FreeMem`; im
Capture tritt er spaeter mit `0x625b8,size=0x80` auf:

```asm
00e08730: movem.l d2-d3/a6, -(a7)
...
00e08756: movea.l d2, a1
00e08758: movea.l $1a4(a6), a6
00e0875c: jsr     -$d2(a6)
00e08760: movem.l (a7)+, d2-d3/a6
```

Diese zweite Freigabe erklaert nicht den ersten Umschlag des initialisierten
Blocks zum Exec-Free-Chunk; sie ist ein Folgepfad oder ein spaeterer
Doppelfree-artiger Effekt.

Naechster enger Schritt: nicht mehr `F8C9EA/F8C9EE` breit verfolgen, sondern
`E20870..E20892` instrumentieren. Entscheidend sind vor `E2088E`: `A3`,
`$14(a3)`, `A1`, `D0`, `D4`, `A4`, `A5`, Stack und die Speicherfelder
`$24e/$252/$24a` relativ zu `$14(a3)`. Damit laesst sich klaeren, warum
dieser AROS-Ext-ROM-Pfad den noch benutzten Block `0x625b8` freigibt.

## 2026-06-29: `E208`-Hook bestaetigt direkten falschen FreeMem-Aufruf

Capture:

```text
work/kickstart-deps/runtime/enemy1_aros_a500_20260629T162823+0200
```

Der Capture erreichte diesmal den Debugger-Prompt und enthaelt Register-Dumps:

```text
debugger_prompt_found=yes
debugger_register_dump_found=yes
```

Der neue Hook auf `E20870..E20892` belegt den fehlerhaften Aufruf ohne
Zwischenannahme:

```text
ENEMY_FREECALL 0170 e2087e_load_saved_block_to_a1
E208CTX a3=00070ACA a3_14_block=000625B8 ... d0=00000001 a1=00000000

ENEMY_FREECALL 0171 e20882_set_bad_freemem_size_256
E208CTX a3=00070ACA a3_14_block=000625B8 ... d0=00000001 a1=000625B8

ENEMY_FREECALL 0172 e20888_load_execbase
E208CTX a3=00070ACA a3_14_block=000625B8 ... d0=00000256 a1=000625B8

ENEMY_FREECALL 0173 e2088e_call_exec_freemem_bad_625b8
E208CTX a3=00070ACA a3_14_block=000625B8 ... d0=00000256 a1=000625B8
E208MEM block=000625B8: 00000000 00000000 02800100 00000000 00000000 00000000 0000C0DE BAD00005

ENEMY_FREECALL 0183 e20892_after_bad_freemem
E208MEM block=000625B8: 00062CB0 00000258 02800100 00000000 00000000 00000000 0000C0DE BAD00005
KEYMEM 625B8=00062CB0,00000258,02800100,00000000,...
```

Damit ist die minimale Ursache auf Runtime-Ebene:

```text
vor  E2088E: A1=0x000625b8, D0=0x00000256
nach E20892: 0x625b8 = { next=0x00062cb0, size=0x00000258, ... }
```

Zusaetzliche Map-Reports fuer den umgebenden Handler:

```text
work/kickstart-deps/runtime/enemy1_aros_a500_20260629T162823+0200/e2063c_e208_owner_function_map_report.md
work/kickstart-deps/runtime/enemy1_aros_a500_20260629T162823+0200/e20786_bad_free_function_body_map_report.md
work/kickstart-deps/runtime/enemy1_aros_a500_20260629T162823+0200/e205b2_pre_bad_free_helper_map_report.md
```

Statisch liegt der Pfad in einem groesseren AROS-Ext-ROM-Handler ab
`E2063C`. Der Handler bekommt seine zwei sichtbaren Argumente ueber den Stack:

```asm
00e2063c: lea.l   -$c(a7), a7
00e20640: movem.l d2-d5/a2-a6, -(a7)
00e20644: movea.l $34(a7), a3
00e20648: movea.l $38(a7), a4
...
00e207ea: movea.l $14(a3), a0
00e207ee: movea.l $24(a0), a2
00e207f2: cmpa.w  #$0, a2
00e207f6: bne.w   $e208c4
00e207fa: move.l  a4, -(a7)
00e207fc: move.l  $14(a3), -(a7)
00e20800: jsr     $e205b2.l
...
00e20862: movea.l $14(a3), a0
00e20866: movea.l $252(a0), a1
00e2086a: cmpa.w  #$0, a1
00e2086e: beq.b   $e2087e
00e20870: move.l  $24e(a0), d0
00e20874: movea.l $4.l, a6
00e2087a: jsr     -$d2(a6)
00e2087e: movea.l $14(a3), a1
00e20882: move.l  #$256, d0
00e20888: movea.l $4.l, a6
00e2088e: jsr     -$d2(a6)
```

Im beobachteten Lauf sind `$24a/$24e/$252` relativ zum Block `0x625b8` alle
`0`, dadurch wird der optionale erste Free bei `E20870` uebersprungen, aber
der zweite Free bei `E2088E` trotzdem ausgefuehrt.

Naechster sinnvoller Schritt: den Eintritt in `E2063C` instrumentieren und den
Aufrufer bestimmen, der `A3=0x70aca` und `A4=0xc3682c` liefert. Dabei sollten
`$14(a3)`, `$24(a0)`, `$24a/$24e/$252(a0)`, `$c8(a4)` und die Branch-Entscheidung
`E207F2 -> E207FA -> E20862` geloggt werden. Ziel ist nicht mehr "wer schreibt
den Free-Chunk", sondern "warum betrachtet der AROS-Handler diesen Block als
zerstoerbar".

## 2026-06-29: Beschleunigte Eingrenzung ohne neuen Emulator-Build

Der temporaere FS-UAE-Instrumentierungsbaum war in der neuen Shell nicht mehr
vorhanden. Statt ihn sofort neu zu bauen, wurde die Spur statisch aus den ROMs
und mit vorhandenen Captures verdichtet.

Neue Map-Reports:

```text
work/kickstart-deps/runtime/enemy1_aros_a500_20260629T162823+0200/e204d0_callback_registration_map_report.md
work/kickstart-deps/runtime/enemy1_aros_a500_20260629T162823+0200/e35bc4_callback_dispatcher_map_report.md
work/kickstart-deps/runtime/enemy1_aros_a500_20260629T162823+0200/e33d70_pre_handler_helper_map_report.md
work/kickstart-deps/runtime/enemy1_aros_a500_20260629T162823+0200/e35444_post_bad_free_helper_map_report.md
```

Der entscheidende statische Befund: `E2063C` wird bei `E204D0..E204E0` als
Callback an `E35BC4` uebergeben.

```asm
00e20448: link.w  a5, #$ffe8
...
00e204d0: move.l  a2, -$4(a5)
00e204d4: move.l  a3, -(a7)
00e204d6: pea.l   -$18(a5)
00e204da: pea.l   $e2063c.l
00e204e0: jsr     $e35bc4.l
```

`E35BC4` ist ein Dispatcher/Defer-Helper. Er laedt seine drei Argumente
nach dem Prolog als Callback, Parameterblock und Library-/Context-Pointer:

```asm
00e35bc4: lea.l   -$48(a7), a7
00e35bc8: movem.l d2-d3/a2-a6, -(a7)
00e35bcc: movea.l $68(a7), a5    ; Callback
00e35bd0: movea.l $6c(a7), a3    ; Parameter/closure
00e35bd4: movea.l $70(a7), a4    ; Context/library base
...
00e35bee: cmp.l   $120(a2), d0
00e35bf2: bne.b   $e35c06
00e35bf4: move.l  a4, -(a7)
00e35bf6: move.l  a3, -(a7)
00e35bf8: jsr     (a5)
```

Wenn der aktuelle Task dem erwarteten Task entspricht, ruft `E35BC4` den
Callback sofort mit zwei Stack-Argumenten auf. Das passt zu `E2063C`:

```asm
00e2063c: lea.l   -$c(a7), a7
00e20640: movem.l d2-d5/a2-a6, -(a7)
00e20644: movea.l $34(a7), a3
00e20648: movea.l $38(a7), a4
```

Damit ist der Call-Stack nicht mehr offen:

```text
E20448 handler
  -> E204DA/E204E0 registriert/ruft Callback E2063C ueber E35BC4
  -> E35BC4 ruft bei passendem Task sofort jsr (a5)
  -> E2063C bekommt A3=0x70aca, A4=0xc3682c
  -> E2088E ruft FreeMem($14(A3)=0x625b8, 0x256)
```

Vorhandene Captures bestaetigen diese Struktur runtime-seitig bereits, ohne
neue Instrumentierung:

```text
ENEMY_TRACE ... entry_obtainsemaphore
A0-A7=00C36A16,00C7AEA0,00C7AE78,00070ACA,00C3682C,00E2063C,00C00560,00070A22
```

und im neuesten Capture:

```text
ENEMY_ALLOC 2137 allocmem_entry_f8cf8c_pre_movem
STACKL2 ... 00070ACA 00C3682C 00E2063C 00C00560 ...
```

Interpretation mit Evidenzlevel `static+runtime`: Das Problem sitzt nicht mehr
im Exec-MemChunk-Pfad, sondern in einem AROS-Ext-ROM-Cleanup-/Dispose-Handler
ab `E20448`, der `E2063C` ueber `E35BC4` laufen laesst. `E2063C` behandelt
`$14(a3)` als zu zerstoerendes Objekt und gibt es am Ende immer mit Groesse
`0x256` frei, wenn der Pfad `E207F2 -> E207FA -> E20862 -> E2088E` genommen
wird.

Beschleunigter naechster Schritt: nicht den Emulator breit neu instrumentieren,
sondern gezielt symbolisch/statisch den `E20448`-Handler identifizieren. Der
lokale Workspace enthaelt keinen AROS-Sourcebaum, nur:

```text
roms/aros/aros-rom.bin
roms/aros/aros-ext.bin
```

Praktisch sind jetzt zwei schnelle Optionen sinnvoll:

1. AROS-Source fuer die ROM-Version beschaffen und die Bytefolge um
   `E20448/E2063C/E35BC4` gegen `graphics/layers/intuition`-Quellen matchen.
2. Ohne Source einen kleinen ROM-Signatur-Scanner bauen, der alle direkten
   `pea $e2063c; jsr $e35bc4`- und `jsr $e20448`-Xrefs aus `aros-ext.bin`
   extrahiert. Das ist schneller als ein neuer FS-UAE-Build und grenzt den
   externen API-Einstieg des Cleanup-Handlers ein.

### ROM-Xref-Scanner

Um die Eingrenzung zu beschleunigen, wurde ein einfacher direkter 68k-Xref-
Scanner angelegt:

```text
scripts/scan_aros_rom_xrefs.py
```

Er sucht in ROM-Bytes nach einfachen direkten Referenzen (`jsr abs.l`,
`jmp abs.l`, `pea abs.l`, `lea abs.l`, `bsr`) auf die relevanten PCs.

Reports:

```text
work/kickstart-deps/runtime/enemy1_aros_a500_20260629T162823+0200/aros_ext_xrefs_e20448_e2063c.md
work/kickstart-deps/runtime/enemy1_aros_a500_20260629T162823+0200/aros_rom_xrefs_e20448_e2063c.md
```

Ergebnis:

```text
aros-ext.bin: 29 direkte Treffer
aros-rom.bin: 0 direkte Treffer
```

Der wichtigste Treffer ist eindeutig:

```text
0x00e204da  pea_abs_l  0x00e2063c  bad_free_callback_e2063c
0x00e204e0  jsr_abs_l  0x00e35bc4  callback_dispatcher_e35bc4
```

Damit ist `E2063C` im direkten Xref-Sinn nicht mehrfach verteilt: die
beobachtete falsche Freigabe kommt aus der einen Callback-Registrierung bei
`E204DA`, nicht aus einer Gruppe verschiedener Callsites. Weitere Treffer auf
`E35BC4` zeigen nur, dass derselbe Dispatcher an anderen Stellen ebenfalls
verwendet wird.

Beschleunigter Arbeitsstand:

```text
E20448-Funktion
  E204DA pea E2063C
  E204E0 jsr E35BC4
    E35BC4 jsr (a5), falls aktueller Task passt
      E2063C
        E2088E FreeMem($14(A3), 0x256)
```

Der naechste echte Informationsgewinn kommt daher nicht mehr von breiter
Runtime-Suche, sondern von Identifikation der Funktion `E20448` gegen AROS-
Source oder von einem minimalen Live-Hook nur an `E20448/E204DA/E35BC4`.

### Source-Match: `E20448` ist AROS `CloseWindow`

Die beschleunigte Source-Korrelation wurde gegen den aktuellen AROS-Tree unter
`rom/intuition` gemacht. Das ist weiterhin kein bytegenauer Build-Nachweis fuer
das konkrete ROM, aber die Struktur passt jetzt bis auf Callfolge und
Freigabegroesse.

Relevante AROS-Dateien:

```text
rom/intuition/closewindow.c
rom/intuition/inputhandler_actions.c
rom/intuition/intuition_intern.h
rom/intuition/openwindow.c
```

Der ROM-Code bei `E20448` passt zur Library-Funktion `CloseWindow(window)`.
Die zentrale Callfolge aus der Source ist:

```c
msg.window = window;
DoSyncAction((APTR)int_closewindow, &msg.msg, IntuitionBase);
```

Das entspricht dem ROM-Ausschnitt:

```asm
00e204d0: move.l  a2,-$4(a5)       ; msg.window = window
00e204d4: move.l  a3,-(a7)         ; IntuitionBase
00e204d6: pea.l   -$18(a5)         ; &msg.msg
00e204da: pea.l   $e2063c.l        ; int_closewindow
00e204e0: jsr     $e35bc4.l        ; DoSyncAction
```

Der Dispatcher `E35BC4` passt zu `DoSyncAction()` aus
`inputhandler_actions.c`: wenn der aktuelle Task bereits der
`InputDeviceTask` ist, ruft AROS den Handler direkt; sonst wird eine
Action-Message eingereiht. Im beobachteten Lauf wird `E2063C` direkt/effektiv
als Handler ausgefuehrt.

Der ROM-Code bei `E2063C` passt zu `int_closewindow()`. Am Ende der Source
steht:

```c
FreeMem (msg->window, sizeof(struct IntWindow));
```

Das entspricht dem beobachteten ROM-Free:

```asm
00e20886: movea.l $14(a3),a1
00e2088a: move.w  #$256,d0
00e2088e: jsr     -$d2(a6)         ; Exec FreeMem
```

Damit ist die vorherige unscharfe Bitmap-/Raster-Interpretation fuer diesen
konkreten `0x256`-Free ueberholt: `0x625b8` wird hier nicht als freier
Rasterblock ausgewaehlt, sondern von AROS als `struct Window *` aus
`msg->window` behandelt und als `struct IntWindow` freigegeben.

Runtime-Zuordnung:

```text
E2063C entry:
  A3 = 0x00070aca          ; CloseWindowActionMsg-Umfeld
  A4 = 0x00c3682c          ; IntuitionBase
  $14(A3) = 0x000625b8     ; msg->window

E2088E:
  FreeMem(0x000625b8, 0x00000256)
```

`sizeof(struct IntWindow)` ist in diesem ROM offensichtlich `0x256`, weil genau
diese Konstante im finalen Free verwendet wird. Die aktuelle Source definiert
`struct IntWindow` als `struct Window` plus AROS-interne Felder in
`intuition_intern.h`.

Beschleunigte Schlussfolgerung:

```text
CloseWindow(0x625b8)
  -> DoSyncAction(int_closewindow, &msg)
    -> int_closewindow(msg)
      -> FreeMem(msg->window=0x625b8, sizeof(struct IntWindow)=0x256)
```

Der Fehler ist damit enger: Zu klaeren ist nicht mehr, welcher Allocator den
Block auswaehlt, sondern warum AROS/Enemy ueberhaupt `CloseWindow()` auf
`0x625b8` ausfuehrt, obwohl derselbe Speicherbereich zuvor als Raster-/Bitmap-
naher Puffer benutzt wurde.

### Caller-Match: `closewb` liest `IntuitionBase.ActiveWindow`

Naechster Runtime-Capture:

```text
work/kickstart-deps/runtime/enemy1_aros_a500_20260630T000349+0200/
work/kickstart-deps/runtime/enemy1_aros_a500_20260630T001040+0200/
```

Der Ruecksprung aus `CloseWindow()` zeigt auf `0006C444`. Der unmittelbare
Caller ist damit der RAM-Code um `0006C41A`:

```asm
0006C41A 4e55 0000                LINK.W A5,#$0000
0006C41E 42a7                     CLR.L -(A7)
0006C420 486c 8002                PEA.L (A4, -$7ffe)   ; "intuition.library"
0006C424 4eba 06e2                JSR 0006CB08          ; OpenLibrary-Wrapper
0006C428 2940 801e                MOVE.L D0,(A4,-$7fe2) ; IntuitionBase global
0006C42C 206c 801e                MOVEA.L (A4,-$7fe2),A0
0006C430 4aa8 0034                TST.L (A0,$0034)
0006C436 670e                     BEQ 0006C446
0006C438 206c 801e                MOVEA.L (A4,-$7fe2),A0
0006C43C 2f28 0034                MOVE.L (A0,$0034),-(A7)
0006C440 4eba 0718                JSR 0006CB5A          ; CloseWindow-Wrapper
0006C444 584f                     ADDA.W #$0004,A7
0006C446 4eba 071e                JSR 0006CB66
0006C44A 4eba 0722                JSR 0006CB6E
0006C44E 2f2c 801e                MOVE.L (A4,-$7fe2),-(A7)
0006C452 4eba 0666                JSR 0006CABA          ; CloseLibrary-Wrapper
```

Der Wrapper bei `0006CB5A` ist die normale Library-Vektor-Form:

```asm
0006CB5A 206f 0004                MOVEA.L (A7,$0004),A0 ; window argument
0006CB5E 2c6c 801e                MOVEA.L (A4,-$7fe2),A6 ; IntuitionBase
0006CB62 4eee ffb8                JSR (A6,-$48)          ; CloseWindow()
```

Im selben RAM-Block steht der String `closewb`:

```text
0006CB80 632F 636C 6F73 6577 6200 6600 000A 294A  c/closewb.f...)J
```

Damit ist der Caller semantisch sehr wahrscheinlich ein alter
Workbench-Fenster-Schliesser. Er oeffnet `intuition.library`, liest
`IntuitionBase+$34` und ruft `CloseWindow()` auf diesem Zeiger auf.

Der Live-Dump belegt den konkreten Wert:

```text
CloseWindow breakpoint:
  A0 = 000625B8
  A6 = 00C3682C          ; IntuitionBase
  A7 = 00070AE6
  (A7) = 0006C444        ; Return nach dem CloseWindow-Wrapper

00C3682C + 0x34 = 00C36860
00C36860 0006 25B8 00C3 7264 00C3 7264 0000 0000
```

Der aktuelle AROS-Header `compiler/include/intuition/intuitionbase.h` definiert
`struct IntuitionBase` mit `ActiveWindow` direkt nach `LibNode` und `ViewLord`:

```c
struct IntuitionBase
{
    struct Library LibNode;
    struct View ViewLord;

    struct Window * ActiveWindow;
    struct Screen * ActiveScreen;
    struct Screen * FirstScreen;
    ...
};
```

Der Header-Kommentar sagt explizit, dass vor dem Lesen `LockIBase()` noetig ist.
Der Enemy-/Startup-Code macht hier aber keinen Lock, sondern liest das Feld
direkt und schliesst das aktive Fenster. Das ist fuer alte Kickstart-Umgebungen
ein bekannter `closewb`-Stil, unter AROS aber ein plausibler
Kompatibilitaetsbruch: `ActiveWindow` ist in diesem Moment `0x625b8`, und der
Code ruft daraus sofort `CloseWindow(0x625b8)`.

Aktueller Befund mit Evidenzlevel `runtime+source`:

```text
0006C420 open "intuition.library"
0006C428 save IntuitionBase
0006C430 test IntuitionBase->ActiveWindow
0006C43C push IntuitionBase->ActiveWindow == 0x625b8
0006C440 CloseWindow(0x625b8)
00E20448 AROS CloseWindow()
00E2088E AROS FreeMem(0x625b8, sizeof(IntWindow)=0x256)
```

Damit ist der naechste sinnvolle Test nicht mehr, den Allocator weiter zu
verfolgen. Besser ist ein gezielter Patch/Experiment am `closewb`-Pfad:

1. `0006C436 BEQ` zwangsweise nehmen oder den `JSR 0006CB5A` bei `0006C440`
   ueberspringen.
2. Danach AROS-Lauf erneut starten.
3. Wenn dann Diskettenzugriffe oder ein spaeterer stabiler Fortschritt kommen,
   ist `closewb`/`ActiveWindow` der primäre AROS-Kickstart-Dependency.
4. Falls der Lauf dann spaeter anders crasht, bleibt `closewb` trotzdem als
   erster Kompatibilitaetsbruch belegt und der naechste Crash kann separat
   instrumentiert werden.

### Live-Experiment: `CloseWindow(0x625b8)` uebersprungen

Capture:

```text
work/kickstart-deps/runtime/enemy1_aros_a500_20260630T002530+0200/
```

Der erste Versuch, direkt bei `0006C440` zu patchen, erreichte den Breakpoint im
kurzen Zeitfenster nicht. Der robuste Test stoppte stattdessen bei AROS
`CloseWindow()` und simulierte den Ruecksprung:

```text
f e20448
g
r
m 00c36860 4
r a7 00070aea
r pc 0006c444
di R
g
r
```

Beleg am Breakpoint:

```text
Breakpoint at 00E20448
  A0 000625B8 ... A6 00C3682C A7 00070AE6
USP 00070AE6 ISP 00C80000

00C36860 0006 25B8 00C3 7264 00C3 7264 0000 0000
```

`A7=0x70ae6` zeigt auf die Return-Adresse `0006C444`; nach einem normalen
`RTS` waere `A7=0x70aea`. Deshalb setzt das Experiment `A7=0x70aea` und
`PC=0x0006c444`. Damit wird nur der `CloseWindow()`-Call umgangen; der Caller
laeuft danach durch seine normale Stack-Bereinigung weiter.

Ergebnis: Nach dem Skip erreicht der Lauf echte Disk-Zugriffe, die in den
vorherigen AROS-Captures vor diesem Punkt nicht sichtbar waren:

```text
amigados read track 61
amigados read track 63
...
amigados read track 127
LEN=1A9F (6815) SYNC=4489 PT=00000468 ADKCON=1500 INTREQ=1041 PC=00FB3C04
disk read DMA started, drvmask=1 track 127 mfmpos 50739 dmaen=0 PC=00FB3C04
```

Das bestaetigt den `closewb`-Befund praktisch: Der erste relevante AROS-Bruch
liegt vor den erwarteten Diskgeraeuschen im Startcode, der
`IntuitionBase->ActiveWindow == 0x625b8` nimmt und daraus
`CloseWindow(0x625b8)` macht. Wird dieser eine Call uebersprungen, kommt Enemy
unter AROS weiter bis in Disk-I/O.

Naechster enger Schritt:

1. Einen reproduzierbaren RAM-/ADF-Testpatch bauen, der den `closewb`-Call
   ueberspringt, ohne manuelles Debugger-Registersetzen.
2. Danach den naechsten Halt nach dem Disk-DMA erfassen: `PC=00FB3C04`,
   Register, Stack, Track/DMA-Kontext.
3. Erst falls danach ein neuer Crash kommt, diesen als zweite
   Kickstart-Abhaengigkeit behandeln. Der `CloseWindow`-Pfad ist jetzt
   unabhaengig davon als erster AROS-Inkompatibilitaetspunkt belegt.

### Reproduzierbarer ADF-Testpatch fuer `closewb`

Artefakte:

```text
scripts/build_closewb_skip_adf.py
configs/fs-uae/enemy1_arosclosewbskip_a500.fs-uae
work/kickstart-deps/patches/closewb-skip/ENEMY1_V2_DE_A.closewb-skip.adf
work/kickstart-deps/patches/closewb-skip/manifest.txt
```

Der Patch-Generator prueft den Original-ADF-Hash und die eindeutige Signatur
von `c/closewb`, patcht dann nur eine Kopie des ADFs:

```text
source_sha256=f8a970e7225541c34d2322875df8294a73604afbab679d0ecb002a5ac01cc28e
signature_offset=0x053042
patch_offset=0x05305e
original_bytes=670e
patched_bytes=600e
runtime_effect=0006C436 BEQ.B 0006C446 -> BRA.B 0006C446
```

Der geaenderte Code ist damit:

```asm
0006C430 4aa8 0034                TST.L (A0,$0034)
0006C434 504f                     ADDA.W #$00000008,A7
0006C436 600e                     BRA.B 0006C446
0006C438 206c 801e                MOVEA.L (A4,-$7fe2),A0 ; uebersprungen
0006C43C 2f28 0034                MOVE.L (A0,$0034),-(A7); uebersprungen
0006C440 4eba 0718                JSR 0006CB5A            ; uebersprungen
0006C444 584f                     ADDA.W #$00000004,A7    ; uebersprungen
0006C446 4eba 071e                JSR 0006CB66
```

Wichtig: Der Patch liegt in einem OFS-Datenblock. Der Generator korrigiert
deshalb die AmigaDOS-Blockchecksumme. Der aktuelle Manifest-Auszug:

```text
checksum_block_offset=0x053000
old_checksum=0x3756ae9a
new_checksum=0x3756b59a
patched_sha256=282a33d92b3a2b6f0807023930b436f2d61af34e3cdcd9a4ea00d2294e7931e2
```

Verifikation:

```text
diff_count 2
0x53016: checksum byte ae -> b5
0x5305e: branch byte   67 -> 60

OFS block 0x53000 checksum sum == 0x0
unadf extrahiert /c/closewb aus dem gepatchten ADF ohne Fehler.
```

`unadf` bestaetigt, dass die Signatur in `/c/closewb` liegt:

### 2026-06-30: ADF-Patch-Lauf reproduziert den manuellen Skip noch nicht

Zwei ADF-Varianten wurden gebaut und gegen AROS getestet:

```text
work/kickstart-deps/patches/closewb-skip/ENEMY1_V2_DE_A.closewb-skip.adf
work/kickstart-deps/patches/closewb-nop/ENEMY1_V2_DE_A.closewb-nop.adf
```

Die erste Variante patcht den Branch nach `TST.L (A0,$0034)` von `BEQ` auf
`BRA`:

```text
patch_offset=0x05305e
original_bytes=670e
patched_bytes=600e
patched_sha256=282a33d92b3a2b6f0807023930b436f2d61af34e3cdcd9a4ea00d2294e7931e2
```

Die zweite, engere Variante laesst ActiveWindow-Load, Argument-Push und
Stack-Cleanup unveraendert und ersetzt nur den eigentlichen
`JSR CloseWindow` durch zwei NOPs:

```text
scripts/build_closewb_nop_adf.py
configs/fs-uae/enemy1_arosclosewbnop_a500.fs-uae
work/kickstart-deps/patches/closewb-nop/manifest.txt

patch_offset=0x053068
original_bytes=4eba0718
patched_bytes=4e714e71
patched_sha256=a685d1c2d3f24ba70a96ed02f7e6385e463e3acf9d285de3e39d68f24597ea75
runtime_effect=0006C440 JSR CloseWindow -> NOP; NOP
```

Beide Generatoren korrigieren die OFS-Datenblockchecksumme. Fuer die
NOP-Variante wurde zusaetzlich verifiziert:

```text
checksum_sum=0x00000000
0x053068: 4e71
0x05306a: 4e71
unadf extrahiert /c/closewb mit 4e71 4e71 an File-Offset 0x50.
```

Runtime-Captures:

```text
work/kickstart-deps/runtime/enemy1_arosclosewbskip_a500_20260630T014859+0200
work/kickstart-deps/runtime/enemy1_arosclosewbnop_a500_20260630T020542+0200
```

Beide Laeufe binden nachweislich die jeweilige gepatchte ADF in DF0 ein, zeigen
aber keine `amigados read track`/`disk read DMA`-Zeilen und enden im normalen
AROS-Startlog weiter bei:

```text
SERIAL: period=372, baud=9600, hsyncs=14, bits=8, PC=f8016a
Illegal instruction: 4e7b at 00F802B0 -> 00F80362
B-Trap F280 at 00F80294 -> 00F802A6
```

Es gibt kein `.sdf`-Overlay in `output/states`, das alte Diskdaten erklaeren
wuerde. Damit ist der Befund:

- Die ADF-Patches sind formal korrekt und werden von FS-UAE eingebunden.
- Der manuelle Debugger-Skip bei `E20448` wird dadurch noch nicht reproduziert.
- Die interaktive Debugger-Aktivierung ist in den frischen Laeufen nicht
  verlaesslich: Hotkey, `SIGINT` und PTY-`Ctrl-C` erzeugten keinen
  Debugger-Prompt.

Naechster sinnvoller Schritt: nicht weiter ADF-Patchvarianten raten, sondern
den instrumentierten FS-UAE-Build wiederherstellen und den `E20448`-Moment
programmatisch behandeln/loggen. Konkret: beim Eintritt in `E20448` Register,
Stack und Return-Adresse loggen und optional exakt denselben PC/A7-Skip wie im
manuellen Erfolgsfall im Emulator erzwingen. Das trennt drei moegliche Ursachen:

1. `c/closewb` aus DF0 wird unter AROS gar nicht bis zu dieser Stelle
   ausgefuehrt.
2. Der manuelle Skip veraenderte mehr Kontext als nur den Call.
3. Nach `closewb` folgt eine zweite AROS-Abhaengigkeit, die ohne Debugger noch
   nicht sichtbar ist.

```text
/tmp/enemy_a_orig/c/closewb  sig=0x2a branch=670e
/tmp/enemy_a_patch/c/closewb sig=0x2a branch=600e
```

Historischer Runtime-Status: Die fruehen Patch-Laeufe
`enemy1_arosclosewbskip_a500_20260630T012602+0200` und
`enemy1_arosclosewbskip_a500_20260630T013241+0200` aktivierten den Debugger
nicht (`debugger_prompt_found=no`) und waren deshalb keine gueltige
Breakpoint-Bestaetigung. Der spaetere Stand oben ersetzt diese offene
Pruefung: auch ohne Debugger-Hotkey reproduzieren die Branch- und NOP-ADF-
Patchvarianten den manuellen Erfolgsfall noch nicht.

### 2026-06-30: Emulator-Skip bei `E20448` erreicht Disk-DMA-Code

Der instrumentierte FS-UAE-Build wurde wiederhergestellt unter:

```text
/tmp/fs-uae-3.2.35-enemy-e20448-skip/fs-uae
```

Die Instrumentierung in `src/newcpu.cpp` loggt beim Eintritt in AROS
`CloseWindow()` (`0x00e20448`) Register und Stack. Optional emuliert sie mit
`ENEMY_E20448_SKIP=1` den manuellen Ruecksprung:

```text
A7 = 0x00070aea
PC = 0x0006c444
```

Kontrolllauf ohne Skip:

```text
work/kickstart-deps/runtime/enemy1_aros_a500_20260630T094733+0200
```

Er belegt erneut den kaputten Aufruf:

```text
ENEMY_E20448 0001 hit PC=00E20448 SR=0010 USP=000709AC ISP=00C80000 A7=00070AE6
ENEMY_E20448 0001 A0-A7=000625B8,00C7AE78,000630F8,0006C414,00C82CFE,00070AEE,00C3682C,00070AE6
ENEMY_E20448 0001 STACK 00070AE6: 0006C444 000625B8 00070B00 0006C5FE
Exception 3 (2489 f87452) at f87452 -> fe774c!
```

Der programmatische Skip fuehrt danach sauber durch den Caller:

```text
work/kickstart-deps/runtime/enemy1_aros_a500_20260630T095236+0200

ENEMY_E20448 0001 forced_skip A7=00070AEA PC=0006C444 IR=584F IRC=4EBA
ENEMY_POSTSKIP 0032 PC=0006C444 IR=584F IRC=4EBA SR=0010 A7=00070AEA
ENEMY_POSTSKIP 0031 PC=0006C446 IR=4EBA IRC=071E SR=0010 A7=00070AEE
```

Ein laengerer Post-Skip-Trace zeigt anschliessend den erwarteten Disk-nahen
Codepunkt:

```text
work/kickstart-deps/runtime/enemy1_aros_a500_20260630T095657+0200

ENEMY_POSTSKIP hotpc left=149409 elapsed=150591 PC=00FB3C04 IR=3142 IRC=0024 SR=0000 A7=00C2E614 D0=00009500 D1=00010000 D2=00009A9F A0=00DFF000 A1=00C2EB40 A6=00C00560
ENEMY_POSTSKIP hotpc left=017267 elapsed=282733 PC=00FB3C04 IR=3142 IRC=0024 SR=0000 A7=00C2E614 D0=00009500 D1=00010000 D2=00009A9F A0=00DFF000 A1=00C2EB40 A6=00C00560
```

`IR=3142` mit `IRC=0024` und `A0=00DFF000` ist ein Write auf
`$24(A0) == $DFF024`, also auf das Amiga-Custom-Register `DSKLEN`. Damit ist
der urspruengliche manuelle Befund inhaltlich reproduziert: Wird nur der
kaputte `CloseWindow(0x625b8)`-Pfad uebersprungen, erreicht Enemy unter AROS
den Disk-DMA-Code.

Wichtig: Die FS-UAE-Logs enthalten in diesen automatisierten Laeufen trotzdem
keine Textzeilen `amigados read track` oder `disk read DMA started`. Der
saubere Beleg ist daher aktuell der CPU-/Opcode-Trace am `DSKLEN`-Write, nicht
eine FS-UAE-Disk-Subsystem-Logzeile.

Aktueller Schluss:

- `CloseWindow(0x625b8)` bleibt die erste harte AROS-Inkompatibilitaet.
- Der Skip selbst ist korrekt; PC/A7 laufen danach erwartungsgemaess weiter.
- Die ADF-Patchvarianten muessen separat erklaert werden, weil der
  Emulator-Skip den Disk-DMA-Code erreicht, die gepatchten ADF-Laeufe aber
  bisher nicht.
- Naechster sinnvoller Schritt ist ein direkter Vergleich, ob die gepatchten
  ADFs unter AROS ueberhaupt denselben RAM-Code bei `0006C41A..0006C444`
  laden/ausfuehren wie der Original-ADF-Lauf.

### 2026-06-30: `closewb`-Matrix korrigiert die Patch-Bewertung

Der Prozess wurde auf einen engeren, reproduzierbaren Vergleich optimiert.
Statt auf FS-UAE-Disk-Textzeilen zu warten, loggt der instrumentierte
FS-UAE-Build jetzt nur noch Marker fuer:

```text
0006C41A/0006C430/0006C436/0006C440/0006C444/0006C446  closewb-Pfad
00E20448                                                  AROS CloseWindow
00FB3C04                                                  DSKLEN-Write
```

Neue Hilfsskripte:

```text
scripts/summarize_closewb_trace.py
scripts/run_closewb_trace_matrix.sh
```

Die aktuell relevante Matrix:

```bash
python3 scripts/summarize_closewb_trace.py \
  work/kickstart-deps/runtime/enemy1_aros_a500_20260630T104817+0200 \
  work/kickstart-deps/runtime/enemy1_arosclosewbskip_a500_20260630T103135+0200 \
  work/kickstart-deps/runtime/enemy1_arosclosewbnop_a500_20260630T103858+0200
```

Ergebnis:

```text
original: original_reaches_closewindow_then_exception
  code=... 670E ... 4EBA 0718 ...
  closewb_path=0006C41A:1 0006C430:1 0006C436:1 0006C440:1 0006C444:1 0006C446:1
  dsklen_hits=30
  e20448_hits=1
  exception3=1

branch patch: branch_patch_skips_closewindow_and_reaches_dsklen
  code=... 600E ... 4EBA 0718 ...
  closewb_path=0006C41A:1 0006C430:1 0006C436:1 0006C440:0 0006C444:0 0006C446:1
  dsklen_hits=27
  e20448_hits=0
  exception3=0

nop patch: nop_patch_skips_closewindow_and_reaches_dsklen
  code=... 670E ... 4E71 4E71 ...
  closewb_path=0006C41A:1 0006C430:1 0006C436:1 0006C440:1 0006C444:1 0006C446:1
  dsklen_hits=27
  e20448_hits=0
  exception3=0
```

Damit ist die vorherige Bewertung der ADF-Patchlaeufe korrigiert:

- Beide gepatchten ADFs laden und fuehren den erwarteten RAM-Code aus.
- Beide Varianten erreichen `PC=00FB3C04` mit `IR=3142 IRC=0024 A0=00DFF000`,
  also den `DSKLEN`-Write.
- Beide Varianten vermeiden `00E20448` und damit den `CloseWindow(0x625b8)`-
  Crash.
- Die FS-UAE-Zeilen `amigados read track`/`disk read DMA started` sind fuer
  diese automatisierten Laeufe kein verlaessliches Primaerkriterium.

Neuer Prozess fuer schnelle, belastbare Ergebnisse:

1. Erst `scripts/run_closewb_trace_matrix.sh` laufen lassen.
2. Nur die Summary-Tabelle akzeptieren, wenn `code`, `closewb_path`,
   `dsklen_hits`, `e20448_hits` und `exception3` plausibel sind.
3. Erst danach tiefer instrumentieren. Fuer die naechste Abhaengigkeit ist der
   `CloseWindow`-Pfad jetzt erledigt; relevant ist der erste neue Crash oder
   Reset nach erfolgreichem `DSKLEN`-Fortschritt in den Patchlaeufen.
