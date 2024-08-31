// based on: https://github.com/swiftlang/swift/blob/60dc7cda12c524b87ce886de8a778fecd3a667c5/stdlib/public/core/Result.swift

//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import CasePaths

/// A value that represents the absence of a value , the loading of a value, a success or a
/// failure, including an associated value for the success and failure cases.
@dynamicMemberLookup @CasePathable public enum RemoteResult<Success, Failure: Error> {
  /// A success, storing a `Success` value.
  case success(Success)

  /// A failure, storing a `Failure` value.
  case failure(Failure)

  /// The value is loading.
  case loading

  /// The initial value.
  case initial

  /// Returns a new remote result, mapping any success value using the given
  /// transformation.
  ///
  /// Use this method when you need to transform the value of a `RemoteResult`
  /// instance when it represents a success. The following example transforms
  /// the integer success value of a remote result into a string:
  ///
  ///     func getNextInteger() -> RemoteResult<Int, Error> { /* ... */ }
  ///
  ///     let integerRemoteResult = getNextInteger()
  ///     // integerRemoteResult == .success(5)
  ///     let stringRemoteResult = integerRemoteResult.map { String($0) }
  ///     // stringRemoteResult == .success("5")
  ///
  /// - Parameter transform: A closure that takes the success value of this
  ///   instance.
  /// - Returns: A `RemoteResult` instance with the remote result of evaluating `transform`
  ///   as the new success value if this instance represents a success.
  @inlinable public func map<NewSuccess>(_ transform: (Success) -> NewSuccess) -> RemoteResult<
    NewSuccess, Failure
  > {
    switch self {
    case let .success(success): .success(transform(success))
    case let .failure(failure): .failure(failure)
    case .loading: .loading
    case .initial: .initial
    }
  }

  /// Returns a new remote result, mapping any failure value using the given
  /// transformation.
  ///
  /// Use this method when you need to transform the value of a `RemoteResult`
  /// instance when it represents a failure. The following example transforms
  /// the error value of a remote result by wrapping it in a custom `Error` type:
  ///
  ///     struct DatedError: Error {
  ///         var error: Error
  ///         var date: Date
  ///
  ///         init(_ error: Error) {
  ///             self.error = error
  ///             self.date = Date()
  ///         }
  ///     }
  ///
  ///     let remote result: RemoteResult<Int, Error> = // ...
  ///     // remote result == .failure(<error value>)
  ///     let remote resultWithDatedError = remote result.mapError { DatedError($0) }
  ///     // remote result == .failure(DatedError(error: <error value>, date: <date>))
  ///
  /// - Parameter transform: A closure that takes the failure value of the
  ///   instance.
  /// - Returns: A `RemoteResult` instance with the remote result of evaluating `transform`
  ///   as the new failure value if this instance represents a failure.
  @inlinable public func mapError<NewFailure>(_ transform: (Failure) -> NewFailure) -> RemoteResult<
    Success, NewFailure
  > {
    switch self {
    case let .success(success): .success(success)
    case let .failure(failure): .failure(transform(failure))
    case .loading: .loading
    case .initial: .initial
    }
  }

  /// Returns a new remote result, mapping any success value using the given
  /// transformation and unwrapping the produced remote result.
  ///
  /// Use this method to avoid a nested remote result when your transformation
  /// produces another `RemoteResult` type.
  ///
  /// In this example, note the difference in the remote result of using `map` and
  /// `flatMap` with a transformation that returns a remote result type.
  ///
  ///     func getNextInteger() -> RemoteResult<Int, Error> {
  ///         .success(4)
  ///     }
  ///     func getNextAfterInteger(_ n: Int) -> RemoteResult<Int, Error> {
  ///         .success(n + 1)
  ///     }
  ///
  ///     let remote result = getNextInteger().map { getNextAfterInteger($0) }
  ///     // remote result == .success(.success(5))
  ///
  ///     let remote result = getNextInteger().flatMap { getNextAfterInteger($0) }
  ///     // remote result == .success(5)
  ///
  /// - Parameter transform: A closure that takes the success value of the
  ///   instance.
  /// - Returns: A `RemoteResult` instance, either from the closure or the previous
  ///   `.failure`.
  @inlinable public func flatMap<NewSuccess>(
    _ transform: (Success) -> RemoteResult<NewSuccess, Failure>
  ) -> RemoteResult<NewSuccess, Failure> {
    switch self {
    case let .success(success): transform(success)
    case let .failure(failure): .failure(failure)
    case .loading: .loading
    case .initial: .initial
    }
  }

  /// Returns a new remote result, mapping any failure value using the given
  /// transformation and unwrapping the produced remote result.
  ///
  /// - Parameter transform: A closure that takes the failure value of the
  ///   instance.
  /// - Returns: A `RemoteResult` instance, either from the closure or the previous
  ///   `.success`.
  @inlinable public func flatMapError<NewFailure>(
    _ transform: (Failure) -> RemoteResult<Success, NewFailure>
  ) -> RemoteResult<Success, NewFailure> {
    switch self {
    case let .success(success): .success(success)
    case let .failure(failure): transform(failure)
    case .loading: .loading
    case .initial: .initial
    }
  }
}

extension RemoteResult {
  public init(_ result: Result<Success, Failure>) {
    switch result {
    case let .success(success): self = .success(success)
    case let .failure(failure): self = .failure(failure)
    }
  }

  /// Creates a new remote result by evaluating a throwing closure, capturing the
  /// returned value as a success, or any thrown error as a failure.
  ///
  /// - Parameter body: A potentially throwing closure to evaluate.
  @inlinable public func toOptional() -> Success? {
    switch self {
    case let .success(success): success
    case .failure, .loading, .initial: nil
    }
  }
}

extension RemoteResult: Equatable where Success: Equatable, Failure: Equatable {}

extension RemoteResult: Hashable where Success: Hashable, Failure: Hashable {}

extension RemoteResult: Sendable where Success: Sendable {}

extension RemoteResult: Codable where Success: Codable, Failure: Codable {
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    switch self {
    case let .success(successValue): try container.encode(successValue, forKey: .success)
    case let .failure(failureValue): try container.encode(failureValue, forKey: .failure)
    case .loading: try container.encode(true, forKey: .loading)
    case .initial: try container.encode(true, forKey: .initial)
    }
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    if let successValue = try? container.decode(Success.self, forKey: .success) {
      self = .success(successValue)
    } else if let failureValue = try? container.decode(Failure.self, forKey: .failure) {
      self = .failure(failureValue)
    } else if container.contains(.loading) {
      self = .loading
    } else if container.contains(.initial) {
      self = .initial
    } else {
      let context = DecodingError.Context(
        codingPath: decoder.codingPath,
        debugDescription: "Data does not match any case of RemoteResult"
      )

      throw DecodingError.dataCorrupted(context)
    }
  }

  private enum CodingKeys: String, CodingKey {
    case success
    case failure
    case loading
    case initial
  }
}
