import NIOCore
import Vapor

/*
 It is safe to mark this with `@unchecked Sendable` because all WebSocket
 callbacks (for a single connection) run on the same event loop thread.
 Each event loop is single-threaded and processes events serially,
 preventing concurrent access to `state`.
 */
class WebSocketState: @unchecked Sendable {
    var subscriptionId: UUID?
}

final class DataWebSocketController: Sendable {
    private let scanner: NetworkScanner

    init(scanner: NetworkScanner = NetworkScanner()) {
        self.scanner = scanner
    }

    func handle(_ req: Request, _ ws: WebSocket) {
        let state = WebSocketState()

        ws.onText { ws, text in
            self.handleMessage(ws: ws, text: text, state: state)
        }

        ws.onClose.whenComplete { _ in
            self.handleClose(ws: ws, state: state)
        }

    }

    private func handleMessage(ws: WebSocket, text: String, state: WebSocketState) {
        print("received: \(text)")

        guard let jsonData = text.data(using: .utf8) else {
            sendError(ws: ws, message: "Invalid text encoding")
            return
        }

        do {
            let clientCommand = try JSONDecoder().decode(ClientCommand.self, from: jsonData)
            switch clientCommand.type {
            case "subscribe":
                handleSubscribe(ws: ws, state: state)
            case "unsubscribe":
                handleUnsubscribe(ws: ws, state: state)
            default:
                sendError(ws: ws, message: "Unknown command type: \(clientCommand.type)")
            }
        } catch {
            sendError(ws: ws, message: error.localizedDescription)
        }
    }

    private func handleSubscribe(ws: WebSocket, state: WebSocketState) {
        guard state.subscriptionId == nil else { return }

        // This task is not executed on the event loop.
        Task {

            let id = await scanner.subscribe { hostData in
                ws.eventLoop.execute {
                    // WebSocket operations must run on the event loop thread.
                    self.sendDataMessage(ws: ws, hostData: hostData)
                }
            }

            ws.eventLoop.execute {
                print("subscribed with id: \(id)")
                // We promised Swift that all access to `state` happens on one thread,
                // so we need to execute this on the event loop.
                state.subscriptionId = id
                // WebSocket operations must run on the event loop thread.
                self.sendAckMessage(ws: ws, message: "subscribed")
            }
        }
    }

    private func handleUnsubscribe(ws: WebSocket, state: WebSocketState) {
        if let id = state.subscriptionId {
            Task {
                await scanner.unsubscribe(id: id)
            }
            print("unsubscribed with id: \(id)")
            state.subscriptionId = nil
        }
        sendAckMessage(ws: ws, message: "unsubscribed")
    }

    private func handleClose(ws: WebSocket, state: WebSocketState) {
        if let id = state.subscriptionId {
            Task {
                await scanner.unsubscribe(id: id)
            }
            print("connection closed: \(id)")
            state.subscriptionId = nil
        }
    }

    private func sendDataMessage(ws: WebSocket, hostData: [NmapHost]) {
        let data = ServerMessage(
            type: "data",
            message: nil,
            data: hostData
        )

        sendMessage(ws: ws, message: data)
    }

    private func sendAckMessage(ws: WebSocket, message: String) {
        let ack = ServerMessage(
            type: "ack",
            message: message,
            data: nil
        )

        sendMessage(ws: ws, message: ack)
    }

    private func sendError(ws: WebSocket, message: String) {
        let error = ServerMessage(
            type: "error",
            message: message,
            data: nil
        )

        sendMessage(ws: ws, message: error)
    }

    private func sendMessage(ws: WebSocket, message: ServerMessage) {
        guard let messageData = try? JSONEncoder().encode(message),
            let messageString = String(data: messageData, encoding: .utf8)
        else {
            print("Failed to encode message")
            return
        }
        ws.send(messageString)
        print("sent: \(messageString)")
    }
}
