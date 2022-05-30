extrn _hscplayer:far

.286
.model small
.stack 100h
.data

shoot_music label byte
include bchild.mus
adlib   db 0

palette label byte
include bc.pal

pic_pal label byte
include bc_pic.pal

picture label byte
include bc_pic.pic

font    label byte    ;fghe [\]^_`abcd
include bc.fnt        ;!-+. 0123456789

string  db '   \ BLAZING NODE   ',254
        db ' gggggggggggggggggg ',254   
        db '         ',254,254,254,254
        db ' gggggggggggggggggg ',254
        db '   ha\gdg^c`g[b_[   ',255

;string2 db '   gh SYSOP hg   ',254
;        db '   BRAIN CHILD   ',254,254
;        db '   SUPPORTING    ',254
;        db '  ]_[[ TO ]cecK  ',255

string2 db '    PURE WEST OZ    ',254
        db '  HACK AND PHREAK   ',254
        db '         ',254,254,254,254,254
        db '    INFINITY WHQ    ',255

;string3 db '`[[ MB OF STORAGE',254,254
;        db '    HePeAeCeV    ',254
;        db '       IBM       ',254
;        db '      UNIX       ',254
;        db '   ART N DEMOS   ',254
;        db '  AND LOTS MORE  ',255

string3 db ' ALL SPEEDS WELCOME ',254
        db '         ',254,254,254,254,254
        db '    NO RATIOSfff    ',255

;string4 db '  INFINITY WHQ   ',254,254
;        db '  KIND  RATIOS   ',254,254
;        db '   NO  LAMERS    ',254,254
;        db '  RING NOWffff   ',255

no_vga  db 'Sorry, This loader requires VGA$'
end_txt db 'Programmed in 100% ASM by Earwax/Myst in ''95',10,13
        db 'Player by Chicken/ECR$'

include field.dw

x       dw ?
y       dw ?
z       dw ?

real_x  dw ?
real_y  dw ?

s_color db 0

delay   dw 6
t_x     dw ?
t_y     dw ?

stars   db 0,0,0
     i = 0
     REPT 15
        db i,i,i
     i = i+4
     ENDM

c_p     db 768 dup (0)

p_seg   dw ?

.code

proc    main
        mov     ax,@data
        mov     ds,ax

        mov     ax,4a00h
        mov     bx,2000h
        int     21h
        mov     ax,4800h
        mov     bx,1000h
        int     21h
        mov     p_seg,ax

        mov     ax,0013h
        int     10h
        mov     ah,0fh
        int     10
        cmp     al,13h
        jz      vga_ok
        mov     ax,0003h
        int     10h
        mov     ah,9
        lea     dx,no_vga
        int     21h
        mov     ax,4c00h
        int     21h
vga_ok:

        mov     dx,3c8h
        xor     al,al
        out     dx,al
        inc     dx
        mov     cx,768
        lea     si,palette
load_colors:
        mov     al,[si]
        out     dx,al
        inc     si
        loop    load_colors

        mov     dx,3c8h
        mov     al,16
        out     dx,al
        inc     dx
        mov     cx,16*3
        lea     si,stars
load_star_colors:
        mov     al,[si]
        out     dx,al
        inc     si
        loop    load_star_colors

        call    start_music

        mov     dx,3c8h
        mov     al,64
        out     dx,al
        inc     dx
        lea     si,pic_pal
        mov     cx,768-(64*3)
load_picture_colors:
        mov     al,[si]
        out     dx,al
        inc     si
        loop    load_picture_colors

        push    ds
        mov     ax,p_seg
        mov     ds,ax
        mov     cx,320*200
        xor     di,di
clear_buffer:
        xor     al,al
        mov     ds:[di],al
        inc     di
        loop    clear_buffer
        pop     ds


        mov     ax,0a000h
        mov     es,ax

        
        mov     di,320*50
        mov     cx,320*100
        lea     si,picture
load_piccy:
        mov     al,ds:[si]
        cmp     al,0
        jz      stay_zero
        add     al,64
stay_zero:
        inc     si
        push    ds
        push    ax
        mov     ax,p_seg
        mov     ds,ax
        pop     ax
        mov     ds:[di],al
        pop     ds
        inc     di
        loop    load_piccy

        mov     cx,320*200
        xor     di,di
copy_buffer:
        push    ds
        mov     ax,p_seg
        mov     ds,ax
        mov     al,ds:[di]
        pop     ds
        mov     es:[di],al
        inc     di
        loop    copy_buffer

        mov     cx,70
wait_a_sec_:
        call    poll_music
        call    draw_star_field
        call    vertical
        loop    wait_a_sec_


animation_loop:
        lea     si,string
        mov     t_x,0
        mov     t_y,24
        call    write_string
        call    wait_for_read
        call    clear_text

        lea     si,string2
        mov     t_y,17
        call    write_string
        call    wait_for_read
        call    clear_text
        ;mov     t_x,25
        ;mov     t_y,50
        
        lea     si,string3
        mov     t_y,33
        call    write_string
        call    wait_for_read
        call    clear_text

        ;lea     si,string4
        ;mov     t_y,30
        ;call    write_string
        ;call    wait_for_read
        ;call    clear_text

        mov     ah,1
        int     16h
        jz      animation_loop

end_of_loader:

        call    flash_out
        
        mov     ax,0003h
        int     10h

        mov     ah,9
        lea     dx,end_txt
        int     21h

        mov     ax,4c00h
        int     21h
endp    main

proc    wait_for_read
        pusha
        mov     cx,200
wait_while_animating:
        call    poll_music
        call    vertical
        call    draw_star_field
        mov     ah,1
        int     16h
        jnz     end_of_loader
        loop    wait_while_animating
        popa
        ret
endp    wait_for_read



proc    save_palette
        pusha
        mov     dx,3c7h
        xor     al,al
        out     dx,al
        mov     dx,3c9h
        mov     cx,768
        lea     si,c_p
save_pal_loop:
        in      al,dx
        mov     [si],al
        inc     si
        loop    save_pal_loop
        popa
        ret
endp    save_palette

proc    flash_out
        pusha
        call    save_palette
        mov     cx,63
fade_to_white:
        push    cx
        mov     dx,3c8h
        xor     al,al
        out     dx,al
        inc     dx
        lea     si,c_p
        mov     cx,768
all_of_them:
        mov     al,[si]
        cmp     al,63
        jz      is_white
        inc     al
is_white:
        mov     [si],al
        inc     si
        out     dx,al
        loop    all_of_them
        pop     cx
        call    vertical
        call    poll_music
        call    draw_star_field
        loop    fade_to_white

        mov     cx,63
fade_out:
        push    cx
        mov     ax,cx
        mov     cx,768
f_o_l:
        out     dx,al
        loop    f_o_l
        pop     cx
        call    vertical
        call    poll_music
        loop    fade_out

        call    stop_music

        popa
        ret
endp    flash_out

proc    draw_star_field
        pusha
        lea     si,starfield
        mov     cx,400
draw_single_star_loop:
        push    cx
        lodsw
        mov     x,ax
        lodsw
        mov     y,ax
        mov     ax,[si]
        mov     z,ax
        mov     s_color,0
        call    draw_star
        dec     z
        cmp     z,3
        ja      z_is_still_on_page
        mov     z,150
z_is_still_on_page:
        mov     ax,z
        mov     [si],ax
        add     si,2

        xor     dx,dx
        mov     ax,z
        mov     bx,10
        idiv    bx
        neg     ax
        add     ax,32
        mov     s_color,al
        call    draw_star
        pop     cx
        loop    draw_single_star_loop
        popa
        ret

draw_star:
        xor     dx,dx
        mov     ax,x
        mov     bx,64
        imul    bx
        mov     bx,z
        idiv    bx
        add     ax,160
        mov     real_x,ax

        xor     dx,dx
        mov     ax,y
        mov     bx,64
        imul    bx
        mov     bx,z
        idiv    bx
        add     ax,100
        mov     real_y,ax

        cmp     real_x,5
        jb      no_draw_off_page
        cmp     real_x,315
        ja      no_draw_off_page
        cmp     real_y,5
        jb      no_draw_off_page
        cmp     real_y,195
        ja      no_draw_off_page
        
        xor     dx,dx
        mov     ax,real_y
        mov     bx,320
        imul    bx
        add     ax,real_x
        mov     di,ax
        mov     al,es:[di]
        cmp     al,0
        jz      yep_draw_it
        cmp     al,16
        jb      no_draw_off_page
        cmp     al,32
        ja      no_draw_off_page
yep_draw_it:
        mov     al,s_color
        mov     es:[di],al
no_draw_off_page:
        ret
endp    draw_star_field

proc    clear_text
        pusha
        xor     di,di
        mov     cx,100
clear_text_off_screen_loop:
        push    cx
        mov     cx,640
frame_loop:
        mov     al,es:[di]
        cmp     al,16
        ja      no_clear
        push    ds
        mov     ax,p_seg
        mov     ds,ax
        mov     al,ds:[di]
        pop     ds
        mov     es:[di],al
no_clear:
        inc     di
        loop    frame_loop
        call    poll_music
        call    vertical
        call    draw_star_field
        mov     ah,1
        int     16h
        jz      ctos
        jmp     end_of_loader
ctos:
        pop     cx
        loop    clear_text_off_screen_loop
        popa
        ret
endp    clear_text

proc    write_string
        pusha
        push    t_y
calculate_start:
        xor     dx,dx
        mov     ax,t_y
        mov     bx,320
        imul    bx
        add     ax,t_x
        mov     di,ax
next_letter:
        lodsb
        cmp     al,255
        jnz     not_finished_string
        pop     t_y
        popa
        ret
not_finished_string:
        cmp     al,32
        jnz     not_a_space
        add     di,16
        mov     cx,delay
        jmp     character_delay
not_a_space:
        cmp     al,254
        jnz     not_a_new_line
        add     t_y,20
        jmp     calculate_start
not_a_new_line:
        xor     dx,dx
        sub     al,65
        xor     ah,ah
        push    ax
        mov     bx,16
        imul    bx
        pop     bx
        cmp     bx,20
        jb      offset_ok        
        add     ax,320*15
offset_ok:
        lea     bp,font
        add     bp,ax
        push    di
        mov     cx,15
draw_letter_loop_1:
        push    cx
        mov     cx,16
draw_letter_loop_2:
        mov     al,ds:[bp]
        inc     bp
        cmp     al,0
        jz      its_clear
        mov     es:[di],al
its_clear:
        inc     di
        loop    draw_letter_loop_2
        add     di,320-16
        add     bp,320-16
        pop     cx
        loop    draw_letter_loop_1
        pop     di
        add     di,16
        mov     cx,delay
character_delay:
        call    poll_music
        call    draw_star_field
        call    vertical
        loop    character_delay
        mov     ah,1
        int     16h
        jz      nl
        jmp     end_of_loader
nl:
        jmp     next_letter
endp    write_string

proc    vertical
        pusha
        mov     dx,3dah
vrt1:
        in      al,dx
        test    al,8
        jnz     vrt1
vrt2:
        in      al,dx
        test    al,8
        jz      vrt2
        popa
        ret
endp    vertical

proc    detect_adlib
        pusha
        stc
        mov     dx,388h
        in      al,dx
        cmp     al,0
        jz      has_adlib
        cmp     al,6
        jnz     doesnt_have_adlib
has_adlib:
        clc
doesnt_have_adlib:
        popa
        ret
endp    detect_adlib

proc    start_music
        pusha
        call    detect_adlib
        jc      no_music
no_music:
        mov     adlib,1
        mov     ax,ds
        mov     es,ax
        lea     si,shoot_music
        xor     ah,ah
        mov     bl,1
        call    _hscplayer
        popa
        ret
endp    start_music

proc    poll_music near
        pusha
        cmp     adlib,1
        jnz     no_poll
        mov     ah,1
        call    _hscplayer
no_poll:
        popa
        ret
endp    poll_music

proc    stop_music
        pusha
        cmp     adlib,1
        jnz     no_stop
        mov     ah,2
        call    _hscplayer
no_stop:
        popa
        ret
endp    stop_music
end     main
