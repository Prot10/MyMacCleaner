import SwiftUI

// MARK: - Port Management View Model

@MainActor
class PortManagementViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var connections: [NetworkConnection] = []
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var filterType: FilterType = .all

    @Published var showKillConfirmation = false
    @Published var connectionToKill: NetworkConnection?

    @Published var showToast = false
    @Published var toastMessage = ""
    @Published var toastType: ToastType = .success

    enum FilterType: String, CaseIterable {
        case all
        case listening
        case established

        var icon: String {
            switch self {
            case .all: return "network"
            case .listening: return "antenna.radiowaves.left.and.right"
            case .established: return "link"
            }
        }

        var localizedName: String {
            switch self {
            case .all: return L("portManagement.filter.all")
            case .listening: return L("portManagement.filter.listening")
            case .established: return L("portManagement.filter.established")
            }
        }
    }

    // MARK: - Computed Properties

    var filteredConnections: [NetworkConnection] {
        var result = connections

        if !searchText.isEmpty {
            result = result.filter {
                $0.processName.localizedCaseInsensitiveContains(searchText) ||
                String($0.localPort).contains(searchText) ||
                ($0.remoteAddress?.contains(searchText) ?? false)
            }
        }

        switch filterType {
        case .all:
            break
        case .listening:
            result = result.filter { $0.state == "LISTEN" }
        case .established:
            result = result.filter { $0.state == "ESTABLISHED" }
        }

        return result.sorted { $0.localPort < $1.localPort }
    }

    var listeningCount: Int {
        connections.filter { $0.state == "LISTEN" }.count
    }

    var establishedCount: Int {
        connections.filter { $0.state == "ESTABLISHED" }.count
    }

    // MARK: - Initialization

    init() {
        refreshConnections()
    }

    // MARK: - Public Methods

    func refreshConnections() {
        isLoading = true

        Task {
            let result = await scanNetworkConnections()
            connections = result
            isLoading = false
        }
    }

    func prepareKill(_ connection: NetworkConnection) {
        connectionToKill = connection
        showKillConfirmation = true
    }

    func confirmKill() {
        guard let connection = connectionToKill else { return }

        Task {
            let success = await killProcess(pid: connection.pid)

            if success {
                connections.removeAll { $0.id == connection.id }
                showToastMessage(LFormat("portManagement.toast.terminated %@", connection.processName), type: .success)
            } else {
                showToastMessage(L("portManagement.toast.failedAdmin"), type: .error)
            }

            showKillConfirmation = false
            connectionToKill = nil
        }
    }

    func cancelKill() {
        showKillConfirmation = false
        connectionToKill = nil
    }

    func dismissToast() {
        showToast = false
    }

    // MARK: - Private Methods

    private func scanNetworkConnections() async -> [NetworkConnection] {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var connections: [NetworkConnection] = []

                // Run lsof to get network connections
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
                process.arguments = ["-iTCP", "-sTCP:LISTEN,ESTABLISHED", "-n", "-P"]

                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = FileHandle.nullDevice

                do {
                    try process.run()
                    process.waitUntilExit()

                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    if let output = String(data: data, encoding: .utf8) {
                        connections = self.parseLsofOutput(output)
                    }
                } catch {
                    // Silent fail
                }

                continuation.resume(returning: connections)
            }
        }
    }

    private nonisolated func parseLsofOutput(_ output: String) -> [NetworkConnection] {
        var connections: [NetworkConnection] = []
        let lines = output.components(separatedBy: "\n")

        // Skip header line
        for line in lines.dropFirst() {
            guard !line.isEmpty else { continue }

            let parts = line.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
            guard parts.count >= 9 else { continue }

            let processName = parts[0]
            guard let pid = Int32(parts[1]) else { continue }

            // Parse the NAME column (last part)
            let nameColumn = parts[8]

            // Parse local address and port
            var localAddress = "*"
            var localPort: Int = 0
            var remoteAddress: String? = nil
            var remotePort: Int? = nil
            var state = "UNKNOWN"

            // Check if there's a state at the end
            if parts.count >= 10, ["LISTEN", "ESTABLISHED", "CLOSE_WAIT", "TIME_WAIT", "SYN_SENT", "SYN_RECEIVED"].contains(parts[9].replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")) {
                state = parts[9].replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
            }

            // Parse addresses
            if nameColumn.contains("->") {
                // Established connection: local->remote
                let addressParts = nameColumn.components(separatedBy: "->")
                if addressParts.count == 2 {
                    let localParts = parseAddressPort(addressParts[0])
                    localAddress = localParts.address
                    localPort = localParts.port

                    let remoteParts = parseAddressPort(addressParts[1])
                    remoteAddress = remoteParts.address
                    remotePort = remoteParts.port
                }
                state = "ESTABLISHED"
            } else {
                // Listening
                let localParts = parseAddressPort(nameColumn)
                localAddress = localParts.address
                localPort = localParts.port
                state = "LISTEN"
            }

            guard localPort > 0 else { continue }

            let connection = NetworkConnection(
                processName: processName,
                pid: pid,
                localAddress: localAddress,
                localPort: localPort,
                remoteAddress: remoteAddress,
                remotePort: remotePort,
                state: state,
                protocol: "TCP"
            )

            connections.append(connection)
        }

        return connections
    }

    private nonisolated func parseAddressPort(_ string: String) -> (address: String, port: Int) {
        // Format: address:port or [ipv6]:port
        if let lastColon = string.lastIndex(of: ":") {
            let address = String(string[..<lastColon])
            let portString = String(string[string.index(after: lastColon)...])
            let port = Int(portString) ?? 0
            return (address, port)
        }
        return ("*", 0)
    }

    private func killProcess(pid: Int32) async -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = kill(pid, SIGTERM)
                continuation.resume(returning: result == 0)
            }
        }
    }

    private func showToastMessage(_ message: String, type: ToastType) {
        toastMessage = message
        toastType = type
        showToast = true

        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            showToast = false
        }
    }
}

// MARK: - Network Connection Model

struct NetworkConnection: Identifiable, Equatable {
    let id = UUID()
    let processName: String
    let pid: Int32
    let localAddress: String
    let localPort: Int
    let remoteAddress: String?
    let remotePort: Int?
    let state: String
    let `protocol`: String

    var stateColor: Color {
        switch state {
        case "LISTEN": return .green
        case "ESTABLISHED": return .blue
        case "CLOSE_WAIT", "TIME_WAIT": return .orange
        default: return .gray
        }
    }

    var formattedLocal: String {
        "\(localAddress):\(localPort)"
    }

    var formattedRemote: String? {
        guard let addr = remoteAddress, let port = remotePort else { return nil }
        return "\(addr):\(port)"
    }

    static func == (lhs: NetworkConnection, rhs: NetworkConnection) -> Bool {
        lhs.id == rhs.id
    }
}
