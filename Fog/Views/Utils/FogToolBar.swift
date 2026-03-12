//
//  FogToolBar.swift
//  Fog
//
//  Created by Akshat  Saladi on 2/25/26.
//

import SwiftUI
import SwiftData

struct FogToolbar: ViewModifier {
    @Environment(\.modelContext) private var context
    @Environment(PileManager.self) private var pileManager
    @Binding var filterByCanvases: Bool
    @Binding var sortOrder: CanvasSortOrder
    @State private var showSortSheet = false

    let namespace: Namespace.ID
    @Binding var path: NavigationPath

    @State private var showSettings = false

    @Query(sort: \Pile.createdOn, order: .forward) private var allPiles: [Pile]

    func body(content: Content) -> some View {
        content
            .toolbar {
                // Pile switcher — top left
                ToolbarItem(placement: .topBarLeading) {
                    pileSwitcherMenu
                }

                ToolbarItem(placement: .destructiveAction) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .matchedTransitionSource(id: "settings", in: namespace)
                }
                ToolbarItem(placement: .bottomBar) {
                    if filterByCanvases {
                        HStack(spacing: 0) {
                            Button {
                                withAnimation(.spring) { filterByCanvases.toggle() }
                            } label: {
                                Image(systemName: "rectangle.stack.fill")
                                   
                            }
                            
                            Button {
                                showSortSheet = true
                            } label: {
                                VStack(alignment: .leading) {
                                    Text("Filtered by")
                                        .font(.caption2)
                                    Text("Canvases")
                                        .font(.caption2)
                                    Text(sortOrder.shortLabel)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                
                                
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption2)
                                    .foregroundStyle(Color.accentColor)
                            }
                            .matchedTransitionSource(id: "sort", in: namespace)

                        }
                        .animation(.spring, value: filterByCanvases)
                    } else {
                        Button {
                            withAnimation(.spring) { filterByCanvases.toggle() }
                        } label: {
                            Image(systemName: "rectangle.stack")
                        }
                        .animation(.spring, value: filterByCanvases)
                    }
                }
                
                ToolbarSpacer(.fixed, placement: .bottomBar)
                
                DefaultToolbarItem(kind: .search, placement: .bottomBar)
                
                ToolbarSpacer(.flexible, placement: .bottomBar)
                
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        let newCanvas = Canvas()
                        newCanvas.pile = pileManager.activePile
                        context.insert(newCanvas)
                        path.append(newCanvas)
                    } label: {
                        Image(systemName: "plus")
                    }
                    .matchedTransitionSource(id: "createCanvas", in: namespace)
                    .buttonStyle(.glassProminent)
                }
            }
            .sheet(isPresented: $showSortSheet) {
                SortOptionsSheet(sortOrder: $sortOrder)
                    .navigationTransition(.zoom(sourceID: "sort", in: namespace))
                    .presentationDetents([.height(320)])
                    .presentationDragIndicator(.visible)

            }
        
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .navigationTransition(.zoom(sourceID: "settings", in: namespace))
                    .presentationDetents([.medium, .large])
            }
    }

    // MARK: - Pile Switcher

    @ViewBuilder
    private var pileSwitcherMenu: some View {
        Menu {
            ForEach(allPiles) { pile in
                Button {
                    pileManager.switchTo(pile)
                } label: {
                    HStack {
                        Text(pile.name)
                        if pile === pileManager.activePile {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                if let name = pileManager.activePile?.name {
                    Text(name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

extension View {
    func fogToolBar(namespace: Namespace.ID, path: Binding<NavigationPath>, filterByCanvases: Binding<Bool>, sortOrder: Binding<CanvasSortOrder>) -> some View {
        modifier(FogToolbar(filterByCanvases: filterByCanvases, sortOrder: sortOrder, namespace: namespace, path: path))
    }
}
