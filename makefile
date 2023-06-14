all: BootLoader Disk.img  //BootLoader와 Disk.img라는 실행파일 생성

# all: - 실행 파일을 여러 개 생성할 때 사용.

BootLoader:
	@echo
	@echo ===== Build Boot Loader ===== 
	@echo

	make -C 00.BootLoader 	//makefile을 계속 읽지 말고, 우선 00.BootLoader파일로 이동

	@echo
	@echo ===== Build Complete =====
	@echo

Disk.img: 00.BootLoader/BootLoader.bin 
	@echo
	@echo ===== Build Disk Image ===== 
	@echo

	cp 00.BootLoader/BootLoader.bin Disk.img  //00.BootLoader/BootLoader.bin 파일을 Disk.img로 복사

	@echo
	@echo ===== Build Complete =====
	@echo

clean:
	make -C 00.BootLodaer clean  //00.BootLoader로 이동 후, clean 실행
	rm -f Disk.img  //Disk.img 파일 삭제