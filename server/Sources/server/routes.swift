import NIOCore
import Vapor

struct ClientCommand: Decodable {
    let type: String
    /*
     Examples:
     {"type":"subscribe"}
     {"type":"unsubscribe"}
    */
}

struct ServerMessage: Encodable {
    let type: String
    let message: String?
    let data: [String]?
    /*
     Examples:
     {"type":"ack","message":"subscribed"}
     {"type":"data","data":["192.168.2.1","192.168.2.120"]}
     {"type":"ack","message":"unsubscribed"}
     */
}

func routes(_ app: Application) throws {
    app.webSocket("data") { _, ws in
        /*
         It is safe to mark this with `@unchecked Sendable` because all WebSocket
         callbacks (for a single connection) run on the same event loop thread.
         Each event loop is single-threaded and processes events serially,
         preventing concurrent access to `state`.
        
         Without this, the compiler raises:
         Capture of 'state' with non-Sendable type 'WebSocketState' in a '@Sendable' closure
         */
        class WebSocketState: @unchecked Sendable {
            var periodicTask: RepeatedTask?
        }

        let state = WebSocketState()

        ws.onText { ws, text in
            print("received: \(text)")
            let jsonData = text.data(using: .utf8)!

            do {
                let clientCommand = try JSONDecoder().decode(
                    ClientCommand.self,
                    from: jsonData
                )

                if clientCommand.type == "subscribe" {
                    let ack = ServerMessage(
                        type: "ack",
                        message: "subscribed",
                        data: nil
                    )
                    if let ackData = try? JSONEncoder().encode(ack),
                        let ackString = String(data: ackData, encoding: .utf8)
                    {
                        ws.send(ackString)
                    }

                    state.periodicTask?.cancel()

                    let interval = TimeAmount.seconds(10)
                    state.periodicTask = ws.eventLoop.scheduleRepeatedTask(
                        initialDelay: interval,
                        delay: interval
                    ) { task in
                        let hosts = scanNetwork(subnet: "192.168.2.0/24")
                        let hostData = hosts.map { $0.ip }
                        let data = ServerMessage(
                            type: "data",
                            message: nil,
                            data: hostData
                        )
                        if let dataData = try? JSONEncoder().encode(data),
                            let dataString = String(
                                data: dataData,
                                encoding: .utf8
                            )
                        {
                            ws.send(dataString)
                        } else {
                            return task.cancel()
                        }
                    }
                } else if clientCommand.type == "unsubscribe" {
                    state.periodicTask?.cancel()
                    let ack = ServerMessage(
                        type: "ack",
                        message: "unsubscribed",
                        data: nil
                    )
                    if let ackData = try? JSONEncoder().encode(ack),
                        let ackString = String(data: ackData, encoding: .utf8)
                    {
                        ws.send(ackString)
                    }
                }
            } catch {
                let error = ServerMessage(
                    type: "error",
                    message: error.localizedDescription,
                    data: nil
                )
                if let errorData = try? JSONEncoder().encode(error),
                    let errorString = String(
                        data: errorData,
                        encoding: .utf8
                    )
                {
                    ws.send(errorString)
                }
            }
        }
    }
}
