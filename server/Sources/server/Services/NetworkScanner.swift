import Foundation

func scanNetwork(subnet: String) -> [NmapHost] {
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
