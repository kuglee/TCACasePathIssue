import ComposableArchitecture
import SwiftUI

@Reducer public struct AppFeature: Sendable {
  public init() {}

  @ObservableState public struct State: Equatable {
    public var listState: RemoteResult<ListReducer<ChildFeature>.State, AppError>

    public init(listState: RemoteResult<ListReducer<ChildFeature>.State, AppError> = .initial) {
      self.listState = listState
    }
  }

  public enum Action: Sendable { case listAction(ListReducer<ChildFeature>.Action) }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .listAction: return .none
      }
    }
    .ifLet(\.listState.success, action: \.listAction) { ListReducer() }
  }
}

public struct AppView: View {
  @Bindable var store: StoreOf<AppFeature>

  public init(store: StoreOf<AppFeature>) { self.store = store }

  public var body: some View {
    switch self.store.listState {
    case .success:
      if let store = self.store.scope(state: \.listState.success, action: \.listAction) {
        ForEach(store.scope(state: \.childStates, action: \.childAction)) { ChildView(store: $0) }
      }
    default: EmptyView()
    }
  }
}

@Reducer public struct ListReducer<ChildFeature: Reducer & DefaultInit>: Sendable
where
  ChildFeature.State: Equatable & Identifiable & Sendable,
  ChildFeature.State.ID: Sendable,
  ChildFeature.Action: Sendable
{
  public init() {}

  @dynamicMemberLookup @ObservableState public struct State: Equatable, Sendable {
    public var childStates: IdentifiedArrayOf<ChildFeature.State>

    public init(childStates: IdentifiedArrayOf<ChildFeature.State> = []) {
      self.childStates = childStates
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<IdentifiedArrayOf<ChildFeature.State>, T>)
      -> T
    { self.childStates[keyPath: keyPath] }

    public subscript<T>(
      dynamicMember keyPath: WritableKeyPath<IdentifiedArrayOf<ChildFeature.State>, T>
    ) -> T {
      get { self.childStates[keyPath: keyPath] }
      set { self.childStates[keyPath: keyPath] = newValue }
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

@Reducer public struct ChildFeature: Sendable, DefaultInit {
  public init() {}

  @ObservableState public struct State: Equatable, Identifiable, Sendable {
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

public protocol DefaultInit { init() }
