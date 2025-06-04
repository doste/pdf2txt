import Vapor
import Leaf

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    /// config max upload file size
    app.routes.defaultMaxBodySize = "10mb"

    // register routes
    try routes(app)

    app.views.use(.leaf)
}
