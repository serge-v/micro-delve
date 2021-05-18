build:
	sudo docker build . -t delve

run:
	sudo docker run --cap-add=SYS_PTRACE -it delve bash
