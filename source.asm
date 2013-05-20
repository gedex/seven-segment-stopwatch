; Two seven-segments display for stopwatch.
;
; @author Akeda Bagus <admin@gedex.web.id>
; @copyright 2006-2013
; @licens MIT License
;

$MOD51

DSEG
  out7seg EQU p1
  puluhan BIT p3.0  ; Active low, puluhan means digit for tens
  satuan  BIT p3.1  ; satuan means digit for ones.
  sw      BIT p3.2  ; Switch

CSEG
  ORG 0h
  SJMP init__

  ORG 03h
  RETI

init__:
  MOV   IE,#81h         ; INT 0
  SETB  IT0             ; Edge trigerred

init_:                  ; Exec by mcu reset & sw
  CLR   F0              ; F0 -> indikator sudah '00'
  MOV   A,#84h          ; 6
  MOV   B,#0C0h         ; 0

init:
  SETB  satuan          ; Off 7 seg, common 7s for ones digits
  SETB  puluhan         ; common 7s for tens digits
  MOV   dptr,#data7seg  ; Takes address of 7s data at #data7seg
  CLR   p3.4            ; Low source for switch
  jnb   F0,loop         ; Do we get '00' ?

wait00:                 ; If yes
  SJMP  loop
  CLR   satuan          ; ON 7s
  CLR   puluhan
  MOV   out7seg,#0C0h   ; Displays '00'
  SETB  satuan
  jb    satuan, wait00  ; Is reset pressed?
  SJMP  init_   ;iya

; First bootup '60'
loop:
  SETB  satuan
  CLR   puluhan
  MOV   out7seg,A
  acall delay_1ms
  SETB  puluhan
  CLR   satuan
  MOV   out7seg, B
  acall delay_1ms
  SETB  puluhan
  SETB  satuan


; Switch for setting up is pressed,
; starts countdown
startCount:
  MOV r1,#100

sub0:
  MOV r2,#5

sub0_:
  jnb   satuan,init_  ; Is reset pressed?
  SETB  satuan
  CLR   puluhan
  MOV   out7seg,#84h  ; 6
  acall delay_1ms
  SETB  puluhan
  CLR   satuan
  MOV   out7seg,#0C0h ; 0
  acall delay_1ms
  SETB  satuan
  DJNZ  r2,sub0_
  DJNZ  r1,sub0

decPuluhan:
  MOV   A, #04            ; Index pointer for '5'
  MOVC  A, @A+dptr
  CJNE  A, #0ffh,ambil_   ; Not yet '0'?
  MOV   A, #0C0h          ; '0'
  MOV   B, A
  SETB  F0                ; Must be reset to '60'
  AJMP  init

ambil_:                   ; Not yet '0'
  CPL   A
  MOV   B, A              ; B for tens digits
  inc   dptr
  PUSH  dph
  PUSH  dpl
  MOV   dptr, #data7seg   ; Index '0'

decSatuan:
  CLR   A
  MOVC  A, @A+dptr
  inc   dptr
  CJNE  A, #0ffh, ambil   ; Not finished yet?
  SJMP  exit

ambil:                    ; decrement tens
  CPL   A                 ; A for ones digits
  MOV   r1, #100

sub:
  MOV   r2,#5

sub_:                     ; Displaying by switching each 1ms
  jnb   satuan, reset_    ; Is reset pressed?
  SETB  satuan
  CLR   puluhan
  MOV   out7seg, B
  acall delay_1ms
  SETB  puluhan
  CLR   satuan
  MOV   out7seg, A
  acall delay_1ms
  SETB  satuan
  DJNZ  r2, sub_
  DJNZ  r1, sub
  SJMP  decSatuan

reset_:
  AJMP  init_

exit:
  POP   dpl
  POP   dph
  AJMP  decPuluhan        ; Decrement tens

delay_1ms:
  PUSH  07h
  PUSH  06h
  MOV   r6, #02

subz:
  MOV   r7, #220
  DJNZ  r7, $
  DJNZ  r6, subz
  POP   06h
  POP   07h
RET

data7seg:
  DB  5Fh,7Fh,0Eh,7Bh,5Bh,4Dh,5Eh,76h,0Ch,3Fh,0FFh
     ; 9   8   7   6   5   4   3   2   1   0
END
