import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: CloudInventoryStore
    @EnvironmentObject var auth: AuthManager

    @State private var selectedMaterial: MaterialType = .pp
    @State private var amount: Int = 1
    @State private var reason: String = "Print"
    private let reasons = ["Print", "Faulty", "Scrap"]

    @State private var didBootstrap = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {

            // Main content
            if auth.isSignedIn {
                mainUI
            } else {
                AuthView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            // sadece 1 kere çalışsın
            guard !didBootstrap else { return }
            didBootstrap = true

            await auth.restoreSession()
            if auth.isSignedIn {
                await store.refresh()
            }
        }
        .onChange(of: auth.isSignedIn) { _, signedIn in
            if signedIn {
                Task { await store.refresh() }
            } else {
                // store.clear()
            }
        }
        .safeAreaInset(edge: .bottom, alignment: .leading) {
            if !auth.isSignedIn {
                Text("Developed by Özge Sevin Keskin")
                    .font(.footnote)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.55))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.leading, 22)
                    .padding(.bottom, 18)
                    .allowsHitTesting(false)
            }
        }
    }


    private var mainUI: some View {
        NavigationSplitView {
            List {
                Section("Stock") {
                    ForEach(MaterialType.allCases) { m in
                        HStack {
                            Text(m.rawValue)
                            Spacer()
                            Text("\(store.quantity(for: m))")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Settings") {
                    Stepper("Low stock ≤ \(store.lowStockThreshold)",
                            value: $store.lowStockThreshold,
                            in: 0...500)
                }
            }
            .navigationTitle("Filament")
        } detail: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Actions").font(.title2).bold()
                    Spacer()
                    Button("Refresh") { Task { await store.refresh() } }
                    Button("Sign out") { Task { await auth.signOut() } }
                }

                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        Picker("Material", selection: $selectedMaterial) {
                            ForEach(MaterialType.allCases) { Text($0.rawValue).tag($0) }
                        }

                        HStack(spacing: 10) {
                            Text("Amount")
                            TextField("", value: $amount, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                                .onSubmit {
                                    // güvenlik: aralığa zorla
                                    amount = min(max(amount, 1), 1000)
                                }

                            Stepper("", value: $amount, in: 1...1000)
                                .labelsHidden()

                            Text("g")
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Button("Add Stock") {
                                Task {
                                    let email = auth.userEmail
                                    await store.addStock(material: selectedMaterial,
                                                         amount: amount,
                                                         userEmail: email)
                                }
                            }

                            Spacer()

                            Picker("Reason", selection: $reason) {
                                ForEach(reasons, id: \.self) { Text($0) }
                            }
                            .frame(width: 160)

                            Button("Reduce Stock") {
                                Task {
                                    let email = auth.userEmail
                                    await store.subtractStock(material: selectedMaterial,
                                                              amount: amount,
                                                              reason: reason,
                                                              userEmail: email)
                                }
                            }
                        }
                    }
                    .padding(6)
                } label: {
                    Text("Update stock")
                }

                GroupBox {
                    VStack(alignment: .leading) {
                        if store.logs.isEmpty {
                            Text("No logs yet").foregroundStyle(.secondary)
                        } else {
                            Table(store.logs) {
                                TableColumn("Time") { row in
                                    // created_at Date? olabilir → güvenli göster
                                    if let dt = row.created_at {
                                        Text(dt.formatted(date: .abbreviated, time: .shortened))
                                    } else {
                                        Text("—").foregroundStyle(.secondary)
                                    }
                                }
                                .width(160)

                                TableColumn("Material") { row in Text(row.material) }.width(80)
                                TableColumn("Δ") { row in Text("\(row.delta)").monospacedDigit() }.width(60)
                                TableColumn("Reason") { row in Text(row.reason ?? "") }.width(120)
                                TableColumn("User") { row in Text(row.user_email ?? "") }
                            }
                            .frame(minHeight: 260)
                        }
                    }
                    .padding(6)
                } label: {
                    Text("Log")
                }

                Spacer()

                HStack {
                    Text("Developed by Özge Sevin Keskin")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let email = auth.userEmail {
                        Text(email).font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .navigationTitle("Dashboard")
            .task { await store.requestNotificationPermissionIfNeeded() }
        }
    }
}

