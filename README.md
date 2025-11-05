# network-monitor

A network monitoring system that scans the LAN and streams device information to connected clients via WebSockets.

## Features

- Server (macOS): scans the LAN using `nmap -sn` (ping scan) and broadcasts discovered devices to clients via WebSockets (Swift)
- TODO: clients

## Requirements

- macOS 15.6+
- Xcode 26.0.1+

## Usage

Server:

```
$ sudo ./build/Build/Products/Debug/server
[ NOTICE ] Server started on http://127.0.0.1:8080
[ INFO ] GET /data [request-id: F2180912-62D8-4BEF-AB5E-02B8F83B0741]
received: {"type":"subscribe"}

sent: {"type":"ack","message":"subscribed"}
sent: {"type":"data","data":["192.168.2.1","192.168.2.120","192.168.2.141","192.168.2.173","192.168.2.202","192.168.2.234","192.168.2.243"]}
received: {"type":"unsubscribe"}

sent: {"message":"unsubscribed","type":"ack"}
```

Client:

```
$ websocat ws://127.0.0.1:8080/data                       
{"type":"subscribe"}
{"type":"ack","message":"subscribed"}
{"type":"data","data":["192.168.2.1","192.168.2.120","192.168.2.141","192.168.2.173","192.168.2.202","192.168.2.234","192.168.2.243"]}
{"type":"unsubscribe"}
{"message":"unsubscribed","type":"ack"}
```

## Command cheatsheet

### Server

#### Build

```
$ xcodebuild build -scheme server -derivedDataPath build -destination 'platform=macOS,arch=arm64' -quiet
```

#### Run

```
$ sudo ./build/Build/Products/Debug/server
```

#### Format Swift

```
$ brew install swift-format
$ swift-format -i -r Sources/
```

#### Lint Swift

```
$ brew install swiftlint
$ swiftlint --strict Sources/
```
