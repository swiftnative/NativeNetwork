//
//  URLRequest+.swift
//  NativeNetworking
//
//  Created by Alexey Nenastev on 8.6.24..
//

import Foundation
import HTTPTypes

extension URLRequest {

  struct Config {
    public var host: String = defaultHost
    public var path: String = ""
    public var urlParams: [String: String] = [:]
    public var bodyParams: [String: Any] = [:]
    public var method: HTTPRequest.Method = .get
    public var headers = HTTPFields()
    public var timeoutInterval: TimeInterval?
    public var options: JSONSerialization.WritingOptions = []

    public static var defaultHost: String = "https://swiftnative.com"
  }

  static func with(
    _ config: Config = .init(),
    _ configurate: (inout Config) -> Void
  ) -> URLRequest {
    var config = config
    configurate(&config)
    return with(config: config)
  }

  /// Build URLRequest with config
  private static func with(config: Config) -> URLRequest {


    let separator = config.host.last != "/" && config.path.first != "/" ? "/" : ""

    let url = config.host + separator + config.path

    guard var components = URLComponents(string: url) else {
      fatalError("You provide incorrect URL components host+path: \(url)")
    }

    if !config.urlParams.isEmpty {
      components.queryItems = config.urlParams.map { URLQueryItem(name: $0.key, value: $0.value) }
    }

    guard let url = components.url else {
      fatalError("You provide incorrect URL components host:\(config.host) path: \(config.path)")
    }

    var request = URLRequest(url: url)
    request.httpMethod = config.method.rawValue

    if let timeoutInterval = config.timeoutInterval {
      request.timeoutInterval = timeoutInterval
    }

    if !config.bodyParams.isEmpty,
       let jsonData = try? JSONSerialization.data(withJSONObject: config.bodyParams, options: config.options) {
      request.httpBody = jsonData
    }

    request.allHTTPHeaderFields = config.headers.dictionary

    return request
  }

  /// Set header authorization "Bearer <token>"
  public mutating func set(authorization token: String) {
    setValue("Bearer \(token)", forHTTPHeaderField: HTTPField.Name.authorization.rawName)
  }
}


private extension HTTPFields {
  var dictionary: [String: String] {
    var combinedFields = [HTTPField.Name: String](minimumCapacity: self.count)
    for field in self {
      if let existingValue = combinedFields[field.name] {
        let separator = field.name == .cookie ? "; " : ", "
        combinedFields[field.name] = "\(existingValue)\(separator)\(field.isoLatin1Value)"
      } else {
        combinedFields[field.name] = field.isoLatin1Value
      }
    }
    var headerFields = [String: String](minimumCapacity: combinedFields.count)
    for (name, value) in combinedFields {
      headerFields[name.rawName] = value
    }
    return headerFields
  }
}

private extension HTTPField {
  var isoLatin1Value: String {
    if self.value.isASCII {
      return self.value
    } else {
      return self.withUnsafeBytesOfValue { buffer in
        let scalars = buffer.lazy.map { UnicodeScalar(UInt32($0))! }
        var string = ""
        string.unicodeScalars.append(contentsOf: scalars)
        return string
      }
    }
  }
}

private extension String {
  var isASCII: Bool {
    self.utf8.allSatisfy { $0 & 0x80 == 0 }
  }
}