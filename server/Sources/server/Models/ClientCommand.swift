struct ClientCommand: Decodable {
    let type: String
    /*
     Examples:
     {"type":"subscribe"}
     {"type":"unsubscribe"}
    */
}
