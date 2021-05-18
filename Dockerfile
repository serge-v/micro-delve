FROM golang:1.16

RUN go install github.com/go-delve/delve/cmd/dlv@latest

RUN git clone https://github.com/zyedidia/micro && \
	cd micro && \
	make build && \
	mv micro /usr/local/bin

RUN mkdir -p /root/.config/micro/plug/micro-delve

#RUN cd /root/.config/micro/plug && git clone https://github.com/serge-v/micro-delve

COPY repo.json *.go *.lua /root/.config/micro/plug/micro-delve/
COPY config.json /root/.config/micro/settings.json

WORKDIR micro/cmd/micro
RUN echo b main.main > init.txt
RUN echo continue >> init.txt
RUN echo dlv output > /tmp/delve-runner.log
