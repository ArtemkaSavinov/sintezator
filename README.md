# Синтезатор нот для Nexys A7-100T

Проект формирует ноты и аккорды вручную либо принимает MIDI-клавиатуру через
Pmod JA. До трёх одновременно удерживаемых MIDI-клавиш звучат полифонически.
Звук выводится через разъём `MONO AUDIO OUT`.

## Структура тракта

`кнопки / MIDI UART -> частоты 3 голосов -> 3 x (фазовый аккумулятор + CORDIC) -> микшер -> PDM -> AUD_PWM`

- Тактовая частота: 100 МГц.
- Фаза: 32 бита.
- Три независимых CORDIC-генератора: 16 итераций, конвейерный режим.
- Микшер складывает три голоса в 18 битах и делит результат на два, поэтому
  переполнение 16-битного аудиотракта невозможно.
- PDM: сигма-дельта первого порядка на частоте 100 МГц.
- `AUD_PWM` формируется как open-drain: логический ноль — `0`, логическая единица — `Z`.
- `AUD_SD` постоянно равен единице и включает аналоговый тракт.
- Светодиоды `LED[6:0]` показывают выбранную ступень в one-hot виде.
- `LED[7]` горит в режиме аккордов.
- `LED[8]` горит в режиме MIDI; `LED[11:9]` показывают активные MIDI-голоса.

## Ноты

| Индекс | Нота | Расчётная частота, Гц | Фактическая частота DDS, Гц |
|---:|:---:|---:|---:|
| 0 | C4 (До) | 261,626 | 261,632 |
| 1 | D4 (Ре) | 293,665 | 293,669 |
| 2 | E4 (Ми) | 329,628 | 329,618 |
| 3 | F4 (Фа) | 349,228 | 349,223 |
| 4 | G4 (Соль) | 391,995 | 391,994 |
| 5 | A4 (Ля) | 440,000 | 440,003 |
| 6 | B4 (Си) | 493,883 | 493,880 |

В исходном описании частота 439,88 Гц была отнесена к ноте Си. Это частота,
близкая к Ля четвёртой октавы; Си четвёртой октавы имеет частоту около
493,88 Гц. В RTL использован стандартный равномерно темперированный строй.

## Управление

- После сброса выбрана нота C4.
- `BTNU` выбирает следующую ноту, `BTND` — предыдущую.
- На границах список зацикливается.
- `SW[1] = 0` — ручное управление кнопками.
- В ручном режиме `SW[0] = 0` — одиночная нота, `SW[0] = 1` — трезвучие.
- `SW[1] = 1` — MIDI-режим; положение `SW[0]` в нём не используется.
- `CPU_RESETN` — активный низким уровнем сброс.

## Подключение MIDI

MIDI-приёмник работает в стандартном режиме `31250 бод, 8N1`, линия в покое
имеет высокий уровень. Поддерживаются `Note On`, `Note Off`, running status и
вариант `Note On` с velocity 0. Принимаются все MIDI-каналы. Значение velocity
пока используется только для определения Note Off; громкость фиксированная.

- `MIDI_dat` — контакт 1 разъёма JA, вывод FPGA C17.
- Второй провод — GND разъёма JA (контакт 5 или 11).
- В XDC включена внутренняя подтяжка вверх для open-collector выхода.
- На `MIDI_dat` допустим только сигнал 0–3,3 В или open-collector/open-drain.
  Подавать push-pull 5 В на C17 нельзя.
- Для более надёжных фронтов рекомендуется внешний резистор 4,7 кОм между
  `MIDI_dat` и 3,3 В на логической стороне оптопары.

Если интерфейсная схема инвертирует UART, параметр `MIDI_INVERT` верхнего
модуля нужно установить в `1`. Для обычного выхода оптопары с подтяжкой
оставляется значение `0`.

Распределитель предоставляет три голоса. При нажатии четвёртой клавиши один
из занятых голосов заменяется циклически; отпускание клавиши освобождает её
голос.

## Аккорды

| Ступень | Аккорд | Голоса |
|:---:|:---:|:---|
| C | C major | C4, E4, G4 |
| D | D minor | D4, F4, A4 |
| E | E minor | E4, G4, B4 |
| F | F major | F4, A4, C5 |
| G | G major | G4, B4, D5 |
| A | A minor | A4, C5, E5 |
| B | B diminished | B4, D5, F5 |

## Запуск тестов с Icarus Verilog

Из корня репозитория:

```powershell
New-Item -ItemType Directory -Force build | Out-Null

iverilog -g2012 -s cordic_sine_tb -o build/cordic_sine_tb.vvp rtl/*.v tb/cordic_sine_tb.v
vvp build/cordic_sine_tb.vvp

iverilog -g2012 -s pdm_dac_tb -o build/pdm_dac_tb.vvp rtl/*.v tb/pdm_dac_tb.v
vvp build/pdm_dac_tb.vvp

iverilog -g2012 -s note_frequency_lut_tb -o build/note_frequency_lut_tb.vvp rtl/*.v tb/note_frequency_lut_tb.v
vvp build/note_frequency_lut_tb.vvp

iverilog -g2012 -s chord_frequency_lut_tb -o build/chord_frequency_lut_tb.vvp rtl/*.v tb/chord_frequency_lut_tb.v
vvp build/chord_frequency_lut_tb.vvp

iverilog -g2012 -s audio_mixer_tb -o build/audio_mixer_tb.vvp rtl/*.v tb/audio_mixer_tb.v
vvp build/audio_mixer_tb.vvp

iverilog -g2012 -s midi_uart_rx_tb -o build/midi_uart_rx_tb.vvp rtl/*.v tb/midi_uart_rx_tb.v
vvp build/midi_uart_rx_tb.vvp

iverilog -g2012 -s midi_note_parser_tb -o build/midi_note_parser_tb.vvp rtl/*.v tb/midi_note_parser_tb.v
vvp build/midi_note_parser_tb.vvp

iverilog -g2012 -s midi_voice_allocator_tb -o build/midi_voice_allocator_tb.vvp rtl/*.v tb/midi_voice_allocator_tb.v
vvp build/midi_voice_allocator_tb.vvp

iverilog -g2012 -s midi_note_to_phase_inc_tb -o build/midi_note_to_phase_inc_tb.vvp rtl/*.v tb/midi_note_to_phase_inc_tb.v
vvp build/midi_note_to_phase_inc_tb.vvp

iverilog -g2012 -s sintezator_top_tb -o build/sintezator_top_tb.vvp rtl/*.v tb/sintezator_top_tb.v
vvp build/sintezator_top_tb.vvp
```

Скрипт `scripts/create_project.tcl` подключает активный файл
`constraints/sintezator.xdc`. Исходный `constraints/NexysA7_UART.xdc` оставлен
как справочник по выводам и намеренно исключён из проекта: в нём команды
повреждены переносами строк.

Для первого прослушивания лучше использовать наушники или активную колонку и
начать с невысокой громкости. Пассивный динамик непосредственно к линейному
аудиовыходу подключать не следует.
