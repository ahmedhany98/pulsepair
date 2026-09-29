import Foundation

struct HTTPStatusError: LocalizedError {
    let status: Int
    var errorDescription: String? { "The server returned HTTP \(status)." }
}

enum API {
    static let baseURL = URL(string: "https://dummyjson.com")!
    static var accessToken: String?

    static func get<T: Decodable>(_ path: String) async throws -> T {
        try await send(request(path, method: "GET"))
    }

    static func post<T: Decodable, Body: Encodable>(_ path: String, body: Body) async throws -> T {
        var request = request(path, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return try await send(request)
    }

    static func status(_ path: String) async throws -> Int {
        let (_, response) = try await URLSession.shared.data(for: request(path, method: "GET"))
        return (response as? HTTPURLResponse)?.statusCode ?? 0
    }

    private static func request(_ path: String, method: String) -> URLRequest {
        var request = URLRequest(url: URL(string: path, relativeTo: baseURL)!)
        request.httpMethod = method
        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private static func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else { throw HTTPStatusError(status: status) }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

struct LoginRequest: Encodable {
    let username: String
    let password: String
    let expiresInMins: Int
}

struct Clinician: Decodable {
    let id: Int
    let username: String
    let email: String
    let firstName: String
    let lastName: String
    let accessToken: String
}

struct SessionPost: Decodable, Identifiable {
    let id: Int
    let title: String
    let body: String
    let userId: Int
}

struct SessionPostList: Decodable {
    let posts: [SessionPost]
}

struct NewSessionPost: Encodable {
    let title: String
    let body: String
    let userId: Int
}

struct Patient: Decodable {
    struct Address: Decodable {
        let address: String
        let city: String
        let state: String
        let postalCode: String
    }

    struct Bank: Decodable {
        let cardNumber: String
        let cardExpire: String
        let cardType: String
        let iban: String
    }

    let id: Int
    let firstName: String
    let lastName: String
    let email: String
    let phone: String
    let birthDate: String
    let bloodGroup: String
    let ssn: String
    let address: Address
    let bank: Bank
}
