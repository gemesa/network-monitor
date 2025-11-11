struct ServerMessage: Encodable {
    let type: String
    let message: String?
    let data: [NmapHost]?
    /*
     Examples:
     {"type":"ack","message":"subscribed"}
     {"type":"data","data":[{"ip":"192.168.2.1","mac":"XX:XX:XX:XX:XX:XX","hostname":"horus.lan"}]}
     {"type":"ack","message":"unsubscribed"}
     */
}
