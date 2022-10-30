//
//  Network.swift
//  cutjs
//
//  Created by Dan on 6/21/22.
//

import Foundation

struct Net {
    
    enum Error: Swift.Error {
        case unknown
        case invalidResponse
    }
    
    struct Result {
        var status: Int
        var output: Any?
        var data: Data?
        var dataString: String?
        var responseHeaders: [AnyHashable : Any]
    }
    
    struct URL: ExpressibleByStringInterpolation, CustomStringConvertible {
        
        enum Error: Swift.Error {
            case invalidURL
        }
        
        let string: String
        
        let parameters: [String: String]
        
        init(_ string: String, parameters: [String: String] = [:]) {
            self.string = string
            self.parameters = parameters
        }
        
        func toURL() throws -> Foundation.URL {
            guard var urlComps = URLComponents(string: self.string) else {
                throw URL.Error.invalidURL
            }
            
            let queryItems = self.parameters.map { URLQueryItem(name: $0, value: $1) }
            urlComps.queryItems = queryItems
            
            guard let url = urlComps.url else {
                throw URL.Error.invalidURL
            }
            return url
        }
        
        init(stringLiteral: StringLiteralType) {
            self.init(stringLiteral)
        }
        
        var description: String {
            let url = try? self.toURL()
            return url?.absoluteString ?? self.string
        }
        
    }
    
    static func `get`(url: Net.URL, headers: [String: Any] = [:]) async throws -> Net.Result {
        return try await fetch(method: "GET", url: url, headers: headers)
    }
    
    static func post(url: Net.URL, headers: [String: Any] = [:], body: Any? = nil) async throws -> Net.Result {
        return try await fetch(method: "POST", url: url, headers: headers, body: body)
    }
    
    private static func fetch(method: String, url: Net.URL, headers: [String: Any] = [:], body: Any? = nil) async throws -> Net.Result {
        var finalHeaders = headers
        var request = URLRequest(url: try url.toURL())
        request.httpMethod = method
        
        if let body = body {
            if JSONSerialization.isValidJSONObject(body) {
                request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
                if let body = request.httpBody {
                    finalHeaders["Content-Length"] = "\(body.count)"
                    finalHeaders["Content-Type"] = "application/vnd.api+json"
                }
            }
            else if let body = body as? Data {
                request.httpBody = body
            }
            else {
                request.httpBody = "\(body)".data(using: .utf8)
            }
        }
        
        for (key, value) in finalHeaders as? [String: String] ?? [:] {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let dataResult = try await URLSession.shared.data(for: request)
        let httpResponse = dataResult.1 as? HTTPURLResponse
        return Result(status: httpResponse?.statusCode ?? 0,
                            output: parse(data: dataResult.0, response: httpResponse),
                            data:  dataResult.0,
                            dataString: String(data: dataResult.0, encoding: .utf8),
                            responseHeaders: httpResponse?.allHeaderFields ?? [:])
    }
    
    private static func parse(data: Data?, response: HTTPURLResponse?) -> Any? {
        guard let data = data, let response = response else {
            return nil
        }
        
        let contentType = (response.allHeaderFields as? [String: Any])?[caseInsensitive: "content-type"] as? String ?? ""
        
        if contentType.contains("/json") || contentType.contains("+json") {
            return try? JSONSerialization.jsonObject(with: data, options: [])
        }
        
        if contentType.contains("/data") || contentType.contains("+data") {
            return data
        }
        
        return String(data: data, encoding: .utf8)
    }
}
