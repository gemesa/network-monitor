# network-monitor

A network monitoring system that scans the LAN and streams device information to connected clients via WebSockets.

## Features

- Server (macOS): scans the LAN using `nmap -sn` (ping scan) and broadcasts discovered devices to clients via WebSockets (Swift)
- TODO: clients

## Requirements

- macOS 15.6+
- Xcode 26.0.1+

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
