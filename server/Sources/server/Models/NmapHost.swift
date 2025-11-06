struct NmapHost: Encodable, Equatable {
    var ip: String
    var mac: String?
    var hostname: String?
}
