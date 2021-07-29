.PHONY:build
build:
		wg genkey | tee privatekey | wg pubkey > wireguard/peer-publickey
		terraform plan
