import Vapor

func routes(_ app: Application) throws {
    let controller = DataWebSocketController()
    app.webSocket("data", onUpgrade: controller.handle)
}
