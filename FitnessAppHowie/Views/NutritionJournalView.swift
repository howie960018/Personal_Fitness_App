import SwiftUI
import SwiftData
import PhotosUI

struct NutritionJournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \NutritionEntry.timestamp, order: .reverse) private var allEntries: [NutritionEntry]
    
    @State private var showingAddEntry = false
    @State private var showingPendingList = false
    @State private var entryToEdit: NutritionEntry?
    
    // 修正：手動過濾並處理 nil 的舊資料
    private var pendingCount: Int {
        allEntries.filter { ($0.primitiveStatus ?? .complete) == .pending }.count
    }
    
    // 修正：只顯示已完成的記錄，並處理舊資料相容性
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
                AddNutritionEntryView() // 確保此視圖在下方有定義
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
                
                Text("提示：外食時可先拍照，稍後再補完份量")
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
                    NutritionRowView(entry: entry) // 確保此視圖在下方有定義
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
        if let filename = entry.photoFilename,
           let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let filePath = documentsPath.appendingPathComponent(filename).path
            try? FileManager.default.removeItem(atPath: filePath)
        }
        modelContext.delete(entry)
    }
}


// MARK: - NutritionRowView (已簡化：只顯示縮圖與基本資訊)

struct NutritionRowView: View {
    let entry: NutritionEntry
    
    var body: some View {
        HStack(spacing: 12) {
            // 1. 縮圖 (保持不變)
            if let photoPath = entry.photoPath {
                AsyncImage(url: URL(fileURLWithPath: photoPath)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                // 如果沒有照片，顯示一個簡單的佔位符
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: "fork.knife")
                            .foregroundStyle(.secondary)
                    }
            }
            
            // 2. 文字資訊 (移除 MacroTag，只留總結)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.mealType)
                        .font(.headline)
                        // MARK: - 修改：改為 primary (深色模式下為白色)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    // 顯示時間
                    Text(entry.timestamp, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    // 顯示描述 (例如：雞胸肉便當)
                    Text(entry.entryDescription.isEmpty ? "無描述" : entry.entryDescription)
                        .font(.subheadline)
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    // 僅顯示總熱量估算
                    if entry.estimatedCalories > 0 {
                        Text("\(Int(entry.estimatedCalories)) kcal")
                            .font(.caption)
                            .foregroundStyle(.blue)
                            .bold()
                    }
                }
            }
        }
        .padding(.vertical, 6) // 稍微增加一點垂直間距讓視覺更舒適
    }
}
