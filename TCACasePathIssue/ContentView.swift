import ComposableArchitecture
import SwiftUI

@Reducer public struct AppFeature: Sendable {
  public init() {}

  @ObservableState public struct State: Equatable {
    public var childStates: RemoteResult<IdentifiedArrayOf<ChildFeature.State>, AppError>

    public init(
      childStates: RemoteResult<IdentifiedArrayOf<ChildFeature.State>, AppError> = .initial
    ) { self.childStates = childStates }
  }

  public enum Action: Sendable { case childAction(IdentifiedActionOf<ChildFeature>) }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .childAction: return .none
      }
    }
    .ifLet(\.childStates.success, action: \.childAction) {
      EmptyReducer().forEach(\.self, action: \.self) { ChildFeature() }
    }
  }
}

public struct AppView: View {
  @Bindable var store: StoreOf<AppFeature>

  public init(store: StoreOf<AppFeature>) { self.store = store }

  public var body: some View {
    if let store = self.store.scope(state: \.childStates.success, action: \.childAction) {
      ForEach(store) { ChildView(store: $0) }
    }
  }
}

@Reducer public struct ChildFeature: Sendable {
  public init() {}

  @ObservableState public struct State: Equatable, Identifiable {
    public let id: UUID

    public init(id: UUID = UUID()) { self.id = id }
  }

  public enum Action: Sendable { case noop }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .noop: return .none
      }
    }
  }
}

public struct ChildView: View {
  @Bindable var store: StoreOf<ChildFeature>

  public init(store: StoreOf<ChildFeature>) { self.store = store }

  public var body: some View { EmptyView() }
}

public enum AppError: Equatable, Codable, Sendable, Error, LocalizedError { case unauthorized }
