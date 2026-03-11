//
//  SortOptionsSheet.swift
//  Fog
//
//  Created by Akshat  Saladi on 3/10/26.
//

import SwiftUI

import SwiftUI

enum CanvasSortOrder: String, CaseIterable {
    case updatedNewest = "Updated: Newest First"
    case updatedOldest = "Updated: Oldest First"
    case createdNewest = "Created: Newest First"
    case createdOldest = "Created: Oldest First"
    
    var shortLabel: String {
        switch self {
        case .updatedNewest: return "Updated ↓"
        case .updatedOldest: return "Updated ↑"
        case .createdNewest: return "Created ↓"
        case .createdOldest: return "Created ↑"
        }
    }
    
    
}

struct SortOptionsSheet: View {
    @Binding var sortOrder: CanvasSortOrder
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("By Last Updated")) {
                    sortRow(.updatedNewest)
                    sortRow(.updatedOldest)
                }
                Section(header: Text("By Date Created")) {
                    sortRow(.createdNewest)
                    sortRow(.createdOldest)
                }
            }
            .navigationTitle("Sort")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    @ViewBuilder
    private func sortRow(_ option: CanvasSortOrder) -> some View {
        Button {
            withAnimation(.spring) {
                sortOrder = option
            }
            dismiss()
        } label: {
            HStack {
                Text(option.rawValue)
                Spacer()
                if sortOrder == option {
                    Image(systemName: "checkmark")
                        .fontWeight(.semibold)
                        .padding()
                        .glassEffect(.regular.interactive())
                        .transition(.scale.combined(with: .opacity))
                    
                }
            }
        }
    }
}

#Preview {
    SortOptionsSheet(sortOrder: .constant(.updatedNewest))
}
