//
//  ProspectsView.swift
//  HotProspects
//
//  Created by Kok on 11/9/24.
//

import SwiftUI
import SwiftData
import CodeScanner
import UserNotifications

struct ProspectsView: View {
    enum FilterType {
        case none, contacted, uncontacted
    }
    
    @Environment(\.modelContext) var modelContext
    @Query(sort: \Prospect.name) var prospects: [Prospect]
    
    @State private var isShowingScanner = false;
    @State private var selectedProspects = Set<Prospect>();
    
    let filter: FilterType
    
    var title: String {
        switch filter {
        case .none:
            "Everyone"
        case .contacted:
            "Contacted people"
        case .uncontacted:
            "Uncontacted people"
        }
    }
    
    var body: some View {
        NavigationStack {
            List(prospects, id: \.self, selection: $selectedProspects) { prospect in
                VStack(alignment: .leading) {
                    Text(prospect.name)
                        .font(.headline)
                        
                    Text(prospect.emailAddress)
                        .foregroundStyle(.secondary)
                }
                .swipeActions {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        modelContext.delete(prospect);
                        try? modelContext.save();
                    }
                    
                    if prospect.isContacted {
                        Button("Mark Uncontacted", systemImage: "person.crop.circle.badge.xmark") {
                            prospect.isContacted.toggle();
                        }
                        .tint(.blue)
                    } else {
                        Button("Mark Contacted", systemImage: "person.crop.circle.fill.badge.checkmark") {
                            prospect.isContacted.toggle();
                        }
                        .tint(.green)
                        
                        Button("Remind Me", systemImage: "bell") {
                            self.addNotification(for: prospect);
                        }
                        .tint(.orange)
                    }
                }
                .tag(prospect)
            }
            .navigationTitle(self.title)
            .toolbar {
                ToolbarItem {
                    Button("Scan", systemImage: "qrcode.viewfinder") {
                        self.isShowingScanner = true;
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    EditButton();
                }
                
                if (!selectedProspects.isEmpty) {
                    ToolbarItem(placement: .bottomBar) {
                        Button("Delete Selected", action: delete)
                            .foregroundStyle(.red)
                    }
                }
            }
            .sheet(isPresented: $isShowingScanner) {
                CodeScannerView(
                    codeTypes: [.qr],
                    simulatedData: "Paul Hudson\npaul@hackingwithswift.com",
                    completion: handleScan
                )
            }
        }
    }
    
    init(filter: FilterType) {
        self.filter = filter
        
        if filter != .none {
            let showContactOnly = filter == .contacted;
            
            _prospects = Query(filter: #Predicate {
                $0.isContacted == showContactOnly;
            }, sort: [SortDescriptor(\Prospect.name)])
        }
    }
    
    func handleScan(result: Result<ScanResult, ScanError>) {
        self.isShowingScanner = false;
        
        switch result {
        case .success(let result):
            let details = result.string.components(separatedBy: "\n");
            guard details.count == 2 else { return }
            
            let person = Prospect(name: details[0], emailAddress: details[1], isContacted: false);
            modelContext.insert(person);
            try? modelContext.save();
        case .failure(let error):
            print("Scanning failed: \(error.localizedDescription)")
        }
    }
    
    func delete() {
        for prospect in selectedProspects {
            modelContext.delete(prospect);
        }
        try? modelContext.save();
        self.selectedProspects = []
    }
    
    func addNotification(for prospect: Prospect) {
        let center = UNUserNotificationCenter.current();
        
        let addRequest = {
            let content = UNMutableNotificationContent();
            content.title = "Contact \(prospect.name)";
            content.subtitle = prospect.emailAddress;
            content.sound = UNNotificationSound.default;
            
//            var dateComponents = DateComponents();
//            dateComponents.hour = 9;
//            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false);
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false);
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger);
            
            center.add(request);
        }
        
        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                addRequest();
            } else {
                center.requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                    if success { addRequest() }
                    else if let error {
                        print(error.localizedDescription)
                    }
                }
            }
        }
    }
}

#Preview {
    ProspectsView(filter: .contacted)
        .modelContainer(for: Prospect.self)
}
