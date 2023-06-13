[ORG 0x00]  ; 메모리 0x00번지에서 실행.

[BITS 16]  ; 이 프로그램이 16비트 단위로 데이터를 처리하는 프로그램임을 알림.

jmp 0x07C0:START  ; 0x07C0:START 주소로 점프.
                                ; 프로그램 코드가 저장된 코드 세그먼트 레지스터(cs) 값은 0x0000.
                                ; 램의 0x07C0번지로 이동 후, START부분으로 이동.

START:  ; JMP명령으로 여기서부터 수행.

    mov ax, cs  ; 범용 레지스터(ax)에 코드 세그먼트(cs)를 복사한다.
    mov ds, ax  ; 데이터 세그먼트 레지스터(ds)를 ax의 값(0xB800)으로 초기화.

    mov ax, 0xB800  ; 비디오 메모리 시작 주소를 범용 레지스터에 복사한다.
    mov es, ax  ; 엑스트라 세그먼트 레지스터(es)에 0xB800을 복사한다.
    mov di, 0  ; 오프셋(di)를 0으로 초기화한다.

.SCREENCLEARLOOP:

    mov byte [ es : di ], 0x00  ; 0x00(NULL)에 해당하는 문자로 채움.
    mov byte [ es : di+1 ], 0x0A  ;  바탕은 검은색, 문자는 초록색으로 지정한다.
    add di, 2  ; 다음 문자 출력을 위하여 오프셋(di)를 2만큼 올린다.
    cmp di, 80 * 25 * 50  ; di가 4000인가?
    jl .SCREENCLEARLOOP  ; di == 4000이라면 .SCREENCLEARLOOP를 끝냄.

    mov di, 0  ; di 초기화
    mov si, 0  ; si 초기화

.MESSAGELOOP:  ; 문자 출력을 위한 LOOP

    mov cl, byte [ si+.MESSAGE1 ]  ; MESSAGE1+SI 주소에 있는 문자를 CL에 복사.  ; MESSAGE1+si 주소에 있는 문자를 CL에 복사.
    cmp cl, 0  ; cl이 0(0x00(NULL))인가?
    je .MESSAGEEND  ; CL == 0일 경우, .MESSAGEEND로 점프한다.
  
    mov byte [ es : di ], cl  ; ES:DI(0xB800)가 가르키는 비디오 메모리에 cl에 있는 문자를 복사.
    add si, 1  ; 다음 문자를 가져오기 위하여 SI에 1을 증가.
    add di, 2  ; 다음 문자를 출력하기 위하여 DI에 2를 증가.
    jmp .MESSAGELOOP  ; 문자출력 반복

.MESSAGEEND:

    jmp $  ; 현재 주소로 점프(무한 루프)

.MESSAGE1:

    db ‘Boot Loader’, 0  ; 출력하고자 하는 문장 정의

times 510 - ( $ - $$ ) db 0x00  ; $(현재주소에서) $$(처음 시작주소)를 뺀 주소까지 0으로 채움.

db 0x55  ; 511번지에 55를 채움.

db0xAA  ; 512번지에 AA를 채움.