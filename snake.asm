;    set game state memory location
.equ    HEAD_X,         0x1000  ; Snake head's position on x
.equ    HEAD_Y,         0x1004  ; Snake head's position on y
.equ    TAIL_X,         0x1008  ; Snake tail's position on x
.equ    TAIL_Y,         0x100C  ; Snake tail's position on Y
.equ    SCORE,          0x1010  ; Score address
.equ    GSA,            0x1014  ; Game state array address

.equ    CP_VALID,       0x1200  ; Whether the checkpoint is valid.
.equ    CP_HEAD_X,      0x1204  ; Snake head's X coordinate. (Checkpoint)
.equ    CP_HEAD_Y,      0x1208  ; Snake head's Y coordinate. (Checkpoint)
.equ    CP_TAIL_X,      0x120C  ; Snake tail's X coordinate. (Checkpoint)
.equ    CP_TAIL_Y,      0x1210  ; Snake tail's Y coordinate. (Checkpoint)
.equ    CP_SCORE,       0x1214  ; Score. (Checkpoint)
.equ    CP_GSA,         0x1218  ; GSA. (Checkpoint)

.equ    LEDS,           0x2000  ; LED address
.equ    SEVEN_SEGS,     0x1198  ; 7-segment display addresses
.equ    RANDOM_NUM,     0x2010  ; Random number generator address
.equ    BUTTONS,        0x2030  ; Buttons addresses

; button state
.equ    BUTTON_NONE,    0
.equ    BUTTON_LEFT,    1
.equ    BUTTON_UP,      2
.equ    BUTTON_DOWN,    3
.equ    BUTTON_RIGHT,   4
.equ    BUTTON_CHECKPOINT,    5

; array state
.equ    DIR_LEFT,       1       ; leftward direction
.equ    DIR_UP,         2       ; upward direction
.equ    DIR_DOWN,       3       ; downward direction
.equ    DIR_RIGHT,      4       ; rightward direction
.equ    FOOD,           5       ; food

; constants
.equ    NB_ROWS,        8       ; number of rows
.equ    NB_COLS,        12      ; number of columns
.equ    NB_CELLS,       96      ; number of cells in GSA
.equ    RET_ATE_FOOD,   1       ; return value for hit_test when food was eaten
.equ    RET_COLLISION,  2       ; return value for hit_test when a collision was detected
.equ    ARG_HUNGRY,     0       ; a0 argument for move_snake when food wasn't eaten
.equ    ARG_FED,        1       ; a0 argument for move_snake when food was eaten

.equ	WAIT,			0x000A	;time to wait
.equ	BLINK,			0x000A	;number of blinks
.equ	NB_ELEM_CPY,	0x194	;nb of elements to copy

; initialize stack pointer
addi    sp, zero, LEDS

; main
; arguments
;     none
;
; return values
;     This procedure should never return.
main:
	stw zero, CP_VALID(zero)
main_init:
	call wait
	call init_game
main_input:
	call wait
	call get_input
	addi t1, zero, BUTTON_CHECKPOINT
	beq v0, t1, main_rest_cp
	call hit_test
	addi a0, v0, 0
	addi t1, zero, RET_ATE_FOOD
	beq v0, t1, main_food
	addi t1, zero, RET_COLLISION
	beq v0, t1, main_init
	call move_snake
	call clear_leds
	call draw_array 
	jmpi main_input
main_food:
	call display_score
	call move_snake
	call create_food
	call save_checkpoint
	addi t1, zero, 1
	beq v0, t1, main_blink
	call clear_leds
	call draw_array
	jmpi main_input
main_rest_cp:
	call restore_checkpoint
	ldw t1, CP_VALID(zero)
	beq t1, zero, main_input
main_blink:
	call blink_score
	call clear_leds
	call draw_array 
	jmpi main_input
	

; BEGIN: clear_leds
clear_leds:
	stw zero, LEDS(zero)
	addi t0, zero, 4
	stw zero, LEDS(t0)
	addi t0, zero, 8
	stw zero, LEDS(t0)
	ret
; END: clear_leds

 ; BEGIN:set_pixel
set_pixel:
	andi t1, a0, 3       	;x mod 4
	slli t1, t1, 3       	;(x mod 4) * 8
	add t1, t1, a1       	;(x mod 4) * 8 + y
	addi t2, zero, 1		;mask init
	sll t2, t2, t1			;mask
	srli t3, a0, 2			;x/4
	slli t3, t3, 2			;(x/4)*4
	ldw s0, LEDS(t3)		;load pixel
	or s0, t2, s0			;set pixel
	stw s0, LEDS(t3)		;store pixel
	ret
; END: set_pixel

; BEGIN:wait	
wait:
	addi s0, zero, 1
	slli s0, s0, 22		;

wait_loop:	
	beq s0, zero, return
	addi s0, s0, -1
	jmpi wait_loop

return:
	ret
; END:wait

; BEGIN: display_score
display_score:
	ldw s0, SCORE(zero)			;load score
	addi s1, s0, 0				;score mod 100 init
	addi t4, zero, 100			;100

mod_hundred:
	blt s1, t4, display_score_ten			;if (score < 100) continue
	addi s1, s1, -100						;decrement by 100
	jmpi mod_hundred

display_score_ten:
	addi s2, s1, 0							;score mod 10 init
	addi t5, zero, 10						;10

mod_ten:
	blt s2, t5, display_score_div			;if (score < 10) return
	addi s2, s2, -10						;decrement by 10
	jmpi mod_ten

display_score_div:
	sub t6, s1, s2							;score mod 100 - score mod 10
	addi s3, zero, 0						;score_1 digit init

div_ten:
	bge zero, t6, display_score_continue	;if (0 >= t6) return
	addi s3, s3, 1							;increment score_1 digit
	addi t6, t6, -10						;decrement by 10
	jmpi div_ten

display_score_continue:
	ldw t2, digit_map(zero)		;load digit 0
	addi t1, zero, 0
	stw t2, SEVEN_SEGS(t1)		;store 7seg 0
	addi t1, t1, 4
	stw t2, SEVEN_SEGS(t1)		;store 7seg 1
	slli s3, s3, 2				;score_1 digit index
	ldw t2, digit_map(s3)		;load score_1 digit 
	addi t1, t1, 4
	stw t2, SEVEN_SEGS(t1)		;store 7seg 2
	slli s2, s2, 2				;score_0 digit index
	ldw t2, digit_map(s2)		;load score_0 digit 
	addi t1, t1, 4
	stw t2, SEVEN_SEGS(t1)		;store 7seg 3
	ret
; END: display_score


; BEGIN: init_game
init_game:
	addi t0, zero, NB_CELLS		;last index
	addi t1, zero, 0			;counter init
init_loop:
	beq t1, t0, init_continue
	slli t3, t1, 2				;gsa_index
	stw zero, GSA(t3)			;clear gsa[i]
	addi t1, t1, 1				;increment counter
	jmpi init_loop

init_continue:
	addi t0, zero, 4				;dir => right
	stw t0, GSA(zero)				;store gs
	stw zero, HEAD_X(zero)			;store x_head
	stw zero, HEAD_Y(zero)			;store y_head
	stw zero, TAIL_X(zero)			;store x_tail
	stw zero, TAIL_Y(zero)			;store y_tail
	stw zero, SCORE(zero)			;store score	

	addi sp, sp, -4
	stw ra, 0(sp)				;push ra

    call create_food

	ldw ra, 0(sp)				;pop ra
	addi sp, sp, 4

	addi sp, sp, -4
	stw ra, 0(sp)				;push ra

    call clear_leds

	ldw ra, 0(sp)				;pop ra
	addi sp, sp, 4

	addi sp, sp, -4
	stw ra, 0(sp)				;push ra

    call draw_array

	ldw ra, 0(sp)				;pop ra
	addi sp, sp, 4

	addi sp, sp, -4
	stw ra, 0(sp)				;push ra

    call display_score

	ldw ra, 0(sp)				;pop ra
	addi sp, sp, 4
	
	ret
; END: init_game


; BEGIN: create_food
create_food:
	ldw t2, RANDOM_NUM(zero)		;load rand number
	andi t2, t2, 0x00FF				;take the lowest byte
	addi t4, zero, NB_CELLS			;96
	bge t2, t4, create_food			;if(index is too high) retry
	slli t2, t2, 2					;rand nb * 4
	ldw t5, GSA(t2)					;load gsa[i]
	bne t5, zero, create_food		;if(index is used) retry
	addi t1, zero, FOOD				;gs is 5 for food
	stw t1, GSA(t2)					;store gsa[i]
	ret
; END: create_food


; BEGIN: hit_test
hit_test:
	ldw s0, HEAD_X(zero)	;load x_head
	ldw s1, HEAD_Y(zero)	;load y_head
	slli t1, s0, 3       	;x * 8
	add t1, t1, s1       	;x * 8 + y
	slli t1, t1, 2			;gsa_index * 4
	ldw s4, GSA(t1)			;load gs

	cmpeqi t5, s4, DIR_LEFT		;if(current_dir = 1)
	bne t5, zero, hit_left		;if(current_dir = 1) goto move_left
	cmpeqi t5, s4, DIR_UP		;if(current_dir = 2)
	bne t5, zero, hit_up		;if(current_dir = 2) goto move_up
	cmpeqi t5, s4, DIR_DOWN		;if(current_dir = 3)
	bne t5, zero, hit_down		;if(current_dir = 3) goto move_down
	cmpeqi t5, s4, DIR_RIGHT	;if(current_dir = 4)
	bne t5, zero, hit_right		;if(current_dir = 4) goto move_right

hit_left:
	addi s2, s0, -1				;decrement x
	addi s3, s1, 0				;keep y
	jmpi hit_test_continue

hit_up:
	addi s3, s1, -1				;decrement y
	addi s2, s0, 0				;keep x
	jmpi hit_test_continue

hit_down:
	addi s3, s1, 1				;increment y
	addi s2, s0, 0				;keep x
	jmpi hit_test_continue

hit_right:
	addi s2, s0, 1				;increment y
	addi s3, s1, 0				;keep x
	jmpi hit_test_continue

hit_test_continue:
	addi t4, zero, NB_COLS		;12
	bge s2, t4, hit_test_2		;if(x >= 12) return 2
	addi t4, zero, NB_ROWS		;8
	bge s3, t4, hit_test_2		;if(y >= 8) return 2
	blt s2, zero, hit_test_2	;if(x < 0) return 2
	blt s3, zero, hit_test_2	;if(y < 0) return 2
	slli t1, s2, 3       		;x * 8
	add t1, t1, s3       		;x * 8 + y
	slli t1, t1, 2				;gsa_index * 4
	ldw s5, GSA(t1)				;load gs
	beq s5, zero, hit_test_0 	;if(empty) return 0
	addi t3, zero, FOOD
	beq s5, t3, hit_test_1		;if(food) return 1
	br hit_test_2				;else return 2	

hit_test_0:
	addi v0, zero, 0
	ret
	
hit_test_1:
	addi v0, zero, RET_ATE_FOOD
	ldw t2, SCORE(zero)		;load score
	addi t2, t2, 1			;increment score
	stw t2, SCORE(zero)		;store score
	ret

hit_test_2:
	addi v0, zero, RET_COLLISION
	ret
; END: hit_test


; BEGIN: get_input
get_input:
	addi t0, zero, 4
	ldw t1, BUTTONS(t0) 				;load edgecapture at BUTTONS+4
	addi t2, zero, 5 					;counter = 5
but:
	beq t2, zero, get_input_continue	;if(counter = 0) continue
	addi t3, zero, 1					;mask init/reset
	addi t5, t2, -1						;shifting parameter
	sll t3, t3, t5 						;mask
	and t4, t1, t3						;edgecapture and mask
	bne t4, zero, get_input_continue	;if(but found) continue
	addi t2, t2, -1						;decrement counter
	beq t4, zero, but					;if(but not found) goto but

get_input_continue:
	addi v0, t2, 0						;return v0
	stw t0, BUTTONS(t0)					;clear edgecapture
	cmpeqi t6, v0, BUTTON_NONE			;if v0 = 0
	cmpeqi t7, v0, BUTTON_CHECKPOINT	;if v0 = 5
	or t7, t6, t7						;if(v0 = 0 or v0 = 5)
	bne t7, zero, return				;if(v0 = 0 and v0 = 5) return
	ldw s0, HEAD_X(zero)				;load x
	ldw s1, HEAD_Y(zero)				;load y
	slli t3, s0, 3       				;x * 8
	add t3, t3, s1       				;x * 8 + y
	slli t3, t3, 2						;gsa_index * 4
	ldw s2, GSA(t3)						;load gs
	add t4, s2, v0						;current_dir + next_dir 
	cmpeqi t5, t4, 5					;if(current_dir + next_dir = 5)
	bne t5, zero, return				;if(current_dir + next_dir = 5) return
	stw v0, GSA(t3)						;store gsa[i]
	ret
; END: get_input


; BEGIN: draw_array
draw_array:
	addi t0, zero, NB_CELLS		;last index
	addi t1, zero, 0			;counter init

draw_loop:
	beq t1, t0, return
	andi a1, t1, 7				;loop_index mod 8
	sub t2, t1, a1				;loop_index - y
	srli a0, t2, 3				;(loop_index - y)/8
	slli t3, t1, 2				;gsa_index
	ldw t2, GSA(t3)				;load gs
	addi t1, t1, 1				;increment counter
	beq t2, zero, draw_loop		;if(gsa[i] = 0) goto next

	addi sp, sp, -4
	stw ra, 0(sp)			;push ra
	addi sp, sp, -4
	stw t1, 0(sp)			;push counter
	addi sp, sp, -4
	stw t0, 0(sp)			;push last index

    call set_pixel

	ldw t0, 0(sp)			;pop last index
	addi sp, sp, 4
	ldw t1, 0(sp)			;pop counter
	addi sp, sp, 4
	ldw ra, 0(sp)			;pop ra
	addi sp, sp, 4
	jmpi draw_loop
	ret
; END: draw_array


; BEGIN: move_snake
move_snake:
	ldw s0, HEAD_X(zero)	;load x_head
	ldw s1, HEAD_Y(zero)	;load y_head
	slli t1, s0, 3       	;x * 8
	add t1, t1, s1       	;x * 8 + y
	slli t1, t1, 2			;gsa_index * 4
	ldw s4, GSA(t1)			;load gs

	cmpeqi t5, s4, DIR_LEFT		;if(current_dir = 1)
	bne t5, zero, move_left		;if(current_dir = 1) goto move_left
	cmpeqi t5, s4, DIR_UP		;if(current_dir = 2)
	bne t5, zero, move_up		;if(current_dir = 2) goto move_up
	cmpeqi t5, s4, DIR_DOWN		;if(current_dir = 3)
	bne t5, zero, move_down		;if(current_dir = 3) goto move_down
	cmpeqi t5, s4, DIR_RIGHT	;if(current_dir = 4)
	bne t5, zero, move_right	;if(current_dir = 4) goto move_right

move_left:
	addi s2, s0, -1				;decrement x
	addi s3, s1, 0				;keep y
	jmpi move_snake_continue

move_up:
	addi s3, s1, -1				;decrement y
	addi s2, s0, 0				;keep x
	jmpi move_snake_continue

move_down:
	addi s3, s1, 1				;increment y
	addi s2, s0, 0				;keep x
	jmpi move_snake_continue

move_right:
	addi s2, s0, 1				;increment y
	addi s3, s1, 0				;keep x
	jmpi move_snake_continue

move_snake_continue:
	slli t1, s2, 3			;x * 8
	add t1, t1, s3			;x * 8 + y
	slli t1, t1, 2			;gsa_index * 4
	stw s4, GSA(t1)			;store gs
	stw s2, HEAD_X(zero)	;store x_head
	stw s3, HEAD_Y(zero)	;store y_head
	bne a0, zero, return	;if there is food return

no_food_tail:

	ldw s0, TAIL_X(zero)	;load x_tail
	ldw s1, TAIL_Y(zero)	;load y_tail
	slli t1, s0, 3       	;x * 8
	add t1, t1, s1       	;x * 8 + y
	slli t1, t1, 2			;gsa_index * 4
	ldw s4, GSA(t1)			;load gs

	cmpeqi t5, s4, DIR_LEFT			;if(current_dir = 1)
	bne t5, zero, move_left_tail	;if(current_dir = 1) goto move_left
	cmpeqi t5, s4, DIR_UP			;if(current_dir = 2)
	bne t5, zero, move_up_tail		;if(current_dir = 2) goto move_up
	cmpeqi t5, s4, DIR_DOWN			;if(current_dir = 3)
	bne t5, zero, move_down_tail	;if(current_dir = 3) goto move_down
	cmpeqi t5, s4, DIR_RIGHT		;if(current_dir = 4)
	bne t5, zero, move_right_tail	;if(current_dir = 4) goto move_right

move_left_tail:
	addi s2, s0, -1				;decrement x
	addi s3, s1, 0				;keep y
	jmpi no_food_tail_continue

move_up_tail:
	addi s3, s1, -1				;decrement y
	addi s2, s0, 0				;keep x
	jmpi no_food_tail_continue

move_down_tail:
	addi s3, s1, 1				;increment y
	addi s2, s0, 0				;keep x
	jmpi no_food_tail_continue

move_right_tail:
	addi s2, s0, 1				;increment y
	addi s3, s1, 0				;keep x
	jmpi no_food_tail_continue

no_food_tail_continue:
	stw s2, TAIL_X(zero)	;store new x_tail
	stw s3, TAIL_Y(zero)	;store new y_tail
	stw zero, GSA(t1)		;reset prev dir
	ret
; END: move_snake

; BEGIN: save_checkpoint
save_checkpoint:
	ldw s0, SCORE(zero)				;load score
	beq s0, zero, no_save			;if (score = 0) then no save
	addi t0, zero, 10
save_mod_ten:
	blt s0, t0,	save_continue		;if (score < 10) continue
	addi s0, s0, -10				;decrement by 10
	jmpi save_mod_ten
save_continue:
	bne s0, zero, no_save			;if (score mod 10 != 0) then no save
	addi v0, zero, 1				;return 1 if (score multiple of 10)
	stw v0, CP_VALID(zero)
	addi t2, zero, NB_ELEM_CPY 			;nb of elements to copy
	addi t3, zero, 0				;counter of elements
	beq s0, zero, save_memcpy
no_save:
	addi v0, zero, 0				;return 0 if (score isn't multiple of 10)
	ret
save_memcpy:
	blt t2, t3, return				;if (nb of elem < counter) then return
	ldw t4, HEAD_X(t3)				;load the element to copy
	stw t4, CP_HEAD_X(t3)			;store the element
	addi t3, t3, 4					;increment counter by 4
	jmpi save_memcpy
; END: save_checkpoint

; BEGIN: restore_checkpoint
restore_checkpoint:
	ldw s0, CP_VALID(zero)
	beq s0, zero, no_restore
	addi t2, zero, NB_ELEM_CPY		;nb of elements to copy
	addi t3, zero, 0				;counter of elements
	addi v0, zero, 1				;return 1 if (cp_valid)
	br restore_memcpy
no_restore:
	addi v0, zero, 0				;return 0 if (cp invalid)
	ret
restore_memcpy:
	blt t2, t3, return				;if (nb of elem < counter) then return
	ldw t4, CP_HEAD_X(t3)			;load the element to copy
	stw t4, HEAD_X(t3)				;store element
	addi t3, t3, 4					;increment counter by 4
	jmpi restore_memcpy
; END: restore_checkpoint

; BEGIN: blink_score
blink_score:
	addi t0, zero, 0				;counter init

blink_loop:
	addi t2, zero, BLINK			;number of blinks
	beq t0, t2, return				;if(counter = BLINK) then return
	addi t1, zero, 0
	stw zero, SEVEN_SEGS(t1)		;clear 7seg 0
	addi t1, t1, 4
	stw zero, SEVEN_SEGS(t1)		;clear 7seg 1
	addi t1, t1, 4
	stw zero, SEVEN_SEGS(t1)		;clear 7seg 2
	addi t1, t1, 4
	stw zero, SEVEN_SEGS(t1)		;clear 7seg 3
		
	addi sp, sp, -4
	stw ra, 0(sp)			;push ra
	addi sp, sp, -4
	stw t2, 0(sp)			;push blinks
	addi sp, sp, -4
	stw t0, 0(sp)			;push counter

    call wait

	ldw t0, 0(sp)			;pop counter
	addi sp, sp, 4
	ldw t2, 0(sp)			;pop blinks
	addi sp, sp, 4
	ldw ra, 0(sp)			;pop ra
	addi sp, sp, 4

blink_continue:
	addi sp, sp, -4
	stw ra, 0(sp)			;push ra
	addi sp, sp, -4
	stw t2, 0(sp)			;push blinks
	addi sp, sp, -4
	stw t0, 0(sp)			;push counter

    call display_score

	ldw t0, 0(sp)			;pop counter
	addi sp, sp, 4
	ldw t2, 0(sp)			;pop blinks
	addi sp, sp, 4
	ldw ra, 0(sp)			;pop ra
	addi sp, sp, 4

	addi sp, sp, -4
	stw ra, 0(sp)			;push ra
	addi sp, sp, -4
	stw t2, 0(sp)			;push blinks
	addi sp, sp, -4
	stw t0, 0(sp)			;push counter

    call wait

	ldw t0, 0(sp)			;pop counter
	addi sp, sp, 4
	ldw t2, 0(sp)			;pop blinks
	addi sp, sp, 4
	ldw ra, 0(sp)			;pop ra
	addi sp, sp, 4

blink_continue2:
	addi t0, t0, 1			;increment counter
	jmpi blink_loop
; END: blink_score

digit_map:
	.word 0xFC ; 0
	.word 0x60 ; 1
	.word 0xDA ; 2
	.word 0xF2 ; 3
	.word 0x66 ; 4
	.word 0xB6 ; 5
	.word 0xBE ; 6
	.word 0xE0 ; 7
	.word 0xFE ; 8
	.word 0xF6 ; 9
