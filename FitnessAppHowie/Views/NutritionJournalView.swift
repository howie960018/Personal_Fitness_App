import SwiftUI
import SwiftData
import PhotosUI

struct NutritionJournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \NutritionEntry.timestamp, order: .reverse) private var allEntries: [NutritionEntry]
    
    @State private var showingAddEntry = false
    @State private var showingPendingList = false
    @State private var entryToEdit: NutritionEntry?
    
    private var pendingCount: Int {
        allEntries.filter { ($0.primitiveStatus ?? .complete) == .pending }.count
    }
    
    private var completedEntries: [NutritionEntry] {
        allEntries.filter { ($0.primitiveStatus ?? .complete) == .complete }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if allEntries.isEmpty {
                    emptyStateView
                } else {
                    nutritionListView
                }
            }
            .navigationTitle("飲食記錄")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if pendingCount > 0 {
                        Button {
                            showingPendingList = true
                        } label: {
                            Label("\(pendingCount) 筆待補完", systemImage: "clock.badge.exclamationmark")
                                .foregroundStyle(.orange)
                        }
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddEntry = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddEntry) {
                AddNutritionEntryView()
            }
            .sheet(isPresented: $showingPendingList) {
                PendingNutritionView()
            }
            .sheet(item: $entryToEdit) { entry in
                EditNutritionEntryView(entry: entry)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("尚無飲食記錄")
                .font(.title3)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 12) {
                Button("開始記錄飲食") {
                    showingAddEntry = true
                }
                .buttonStyle(.borderedProminent)
                
                Text("提示:外食時可先拍多張照片,稍後再補完份量")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
    
    private var nutritionListView: some View {
        List {
            if pendingCount > 0 {
                Section {
                    Button {
                        showingPendingList = true
                    } label: {
                        HStack {
                            Image(systemName: "clock.badge.exclamationmark")
                                .foregroundStyle(.orange)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("有 \(pendingCount) 筆記錄待補完")
                                    .font(.subheadline)
                                    .bold()
                                Text("點擊前往補完份量資訊")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .tint(.primary)
                }
                .listRowBackground(Color.orange.opacity(0.1))
            }
            
            ForEach(completedEntries) { entry in
                NavigationLink {
                    NutritionDetailView(entry: entry)
                } label: {
                    NutritionRowView(entry: entry)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        deleteEntry(entry)
                    } label: {
                        Label("刪除", systemImage: "trash")
                    }
                    
                    Button {
                        entryToEdit = entry
                    } label: {
                        Label("編輯", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }
        }
    }
    
    private func deleteEntry(_ entry: NutritionEntry) {
        // 刪除所有關聯的照片檔案
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            for filename in entry.photoFilenames {
                let filePath = documentsPath.appendingPathComponent(filename).path
                try? FileManager.default.removeItem(atPath: filePath)
            }
            
            // 也刪除舊格式的照片(向下相容)
            if let oldFilename = entry.photoFilename, !entry.photoFilenames.contains(oldFilename) {
                let filePath = documentsPath.appendingPathComponent(oldFilename).path
                try? FileManager.default.removeItem(atPath: filePath)
            }
        }
        
        modelContext.delete(entry)
    }
}

// MARK: - NutritionRowView (支援多張照片縮圖)

struct NutritionRowView: View {
    let entry: NutritionEntry
    
    var body: some View {
        HStack(spacing: 12) {
            // MARK: - 修改:支援多張照片縮圖顯示
            if !entry.photoURLs.isEmpty {
                if entry.photoURLs.count == 1 {
                    // 單張照片:完整顯示
                    AsyncImage(url: entry.photoURLs[0]) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    // 多張照片:顯示第一張 + 數量標記
                    ZStack(alignment: .bottomTrailing) {
                        AsyncImage(url: entry.photoURLs[0]) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Color.gray.opacity(0.3)
                        }
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        // 照片數量標記
                        Text("+\(entry.photoURLs.count - 1)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.7))
                            .clipShape(Capsule())
                            .padding(3)
                    }
                }
            } else {
                // 無照片佔位符
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: "fork.knife")
                            .foregroundStyle(.secondary)
                    }
            }
            
            // 文字資訊
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.mealType)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Text(entry.timestamp, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text(entry.entryDescription.isEmpty ? "無描述" : entry.entryDescription)
                        .font(.subheadline)
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    if entry.estimatedCalories > 0 {
                        Text("\(Int(entry.estimatedCalories)) kcal")
                            .font(.caption)
                            .foregroundStyle(.blue)
                            .bold()
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }
}
