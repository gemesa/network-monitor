import Foundation

actor NetworkScanner {
    private var latestHosts: [NmapHost] = []
    private var scanTask: Task<Void, Never>?
    private var subscribers: [UUID: ([NmapHost]) -> Void] = [:]

    func getLatestHosts() -> [NmapHost] {
        latestHosts
    }

    func subscribe(callback: @escaping ([NmapHost]) -> Void) -> UUID {
        let id = UUID()
        subscribers[id] = callback

        if subscribers.count == 1 {
            startScanning()
        }

        if !latestHosts.isEmpty {
            callback(latestHosts)
        }

        return id
    }

    func unsubscribe(id: UUID) {
        subscribers.removeValue(forKey: id)

        if subscribers.isEmpty {
            stopScanning()
        }
    }

    func startScanning() {
        guard scanTask == nil else { return }

        scanTask = Task {
            while !Task.isCancelled {
                latestHosts = await scanNetwork(subnet: "192.168.2.0/24")

                notifySubscribers()

                try? await Task.sleep(nanoseconds: 10_000_000_000)
            }
        }
    }

    func stopScanning() {
        scanTask?.cancel()
        scanTask = nil
    }

    func notifySubscribers() {
        for callback in subscribers.values {
            callback(latestHosts)
        }
    }
}

func scanNetwork(subnet: String) async -> [NmapHost] {
    let task = Task.detached {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/nmap")
        process.arguments = ["-sn", subnet, "-oX", "-"]
        let pipe = Pipe()
        process.standardOutput = pipe
        try? process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        return NmapXMLParser().parse(data: data)
    }
    let hosts = await task.value
    return hosts
}
