import LuciqSDK
import SwiftUI

struct PatientProfileView: View {
    @Environment(AuthStore.self) private var auth
    @State private var patient: Patient?
    @State private var loadError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let patient {
                        header(patient)

                        SectionHeader(title: "Patient", systemImage: "person.text.rectangle")
                        VStack(spacing: 0) {
                            privateRow("calendar", "Date of birth", patient.birthDate)
                            Divider()
                            publicRow("drop.fill", "Blood group", patient.bloodGroup)
                            Divider()
                            privateRow("person.badge.shield.checkmark.fill", "SSN", patient.ssn)
                        }
                        .brandCard(padding: 12)

                        SectionHeader(title: "Contact", systemImage: "person.crop.circle")
                        VStack(spacing: 0) {
                            privateRow("envelope.fill", "Email", patient.email)
                            Divider()
                            privateRow("phone.fill", "Phone", patient.phone)
                            Divider()
                            privateRow(
                                "house.fill",
                                "Address",
                                "\(patient.address.address), \(patient.address.city), \(patient.address.state) \(patient.address.postalCode)"
                            )
                        }
                        .brandCard(padding: 12)

                        SectionHeader(title: "Billing", systemImage: "creditcard")
                        VStack(spacing: 0) {
                            privateRow("creditcard.fill", "Card", "\(patient.bank.cardType) \(patient.bank.cardNumber)")
                            Divider()
                            privateRow("calendar.badge.clock", "Expires", patient.bank.cardExpire)
                            Divider()
                            privateRow("building.columns.fill", "IBAN", patient.bank.iban)
                        }
                        .brandCard(padding: 12)
                    } else if let loadError {
                        Label(loadError, systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .foregroundStyle(Brand.heart)
                            .brandCard(padding: 14)
                    } else {
                        ProgressView()
                            .padding(.top, 60)
                    }

                    if let clinician = auth.user {
                        SectionHeader(title: "Signed in as", systemImage: "stethoscope")
                        VStack(spacing: 0) {
                            publicRow("person.fill", "Clinician", "\(clinician.firstName) \(clinician.lastName)")
                            Divider()
                            Button("Sign out", role: .destructive) { auth.signOut() }
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 4)
                        }
                        .brandCard(padding: 12)
                    }
                }
                .padding()
            }
            .background(Brand.canvas.ignoresSafeArea())
            .navigationTitle("Patient profile")
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private func header(_ patient: Patient) -> some View {
        HStack(spacing: 16) {
            Image(systemName: "person.fill")
                .font(.system(size: 34))
                .foregroundStyle(.white)
                .frame(width: 72, height: 72)
                .background(Circle().fill(.white.opacity(0.2)))
                .overlay(Circle().stroke(.white.opacity(0.7), lineWidth: 3))
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text("\(patient.firstName) \(patient.lastName)")
                        .font(.title2.bold())
                        .luciq_privateView()
                    PHIBadge()
                }
                HStack(spacing: 6) {
                    chip("Patient #\(patient.id)")
                    chip(patient.bloodGroup, icon: "drop.fill")
                }
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white)
        .padding(18)
        .background(
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Brand.heroGradient)
                ECGTrace(color: .white.opacity(0.22), lineWidth: 2, speed: 60, beatWidth: 110)
                    .frame(height: 50)
                    .padding(.bottom, 6)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
        )
        .shadow(color: Brand.heart.opacity(0.3), radius: 16, y: 8)
    }

    private func chip(_ text: String, icon: String? = nil) -> some View {
        HStack(spacing: 3) {
            if let icon { Image(systemName: icon) }
            Text(text)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Capsule().fill(.white.opacity(0.22)))
    }

    /// A PHI row: masked as a Luciq private view, like before.
    private func privateRow(_ icon: String, _ label: String, _ value: String) -> some View {
        infoRow(icon, label, value, phi: true).luciq_privateView()
    }

    private func publicRow(_ icon: String, _ label: String, _ value: String) -> some View {
        infoRow(icon, label, value, phi: false)
    }

    private func infoRow(_ icon: String, _ label: String, _ value: String, phi: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Brand.heart)
                .frame(width: 24)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if phi { PHIBadge() }
                }
                Text(value)
                    .font(.body)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 4)
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
