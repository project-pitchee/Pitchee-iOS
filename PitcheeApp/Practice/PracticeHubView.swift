import SwiftUI

/// Live tools and library topics share one native, searchable navigation list.
struct PracticeHubView: View {
    @State private var searchText = ""
    private let store = VoiceTrainingLibraryStore.shared

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var categories: [(id: String, title: String)] {
        Dictionary(grouping: store.articles, by: \.category)
            .compactMap { category, articles in
                articles.first.map { (id: category, title: $0.categoryDisplayTitle) }
            }
            .sorted { $0.id < $1.id }
    }

    var body: some View {
        List {
            if isSearching {
                ForEach(store.search(query: searchText)) { article in
                    NavigationLink {
                        VoiceArticleContentView(article: article)
                    } label: {
                        Text(article.title)
                            .font(.body)
                    }
                }
            } else {
                Section("practice.hub.live.title") {
                    NavigationLink {
                        PitchMonitorView()
                    } label: {
                        Label(LocalizedStringKey(MonitorKind.pitch.titleKey), systemImage: MonitorKind.pitch.symbol)
                    }
                    .accessibilityIdentifier("monitor.openPitch")
                    NavigationLink {
                        SpectrumMonitorView()
                    } label: {
                        Label(LocalizedStringKey(MonitorKind.spectrum.titleKey), systemImage: MonitorKind.spectrum.symbol)
                    }
                    .accessibilityIdentifier("monitor.openSpectrum")
                }
                Section("voiceLibrary.title") {
                    ForEach(categories, id: \.id) { category in
                        NavigationLink {
                            VoiceTrainingLibraryContentView(initialCategory: category.id)
                        } label: {
                            Text(category.title)
                        }
                        .accessibilityIdentifier("practice.category.\(category.id)")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("practice.hub.tab")
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always),
                    prompt: Text("practice.hub.search"))
        .overlay {
            if isSearching && store.search(query: searchText).isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
    }
}
