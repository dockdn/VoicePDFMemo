import SwiftUI

struct ContentView: View {
    @StateObject private var contractStore = ContractStore()
    @State private var searchText = ""
    @State private var contractToDelete: SavedContract?

    private var filteredContracts: [SavedContract] {
        let sorted = contractStore.contracts.sorted {
            $0.createdAt > $1.createdAt
        }

        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return sorted
        }

        return sorted.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                List {
                    Section {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Image(systemName: "house.fill")
                                    .font(.title2)
                                    .foregroundColor(.red)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Panther Home Improvements")
                                        .font(.headline)

                                    Text("Contract Manager")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }

                                Spacer()
                            }

                            NavigationLink {
                                ContractEditorView(
                                    contract: nil,
                                    contractStore: contractStore
                                )
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title)

                                    VStack(alignment: .leading) {
                                        Text("New Contract")
                                            .font(.headline)

                                        Text("Create a new entry agreement")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.85))
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(14)
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    Section {
                        if filteredContracts.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "doc.text")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)

                                Text("No contracts found")
                                    .font(.headline)

                                Text("Create a new contract to get started.")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                        } else {
                            ForEach(filteredContracts) { contract in
                                NavigationLink {
                                    ContractEditorView(
                                        contract: contract,
                                        contractStore: contractStore
                                    )
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "doc.text.fill")
                                            .font(.title2)
                                            .foregroundColor(.red)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(contract.title)
                                                .font(.headline)

                                            Text(contract.createdAt.formatted(date: .abbreviated, time: .shortened))
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding(.vertical, 5)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        contractToDelete = contract
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    } header: {
                        Text("Recent Contracts")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Contracts")
            .searchable(text: $searchText, prompt: "Search contracts")
            .alert("Delete Contract?", isPresented: Binding(
                get: { contractToDelete != nil },
                set: { if !$0 { contractToDelete = nil } }
            )) {
                Button("Cancel", role: .cancel) {
                    contractToDelete = nil
                }

                Button("Delete", role: .destructive) {
                    if let contractToDelete {
                        contractStore.deleteContract(id: contractToDelete.id)
                    }

                    contractToDelete = nil
                }
            } message: {
                Text("This will permanently delete this saved contract.")
            }
        }
    }
}
