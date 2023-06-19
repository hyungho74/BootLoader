[org 0x00]  ; 메모리 0x00번지에서 실행.

[bits 16]  ; 이 프로그램이 16비트 단위로 데이터를 처리하는 프로그램임을 알림.

jmp 0x07C0:START  ; 0x07C0:START 주소로 점프.
                                ; 프로그램 코드가 저장된 코드 세그먼트 레지스터(cs) 값은 0x0000.
                                ; 램의 0x07C0번지로 이동 후, START부분으로 이동.

TOTALSECTORCOUNT:
    dw 1024  ; 부트로더를 제외한 os 이미지 크기
            ; 최대 1152섹터(0x90000byte)까지 가능

START:  ; JMP명령으로 여기서부터 수행.
    mov ax, 0x7C0  ; 범용 레지스터(ax)에 코드 세그먼트(cs)의 값을 복사한다.
    mov ds, ax  ; 데이터 세그먼트 레지스터(ds)를 ax의 값(0x7C0)으로 초기화.

    mov ax, 0xB800  ; 비디오 메모리 시작 주소를 범용 레지스터에 복사한다.
    mov es, ax  ; 엑스트라 세그먼트 레지스터(es)에 0xB800을 복사한다.

    mov ax, 0x0000  ; ax에 0x0000 설정
    mov ss, ax  ; 스택 세그먼트(ss) 레지스터의 시작주소를 ax(0x0000)으로 변환
    mov sp, 0xFFFE  ; 스택 포인트 레지스터(sp)의 값을 0xFFFE로 설정
    mov bp, 0xFFFE  ; 베이스 포인트 레지스터(bp)의 값을 0xFFFE로 설정

    mov si, 0  ; 오프셋(si)를 0으로 초기화한다.

.SCREENCLEARLOOP:
    mov byte [ es : di ], 0x00  ; 0x00(NULL)에 해당하는 문자로 채움.
    mov byte [ es : di+1 ], 0x0A  ;  바탕은 검은색, 문자는 초록색으로 지정한다.
    add si, 2  ; 다음 문자 출력을 위하여 오프셋(si)를 2만큼 올린다.
    cmp si, 80 * 25 * 50  ; di가 4000인가?
    jl .SCREENCLEARLOOP  ; di == 4000이라면 .SCREENCLEARLOOP를 끝냄.

    push MESSAGE1  ; 스택에 출력할 메세지 삽입
    push 0  ; 스택에 Y좌표(0)를 삽입
    push 0  ; 스택에 X좌표(0)를 삽입
    call .PRINTMESSAGE  ; .PRINTMESSAGE 함수를 호출
    add sp, 6  ; 삽입한 파라미터 제거

    push MESSAGE2  ; 스택에 출력할 메세지 삽입
    push 1  ; 스택에 Y좌표(1)를 삽입
    push 0  ; 스택에 X좌표(0)를 삽입
    call .PRINTMESSAGE  ; .PRINTMESSAGE 함수를 호출
    add sp, 6  ; 삽입한 파라미터 제거

    push IMAGELOADINGMESSAGE  ; 스택에 출력할 메세지 삽입
    push 2  ; 스택에 Y좌표(2)를 삽입
    push 0  ; 스택에 X좌표(0)를 삽입
    call .PRINTMESSAGE  ; .PRINTMESSAGE 함수를 호출
    add sp, 6  ; 삽입한 파라미터 제거

.RESETDISK:  ; 디스크를 리셋하는 함수
    mov ax, 0  ; 서비스 번호 0(리셋기능으로 설정)
    mov dl, 0x00  ; 드라이브 번호 0x00(Floppy), 0x80(첫 번째 하드디스크), 0x81(두 번째 하드디스크)
    int 0x13  ; 인터럽트 서비스 수행(읽기)
    jc .HANDLEDISKERROR  ; 에러가 발생했다면, .HANDLEDISKERROR로 이동

    mov si, 0x1000  ; OS 이미지를 복사할 어드레스(0x1000)를  si레지스터 값으로 변환
    mov bx, 0x0000  ; bx레지스터에 0x0000를 설정하여 복사할 어드레스를 0x1000:0000(0x1000)으로 최종설정

    mov di, word[ TOTALSECTORCOUNT ]  ; 복사할 OS 이미지의 섹터 수를 di로 설정

.READDATA:  ; 디스크를 읽는 코드의 시작
    cmp di, 0  ; 복사할 OS이미지의 섹터수를 0과 비교
    je .READEND  ; 복사할 섹터의 수가 0이라면 다 복사가 된 것이므로 .READEND로 이동
    sub di, 0x1  ; 복사할 섹터 수를 1 감소

    mov ah, 0x02  ; BIOS 서비스 번호 2(Read Sector)
    mov al, 0x01  ; 읽을 섹터 수는 1
    mov ch, byte[ TRACKNUMBER ]  ; 읽을 트랙 번호 설정
    mov cl, byte[ SECTORNUMBER ]  ; 읽을 섹터 번호 설정
    mov dh, byte[ HEADNUMBER ]  ; 읽을 헤더 번호 설정
    mov dl, 0x00  ; 읽을 드라이브 번호(0 = Floppy) 설정
    int 0x13  ; 인터럽트 서비스 수행(읽기)
    jc .HANDLEDISKERROR  ; 에러가 발생했다면, .HANDLEDISKERROR로 이동

    add si, 0x0020  ; 512(0x0020)바이트만큼 읽었으므로 이를 si 레지스터 값으로 변환
    mov es, si  ; es레지스터에 더해서 어드레스를 한 섹터 만큼 증가

    mov al, byte[ SECTORNUMBER ]  ; 섹터번호를 al레지스터에 설정
    add al, 0x01  ; 섹터 번호를 1증가.
    mov byte[ SECTORNUMBER ], al  ; 증가시킨 섹터 번호를 다시 SECTORNUMBER에 저장
    cmp al, 19  ; 증가시킨 섹터 번호를 19와 비교
    jl .READDATA  ; 섹터번호가 19미만이라면 .READDATA로 이동

    xor byte[ HEADNUMBER ], 0x01  ; 헤드 번호를 0x01과 xor하여 토글(0 → 1)(1 → 0)
    mov byte[ SECTORNUMBER ], 0x01  ; 섹터 번호를 다시 1로 설정

    cmp byte[ HEADNUMBER ], 0x00  ; 헤드번호를 0x00과 비교
    jne .READDATA  ; 헤드 번호가 0이 아니라면 .READDATA로 이동

    add byte[ TRACKNUMBER ], 0x01  ; 트랙번호를 1증가
    jmp .READDATA  ; .READATA로 이동

.READEND:
    push LOADINGCOMPLETEMESSAGE  ; 출력할 문자열의 어드레스를 스택에 삽입
    push 2  ; 스택에 Y좌표(2) 삽입
    push 20  ; 스택에 X좌표(20) 삽입
    call .PRINTMESSAGE  ; .PRINTMESSAGE함수 호출
    ass sp, 6  ; 삽입한 파라미터 제거

    jmp 0x1000:0x0000  ; 0x1000:0x0000로 점프

.HANDLEDISKERROR:  ; 디스크 에러를 처리하는 함수

    push DISKERRORMESSAGE  ; 에러 메시지의 어드레스를 스택에 삽입
    push 3  ; 스택에 Y좌표(3) 삽입
    push 20  ; 스택에 X좌표(20) 삽입
    call .PRINTMESSAGE  ; .PRINTMESSAGE함수 호출
    ass sp, 6  ; 삽입한 파라미터 제거

    jmp $  ; 현재 주소로 점프(무한 루프)

.PRINTMESSAGE:  ; 메시지를 출력하는 함수
    ; PARAM(매개변수)  ; X좌표, Y좌표, 문자열
    push bp  ; 베이스 포인터 레지스터(bp)를 스택에 삽입
    mov bp, sp  ; bp에 sp의 값을 설정
                ; bp를 사용하여 스택 포인트에 접근할 예정

    push es  ; es세그먼트 레지스터부터 dx레지스터까지 스택에 삽입
    push si   ; 함수에서 임시로 사용하는 레지스터로 함수의 마지막 부분에서
    push di  ; 스택에 삽입된 값을 꺼내어 원래 값으로 복원
    push ax
    push cx
    push dx

    mov ax, 0xB800  ; ax를 비디오 메모리 시작 어드레스(0x0B8000)로 변환
    mov es, ax  ; es세그먼트 레지스터에 설정

    mov ax, word[ bp + 6 ]  ; 파라미터 2(화면좌표 Y)를 ax레지스터에 설정
    mov si, 160  ; 한 라인의 바이트 수(2*80컬럼)를 si에 설정
    mul si  ; ax와 si를 곱하여 화면 Y어드레스 계산
    mov di, ax  ; 계산된 화면 Y어드레스를 di에 설정

    mov ax, word[ bp + 4 ]  ; 파라미터 1(화면좌표 X)를 ax레지스터에 설정
    mov si, 2  ; 한 문자를 나타내는 바이트 수(2)를 si에 설정
    mul si  ; ax와 si를 곱하여 화면 X어드레스 계산
    add di, ax  ; 화면 Y어드레스와 계산된 X어드레스를 더하여 실제 비디오 메모리 어드레스를 계산

    mov si, word[ bp + 8 ]  ; 파라미터 3(출력할 문자열의 어드레스)

.MESSAGELOOP:  ; 문자 출력을 위한 LOOP
    mov cl, byte [ si ]  ; si 레지스터의 값(출력할 문자가 있는 주소)를 cl 레지스터에 복사
                         ; cl은 cx의 하위 1byte를 의미
                         ; 문자는 1byte만 필요하므로 cx의 하위 1byte만 사용
    cmp cl, 0  ; cl이 0(0x00(NULL))인가?
    je .MESSAGEEND  ; CL == 0일 경우, .MESSAGEEND로 점프한다.

    mov byte [ es : di ], cl  ; ES:DI(0xB800)가 가르키는 비디오 메모리에 cl에 있는 문자를 복사.
    add si, 1  ; 다음 문자를 가져오기 위하여 SI에 1을 증가.
    add di, 2  ; 다음 문자를 출력하기 위하여 DI에 2를 증가.
    jmp .MESSAGELOOP  ; 문자출력 반복

.MESSAGEEND:
    pop dx  ; 함수에서 사용이 끝난 dx부터 es까지를 스택에 삽인된 값을 이용하여 복원
    pop cx  ; 스택에 가장 마지막에 들어간 데이터가 가장 먼저 나오는
    pop ax  ; 자료구조(Last-In, First-Out)이므로 삽입(push)의 역순으로 제거(pop) 해야함
    pop di
    pop si
    pop es
    pop bp  ; 베이스 포인터 레지스터(bp) 복원
    ret  ; 함수를 호출한 다음 코드의 위치로 복귀

MESSAGE1:
    db ‘Message1’, 0  ; 출력하고자 하는 문장 정의

MESSAGE1:
    db ‘Message2’, 0  ; 출력하고자 하는 문장 정의

DISKERRORMESSAGE:
    db ‘Error’, 0  ; 에러 메시지

IMAGELOADINGMESSAGE:
    db ‘Loading…’, 0  ; OS 이미지 로딩 메시지

LOADINGCOMPLETEMESSAGE:
    db ‘Complete’ ,0  ; OS 이미지 로딩 완료 메시지

; 디스크 읽기에 관련된 변수
SECTORNUMBER:
    db 0x02  ; OS이미지가 시작하는 섹터번호를 저장하는 영역

HEADNUMBER:
    db 0x00  ; 헤드번호

TRACKNUMBER:
    db 0x00  ; 트랙번호

times 510 - ( $ - $$ ) db 0x00  ; $(현재주소에서) $$(처음 시작주소)를 뺀 주소까지 0으로 채움.

db 0x55  ; 511번지에 55를 채움.

db0xAA  ; 512번지에 AA를 채움.

; add sp, 6 //스택에 6개의 레지스터의 값을 넣어주게 되는데, 문자가 출력되는 동안 값이 계속 바뀌기 때문에 sp(stack point)에 6을 더하여 값이 변환된 6개의 레지스터 다음 부분에 sp를 지정한다.

; 삽입된 파라미터를 제거한다고 생각하면 편함.

; mov byte [ SECTORNUMBER ], al  //  SECTORNUMBER에 al의 1byte의 값만 들어간다.

; mov cl, byte [ SECTORNUMBER ]  // cl에 1byte의 SECTORNUMBER 값이 들어간다.