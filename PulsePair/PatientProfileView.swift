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
                        LabeledContent("Name", value: "\(patient.firstName) \(patient.lastName)")
                        LabeledContent("Date of birth", value: patient.birthDate)
                        LabeledContent("Blood group", value: patient.bloodGroup)
                        LabeledContent("SSN", value: patient.ssn)
                    }
                    Section("Contact") {
                        LabeledContent("Email", value: patient.email)
                        LabeledContent("Phone", value: patient.phone)
                        LabeledContent(
                            "Address",
                            value: "\(patient.address.address), \(patient.address.city), \(patient.address.state) \(patient.address.postalCode)"
                        )
                    }
                    Section("Billing") {
                        LabeledContent("Card", value: "\(patient.bank.cardType) \(patient.bank.cardNumber)")
                        LabeledContent("Expires", value: patient.bank.cardExpire)
                        LabeledContent("IBAN", value: patient.bank.iban)
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

    private func load() async {
        do {
            patient = try await API.get("/users/1")
            loadError = nil
        } catch {
            loadError = "Couldn't load the patient: \(error.localizedDescription)"
        }
    }
}
