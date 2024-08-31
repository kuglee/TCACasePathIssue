import ComposableArchitecture
import SwiftUI

@Reducer public struct AppFeature: Sendable {
  public init() {}

  @ObservableState public struct State: Equatable {
    public var listState: RemoteResult<ListFeature.State, AppError>

    public init(listState: RemoteResult<ListFeature.State, AppError> = .initial) {
      self.listState = listState
    }
  }

  public enum Action: Sendable { case listAction(ListFeature.Action) }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .listAction: return .none
      }
    }
    .ifLet(\.listState.success, action: \.listAction) { ListFeature() }
  }
}

public struct AppView: View {
  @Bindable var store: StoreOf<AppFeature>

  public init(store: StoreOf<AppFeature>) { self.store = store }

  public var body: some View {
    if let store = self.store.scope(state: \.listState.success, action: \.listAction) {
      ListView(store: store)
    }
  }
}

@Reducer public struct ListFeature: Sendable {
  public init() {}

  @ObservableState public struct State: Equatable {
    public var childStates: IdentifiedArrayOf<ChildFeature.State>

    public init(childStates: IdentifiedArrayOf<ChildFeature.State> = []) {
      self.childStates = childStates
    }
  }

  public enum Action: Sendable { case childAction(IdentifiedActionOf<ChildFeature>) }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .childAction: return .none
      }
    }
    .forEach(\.childStates, action: \.childAction) { ChildFeature() }
  }
}

public struct ListView: View {
  @Bindable var store: StoreOf<ListFeature>

  public init(store: StoreOf<ListFeature>) { self.store = store }

  public var body: some View {
    ForEach(self.store.scope(state: \.childStates, action: \.childAction)) { ChildView(store: $0) }
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
