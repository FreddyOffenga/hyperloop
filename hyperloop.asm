; Hyperloop
; F#READY 17-08-2021

; draws circles in gr.9
; version 4, optimised for SV release
; version 1, added clipping
; version 0, crude BASIC conversion (bresenham)

SAVMSC			= $58		; word
screen_mem		= SAVMSC	; alias

ROWCRS			= $54		; byte
y_position		= ROWCRS	; alias

COLCRS			= $55		; word
x_position		= COLCRS	; alias

open_mode		= $ef9c		; A=mode
plot_pixel		= $f1d8

ATACHR			= $2fb		; drawing color
draw_color		= ATACHR	; alias

var_a			= $f0
var_b			= $f1
radius			= $f2
var_phi			= $f3
var_phiy		= $f4
var_phixy		= $f5
var_x1			= $f6
var_y1			= $f7
var_a_plus_x1	= $f8
var_a_min_x1	= $f9
var_a_plus_y1	= $fa
var_a_min_y1	= $fb
var_b_plus_x1	= $f8
var_b_min_x1	= $f9
var_b_plus_y1	= $fa
var_b_min_y1	= $fb
var_abs_phiy	= $fc
var_abs_phixy	= $fd

A_START		= 63
B_START		= 63
R_START		= 3	; max 49

			org $0600

			lda #9
            sta $d201

			jsr open_mode

            ;lda #$08
            ;sta $d201

			;lda #0
			;sta draw_color
loop
			inc draw_color
;			lda draw_color
            lda draw_color
;            sta draw_color
            sta $d200
			
			lda #A_START
			sta var_a
;			lda #B_START
			sta var_b
			lda #R_START
			sta radius
            
draw_more
			jsr draw_circle
			
			dec draw_color
			
			lda radius

			clc
			adc #5
			sta radius

;            sta $d200
			
			cmp #56
			bcc draw_more
            
			bcs loop
						
draw_circle
			sta var_x1
			
			lda #0
			sta var_phi
			sta var_y1

; 300 PHIY=PHI+Y1+Y1+1
draw_all_pixels
			lda var_phi
			clc
			adc var_y1
			adc var_y1
;			adc #1
			sta var_phiy
			and #$7f
			sta var_abs_phiy


; 310 PHIXY=PHIY-X1-X1+1

			lda var_phiy
			sec
			sbc var_x1
			sbc var_x1
			clc
;			adc #1
			sta var_phixy
			and #$7f
			sta var_abs_phixy

; prepare sums

; 380 REM A+X1
			lda var_a
			clc
			adc var_x1
			sta var_a_plus_x1

; 381 REM A-X1			
			lda var_a
			sec
			sbc var_x1
			sta var_a_min_x1
			
; 382 REM A+Y1
			lda var_a
			clc
			adc var_y1
			sta var_a_plus_y1
			
; 383 REM A-Y1
			lda var_a
			sec
			sbc var_y1
			sta var_a_min_y1
			
; 384 REM B+Y1
			lda var_b
			clc
			adc var_y1
			sta var_b_plus_y1
						
; 385 REM B-Y1
			lda var_b
			sec
			sbc var_y1
			sta var_b_min_y1

; 386 REM B+X1
			lda var_b
			clc
			adc var_x1
			sta var_b_plus_x1

; 387 REM B-X1
			lda var_b
			sec
			sbc var_x1
			sta var_b_min_x1
						
; 400 PLOT A+X1,B+Y1:REM RIGHT,BOT
			ldx var_a_plus_x1			
;			stx x_position
			ldy var_b_plus_y1
;			sty y_position
			jsr plot_one
			
; 410 PLOT A-X1,B+Y1:REM LEFT,BOT
			ldx var_a_min_x1
;			sta x_position
			ldy var_b_plus_y1
;			sta y_position
			jsr plot_one
			
; 420 PLOT A+X1,B-Y1:REM RIGHT,TOP
			ldx var_a_plus_x1
;			sta x_position
			ldy var_b_min_y1
;			sta y_position
			jsr plot_one
			
; 430 PLOT A-X1,B-Y1:REM LEFT,TOP
			ldx var_a_min_x1
;			sta x_position
			ldy var_b_min_y1
;			sta y_position
			jsr plot_one
			
; 440 PLOT A+Y1,B+X1:REM RIGHT,BOT
			ldx var_a_plus_y1
;			sta x_position
			ldy var_b_plus_x1
;			sta y_position
			jsr plot_one
			
; 450 PLOT A-Y1,B+X1:REM LEFT,BOT
			ldx var_a_min_y1
;			sta x_position
			ldy var_b_plus_x1
;			sta y_position
			jsr plot_one
			
; 460 PLOT A+Y1,B-X1:REM RIGHT,TOP
			ldx var_a_plus_y1
;			sta x_position
			ldy var_b_min_x1
;			sta y_position
			jsr plot_one
			
; 470 PLOT A-Y1,B-X1:REM LEFT,TOP
			ldx var_a_min_y1
;			sta x_position
			ldy var_b_min_x1
;			sta y_position
			jsr plot_one
			
; 500 PHI=PHIY
			lda var_phiy
			sta var_phi
			
; 510 Y1=Y1+1
			inc var_y1
			
;520 IF ABS(PHIXY)<ABS(PHIY) THEN PHI=PHIXY:X1=X1-1
			lda var_abs_phixy
			cmp var_abs_phiy
			bcs skip_dec_x1
			
			lda var_phixy
			sta var_phi
			dec var_x1
			
skip_dec_x1
; 530 IF X1>=Y1 THEN 300
			lda var_x1
			cmp var_y1
			bcc draw_one_done
			jmp draw_all_pixels
draw_one_done

clip_it
			rts
			
plot_one
            txa
;            sta $d201
;            sta $d01f
;			lda x_position
			sec
			sbc #24
			sta x_position

			bcc clip_it
			cmp #79
			bcs clip_it

            tya		
;			lda y_position
			sec
			sbc #24
			sta y_position
			bcc clip_it
			cmp #79
			bcs clip_it
					
			asl y_position	
			         
			;sta $d01f
			
			jmp plot_pixel
;clip_it
;			rts
			
