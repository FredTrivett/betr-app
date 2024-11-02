import SwiftUI

struct ReflectionHistoryList: View {
    let reflections: [DailyReflection]
    let onLoadMore: () -> Void
    let onTapReflection: (Date) -> Void
    
    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(reflections) { reflection in
                ReflectionRow(reflection: reflection, onTap: onTapReflection)
                    .onAppear {
                        if reflection == reflections.last {
                            onLoadMore()
                        }
                    }
            }
        }
    }
} 