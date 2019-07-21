#
# Socks My VPN
# 

#
# GoBuilder machine, build the SOCKS server and 
# save for later
#
FROM golang:alpine as builder

RUN echo "Configuring the apk"						&&\
	apk update 										&&\
	apk add --update --no-cache git

WORKDIR /opt/socks-ovpn
COPY . .
RUN go build -mod=vendor -o /go/bin/socks-my-vpn


#
# Build the Socks-My-VPN image starting from scratch
#
FROM alpine:latest
COPY --from=builder /go/bin/socks-my-vpn /socks/server
COPY socks.sh /socks/

RUN echo "Configuring the apk"						&&\
	apk update										&&\
	apk add --update --no-cache	\
				openvpn bash openresolv curl		&&\
	rm -rf /tmp/* /var/cache/apk/* 					&&\
	chmod a+x /socks/server /socks/socks.sh 		&&\
	wget -O /etc/openvpn/update-resolv-conf https://raw.githubusercontent.com/masterkorp/openvpn-update-resolv-conf/master/update-resolv-conf.sh &&\
	chmod +x /etc/openvpn/update-resolv-conf &&\
	sysctl net.ipv6.conf.all.disable_ipv6=0 &&\
	echo "Done."


HEALTHCHECK --interval=60s --timeout=15s 			\
			--start-period=120s 					\
			CMD curl -L 'https://ifconfig.co'

VOLUME ["/vpn"]

ENTRYPOINT [ \
    "/bin/bash", "-c", \
    "/socks/socks.sh && cd /vpn/ && /usr/sbin/openvpn --config /vpn/*.ovpn " \
]


