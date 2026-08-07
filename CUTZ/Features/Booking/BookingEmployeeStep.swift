import SwiftUI

/// Schritt 2: Wer soll dich schneiden?
///
/// Ganz oben steht "Schnellster Termin" — das ist die Antwort für alle,
/// denen die Person egal ist, und sie soll keinen Umweg kosten. Wer
/// dagegen zu einer bestimmten Person will, findet sie direkt darunter.
///
/// Beide Wege sind gleich kurz. Genau das ist der Punkt: Die App darf
/// niemanden zu einer Entscheidung zwingen, die er gar nicht treffen
/// möchte.
struct BookingEmployeeStep: View {

    let employees: [BarberEmployee]

    /// `nil` bedeutet "egal welcher Barber".
    @Binding var selection: BarberEmployee?

    var body: some View {
        VStack(spacing: 10) {
            anyBarberCard

            if !employees.isEmpty {
                HStack {
                    Text("Oder direkt jemanden wählen")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.top, 8)
                .padding(.horizontal, 4)

                ForEach(employees) { employee in
                    EmployeeCard(
                        employee: employee,
                        isSelected: selection?.id == employee.id
                    ) {
                        withAnimation(.snappy(duration: 0.2)) {
                            selection = employee
                        }
                    }
                }
            }
        }
    }

    private var anyBarberCard: some View {
        Button {
            withAnimation(.snappy(duration: 0.2)) { selection = nil }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "bolt.fill")
                    .font(.title3)
                    .foregroundStyle(selection == nil ? Color.accentColor : .secondary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Schnellster Termin")
                        .font(.headline)
                    Text("Egal welcher Barber")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(selection == nil ? Color.accentColor : Color.clear, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
    }
}

/// Eine auswählbare Person.
private struct EmployeeCard: View {

    let employee: BarberEmployee
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ShopImage(
                    seed: employee.id.uuidString,
                    url: employee.imageURL,
                    symbolSize: 18,
                    symbolName: "person.fill"
                )
                .frame(width: 52, height: 52)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(employee.name)
                        .font(.headline)

                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.orange)
                        Text(AppText.number(employee.rating))
                            .font(.caption)
                            .fontWeight(.medium)
                        Text("· \(employee.specialtiesText)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ScrollView {
        BookingEmployeeStep(
            employees: MockData.shops[0].employees,
            selection: .constant(nil)
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
