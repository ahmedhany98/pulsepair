import LuciqSDK
import SwiftUI

struct PatientProfileView: View {
    @Environment(AuthStore.self) private var auth
    @State private var patient: Patient?
    @State private var loadError: String?

    var body: some View {
        NavigationStack {
            List {
                if let patient {
                    Section("Patient") {
                        privateRow("Name", "\(patient.firstName) \(patient.lastName)")
                        privateRow("Date of birth", patient.birthDate)
                        LabeledContent("Blood group", value: patient.bloodGroup)
                        privateRow("SSN", patient.ssn)
                    }
                    Section("Contact") {
                        privateRow("Email", patient.email)
                        privateRow("Phone", patient.phone)
                        privateRow(
                            "Address",
                            "\(patient.address.address), \(patient.address.city), \(patient.address.state) \(patient.address.postalCode)"
                        )
                    }
                    Section("Billing") {
                        privateRow("Card", "\(patient.bank.cardType) \(patient.bank.cardNumber)")
                        privateRow("Expires", patient.bank.cardExpire)
                        privateRow("IBAN", patient.bank.iban)
                    }
                } else if let loadError {
                    Text(loadError).foregroundStyle(.red)
                } else {
                    ProgressView()
                }
                if let clinician = auth.user {
                    Section("Signed in as") {
                        LabeledContent("Clinician", value: "\(clinician.firstName) \(clinician.lastName)")
                        Button("Sign out", role: .destructive) { auth.signOut() }
                    }
                }
            }
            .navigationTitle("Patient profile")
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private func privateRow(_ label: String, _ value: String) -> some View {
        LabeledContent(label, value: value).luciq_privateView()
    }

    private func load() async {
        do {
            patient = try await API.get("/users/1")
            loadError = nil
        } catch {
            loadError = "Couldn't load the patient: \(error.localizedDescription)"
        }
    }
}
