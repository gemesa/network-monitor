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
    let data: [NmapHost]?
    /*
     Examples:
     {"type":"ack","message":"subscribed"}
     {"type":"data","data":[{"ip":"192.168.2.1","mac":"XX:XX:XX:XX:XX:XX","hostname":"horus.lan"}]}
     {"type":"ack","message":"unsubscribed"}
     */
}

func routes(_ app: Application) throws {
    app.webSocket("data") { _, ws in
        let scanner = NetworkScanner()

        /*
         It is safe to mark this with `@unchecked Sendable` because all WebSocket
         callbacks (for a single connection) run on the same event loop thread.
         Each event loop is single-threaded and processes events serially,
         preventing concurrent access to `state`.
        
         Without this, the compiler raises:
         Capture of 'state' with non-Sendable type 'WebSocketState' in a '@Sendable' closure
         */
        class WebSocketState: @unchecked Sendable {
            var subscriptionId: UUID?
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
                    guard state.subscriptionId == nil else { return }

                    // This task is not executed on the event loop.
                    Task {
                        let id = await scanner.subscribe { hostData in
                            let data = ServerMessage(
                                type: "data",
                                message: nil,
                                data: hostData
                            )

                            guard let dataData = try? JSONEncoder().encode(data),
                                let dataString = String(
                                    data: dataData,
                                    encoding: .utf8
                                )
                            else {
                                return
                            }

                            // WebSocket operations must run on the event loop thread.
                            ws.eventLoop.execute {
                                ws.send(dataString)
                                print("sent: \(dataString)")
                            }
                        }
                        ws.eventLoop.execute {
                            print("subscribed with id: \(id)")
                            // We promised Swift that all access to `state` happens on one thread,
                            // so we need to execute this on the event loop.
                            state.subscriptionId = id

                            let ack = ServerMessage(
                                type: "ack",
                                message: "subscribed",
                                data: nil
                            )
                            if let ackData = try? JSONEncoder().encode(ack),
                                let ackString = String(data: ackData, encoding: .utf8)
                            {
                                // WebSocket operations must run on the event loop thread.
                                ws.send(ackString)
                                print("sent: \(ackString)")
                            }
                        }
                    }
                } else if clientCommand.type == "unsubscribe" {
                    if let id = state.subscriptionId {
                        Task {
                            await scanner.unsubscribe(id: id)
                        }
                        state.subscriptionId = nil
                    }
                    let ack = ServerMessage(
                        type: "ack",
                        message: "unsubscribed",
                        data: nil
                    )
                    if let ackData = try? JSONEncoder().encode(ack),
                        let ackString = String(data: ackData, encoding: .utf8)
                    {
                        ws.send(ackString)
                        print("sent: \(ackString)")
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
                    print("sent: \(errorString)")
                }
            }
        }
        ws.onClose.whenComplete { _ in
            if let id = state.subscriptionId {
                Task {
                    await scanner.unsubscribe(id: id)
                }
                print("connection closed: \(id)")
                state.subscriptionId = nil
            }
        }
    }
}
