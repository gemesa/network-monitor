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
    let task = Task.detached { () -> [NmapHost] in
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/nmap")
        process.arguments = ["-sn", subnet, "-oX", "-"]
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        do {
            try process.run()
            let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else {
                let errorMessage = String(data: stderrData, encoding: .utf8) ?? "Unknown error"
                print("nmap failed with status: \(process.terminationStatus)")
                print("nmap stderr: \(errorMessage)")
                return []
            }

            return NmapXMLParser().parse(data: stdoutData)
        } catch {
            print("Failed to run nmap: \(error)")
            return []
        }
    }
    let hosts = await task.value
    return hosts
}
