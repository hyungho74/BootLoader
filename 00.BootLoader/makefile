all: BootLoader.bin //BootLoader.bin이라는 실행파일 생성

BootLoader.bin: BootLoader.asm  //make할 때, BootLoader.asm을 사용함.
	nasm -o BootLoader.bin BootLoader.asm  //BootLoader.asm 파일을 실행한 후, BootLoader.bin v파일을 생성

clean:
	rm -f BootLoader.bin  //BootLoader.bin 파일 삭제